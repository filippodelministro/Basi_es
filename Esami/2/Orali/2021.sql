--? Considerati i soli pazienti di Pisa e Firenze che hanno contratto al massimo una
--? patologia per settore medico (una o più volte), scrivere una query che, per ogni
--? paziente, restituisca il nome, il cognome, la città, il farmaco usato nel maggior
--? numero di terapie, considerando nel complesso le varie patologie, e la posologia
--? media. In caso di pari merito fra i farmaci usati da un paziente, completare il record
--? con valori NULL. 



--? Considerate le terapie dei pazienti aventi reddito inferiore al reddito medio della loro
--? città, scrivere una query che, per ciascun paziente target, restituisca il codice fiscale, il
--? cognome, e la durata media delle terapie (oggi terminate) in cui, se avesse assunto il
--? farmaco più economico basato sullo stesso principio attivo del farmaco
--? effettivamente assunto, avrebbe ottenuto un risparmio sul costo totale della terapia
--? superiore al 50%, e a quanto sarebbe ammontato tale risparmio.”


--? Implementare una stored procedure che, presa in ingresso una data d e una città di
--? provenienza dei pazienti c, consideri i pazienti della città c e stampi una classifica
--? delle patologie, dove una patologia è in posizione tanto più alta quanto più è basso,
--? in media fra i pazienti di città c, il numero di giorni impiegati per guarire da tutte
--? le patologie (oggi concluse) dalle quali i pazienti di città c erano affetti in data d.

--? Creare una materialized view SpesaVisite che, per ogni paziente visitato da almeno un
--? medico di tutte le città, in almeno due specializzazioni, contenga il nome e cognome
--? del paziente, il numero totale di medici da cui è stato visitato, e la spesa complessiva
--? sostenuta per tali visite. Se mutuate, le visite hanno un costo di 38 Euro. Popolare 
--? la materialized view e scrivere il codice per mantenerla in sync con i raw data.


--? Scrivere una stored procedure che sposti, in una tabella di archivio con stesso schema
--? di Esordio, gli esordi di patologie gastriche conclusi con guarigione, relativi a pazienti
--? che non hanno contratto, precedentemente all'esordio, patologie gastriche, ma che ne
--? hanno curate con successo almeno due successivamente.

