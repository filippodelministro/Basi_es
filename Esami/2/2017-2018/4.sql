--? Scrivere una query che consideri i farmaci a base di diazepam e lorazepam e restituisca codice
--? fiscale e sesso dei pazienti che hanno assunto tutti i farmaci basati sul primo o, alternativamente,
--? sul secondo principio attivo durante il triennio 2010-2012, e con quale posologia media.
with
FarmaciTargetDiaz as (
	select NomeCommerciale
	from Farmaco
	where PrincipioAttivo = 'Diazepam'
),
FarmaciTargetLora as (
	select NomeCommerciale
	from Farmaco
	where PrincipioAttivo = 'Lorazepam'
)

select T.Paziente, avg(T.Posologia) as PosologiaMedia
from Terapia T
where T.Farmaco in (select * from FarmaciTargetDiaz)
	and year(T.DataInizioTerapia) between 2010 and 2012
    and year(T.DataFineTerapia) between 2010 and 2012
group by T.Paziente
having count(distinct T.Farmaco) = (select count(*) from FarmaciTargetDiaz)

union

select T.Paziente, avg(T.Posologia) as PosologiaMedia
from Terapia T
where T.Farmaco in (select * from FarmaciTargetLora)
	and year(T.DataInizioTerapia) between 2010 and 2012
    and year(T.DataFineTerapia) between 2010 and 2012
group by T.Paziente
having count(distinct T.Farmaco) = (select count(*) from FarmaciTargetLora)

--? Implementare un event che sposti mensilmente le terapie terminate oltre sei mesi prima in una
--? tabella di archivio ARCHIVIO_TERAPIE mediante una stored procedure dump_therapies(). Salvare
--? in ARCHIVIO_TERAPIE il codice fiscale del paziente, la patologia, il nome commerciale del
--? farmaco, l’anno d’inizio, la durata della terapia in giorni e il numero totale di compresse
--? assunte. L’event deve salvare in una tabella persistente la data dell’ultima volta in cui è 
--? andato in esecuzione e il numero di terapie archiviate.

-- creo tabella e la popolo: la popolo a partire da sempre, quindi
-- ultimi 6 mesi esclusi
drop table if exists ARCHIVIO_TERAPIE;
create table ARCHIVIO_TERAPIE(
	Paziente char(50),
    Patologia char(50),
    Farmaco char(50),
    AnnoInizo int,
    Durata int,
    Compresse int
)Engine=InnoDB charset = latin1;

insert into ARCHIVIO_TERAPIE
select T.Paziente, T.Patologia, T.Farmaco, year(T.DataInizioTerapia), datediff(T.DataFineTerapia, T.DataInizioTerapia), datediff(T.DataFineTerapia, T.DataInizioTerapia) * T.Posologia 
from Terapia T
where T.DataFineTerapia is not null
	and year(T.DataInizioTerapia) < year(current_date())	-- tutti gli anni passati
	or (year(T.DataInizioTerapia) = year(current_date())	-- anno corrente oltre i sei mesi
		 and month (T.DataFineTerapia) < month(current_date()) - interval 6 month)
order by T.Paziente, year(T.DataInizioTerapia), T.Patologia;


-- procedura che inserisce in ARCHIVIO_TERAPIE solo le terapie di un mese: quello
-- di sei mesa fa rispetto a quando viene chiamata
drop procedure if exists dump_therapies;
delimiter $$
create procedure dump_therapies()
begin
	insert into ARCHIVIO_TERAPIE
	select T.Paziente, T.Patologia, T.Farmaco, year(T.DataInizioTerapia), datediff(T.DataFineTerapia, T.DataInizioTerapia), datediff(T.DataFineTerapia, T.DataInizioTerapia) * T.Posologia 
	from Terapia T
	where year(T.DataInizioTerapia) = year(current_date())
		and month(T.DataInizioTerapia) = month(current_date()) - interval 6 month
	order by T.Paziente, year(T.DataInizioTerapia), T.Patologia;
end $$
delimiter ;

-- event che ogni mese chiama la procedura di sopra
drop event if exists dump_therapies_event;
delimiter $$
create event dump_therapies_event
starts current_timestamp
every 1 month
do
	call dump_therapies();
delimiter ;

--? Implementare una funzionalità analytics efficiente (mediante un unico select statement con
--? variabili user-defined) che, per ogni paziente con più di tre esordi, consideri tali esordi e
--? li partizioni in quattro gruppi di uguale numerosità sulla base della loro durata, associando
--? così a ciascun esordio il cosiddetto quartile, cioè un intero da 1 a 4. Gli esordi più brevi
--? saranno associati al quartile 1, quelli un po’ più lunghi al quartile 2, e così via. Se è 
--? impossibile associare lo stesso numero di esordi a tutti i quartili, gli esordi in più devono es-
--? sere equamente divisi fra i primi quartili.

