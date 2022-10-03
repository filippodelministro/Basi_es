--? Indicare nome e cognome di ciascun medico che ha visitato tutti i pazienti
--? della sua città.

                

--? Indicare nome e cognome dei pazienti che hanno avuto, anche solo per un 
--? giorno, più terapie in corso contemporaneamente.



--? Indicare il reddito massimo fra quelli di tutti i pazienti che, nell’
--? anno 2011, hanno effettuato esattamente tre visite, ognuna delle quali 
--? con un medico avente specializzazione diversa dagli altri.


--? Creare un vincolo di integrità generico (mediante un trigger) per impedire 
--? che un medico possa visitare mensilmente più di due volte lo stesso 
--? paziente, qualora all’atto delle due visite già effettuate in un dato 
--? mese dal medico sul paziente, quest’ultimo non fosse affetto da alcuna 
--? patologia.


--? Considerato ciascun farmaco per la cura di patologie gastroenterologiche,
--? indicato per più di una patologia, ma di fatto assunto per curare un’unica
--? patologia per oltre il 60% delle terapie basate su di esso iniziate negli 
--? ultimi cento anni, mantenere nella tabella INDICAZIONE la sola indicazione
--? del farmaco considerato riguardante tale unica patologia, eliminando 
--? tutte le altre.
