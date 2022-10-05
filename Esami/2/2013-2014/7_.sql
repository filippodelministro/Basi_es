--? Considerato ogni principio attivo, indicarne il nome e il numero medio 
--? di giorni per cui sono indicati i farmaci che lo contengono.
select F.PrincipioAttivo, avg(I.NumGiorni) as MediaGiorni
from Farmaco F inner join Indicazione I on F.NomeCommerciale = I.Farmaco
group by F.PrincipioAttivo


--? Indicare nome e cognome dei pazienti che, per curare gli esordi di almeno
--? una patologia, hanno complessivamente assunto tutti i farmaci assunti
--? da almeno un paziente per curare tale patologia 
select distinct P.Nome, P.Cognome
from Terapia T inner join Paziente P on T.Paziente = P.CodFiscale
where T.Farmaco in (
		select distinct T2.Farmaco
        from Terapia T2
        where T2.Patologia = T.Patologia
			and T2.Paziente <> T.Paziente
)
group by T.Paziente, T.Patologia
having count(distinct T.Farmaco) = (
		select count(distinct T1.Farmaco)
        from Terapia T1
        where T1.Patologia = T.Patologia
			and T1.Paziente <> T.Paziente
)


--? Scrivere un evento che sconti mensilmente del 2% i farmaci che sono stati 
--? assunti in meno del 10% delle terapie iniziate nel mese precedente.
set global event_scheduler = on;
delimiter $$
create event nome_ev
on schedule every 1 month
do

with
NumUtilizzi as (
		select T.Farmaco, count(*) NumUtilizzi, (select count(*)
												 from Terapia T1
												 where month(T1.DataInizioTerapia) = month(current_date()) - 1
													 and year(T1.DataInizioTerapia) = year(current_date())
																	) as TotTerapie
		from Terapia T
		where month(T.DataInizioTerapia) = month(current_date()) - 1
			and year(T.DataInizioTerapia) = year(current_date())
		group by T.Farmaco
)

update Farmaco F inner join (
		select NU.Farmaco
		from NumUtilizzi NU
		where NU.NumUtilizzi < NU.TotTerapie * 0.1
) as D on D.Farmaco = F.NomeCommerciale
set F.Costo = F.Costo * 0.98

on completion preserve;
delimiter ;





--? In relazione a ciascuna patologia a carico dell’orecchio, indicarne il 
--? nome, il costo della terapia più economica fra quelle effettuate, nell’
--? anno 2013, dai soli pazienti di Pisa e Siena, usando farmaci indicati
--? unicamente per la patologia considerata, e con quale farmaco tale terapia
--? è stata effettuata.
with
CostiPatOrecchio as (
		select T.Patologia, (floor(
					(
						datediff(                                               -- conto i giorni di Terapia
								ifnull(T.DataFineTerapia, current_date()),      -- se non è terminata, fino ad oggi
								T.DataInizioTerapia
								) * T.Posologia         
					) / F.Pezzi)                
				+ 1)                            
				* F.Costo                       
				* (100 - PA.PercEsenzione) / 100   as Costo 
		from Terapia T inner join Patologia PA on T.Patologia = PA.Nome
					   inner join Paziente P on T.Paziente = P.CodFiscale
					   inner join Farmaco F on T.Farmaco = F.NomeCommerciale
		where PA.ParteCorpo = 'Orecchio'
			and (P.Citta = 'Pisa' or P.Citta = 'Siena')
			and year(T.DataInizioTerapia) = 2013
			and year(T.DataFineTerapia) = 2013
			and not exists (		-- non esiste Indicazione per una patologia diversa
				select *
				from Indicazione I
				where I.Farmaco = T.Farmaco
					and I.Patologia <> T.Patologia
			)
)
    
select C.Patologia, C.Costo
from CostiPatOrecchio C
where C.Costo = (
		select min(C1.Costo)
		from CostiPatOrecchio C1
        where C1.Patologia = C.Patologia
)   
