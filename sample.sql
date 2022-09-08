-- DDL
--! Insert
insert into Medico values (...)

insert into Medico
select *
from -- [...]

--! Delete
delete from Medico M
where M.Specializzazione = '...'

delete from Medico M
where M.Matricola in (
    select *
    from (
        select *
        from Medico M1
    )as D
)

delete M1.* inner join (
    select *
    from Medico M
    where -- [...]
) on D.Matricola = M1.Matricola
where D.Matricola is null


--! Update
update M1.* inner join (
    select *
    from Medico M
    where -- [...]
) on D.Matricola = M1.Matricola
where D.Matricola is null
set M1.Parcella = D.Parcella


-- DML
--! Create

--! Drop

--! Alter


-- TABLE
--! CTE

--! View

--! Temporary Table


--! Materialized View


-- DINAMICO
--! Trigger

--! Event

-- GESTIONE

--! Cursori

--! Errori

