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
