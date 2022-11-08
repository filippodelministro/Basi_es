--? Scrivere una query che consideri i casi di reflusso gastroesofageo dell’anno scorso e, in
--? merito al/ai mese/i in cui non ci sono stati casi e a quello/i in cui ce ne sono stati di
--? più rispetto a tutti i mesi di quell’anno, restituisca il mese, il numero di casi, e l’età
--? media (età = anni compiuti) dei pazienti al momento dell’esordio.
with
TabTarget as (
	select month(E.DataEsordio) as Mese, count(*) as NumEsordi, avg(datediff(current_date(), P.DataNascita)/365) as MediaEta
	from Esordio E inner join Paziente P on E.Paziente = P.CodFiscale 
	where E.Patologia = 'Dolore'
	group by month(E.DataEsordio)
    order by month(E.DataEsordio)
),
EsordiMax as (
	select max(TT.NumEsordi)
    from TabTarget TT 
)

select *
from TabTarget TT
where TT.NumEsordi = (select * from EsordiMax)
	or TT.NumEsordi = 0


--? Creare una materialized view di reporting DRUG_STATISTICS contenente, per ogni farmaco,
--? nessuno escluso, il nome commerciale del farmaco e il numero di terapie in corso basate su di
--? esso in ogni mese, anno per anno.
--? Effettuare il build a partire da Gennaio 2015 e implementare
--? il complete incremental refresh in modalità deferred, effettuato il primo giorno di ogni mese.
-- Materialized view target: creo e faccio build da data indicata
drop table if exists DRUG_STATISTICS;
create table DRUG_STATISTICS(
	Farmaco char(50) not null,
    Anno int, 
    Mese int,
    NumTerapie int,
    primary key(Farmaco, Anno, Mese)
)engine = InnoDB default charset = latin1;

insert into DRUG_STATISTICS
select T.Farmaco, year(T.DataInizioTerapia) as Anno, month(T.DataInizioTerapia) as Mese, count(*) as NumTerapie
from Terapia T
where T.DataFineTerapia is null
	and year(T.DataInizioTerapia) > 2014
group by T.Farmaco, year(T.DataInizioTerapia), month(T.DataInizioTerapia)
order by T.Farmaco, year(T.DataInizioTerapia), month(T.DataInizioTerapia);

-- LOG: si aggiorna ad ogni modifica della tabella Terapia
drop table if exists LOG_DRUG_STATISTICS;
create table LOG_DRUG_STATISTICS(
	Farmaco char(50) not null,
    NumTerapie int default 0,
    primary key(Farmaco)
)engine = InnoDB default charset = latin1;

-- trigger di push che aggiorna il LOG
drop trigger if exists push_log_drug_statistic;
delimiter $$
create trigger push_log_drug_statistic
after insert on Terapia for each row
begin
	declare NumTerapie int default 0;
    set NumTerapie = (
		select ifnull(LDS.NumTerapie, 0)
        from LOG_DRUG_STATISTICS LDS
        where LDS.Farmaco = new.Farmaco
    );

	insert into LOG_DRUG_STATISTICS
    select new.Farmaco, NumTerapie + 1;
end $$
delimiter ;

-- event che aggiorna la MV a partire dal LOG
-- drop event if exists incremental_refresh_DRUG_STATISTIC;
delimiter $$
create event incremental_refresh_DRUG_STATISTIC
on schedule every 1 month
starts '2015-01-01 23:55:00'
do
	insert into DRUG_STATISTIC
    select LDS.Farmaco, year(current_date()), month(current_date()), LDS.NumTerapie
    from LOG_DRUG_STATISTIC LDS;
    
    truncate LOG_DRUG_STATISTIC;	-- svuoto il LOG
delimiter ;
