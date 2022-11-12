--? Scrivere una query che restituisca codice fiscale, cognome ed età (anni compiuti) dei pazienti
--? di Pisa e Roma che hanno trattato la rinite solo con farmaci a base di ambroxolo o mometasone
--? fuorato.
select distinct T.Paziente, P.Cognome, year(current_date) - year(P.DataNascita) as Età
from Paziente P inner join Terapia T on P.CodFiscale = T.Paziente
where (P.Citta = 'Pisa' or P.Citta = 'Roma')
	and T.Patologia = 'Rinite'
    and T.Paziente not in (
		select distinct T.Paziente
		from Paziente P inner join Terapia T on P.CodFiscale = T.Paziente
		where (P.Citta = 'Pisa' or P.Citta = 'Roma')
			and T.Patologia = 'Rinite'
			and T.Farmaco not in (
				select F.NomeCommerciale
				from Farmaco F
				where F.PrincipioAttivo = 'Ambroxolo'
					or F.PrincipioAttivo = 'Mometasone fuorato'
			)
)

--? Implementare una business rule che consenta di inserire una nuova terapia solo se le precedenti
--? dello stesso esordio sono terminate. Se la nuova terapia si basa su un farmaco già assunto
--? nell’esordio, essa non deve seguire immediatamente la terapia precedente con lo stesso farmaco,
--? e la sua posologia non deve superare di oltre il 20% la posologia media delle precedenti
--? terapie dello stesso esordio con lo stesso farmaco.




--? Lo stress lavoro-correlato è stato recentemente inserito nell’elenco delle patologie dall’
--? Organizzazione Mondiale della Sanità (OMS), dopo dieci anni di dibattiti sul tema. Lo stomaco
--? è uno degli organi bersaglio della somatizzazione dello stress, e l’OMS ha richiesto alla
--? clinica di fornire un report periodico per eseguire un’analisi dettagliata dei casi delle più
--? frequenti patologie stress-correlate a carico dello stomaco: la gastrite e il reflusso
--? gastroesofageo. A tale scopo, creare una materialized view STRESSSTOMACHDISEASES contenente,
--? per gli esordi di entrambe le patologie, il nome della patologia, il codice fiscale del paziente,
--? la gravità, la data dell’esordio, i giorni trascorsi dall’esordio precedente della stessa
--? patologia dello stesso paziente, la differenza di gravità con esso, una stringa contenente i
--? farmaci che il paziente ha assunto nell’esordio precedente della stessa patologia (separati
--? da virgola), e il numero medio di giorni fra la data d’inizio dell’esordio e la data d’inizio
--? dell’ultimo esordio della stessa patologia di tutti gli altri pazienti della stessa città.
--? Implementare il complete incremental refresh in modalità on demand.