--? Scrivere una query che, considerate le sole terapie finalizzate alla cura di 
--? patologie cardiache, restituisca, per ciascuna di esse, il nome della patologia
--? e il farmaco più utilizzato per curarla. La soluzione proposta deve presupporre
--? che, data una patologia cardiaca, tale farmaco possa non essere unico.
with
Utilizzi as (
		select T.Patologia, T.Farmaco, count(*) as NumUtilizzi
		from Terapia T inner join Patologia PA on T.Patologia = PA.Nome
		where PA.SettoreMedico = 'Cardiologia'
		group by T.Patologia, T.Farmaco
)

select U1.*
from Utilizzi U1 inner join (
		select U.Patologia, max(U.NumUtilizzi) as MaxUtilizzi
		from Utilizzi U
		group by U.Patologia
) as D on U1.Patologia = D.Patologia
	   and U1.NumUtilizzi = D.MaxUtilizzi


--? Scrivere una query che restituisca nome, cognome e reddito dei pazienti di
--? sesso femminile che al 15 Giugno 2010 risultavano affetti, oltre alle eventuali
--? altre, da un’unica patologia cronica, con invalidità superiore al 50%, e non
--? l’avevano mai curata con alcun farmaco fino a quel momento.
select P.Nome, P.Cognome, P.Reddito
from Esordio E inner join Paziente P on E.Paziente = P.CodFiscale
			   inner join Patologia PA on E.Patologia = PA.Nome
where E.DataEsordio < '2010-06-15'
	and E.Cronica = 'Si'
	and PA.Invalidita > 50
	and P.Sesso = 'F'
    and not exists (	-- non esite alcune terapia per tale patologia
		select *
        from Terapia T
        where T.Paziente = E.Paziente
            and T.Patologia = E.Patologia
            and T.DataInizioTerapia < '2010-06-15'
    )
group by E.Paziente
having count(distinct E.Patologia) = 1

--? Scrivere una query che restituisca, per tutte le patologie, nessuna esclusa,
--? il nome della patologia e il numero di pazienti di età superiore a quarant’anni
--? che l’hanno contratta almeno due volte, la seconda delle quali con gravità
--? superiore alla prima, comunque sempre in forma non cronica.
select P.Nome, ifnull(D.NumPaziente, 0)
from Patologia P left outer join (
		select E.Patologia, count(distinct E.Paziente) as NumPaziente
		from Esordio E inner join Paziente P on E.Paziente = P.CodFiscale
		where P.DataNascita + interval 40 year < current_date()
			and not exists (	-- mai in forma cronica
				select *
				from Esordio E1
				where E1.Patologia = E.Patologia
					and E1.Paziente = E.Paziente
					and E1.Cronica = 'si'
		)
			and exists (
				select *
				from Esordio E2
				where E2.Patologia = E.Patologia
					and E2.Paziente = E.Paziente
					and E2.Cronica = 'no'
					and E2.DataEsordio > E.DataEsordio
					and E2.Gravita > E.Gravita
		)
		group by E.Patologia
) as D on P.Nome = D.Patologia


--? Scrivere una stored procedure che, ricevuto in ingresso il codice fiscale di un 
--? paziente e il nome di un principio attivo, blocchi immediatamente tutte le terapie
--? attualmente in corso, impostando la data di fine terapia alla data corrente,
--? qualora si stiano protraendo per oltre una settimana, e il paziente abbia già 
--? effettuato in precedenza, comunque non oltre sei mesi prima, almeno tre terapie con
--? lo stesso farmaco o con un farmaco contenente lo stesso principio attivo, di cui 
--? almeno una con posologia superiore a tre compresse al giorno. Al termine delle 
--? elaborazioni, la procedura deve restituire, nonché mostrare a video, un resoconto
--? contenente le seguenti informazioni sulle terapie bloccate: codice fiscale del
--? paziente, farmaco, durata della terapia interrotta, posologia, numero di terapie
--? precedenti con posologia superiore a tre compresse al giorno.
