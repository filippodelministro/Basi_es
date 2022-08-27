--? Scrivere una query che, relativamente a ciascun mese del 2013, restituisca il mese
--? (come intero da 1 a 12) e il numero medio di terapie per esordio effettuate dai
--? pazienti per combattere il dolore.
select month(E1.DataEsordio) as Mese, avg(D.NumTerapie) as MediaTerapie
from Esordio E1 left outer join (
		select T.Paziente, T.DataEsordio, count(distinct T.DataInizioTerapia) as NumTerapie
		from Terapia T
		where year(T.DataEsordio) = 2013
			and T.Patologia = 'Dolore'
		group by T.Paziente, T.DataEsordio
) as D on E1.DataEsordio = D.DataEsordio and E1.Paziente = D.Paziente
group by month(E1.DataEsordio)


--? Scrivere una query che restituisca nome e cognome dei pazienti che, esclusivamente 
--? per le patologie ortopediche, hanno assunto, man mano nella vita, tutti i farmaci 
--? a base di nimesulide.
select P.Nome, P.Cognome
from Terapia T inner join Patologia PA on T.Patologia = PA.Nome
			   inner join Paziente P on T.Paziente = P.CodFiscale
where PA.SettoreMedico = 'Ortopedia'
	and T.Farmaco in (
		select NomeCommerciale
		from Farmaco
		where PrincipioAttivo = 'Nimesulide'
	)
group by T.Paziente
having count(distinct T.Farmaco) = (
			select count(*)
			from Farmaco F
			where PrincipioAttivo = 'Nimesulide'
)



--todo: ======================================================================
Scrivere una function che, ricevuto in ingresso il codice fiscale di un paziente, restituisca il suo stato attuale
di salute SS ottenuto mediante l’espressione ...
dove n è il numero di esordi attualmente in corso, g i è la gravità con cui la patologia è stata contratta
nell’esordio i-esimo, e w i è un coefficiente di penalizzazione pari a: 1 se l’esordio i-esimo non ha terapie
fallite; 1.5 se l’esordio i-esimo ha da 1 a 2 terapie fallite; 2.5 se l’esordio i-esimo ha più di 3 terapie fallite.


--? Scrivere una query che restituisca l’anno (o gli anni) in cui si sono verificati,
--? complessivamente fra i pazienti di Pisa e Firenze, più del 30% degli esordi di rinite
--? nel trimestre Marzo-Maggio rispetto al totale degli esordi della stessa patologia nello
--? stesso trimestre dello stesso anno, con il picco più alto di esordi raggiunto dai
--? pazienti di Pisa.
--todo: ======================================================================