
--? Considerate tutte le città di provenienza dei pazienti, scrivere una query che restituisca
--? la patologia mediamente più contratta, fra tutte le città, da pazienti al di sotto dei venti
--? anni d’età. In caso di pari merito, restituire tutti gli ex aequo.


--? Implementare una analytic function efficiente (tramite un select statement con variabili
--? user-defined) che effettui il dense rank dei medici in base al totale di pazienti visitati,
--? da ognuno, nel quadriennio 2013-2016. Il result set deve contenere il dense rank value e 
--? la matricola del medico. Non si usino istruzioni CREATE. 

--? Implementare una stored procedure all_drugs()che riceva in ingresso un principio attivo p e
--? un settore medico s, consideri i farmaci basati su p, e restituisca il numero totale di
--? pazienti che, per curare patologie del settore medico s, nel corso della vita li hanno
--? assunti tutti o tutti tranne quello in generale meno usato nelle terapie per patologie del
--? settore medico s. Il parametro OUT della stored procedure deve essere unico, contenente il
--? valore cumulativo dei pazienti sopra descritti.