Esercizio 1 (9 punti)
Scrivere una query che blocchi, cancellandole, le terapie in corso basate sul farmaco Broncho-Vaxom, ini-
ziate più di tre giorni fa, da pazienti pediatrici (età inferiore a 12 anni) attualmente affetti da broncospasmo.
A cancellazione avvenuta, restituire, come result set, il codice fiscale dei pazienti oggetto di blocco.

Esercizio 2 (10 punti)
Introdurre una ridondanza SpesaGiornaliera nella tabella P AZIENTE per mantenere l’attuale spesa giornalie-
ra in farmaci di ciascun paziente. Nel computo, si ignorino le patologie con diritto di esenzione. Scrivere il
codice per creare, popolare e mantenere costantemente aggiornata la ridondanza.


--? Considerato ogni medico avente parcella inferiore alla parcella media di almeno altre due 
--? specializzazioni oltre alla sua, scrivere una query che restituisca, per ciascuna 
--? specializzazione medica della clinica, nessuna esclusa, il nome della specializzazione,
--? la matricola del medico con il più alto numero di visite mutuate realizzate nel mese in 
--? corso, e l’ammontare dell’incasso derivante dalle sue visite mutuate. In caso di pari merito,
--? restituire l’incasso di ciascun medico ex aequo di ogni specializzazione. L’importo pagato
--? dal paziente per una visita specialistica mutuata è calcolato da una stored function 
--? ticket(), di cui si richiede il codice, e corrisponde al ticket derivante dalla fascia di
--? reddito annuale del paziente: 
--?     € 36.15 per redditi fino a € 36,152;
--?     € 50.00 per redditi tra € 36,153 e € 100,000;
--?     € 70.00 per redditi superiori a € 100,000.
--? Se la visita specialistica mutuata è una visita di controllo, cioè se il paziente ha 
--? già effettuato una visita mutuata con lo stesso medico non oltre sei mesi prima, ma 
--? comunque nello stesso anno, il ticket è ridotto del 35%. Un paziente può effettuare un 
--? numero illimitato di visite specialistiche mutuate in un anno, e ognuna di esse può
--? prevedere al massimo due visite di controllo.