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
--? esso in ogni mese, anno per anno. Effettuare il build a partire da Gennaio 2015 e implementare
--? il complete incremental refresh in modalità deferred, effettuato il primo giorno di ogni mese.


--? Implementare una analytic function efficiente (usando il meccanismo di processazione delle
--? variabili user-defined nell’invio al client) che restituisca le specializzazioni che, nel
--? mese di Maggio 2017, hanno totalizzato oltre il 30% in meno di visite rispetto alla media delle
--? visite totalizzate dalle specializzazioni aventi, ciascuna, un totale di visite effettuate
--? nello stesso mese uguale a uno dei tre totali di visite più alti, considerando il totale di
--? visite effettuate da ogni specializzazione nello stesso mese. Scrivere in un commento la/le 
--? analytic function utilizzata/e per risolvere l’esercizio, fra quelle viste a lezione.