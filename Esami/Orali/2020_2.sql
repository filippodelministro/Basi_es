--? Scrivere una query che cancelli le terapie in corso a base di pantoprazolo, iniziate più di 
--? due giorni fa, da pazienti di sesso femminile che avevano già assunto lo stesso farmaco
--? non meno di una settimana prima
delete Ter.*
from Terapia Ter left outer join (
				select *
				from Terapia T inner join Farmaco F on T.Farmaco = F.NomeCommerciale
							   inner join Paziente P on T.Paziente = P.CodFiscale
				where F.PrincipioAttivo = 'Pantoprazolo'
					and T.DataFineTerapia is null
					and T.DataInizioTerapia < current_date() - interval 2 day
					and P.Sesso = 'F'
					and exists (			-- esiste una terapia con stesso farmaco precedente
						select *
						from Terapia T1
						where T1.Paziente = T.Paziente
							and T1.Farmaco = T.Farmaco
							and T1.DataFineTerapia < T.DataFineTerapia
					)
					and not exists (		-- ma non prima di una settimana
						select *
						from Terapia T1
						where T1.Paziente = T.Paziente
							and T1.Farmaco = T.Farmaco
							and T1.DataInizioTerapia < T.DataInizioTerapia
							and T1.DataFineTerapia > current_date() - interval 1 week 
					)
) as D on D.Paziente = Ter.Paziente
	   and D.Patologia = Ter.Patologia
	   and D.DataEsordio = Ter.DataEsordio
	   and D.Farmaco = Ter.Farmaco
	   and D.DataInizioTerapia = Ter.DataInizioTerapia
where D.Paziente is not null


--? Scrivere una query che restituisca la città dalla quale proviene il maggior numero di
--? pazienti che non hanno sofferto d’insonnia per un numero di giorni maggiore a quello
--? degli altri pazienti della loro città. In caso di pari merito restituire tutti gli
--? ex aequo

with
Durata as (
		select D.*, P.Citta
        from Paziente P inner join (
				select E.Paziente, max(E.DataGuarigione - E.DataEsordio) as DurataMax
				from Esordio E
				where E.Patologia = 'Insonnia'
					and E.DataGuarigione is not null
				group by E.Paziente
		) as D on D.Paziente = P.CodFiscale
)

select D1.Citta
from Durata D1
where not exists (
		select *
		from Durata D2
		where D2.Paziente <> D1.Paziente
			and D2.Citta = D1.Citta
			and D2.DurataMax < D1.DurataMax
)
group by D1.Citta
having count(*) = (
		select max(D.Num) as NumInsonni
		from (
				select D1.Citta, count(*) as Num
				from Durata D1
				where not exists (
						select *
						from Durata D2
						where D2.Paziente <> D1.Paziente
							and D2.Citta = D1.Citta
							and D2.DurataMax < D1.DurataMax
				)
				group by D1.Citta
		) as D
)

--? Scrivere una query che, considerati gli ultimi dieci anni, restituisca anno e mese (come 
--? numeri interi) in cui non è stata effettuata alcuna visita in una (e una sola) specializzazione
--? fra quelle aventi almeno due medici provenienti dalla stessa città. Il nome di tale
--? specializzazione deve completare il record.



--? Scrivere una query che restituisca il nome commerciale dei farmaci che, in almeno un mese
--? del 2013, sono stati impiegati in terapie, iniziate e concluse in quel mese, tutte di 
--? durata inferiore a quelle iniziate e concluse nello stesso mese basate su un altro farmaco,
--? nell’ambito della cura di una stessa patologia. La query restituisca anche la patologia,
--? e le durate mensili medie delle terapie dei due farmaci per tale patologia, calcolate 
--? considerando i mesi in cui la condizione si è verificata.
with
TerapieTarget as (
		select *
		from Terapia T1
		where year(T1.DataInizioTerapia) = 2013
			and month(T1.DataInizioTerapia) = month(T1.DataFineTerapia)
),
Risultato as (
		select TT1.Patologia, TT1.Farmaco as Farmaco1, TT2.Farmaco as Farmaco2, month(TT1.DataInizioTerapia) as Mese
		from TerapieTarget TT1 inner join TerapieTarget TT2 on TT1.Patologia = TT2.Patologia
															and TT1.Farmaco <> TT2.Farmaco
															and month(TT1.DataInizioTerapia) = month(TT2.DataInizioTerapia)
		where datediff(TT1.DataFineTerapia, TT1.DataInizioTerapia) < datediff(TT2.DataFineTerapia, TT2.DataInizioTerapia)
)

select T1.Farmaco, avg(datediff(T1.DataFineTerapia, T1.DataInizioTerapia)) as Media
from Terapia T1 inner join Risultato R1 on T1.Patologia = R1.Patologia
									   and T1.Farmaco = R1.Farmaco1
                                       and month(T1.DataInizioTerapia) = R1.Mese
                                       and year(T1.DataInizioTerapia) = 2013
                                       and month(T1.DataInizioTerapia) = month(T1.DataFineTerapia)
group by T1.Farmaco

union

select T1.Farmaco, avg(datediff(T1.DataFineTerapia, T1.DataInizioTerapia))
from Terapia T1 inner join Risultato R1 on T1.Patologia = R1.Patologia
									   and T1.Farmaco = R1.Farmaco2
                                       and month(T1.DataInizioTerapia) = R1.Mese
                                       and year(T1.DataInizioTerapia) = 2013
                                       and month(T1.DataInizioTerapia) = month(T1.DataFineTerapia)
group by T1.Farmaco


--? Scrivere una query che consideri le specializzazioni della clinica e il primo trimestre degli 
--? ultimi 10 anni, e per ciascuna restituisca il nome della specializzazione, l’anno, e la 
--? differenza percentuale fra l’incasso ottenuto nel primo trimestre di tale anno con le visite
--? non mutuate e quelle realizzate nel primo trimestre dell’anno precedente.

with
IncassiAnno as (
		select year(V.Data) as Anno, M.Specializzazione, sum(M.Parcella) as Incasso
		from Medico M inner join Visita V on M.Matricola = V.Medico
		where V.Data > current_date() - interval 20 year
			and month(V.Data) < 4
			and V.Mutuata = 0
		group by year(V.Data), M.Specializzazione
)

select IA2.Anno, IA2.Specializzazione, (IA2.Incasso - IA1.Incasso) / IA1.Incasso*100 as Percentuale
from IncassiAnno IA1 inner join IncassiAnno IA2 on IA1.Anno = IA2.Anno - 1
													 and IA1.Specializzazione = IA2.Specializzazione

