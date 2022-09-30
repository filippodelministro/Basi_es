--? Considerato ciascun principio attivo, indicarne il nome e il costo medio 
--? al pezzo fra tutti i farmaci che lo contengono.
select F.PrincipioAttivo, avg(F.Costo/F.Pezzi) as CostoMedio
from Farmaco F
group by F.PrincipioAttivo

--? Indicare nome e cognome dei pazienti che hanno contratto almeno due volte 
--? tutte le patologie intestinali.



--? Indicare le patologie esordite esclusivamente in forma cronica, curate 
--? con il farmaco Lyrica.
select E.Patologia
from Esordio E inner join Terapia T on E.Patologia = T.Patologia
where E.Patologia not in (
	select Patologia
	from Esordio
	where Cronica = 'no'
)
	and T.Farmaco = 'Lyrica'


--? Scrivere un trigger che, in risposta all’aggiornamento della gravità di 
--? un esordio, elimini l’esordio stesso, e ne inserisca un altro caratterizzato
--? dalla nuova gravità, dalla data dell’aggiornamento come data di esordio, 
--? e dagli stessi valori dell’esordio eliminato per i restanti attributi.

--? Indicare la specializzazione medica che, considerate le visite effettuate
--? dai suoi medici dall’anno 2010 a oggi, ha totalizzato ogni anno un numero
--? di pazienti visitati per ciascuna città mai inferiore all’anno precedente.

