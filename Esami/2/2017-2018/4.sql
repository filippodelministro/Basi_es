--? Scrivere una query che consideri i farmaci a base di diazepam e lorazepam e restituisca codice
--? fiscale e sesso dei pazienti che hanno assunto tutti i farmaci basati sul primo o, alternativamente,
--? sul secondo principio attivo durante il triennio 2010-2012, e con quale posologia media.


--? Implementare un event che sposti mensilmente le terapie terminate oltre sei mesi prima in una
--? tabella di archivio ARCHIVIO TERAPIE mediante una stored procedure dump_therapies(). Salvare
--? in ARCHIVIO TERAPIE il codice fiscale del paziente, la patologia, il nome commerciale del
--? farmaco, l’anno d’inizio, la durata della terapia in giorni e il numero totale di compresse
--? assunte. L’event deve salvare in una tabella persistente la data dell’ultima volta in cui è 
--? andato in esecuzione e il numero di terapie archiviate.


--? Implementare una funzionalità analytics efficiente (mediante un unico select statement con
--? variabili user-defined) che, per ogni paziente con più di tre esordi, consideri tali esordi e
--? li partizioni in quattro gruppi di uguale numerosità sulla base della loro durata, associando
--? così a ciascun esordio il cosiddetto quartile, cioè un intero da 1 a 4. Gli esordi più brevi
--? saranno associati al quartile 1, quelli un po’ più lunghi al quartile 2, e così via. Se è 
--? impossibile associare lo stesso numero di esordi a tutti i quartili, gli esordi in più devono es-
--? sere equamente divisi fra i primi quartili.

