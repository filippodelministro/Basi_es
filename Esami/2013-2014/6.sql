--? Indicare nome e cognome di ciascun medico che ha visitato tutti i pazienti
--? della sua città.
select M1.Nome, M1.Cognome
from Medico M1 inner join(
		select V.Medico, P.Citta
		from Paziente P inner join Visita V on P.CodFiscale = V.Paziente
						inner join Medico M on M.Matricola = V.Medico
		where M.Citta = P.Citta
		group by V.Medico, P.Citta
		having count(distinct V.Paziente) = (
				select count(*)
				from Paziente P1
				where P1.Citta = P.Citta
		)
) as D on D.Medico = M1.Matricola
                

--? Indicare nome e cognome dei pazienti che hanno avuto, anche solo per un 
--? giorno, più terapie in corso contemporaneamente.

select distinct P.Nome, P.Cognome
from Terapia T1 inner join Terapia T2 on (	-- cond. di Terapie diverse per un paz
					T1.Paziente = T2.Paziente
                    and T1.Patologia <> T2.Patologia
                    and T1.Farmaco <> T2.Farmaco
					and T1.DataInizioTerapia <> T2.DataInizioTerapia
)
				inner join Paziente P on T1.Paziente = P.CodFiscale
where (	-- T1 e T2 terminate: controllo le date, entrambi i casi sono validi
		T1.DataFineTerapia is not null
		and(T2.DataFineTerapia is not null
		and (T2.DataInizioTerapia between T1.DataInizioTerapia and T1.DataFineTerapia
				or
				T2.DataFineTerapia between T1.DataInizioTerapia and T1.DataFineTerapia
            )
		)
)
OR	-- T1 in corso, T2 terminata
(T1.DataFineTerapia is null
		and (T2.DataFineTerapia is not null
		and (T2.DataInizioTerapia >= T1.DataInizioTerapia
				or
				T2.DataFineTerapia >= T1.DataInizioTerapia
			)
	)
)
OR	-- T1 terminata, T2 in corso
	(T1.DataFineTerapia is not null
		and T2.DataFineTerapia is null
		and T2.DataInizioTerapia <= T1.DataFineTerapia
		)
OR
	(	-- entrambe Terapie in corso
        T1.DataFineTerapia is null and T2.DataFineTerapia is null
);


Esercizio 3 (6 punti)
Indicare il reddito massimo fra quelli di tutti i pazienti che, nell’anno 2011, hanno effettuato esat-
tamente tre visite, ognuna delle quali con un medico avente specializzazione diversa dagli altri.
Esercizio 4 (7 punti)
Creare un vincolo di integrità generico (mediante un trigger) per impedire che un medico possa vi-
sitare mensilmente più di due volte lo stesso paziente, qualora all’atto delle due visite già effettuate
in un dato mese dal medico sul paziente, quest’ultimo non fosse affetto da alcuna patologia.
Esercizio 5 (8 punti)
Considerato ciascun farmaco per la cura di patologie gastroenterologiche, indicato per più di una
patologia, ma di fatto assunto per curare un’unica patologia per oltre l’80% delle terapie basate su
di esso iniziate negli ultimi dieci anni, mantenere nella tabella I NDICAZIONE la sola indicazione del
farmaco considerato riguardante tale unica patologia, eliminando tutte le altre.