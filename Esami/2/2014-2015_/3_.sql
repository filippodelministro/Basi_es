--? Scrivere una query che, relativamente a ciascun mese del 2013, restituisca il mese
--? (come intero da 1 a 12) e il numero medio di terapie per esordio effettuate dai
--? pazienti per combattere il dolore.
select distinct(month(E.DataEsordio)) as Mese, ifnull(D1.Mese, 0) MediaTer
from Esordio E left outer join (
		select month(D.DataEsordio) as Mese, avg(D.NumTerapie) as MediaTer
		from (
				select E.Paziente, E.DataEsordio, count(T.DataInizioTerapia) as NumTerapie
				from Esordio E inner join Terapia T on E.Paziente = T.Paziente
													and E.Patologia = T.Patologia
													and E.DataEsordio = T.DataEsordio
				where year(E.DataEsordio) = 2013
					and E.Patologia = 'Dolore'
				group by E.Paziente, E.DataEsordio
		) as D
		group by month(D.DataEsordio)
) as D1 on month(E.DataEsordio) = D1.Mese


--? Scrivere una query che restituisca nome e cognome dei pazienti che, esclusivamente 
--? per le patologie ortopediche, hanno assunto, man mano nella vita, tutti i farmaci 
--? a base di nimesulide.
select P.Nome, P.Cognome
from Terapia T inner join Patologia PA on T.Patologia = PA.Nome
			   inner join Paziente P on T.Paziente = P.CodFiscale
where PA.SettoreMedico = 'Ortopedia'
	and T.Farmaco in (
		select F.NomeCommerciale
		from Farmaco F
		where F.PrincipioAttivo = 'Nimesulide'
)
group by T.Paziente
having count(distinct T.Farmaco) = (
		select count(*)
		from Farmaco F
		where F.PrincipioAttivo = 'Nimesulide'
)

--? Scrivere una function che, ricevuto in ingresso il codice fiscale di un paziente,
--? restituisca il suo stato attuale di salute SS ottenuto mediante l’espressione ...
--? dove n è il numero di esordi attualmente in corso, g i è la gravità con cui la
--? patologia è stata contratta nell’esordio i-esimo, e w i è un coefficiente di
--? penalizzazione pari a: 1 se l’esordio i-esimo non ha terapie fallite; 1.5 se 
--? l’esordio i-esimo ha da 1 a 2 terapie fallite; 2.5 se l’esordio i-esimo ha più 
--? di 3 terapie fallite.



--? Scrivere una query che restituisca l’anno (o gli anni) in cui si sono verificati,
--? complessivamente fra i pazienti di Pisa e Firenze, più del 30% degli esordi di rinite
--? nel trimestre Marzo-Maggio rispetto al totale degli esordi della stessa patologia nello
--? stesso trimestre dello stesso anno, con il picco più alto di esordi raggiunto dai
--? pazienti di Pisa.

with
EsordiPisa as (
	select year(E.DataEsordio) as Anno, count(*) as NumEsordi 
	from Esordio E inner join Paziente P on E.Paziente = P.CodFiscale
	where P.Citta = 'Pisa'
		and E.Patologia = 'Febbre'
		and month(E.DataEsordio) between 3 and 5
	group by year(E.DataEsordio)
),
EsordiFirenze as (
	select year(E.DataEsordio) as Anno, count(*) as NumEsordi 
	from Esordio E inner join Paziente P on E.Paziente = P.CodFiscale
	where P.Citta = 'Firenze'
		and E.Patologia = 'Febbre'
		and month(E.DataEsordio) between 3 and 5
	group by year(E.DataEsordio)
),
EsordiTot as (
	select year(E.DataEsordio) as Anno, count(*) as NumEsordi 
	from Esordio E inner join Paziente P on E.Paziente = P.CodFiscale
	where E.Patologia = 'Febbre'
		and month(E.DataEsordio) between 3 and 5
	group by year(E.DataEsordio)
)

select EP.Anno
from EsordiPisa EP inner join EsordiFirenze EF on EP.Anno = EF.Anno
				   inner join EsordiTot ET on EP.Anno = ET.Anno
where EP.NumEsordi + EF.NumEsordi > ET.NumEsordi * 0.3
	and EP.Anno in (
		select EP.Anno
		from EsordiPisa EP inner join EsordiFirenze EF on EP.Anno = EF.Anno
		where EP.NumEsordi > EF.NumEsordi
    )
