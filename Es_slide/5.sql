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
select M.Specializzazione
from Medico M
group by M.Specializzazione
having avg(M.Parcella) = (
		select max(D.MediaParcella)
		from(
			select M.Specializzazione, avg(M.Parcella) as MediaParcella
			from Medico M
			group by M.Specializzazione
		) as D
)

--*==================================================================================
--*									ES IN FONDO												
--*==================================================================================