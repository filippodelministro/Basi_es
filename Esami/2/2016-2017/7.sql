--? Scrivere una query che restituisca le patologie i cui farmaci indicati sono tutti venduti
--? in confezioni contenenti compresse sufficienti a completare oltre il 65% delle terapie
--? basate su ciascuno di essi con una sola confezione.


--? Aggiungere un attributo ridondante NVisitePrec nella tabella VISITA contenente il numero di
--? visite precedenti effettuate dal paziente con quel medico. Implementare l’aggiornamento
--? immediate della ridondanza.


--? Implementare una analytic function efficiente (tramite un select statement con variabili
--? user-defined) che restituisca, per ciascun esordio di ogni paziente, il codice fiscale del
--? paziente, la patologia contratta, la data in cui è stata contratta, la patologia contratta
--? nell’esordio successivo e la data in cui quest’ultima è stata contratta. Scrivere in un
--? commento di quale analytic function si tratta fra quelle viste a lezione.