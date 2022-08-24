Argomenti:
    - Data Manipulation
        · Inserimento
        · Cancellazione
        · Aggiornamento
    - Stored Procedure

--*==================================================================================
--*									ES SLIDE										
--*==================================================================================

--?Rimuovere dal database tutti i medici di Pisa che non hanno effettuato
--?visite mutuate il mese scorso.

delete from Medico
where Matricola IN (
	select * from (     --bisogna far cosi perchè altrimenti non compila!! '*'
		select M.Matricola
		from Medico M
		where M.Matricola NOT IN (
				select V.Medico
				from Visita V
				where V.Mutuata is true
					and year(V.Data) = year(current_date())
					and month(V.Data) = month(current_date()) - 1
		)
    ) as D
)
-- '*' non gli va bene che si elimini da Medico e si prenda da Medico nel from


--?Aumentare del 5% la parcella ai medici che hanno effettuato nell’ultimo anno più
--?della metà delle visite della loro specializzazione.
with
VisiteSpec as (
		select M.Specializzazione, count(*) NumVisite
		from Medico M inner join Visita V on M.Matricola = V.Medico
        where V.Data > current_date() - interval 10 year
		group by M.Specializzazione
),
VisiteMed as (
		select V.Medico, count(*) NumVisite, M.Specializzazione
		from Medico M inner join Visita V on M.Matricola = V.Medico
        where V.Data > current_date() - interval 10 year
		group by V.Medico
)
update Medico M
set M.Parcella = 1.05 * M.Parcella
where M.Matricola IN (
	select * from (
			select VM.Medico
			from VisiteSpec VS inner join VisiteMed VM on VS.Specializzazione = VM.Specializzazione
			where VM.NumVisite > 0.5 * VS.NumVisite
    ) as D
)


--?Scrivere una stored procedure che restituisca le specializzazioni mediche
--?offerte dalla clinica
drop procedure if exists mostra_specializzazioni
delimiter $$

create procedure mostra_specializzazioni()
begin
	select distinct Specializzazione
    from Medico ;
end $$

delimiter ;

-- per eseguire
call mostra_specializzazioni()






