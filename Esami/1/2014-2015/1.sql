--? Scrivere una query che restituisca il nome commerciale di ciascun 
--? farmaco utilizzato da almeno un paziente per curare tutte le patologie
--? per le quali è indicato.
select distinct T.Farmaco
from Terapia T
group by T.Farmaco
having count(distinct T.Patologia) = (
		select count(distinct I.Patologia)
        from Indicazione I
        where I.Farmaco = T.Farmaco
)

--? Scrivere una query che restituisca il numero di pazienti visitati solo
--? da medici specializzati in cardiologia o neurologia, almeno due volte 
--? per ciascuna delle due specializzazioni. Si scriva la query senza usare viste.
select count(distinct D.Paziente) as NumPazienti
from (
		select M1.Specializzazione, V1.Paziente
		from Visita V1 inner join Medico M1 on V1.Medico = M1.Matricola
		where V1.Paziente not in (
				select V.Paziente
				from Visita V inner join Medico M on V.Medico = M.Matricola
				where M.Specializzazione <> 'Cardiologia'
					and M.Specializzazione <> 'Neurologia'
		)
			and M1.Specializzazione = 'Cardiologia' or M1.Specializzazione = 'Neurologia'
		group by M1.Specializzazione, V1.Paziente
		having count(distinct V1.Data) > 1
) as D

--todo: ======================================================================
--? Creare una business rule che permetta di inserire un nuovo farmaco F e le
--? relative indicazioni, qualora non vi siano già più di due farmaci di cui
--? almeno uno basato sullo stesso principio attivo, aventi, ciascuno, un’
--? indicazione per una stessa patologia per la quale F è indicato. Supporre
--? che per prima cosa sia inserito il farmaco, dopodiché siano inserite 
--? le varie indicazioni.

--? Un paziente effettua una visita di accertamento quando, dopo essere stato 
--? visitato inizialmente da un medico, desidera avere anche il parere di un altro
--? medico della stessa specializzazione, dal quale si fa visitare senza iniziare, 
--? nel frattempo, alcuna terapia per la cura di patologie inerenti tale
--? specializzazione. In generale, dopo una visita iniziale, un paziente può
--? effettuare più visite di accertamento, posticipando ulteriormente l’inizio
--? della terapia. Creare una materialized view ACCERTAMENTO contenente codice
--? fiscale, nome e cognome dei pazienti che, nell’ultimo trimestre,
--? relativamente ad almeno una visita iniziale, hanno effettuato una o più 
--? visite di accertamento, quante ne hanno effettuate per ogni visita iniziale,
--? e il cognome del medico che ha effettuato tale visita iniziale.
--? Gestire la materialized view mediante deferred refresh con cadenza trimestrale.
--todo: ======================================================================
