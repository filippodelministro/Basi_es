Argomenti:
    - Query complesse 
    - Query insiemistiche
        · UNION (ALL)
        · EXISTS
    - Modificatori
        · ANY
        · ALL

--*==================================================================================
--*									ES SLIDE										
--*==================================================================================
--?Indicare le specializzazioni contenenti solamente medici provenienti dalla stessa città, di
--?cui almeno uno abbia superato nell’anno 2011 un totale di visite pari al 10% di tutte le
--?visite della sua specializzazione nello stesso anno
create or replace view SpecTarget as
	select M.Specializzazione
	from Medico M
	group by M.Specializzazione
	having count(distinct M.Citta) = 1;

create or replace view VisiteMed as
	select M.Specializzazione, V.Medico, count(*) as NumVisite
	from Medico M inner join Visita V on M.Matricola = V.Medico
	where M.Specializzazione IN (
				select M.Specializzazione
				from Medico M
				group by M.Specializzazione
				having count(distinct M.Citta) = 1
		) 
		and year(V.Data) = 2011
	group by M.Specializzazione, V.Medico;

create or replace view VisiteSpec as
	select VM.Specializzazione, sum(VM.NumVisite) as TotVisite
	from VisiteMed VM
	group by VM.Specializzazione;

select *
from VisiteMed VM natural join VisiteSpec VS
where VM.NumVisite > 0.1*VS.TotVisite


--? Indicare la parcella media fra quella degli otorini e quella degli ortopedici
select avg(M.Parcella)
from Medico M
where M.Specializzazione =  'Otorinolaringoiatria'
	or M.Specializzazione = 'Ortopedia'


--?I pazienti visitati dal dott. Verdi o dal dott. Rossi
select V.Paziente, M.Cognome
from Medico M inner join Visita V on M.Matricola = V.Medico
where M.Cognome = 'Rossi'    
union
select V.Paziente, M.Cognome
from Medico M inner join Visita V on M.Matricola = V.Medico
where M.Cognome = 'Verdi'    


--?Totale delle visite effettuate il lunedì dal dott. Verdi e il venerdì dal dott. Rossi
-- si conta le visite, non i pazienti: devono rimanere i duplicati
select count(*) as TotVisite
from (
		select V.Paziente
		from Medico M inner join Visita V on M.Matricola = V.Medico
		where dayofweek(V.Data) = 1
			and M.Cognome = 'Verdi'
		union all
		select V.Paziente
		from Medico M inner join Visita V on M.Matricola = V.Medico
		where dayofweek(V.Data) = 5
			and M.Cognome = 'Rossi'
) as D


--?I pazienti visitati da un medico alla cui specializzazione appartenga
--?almeno un medico con parcella superiore a 250 euro

--Fissato un medico (e quindi la sua Spec), controllo che esista un medico con 
--la stessa Spec con parcella superiore a 250; poi prendo i pazienti visitati
--da quei medici
select distinct V.Paziente
from Medico M1 inner join Visita V on M1.Matricola = V.Medico
where exists (
		select *
        from Medico M2
        where M2.Specializzazione = M1.Specializzazione
			and M2.Parcella > 250
)


--?I pazienti visitati dal dott. Verdi ma non dal dott. Rossi
--Prendo quelli visitati da Rossi e li escludo
select distinct V.Paziente
from Medico M inner join Visita V on M.Matricola = V.Medico
where M.Cognome = 'Verdi'
	and V.Paziente NOT IN (
		select V.Paziente
		from Medico M inner join Visita V on M.Matricola = V.Medico
		where M.Cognome = 'Rossi'
    )

--!EXTRA
--?medici che hanno visitato tutti i pazienti
select V.Medico, M.Cognome
from Visita V inner join Medico M on V.Medico = M.Matricola
group by V.Medico
having count(distinct V.Paziente) = (
        select count(*)
        from Paziente
)

--!EXTRA
--?medico che ha visitato più pazienti
select V.Medico, count(distinct V.Paziente) as TotPazVisitati
from Visita V inner join Medico M on V.Medico = M.Matricola
group by V.Medico
having count(distinct V.Paziente) = (
			select max(D.NumPaz) as MaxNumPaz
			from (
					select V.Medico, M.Cognome, count(distinct V.Paziente) as NumPaz
					from Visita V inner join Medico M on V.Medico = M.Matricola
					group by V.Medico
			) as D
)


--?I pazienti visitati solamente dal dott. Verdi
--! soluzione che avrei dato io (subquery)
--fix: secondo me basta cosi perchè tanto non esistono paz che non siano stati
--fix: visitati da nessun altro medico e nemmeno da Verdi; altrimenti andrebbe
--fix: messo in AND anche la condizione di visita da Verdi
select *
from Visita V
where V.Paziente NOT IN (
			select V.Paziente
			from Medico M inner join Visita V on M.Matricola = V.Medico
			where M.Cognome <> 'Verdi'
)

--! soluzione con OUTER JOIN
--versione con outer join; mantiene tutti i record che non fanno join
--aventi un medico diverso da Verdi
select *
from Visita V1 natural left join (
			select V2.Paziente
			from Visita V2 inner join Medico M2 on V2.Medico = M2.Matricola
			where M2.Cognome <> 'Verdi'
) as D
where D.Paziente IS NULL

--! soluzione con NOT EXISTS
--fix: importante che V.Paz = V1.Paz, perchè???
select *
from Visita V
where not exists (
	select *
    from Medico M inner join Visita V1 on M.Matricola = V1.Medico
    where M.Cognome <> 'Verdi'
		and V.Paziente = V1.Paziente
)


--?I pazienti visitati sia dal dott. Verdi che dal dott. Rossi
--! soluzione che avrei dato io (subquery)
select distinct V.Paziente
from Medico M inner join Visita V on M.Matricola = V.Medico
where M.Cognome = 'Verdi'
	and V.Paziente IN (
		select V.Paziente
		from Medico M inner join Visita V on M.Matricola = V.Medico
		where M.Cognome = 'Rossi'
)

--! soluzione con SELF JOIN
--fix: non so cosa faccia USING             ???
select distinct V1.Paziente
from (Visita V1 inner join Medico M1 on V1.Medico = M1.Matricola)
	inner join 
	(Visita V2 inner join Medico M2 on V2.Medico = M2.Matricola)
using (Paziente)
where M1.Cognome = 'Verdi'
	and M2.Cognome = 'Rossi';

--?Indicare i pazienti visitati da tutti i medici

select V.Paziente
from Visita V
group by V.Paziente
having count(distinct V.Medico) = (
		select count(*)
        from Medico M
)

--?Indicare il nome e cognome dei medici la cui parcella è superiore a quella di
--?almeno un cardiologo di Pisa
select M.Nome, M.Cognome
from Medico M
where M.Parcella > ANY (
		select M1.Parcella
        from Medico M1
        where M1.Specializzazione = 'Cardiologia'
			and M1.Citta = 'Pisa'
)


--?Indicare matricola e cognome del medico avente la parcella più bassa
--?delle parcelle di tutti i medici
--Potevo fare anche solo con il '<' ma dovevo mettere where M.Matricola <> M1.Matricola
--NB: In quel caso avrei avuto la versione senza parimerito!
select *
from Medico M
where M.Parcella <= ALL (       --con parimerito!
		select M1.Parcella
        from Medico M1
)
