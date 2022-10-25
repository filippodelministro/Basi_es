--? Considerati i farmaci indicati per patologie di più settori medici, scrivere una query che 
--? restituisca il principio attivo di quelli impiegati, nell’ultimo semestre, solo per 
--? patologie di uno di tali settori medici, da non meno di tre pazienti, nel complesso.
with
FarmaciTarget as (
	select I.Farmaco
	from Indicazione I inner join Patologia PA on I.Patologia = PA.Nome
	group by I.Farmaco
	having count(distinct PA.SettoreMedico) > 1
)

select F.PrincipioAttivo
from Terapia T inner join Farmaco F on T.Farmaco = F.NomeCommerciale
where T.Farmaco in (select Farmaco from FarmaciTarget)
	and T.DataInizioTerapia > current_date() - interval 6 month
group by F.PrincipioAttivo
having count(distinct T.Paziente) > 2


--? Scrivere una stored function dose_therapy() che, ricevuto il codice fiscale di un paziente 
--? e una data di riferimento come parametri, restituisca: –1 se il paziente ha sempre assunto,
--? nelle sue terapie, i farmaci con posologia uguale al dosaggio consigliato nelle indicazioni,
--? a partire dalla data di riferimento; 0 se ci sono state eccezioni in misura non superiore
--? al 20% delle terapie, a partire dalla data di riferimento; 1 se il paziente ha sempre
--? utilizzato i farmaci con posologia superiore rispetto al dosaggio indicato, a partire
--? dalla data di riferimento. Nei rimanenti casi, non d’interesse, la function restituisce NULL.

--? Fra tutte le patologie a carico del fegato che comportano un’invalidità superiore al 
--? 70%, scrivere una query che indichi, qualora esista, quella patologia che, nel triennio 
--? 2013-2016, è stata curata con il più alto numero di principi attivi considerando, 
--? complessivamente, i pazienti di Milano, Roma e Napoli, ambosessi, di età superiore a cinquant’anni
--? che hanno contratto almeno una di tali patologie nello stesso triennio e che, prima dell’esordio
--? della prima di esse, non avevano mai contratto patologie epatiche, ad esclusione dell’ittero
--? fisiologico. Relativamente alla patologia sopra descritta, se esiste, la query deve anche indicare,
--? nello stesso record, la durata media delle terapie per principio attivo (considerando anche 
--? quelle attualmente in corso) per i pazienti di sesso maschile e per i pazienti di sesso
--? femminile, nonché la spesa totale in merito a ciascun principio attivo.