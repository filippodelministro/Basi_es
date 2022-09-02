--?Calcolo età
select year(current_date) - year(P.DataNascita) as Età
from Paziente P

--==================================================================================

--? Parcella minima e chi la detiene per ogni specializzazione      //USO DERIVED TABLE
select M.Specializzazione, D.ParcellaMinima, M.Cognome
from Medico M natural join (
		select M1.Specializzazione, min(M1.Parcella) as ParcellaMinima
        from Medico M1
        group by M1.Specializzazione 
)as D
where M.Parcella = D.ParcellaMinima

--==================================================================================
--* DDL *--
--? DELETE
delete from Medico              -- con subquery
where Matricola in (
    select *
    from ( ... 
    
    ) as D
)

delete M1.*                     -- ocn join anticipato
from Medico M1 left outer join (
    select *
    from ...
) as D on M1.Matricola = D.Medico

--? UPDATE
update Medico M natural join (
    select *
    from ...
) as D
set M.Parcella = M.Parcella * 1.05
where -- cond 

--==================================================================================

--! handler per gestione errori
-- dentro una proc
    -- [...]
    
    declare esito integer default 0;		-- per controllo errori
    
    declare exit handler for sqlexception	-- in caso di errori gravi riporta tutto a stato precedente
    begin
		rollback;
        set esito = 1;
        select 'Si è verificato un errore!';
    end;

    -- [...]