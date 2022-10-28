--? Considerata ciascuna città di provenienza dei medici, scrivere una query che restituisca il 
--? nome della città, il numero di pazienti che sono stati visitati dal medico di tale città che 
--? ne ha visitati di più rispetto agli altri medici della stessa città, e la matricola di tale 
--? medico. In caso di pari merito, restituire tutti gli ex aequo.


--? Aggiungere un attributo booleano DirittoEsenzione alla tabella ESORDIO contenente true se
--? il paziente ha contratto nella vita tutte le patologie con invalidità inferiore al 20%
--? relative allo stesso settore medico della patologia dell’esordio, ma mai con gravità superiore
--? a quella della patologia dell’esordio. Implementare poi il trigger che imposta l’attributo
--? DirittoEsenzione all’atto dell’inserimento di un nuovo esordio.


--? Con l’arrivo dell’estate, l’incidenza e la gravità degli episodi d’insonnia tendono ad acuirsi.
--? Si stima che tre persone su cinque soffrano di tale patologia nel periodo estivo. Per 
--? combatterla, un numero considerevole di persone si affida a rimedi alternativi. Quando però
--? la patologia riduce la qualità della vita, il ricorso ai farmaci tradizionali diviene inevitabile.
--? Relativamente alle città in cui la stima della casistica risulta quest’anno verificata, si
--? desidera produrre un report relativo ai farmaci EN e Tavor, tipicamente usati per trattare
--? l’insonnia di una certa entità. Il report è contenuto in una materialized view REPORT_INSONNIA .
--? Ogni record contiene il nome della città, il numero di casi d’insonnia ivi in corso, il numero 
--? totale di casi ivi registrati dall’inizio dell’estate, il nome di uno dei due farmaci oggetto
--? del report e un indicatore di efficacia definito come, dove è il farmaco, è l’insieme delle
--? terapie basate su , mentre e rappresentano posologia e durata, rispettivamente. Si richiede di:
--?     i) effettuare il build della materialized view al 1° Giugno 2016;
--?     ii) scrivere il codice per la gestione della log table;
--?     iii) implementare l’incremental refresh di tipo partial, in modalità on demand.
--? T f
--? f p i d i
--? feff icacia f = P
--? i2T f p i d i / P
--? i2T f p i

drop table if exists report_insonnia;
create table report_insonnia(
	Citta char(50),
    Farmaco char(50),
    CasiTot int,
    CasiEstate int,
    Efficacia double
)engine=InnoDB default charset=latin1;

create or replace view Insonnia as (
	select P.Citta, count(*) as Casi
	from Esordio E inner join Paziente P on E.Paziente = P.CodFiscale
	where E.Patologia = 'Insonnia'
	group by P.Citta
);
create or replace view InsonniaEstate as (
	select P.Citta, count(*) as Casi
	from Esordio E inner join Paziente P on E.Paziente = P.CodFiscale
	where E.Patologia = 'Insonnia'
		and month(E.DataEsordio) between 6 and 9
    group by P.Citta
);
create or replace view CittaTarget as (
	select distinct IE.Citta
	from Insonnia I inner join InsonniaEstate IE on I.Citta = IE.Citta
	where IE.Casi >= 0.2 * I.Casi
);
create or replace view TabTarget1 as (
	select P.Citta, T.Farmaco, count(*) as NumCasi, (sum(T.Posologia * datediff(ifnull(T.DataFineTerapia, current_date()), T.DataInizioTerapia))/sum(T.Posologia)) as Efficacia
	from Terapia T inner join Paziente P on T.Paziente = P.CodFiscale
	where T.Patologia = 'Insonnia'
		and P.Citta in (select * from CittaTarget)
		and (T.Farmaco = 'EN' or T.Farmaco = 'Tavor')
	group by P.Citta, T.Farmaco
);
create or replace view TabTarget2 as (
	select P.Citta, T.Farmaco, count(*) as NumCasi
	from Terapia T inner join Paziente P on T.Paziente = P.CodFiscale
	where T.Patologia = 'Insonnia'
		and P.Citta in (select * from CittaTarget)
		and (T.Farmaco = 'EN' or T.Farmaco = 'Tavor')
        and month(T.DataEsordio) between 6 and 9
	group by P.Citta, T.Farmaco
);

insert into report_insonnia 
select T1.Citta, T1.Farmaco, T1.NumCasi as CasiTot, T2.NumCasi as CasiEstate, T1.Efficacia
from TabTarget1 T1 left outer join TabTarget2 T2 on T1.Citta = T2.Citta
												 and T1.Farmaco = T2.Farmaco;
                                                 
select * from report_insonnia;