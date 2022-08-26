--? Considerato ogni principio attivo, indicarne il nome e il numero medio 
--? di giorni per cui sono indicati i farmaci che lo contengono.
select F.PrincipioAttivo, avg(I.NumGiorni) as Media
from Farmaco F inner join Indicazione I on F.NomeCommerciale = I.Farmaco
group by F.Principioattivo


--? Indicare nome e cognome dei pazienti che, per curare gli esordi di almeno
--? una patologia, hanno complessivamente assunto tutti i farmaci assunti
--? da almeno un paziente per curare tale patologia.


--? Scrivere un evento che sconti mensilmente del 2% i farmaci che sono stati 
--? assunti in meno del 10% delle terapie iniziate nel mese precedente.


--? In relazione a ciascuna patologia a carico dell’orecchio, indicarne il 
--? nome, il costo della terapia più economica fra quelle effettuate, nell’
--? anno 2013, dai soli pazienti di Pisa e Siena, usando farmaci indicati
--? unicamente per la patologia considerata, e con quale farmaco tale terapia
--? è stata effettuata.