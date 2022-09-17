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



