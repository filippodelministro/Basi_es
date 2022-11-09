--? Scrivere una query che restituisca la percentuale media di esenzione delle patologie cardiache
--? per le quali vi sono solo esordi cronici con gravità maggiore a 7
select avg(PA1.PercEsenzione) as Media
from Esordio E inner join Patologia PA1 on E.Patologia = PA1.Nome
where E.Patologia in (
	select PA.Nome
    from Patologia PA
	where PA.SettoreMedico = 'Cardiologia'
)
	and not exists (
		select *
        from Esordio E1
        where E1.Patologia = E.Patologia
			and E1.Cronica = 'no'
            and E1.Gravita < 8
    )


--? Implementare una stored procedure drug_usage_position() che riceva come parametro un farmaco e ne
--? restituisca la posizione in classifica nella quale un farmaco occupa una posizione tant più alta
--? quante più terapie si basano si di esso. Qualora ci sinao h farmaci a pari merito in posizione k,
--? il successivo occupa la posizione k+h
drop procedure if exists drug_usage_position;
delimiter $$
create procedure drug_usage_position(
	in _farmaco char(50),
    out pos_ int
)
begin
	with Classifica as (
		select D.Farmaco, rank() over(order by D.Utilizzi desc) as Posizione
		from (
			select T.Farmaco, count(*) as Utilizzi
			from Terapia T
			group by T.Farmaco
		) as D
	)
	
	select C.Posizione
	from Classifica C
	where C.Farmaco = _farmaco
	into pos_;

end $$
delimiter ;

set @pos = 0;
call drug_usage_position('Quait', @pos);
select @pos

