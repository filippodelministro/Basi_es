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