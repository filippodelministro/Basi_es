--? Considerate le patologie gastroenteriche, scrivere una query che restituisca il nome 
--? commerciale dei farmaci utilizzati da almeno un paziente in almeno due terapie relative
--? alla stessa patologia, e il numero di tali pazienti per ciascuno di tali farmaci.
select D.Farmaco, count(distinct D.Paziente) as NumPaziente
from (
	select T.Paziente, T.Patologia, T.Farmaco
	from Terapia T inner join Patologia PA on T.Patologia = PA.Nome
	where PA.SettoreMedico = 'Gastroenterologia'
	group by T.Paziente, T.Patologia, T.Farmaco
	having count(distinct T.DataInizioTerapia) > 1
) as D
group by D.Farmaco


--? Implementare una business rule che consenta l’inserimento di una visita mutuata relativa a
--? un settore medico solamente se il paziente non è attualmente in terapia con un farmaco
--? indicato per patologie dello stesso settore medico e le sue visite mutuate effettuate
--? con medici specialisti di quel settore medico, dall’inizio dell’anno, non superino del 
--? 20% le visite non mutuate.




Implementare una stored procedure healthy_patients_in_period() che, ricevute in ingresso due
date _from e _to, restituisca, come result set, il codice fiscale dei pazienti che nel lasso di tempo compre-
so fra le due date risultavano sani, ovverosia, non avevano patologie in essere. Inoltre, per ogni paziente del
risultato, la stored procedure deve restituire da quanto tempo (in giorni) il paziente risultava sano prima di
_from e per quanto tempo (in giorni) lo è stato dopo _to. Si presti attenzione al fatto che in generale gli
esordi possono sovrapporsi temporalmente e che quindi, in un dato istante, un paziente può essere affetto
da più patologie. Si gestiscano i contesti di errore dovuti a input non validi, interrompendo forzatamente
l’elaborazione.