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


--? Ai fini di un indagine predittiva sullo stress, si desidera effettuare un'aggregazione periodica dei dati
--? relativi agli esordi di patologie a carico dello stomaco. In tale aggregazione, ogni esordio E a carico
--? dello stomaco è associato a un valore ricavato aggregandone i dati con quelli dell'esordio precedente
--? E_prec e successivo E_succ dello stesso paziente, realtivi alla stessa patologia. Creare una MV MV_STOMACO
--? che, per ciascun esordio E, contenga, il nome della patologia, il codice fiscale del paziente, la data
--? dell'esordio, e il numero medio di gironi fra quelli trascorsi dall'esordio E_prec e l'inizio dell'esordio
--? E, e quelli trascorsi dall'inizio dell'esordio E e l'inizio dell'esordio E_succ.
--? Effettuare il build a partire dal 1* Genaio 1995 e implementare il deferred refresh in modalità complete,
--? con cadenza mensile. Progettare il LOG in modo da non effettuare accessi ai raw data.

drop table if exists MV_STOMACO;
create table MV_STOMACO(
	Paziente char(50),
    Patologia char(50),
    DiffEprec integer,
    DataEsordio date,
    DiffEsucc integer,
    primary key(Paziente, Patologia, DataEsordio)
) Engine =  InnoDB default charset = latin1;

insert into MV_STOMACO (
	select D.Paziente, D.Patologia, datediff(D.DataEsordio, D.Eprec), D.DataEsordio, datediff(D.Esucc, D.DataEsordio)
	from (
		select E.Paziente, E.Patologia,
			lag(E.DataEsordio, 1) over(partition by E.Paziente, E.Patologia order by E.DataEsordio) as Eprec,
			E.DataEsordio, 
			lead(E.DataEsordio, 1) over(partition by E.Paziente, E.Patologia order by E.DataEsordio) as Esucc
		from Esordio E
		where E.Patologia in (
			select PA.Nome
			from Patologia PA
			where PA.ParteCorpo = 'Stomaco'
		)
			and year(E.DataEsordio) > 1994
		order by E.Paziente, E.Patologia, E.DataEsordio
	) as D
	where D.Eprec is not null
		and D.Esucc is not null
	group by D.Paziente, D.Patologia, D.DataEsordio );
    
    
drop procedure if exists update_MV_STOMACO;
delimiter $$
create procedure update_MV_STOMACO()
begin
	-- azzero la tabella
	truncate MV_STOMACO;
	
    -- e la popolo from scratch
	insert into MV_STOMACO (
		select D.Paziente, D.Patologia, datediff(D.DataEsordio, D.Eprec), D.DataEsordio, datediff(D.Esucc, D.DataEsordio)
		from (
			select E.Paziente, E.Patologia,
				lag(E.DataEsordio, 1) over(partition by E.Paziente, E.Patologia order by E.DataEsordio) as Eprec,
				E.DataEsordio, 
				lead(E.DataEsordio, 1) over(partition by E.Paziente, E.Patologia order by E.DataEsordio) as Esucc
			from Esordio E
			where E.Patologia in (
				select PA.Nome
				from Patologia PA
				where PA.ParteCorpo = 'Stomaco'
			)
				and year(E.DataEsordio) > 1994
			order by E.Paziente, E.Patologia, E.DataEsordio
		) as D
		where D.Eprec is not null
			and D.Esucc is not null
		group by D.Paziente, D.Patologia, D.DataEsordio );
end $$

create event update_MV_STOMACO_event
every 1 month
do
	call update_MV_STOMACO();
delimiter ;



