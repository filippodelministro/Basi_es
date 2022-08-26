--? Considerato ogni principio attivo, indicarne il nome e il numero medio 
--? di giorni per cui sono indicati i farmaci che lo contengono.
select F.PrincipioAttivo, avg(I.NumGiorni) as Media
from Farmaco F inner join Indicazione I on F.NomeCommerciale = I.Farmaco
group by F.Principioattivo


--? Indicare nome e cognome dei pazienti che, per curare gli esordi di almeno
--? una patologia, hanno complessivamente assunto tutti i farmaci assunti
--? da almeno un paziente per curare tale patologia 

--todo: ======================================================================
--? Scrivere un evento che sconti mensilmente del 2% i farmaci che sono stati 
--? assunti in meno del 10% delle terapie iniziate nel mese precedente.
--todo: ======================================================================


--? In relazione a ciascuna patologia a carico dell’orecchio, indicarne il 
--? nome, il costo della terapia più economica fra quelle effettuate, nell’
--? anno 2013, dai soli pazienti di Pisa e Siena, usando farmaci indicati
--? unicamente per la patologia considerata, e con quale farmaco tale terapia
--? è stata effettuata.
with 
FarmaciTarget as (
		select P.Nome as Patologia, I.Farmaco
		from Indicazione I inner join Patologia P on I.Patologia = P.Nome
		where P.ParteCorpo = 'Orecchio'
		group by P.Nome, I.Farmaco
		having count(distinct I.Patologia) = 1
),
TerapieTarget as (
		select T.Patologia, T.Farmaco, T.Posologia * datediff(T.DataFineTerapia, T.DataInizioTerapia) as NumCompresse
		from FarmaciTarget FT inner join Terapia T on FT.Patologia = T.Patologia
							  inner join Paziente P on T.Paziente = P.CodFiscale
		where year(T.DataInizioTerapia) = 2013 and year(T.DataFineTerapia) = 2013
			and (P.Citta = 'Pisa' or P.Citta = 'Siena')
)

select D.Patologia, min(D.PrezzoTerapia) as PrezzoMin
from (
		select TT.Patologia, TT.Farmaco, ((TT.NumCompresse % F.Pezzi)+1 * F.Costo) as PrezzoTerapia
		from TerapieTarget TT inner join Farmaco F on TT.Farmaco = F.NomeCommerciale
							  right outer join Patologia P on TT.Patologia = P.Nome
		where P.ParteCorpo = 'Orecchio'
) as D
group by D.Patologia