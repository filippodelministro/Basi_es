--? Scrivere una query che restituisca la percentuale media di esenzione delle patologie
--? cardiache per le quali vi sono solo esordi cronici con gravita' superiore a 7
select P.Nome, avg(P.PercEsenzione) as MediaEsenzione
from Patologia P
where P.SettoreMedico = 'Cardiologia' 
	 and Nome not in (
			select E.Patologia
			from Esordio E
			where E.Gravita < 7
				or E.Cronica = 'no'
)
group by P.Nome

--? Implementare sotred procedure drug_usage_position() che riceva come par un farmaco e ne
--? restituisca la posizione in una classifica nella quale un farmaco occupa una posizione
--? tanto alta qunate pi terapie si basano su di esso. Qualora vi siano h farmaci a parimerito
--? in posizione k, il successivo occupa la posizione k+h
drop procedure if exists drug_usage_position;
delimiter $$
create procedure drug_usage_position(
		in _farmaco char(50),
        out posizione_ int
)
begin
	create or replace view
	RankFarmaci as (
			select T.Farmaco, rank() over (order by count(*) desc) as Posizione
			from Terapia T
			group by T.Farmaco
	);
    
    set posizione_ = (
		select RF.Posizione
		from RankFarmaci RF
		where RF.Farmaco = _farmaco
	);
    
    drop view RankFarmaci;
end $$
delimiter ;

--? Ai fini di un analisi predittiva dello stress si desidera effettura un'aggregazione periodica dei
--? dati relativi agli esordi di patologie a carico dello stomaco. In tale aggregazione, ogni esordio E
--? a carico dello stomaco è associato a un valore ricavato aggregandone i dati con quelli dell'esordio
--? E_prec e successivo E_succ  dello stesso paziente, relativi alla stessa patologia. Creare una MV
--? MV_Stomaco che, per ciascun esordio E contenga il nome della patologia, il codice fiscale del
--? paziente, la data dell'esordio e il numero medio di giorni fra quelli trascorsi dall'inizio dell'
--? esordio E_prec, l'esordio E, e l'esordio E_succ.
--? Effettuare il build a partire dal primo gennaio 2010 e implementare un deferred incremental refresh
--? in modalità complete con cadenza mensile. Progettare oppurtunamente la LOG Table in modo da non effettuare
--? accessi ai raw data durante il refresh.
