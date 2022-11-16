-- DDL
--! Insert
insert into Tabella values(...)

insert into Tabella (
    select *
    from ...
)


--! Delete
-- tutti quelli che hanno un certo valore
delete from Tabella
where Valore in (
    select *
    from AltraTabella       --NB non posso mettere la stessa Tab che ho nel from
)

-- tutti quelli che fanno join
delete T1.*
from Tabella T1 left outer join (
    select *
    from Tabella T2
) as D on T1.Valore = T2.Valore
where T1.Valore is null


--! Update



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

