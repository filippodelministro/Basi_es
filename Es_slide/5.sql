Argomenti:
    - GROUP BY



--*==================================================================================
--*									ES SLIDE										
--*==================================================================================

--?Indicare la parcella media dei medici di ciascuna specializzazione
select M.Specializzazione, avg(M.Parcella) as ParcellaMedia
from Medico M
group by M.Specializzazione

--?Per ogni specializzazione medica, indicarne il nome, la parcella minima
--?e il cognome del medico a cui appartiene
select M.Specializzazione, D.ParcellaMinima, M.Cognome
from Medico M natural join (
		select M1.Specializzazione, min(M1.Parcella) as ParcellaMinima
        from Medico M1
        group by M1.Specializzazione 
)as D
where M.Parcella = D.ParcellaMinima

--?Indicare le specializzazioni della clinica con più di due medici
select*
from Medico M
group by M.Specializzazione
having count(*) >= 2

--?Indicare le specializzazioni con la più alta parcella media
--cerco specializzazione che abbia la media di parcella uguale alla migliore
select M.Specializzazione
from Medico M
group by M.Specializzazione
having avg(M.Parcella) = (
        --trovo la maggiore
		select max(D.MediaParcella)
		from(
            --trovo media parcelle per ogni specializzazione
			select M.Specializzazione, avg(M.Parcella) as MediaParcella
			from Medico M
			group by M.Specializzazione
		) as D
)

--?Indicare le specializzazioni con più di due medici di Pisa.
select M.Specializzazione
from Medico M
where M.Citta = 'Pisa'
group by M.Specializzazione
having count(*) > 2;		--e se facevo count(distinct M.Matricola)??

--?Considerati i soli pazienti di Pisa, indicarne nome e cognome, e la spesa
--?sostenuta per le visite di ciascuna specializzazione, nel triennio 2008-2010
select P.Nome, P.Cognome, M.Specializzazione, sum(M.Parcella) as spesa
from Paziente P inner join Visita V on P.CodFiscale = V.Paziente
				inner join Medico M on M.Matricola = V.Medico
where P.Citta = 'Pisa'
	and V.Mutuata = 0
    and year(V.Data) between 2008 and 2010
group by P.CodFiscale, M.Specializzazione

--*==================================================================================
--*									ES IN FONDO												
--*==================================================================================

--?1. Indicare le specializzazioni che hanno solo medici della stessa città. [Risolvere con e
--?senza subquery].
select M.Specializzazione
from Medico M
group by M.Specializzazione
having count(distinct M.Citta) = 1;


--?2. Considerando pazienti della stessa città, indicare il numero di medici di città diversa
--?dalla loro, dai quali sono stati visitati.
select P.Citta, count(distinct V.Medico) as MediciDiversi
from Paziente P inner join Visita V on P.CodFiscale = V.Paziente
				inner join Medico M on M.Matricola = V.Medico
where P.Citta <> M.Citta
group by P.Citta


--?3. Indicare la specializzazione più redditizia per la clinica, e il medico che con le sue
--?visite ha contribuito maggiormente agli incassi realizzati da tale specializzazione, nel
--?corso degli ultimi dieci anni. In caso di pari merito, restituire tutti gli ex aequo.
--fix: sicuro c'è un modo migliore, ma non l'ho trovato
with
VisiteTarget as (
		select *
		from Medico M inner join Visita V on M.Matricola = V.Medico
		where V.Data > current_date() - interval 10 year
			and V.Mutuata = 0
),
IncassoSpec as (
		select VT.Specializzazione, sum(VT.Parcella) as Incasso
		from VisiteTarget VT
		group by VT.Specializzazione
),
SpecMigliore as (
		select *
		from IncassoSpec
		where Incasso = (
				select max(I.Incasso) as IncassoMax
				from IncassoSpec I
		)
)

select VT.Specializzazione, VT.Medico
from VisiteTarget VT natural join SpecMigliore SM
group by VT.Medico
having sum(VT.Parcella) = (
			select max(D.Incasso)
			from(
					select VT.Medico, sum(VT.Parcella) as Incasso
					from VisiteTarget VT natural join SpecMigliore SM
					group by VT.Medico

			) as D
)


--?4. Indicare la specializzazione avente meno medici di tutte le altre, e quanti medici ha.
--?In caso di pari merito, restituire tutti gli ex aequo. [Risolvere con e senza subquery].
--todo: senza subquery
with MediciPerSpec as (
		select M.Specializzazione, count(distinct M.Matricola) as NumMedici
		from Medico M
		group by M.Specializzazione
)

select *
from MediciPerSpec
where NumMedici = (
		select min(MPS.NumMedici)
		from MediciPerSpec MPS
)


--?5. Considerate le sole visite otorinolaringoiatriche, scrivere una query che restituisca il
--?numero di pazienti, ad oggi maggiorenni, che sono stati visitati solo da otorini di
--?Firenze durante il primo trimestre del 2015.
with VisiteTarget as (
		select *
		from Visita V 
		where year(V.Data) = 2015
			and month(V.Data) < 4 
)

select count(P.CodFiscale) as NumPazienti
from Paziente P
where P.CodFiscale IN (
		select VT.Paziente
		from VisiteTarget VT inner join Medico M on VT.Medico = M.Matricola
		where M.Specializzazione = 'Otorinolaringoiatria'
			and M.Citta <> 'Firenze'
)
	and P.DataNascita < current_date() - interval 18 year



