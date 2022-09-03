--? Scrivere una query che cancelli le terapie in corso a base di pantoprazolo, iniziate più di 
--? due giorni fa, da pazienti di sesso femminile che avevano già assunto lo stesso farmaco
--? non meno di una settimana prima (con versione join equivalente, sapere cosa vuol dire
--? l’errore “the target table is not updatable”: sto cercando di fare un aggiornamento su
--? una derived table)
delete T4.*
from Terapia T4 left outer join 
(
		select *
		from Terapia T inner join Farmaco F on T.Farmaco = F.NomeCommerciale
					   inner join Paziente P on T.Paziente = P.CodFiscale
		where F.PrincipioAttivo = 'Pantoprazolo'
			and T.DataInizioTerapia < current_date() - interval 2 day
			and P.Sesso = 'F'
			and T.DataFineTerapia is null		-- in corso
			and exists (
					select *
					from Terapia T1
					where T1.Paziente = T.Paziente
						and T1.Farmaco = T.Farmaco
						and T1.DataInizioTerapia <> T.DataInizioTerapia
						and T1.DataFineTerapia < T.DataInizioTerapia
						and T1.DataFineTerapia >= T.DataInizioTerapia - interval 1 week
			)
			and not exists (
							select *
							from Terapia T2
							where T2.Paziente = T.Paziente
								and T2.Farmaco = T.Farmaco
								and T2.DataInizioTerapia <> T.DataInizioTerapia
								and T2.DataFineTerapia < T.DataInizioTerapia
								and T2.DataFineTerapia >= T.DataInizioTerapia - interval 1 week
			)
		) as D on T4.Paziente = D.Paziente
			   and T4.Patologia = D.Patologia
               and T4.DataEsordio = D.DataEsordio
               and T4.Farmaco = D.Farmaco
               and T4.DataInizioTerapia = D.DataInizioTerapia


--? Scrivere una query che restituisca la città dalla quale proviene il maggior numero di
--? pazienti che non hanno sofferto d’insonnia per un numero di giorni maggiore a quello
--? degli altri pazienti della loro città. In caso di pari merito restituire tutti gli
--? ex aequo



--? Scrivere una query che, considerati gli ultimi dieci anni, restituisca anno e mese (come 
--? numeri interi) in cui non è stata effettuata alcuna visita in una (e una sola) specializzazione
--? fra quelle aventi almeno due medici provenienti dalla stessa città. Il nome di tale
--? specializzazione deve completare il record.
select distinct year(V1.Data) as Anno, month(V1.Data) as Mese
from Visita V1 left outer join (
select year(V.Data) as Anno, month(V.Data) as Mese
from Visita V inner join Medico M on V.Medico = M.Matricola
where V.Data > current_date() - interval 10 year
	and M.Specializzazione in (		-- Specializzazioni aventi almeno due medici per ogni citta
		select distinct M.Specializzazione
		from Medico M
		where exists (				-- deve esistere un medico diverso con stessa Spec e stessa Citta
				select *			-- (si poteva fare anche con join (provato))
				from Medico M1
				where M.Matricola <> M1.Matricola
					and M.Specializzazione = M1.Specializzazione
					and M.Citta = M1.Citta
		)
    )
group by year(V.Data), month(V.Data)
having count(distinct M.Specializzazione) = 1
) as D on year(V1.Data) = D.Anno
	   and month(V1.Data) = D.Mese
where V1.Data > current_date() - interval 10 year
	and D.Anno is null
    

--? Scrivere una query che restituisca il nome commerciale dei farmaci che, in almeno un mese
--? del 2013, sono stati impiegati in terapie, iniziate e concluse in quel mese, tutte di 
--? durata inferiore a quelle iniziate e concluse nello stesso mese basate su un altro farmaco,
--? nell’ambito della cura di una stessa patologia. La query restituisca anche la patologia,
--? e le durate mensili medie delle terapie dei due farmaci per tale patologia, calcolate 
--? considerando i mesi in cui la condizione si è verificata.
with
TerapieTarget as (
		select *
		from Terapia T
		where year(T.DataInizioTerapia) = 2013
			and year(T.DataInizioTerapia) = 2013
			and month(T.DataInizioTerapia) = month(T.DataFineTerapia)
)

select TT3.Patologia, TT3.Farmaco, avg(datediff(TT3.DataFineTerapia, TT3.DataInizioTerapia)) over(partition by TT3.Farmaco) as DurataF1,
					  TT4.Farmaco, avg(datediff(TT4.DataFineTerapia, TT4.DataInizioTerapia)) over(partition by TT4.Farmaco) as DurataF2
from TerapieTarget TT3 inner join TerapieTarget TT4 on TT4.Patologia = TT3.Patologia
													and TT4.Farmaco <> TT3.Farmaco
where TT3.Farmaco not in (
			select TT1.Farmaco -- *, datediff(TT2.DataFineTerapia, TT2.DataInizioTerapia)as DurataTT2, datediff(TT1.DataFineTerapia, TT1.DataInizioTerapia) as DurataTT1
			from TerapieTarget TT1 inner join TerapieTarget TT2 on TT1.Patologia = TT2.Patologia
																and TT1.Farmaco <> TT2.Farmaco
			where datediff(TT2.DataFineTerapia, TT2.DataInizioTerapia) < datediff(TT1.DataFineTerapia, TT1.DataInizioTerapia)
)

