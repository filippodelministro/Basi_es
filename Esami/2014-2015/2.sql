--? Scrivere una query che, considerate le sole terapie finalizzate alla cura di 
--? patologie cardiache, restituisca, per ciascuna di esse, il nome della patologia
--? e il farmaco più utilizzato per curarla. La soluzione proposta deve presupporre
--? che, data una patologia cardiaca, tale farmaco possa non essere unico.
with Utilizzi as (
		select T.Patologia, T.Farmaco, count(*) as NumUtilizzi
		from Terapia T inner join Patologia P on T.Patologia = P.Nome
		where P.SettoreMedico = 'Cardiologia'
		group by T.Patologia, T.Farmaco
)

select U.Patologia, U.Farmaco, U.NumUtilizzi
from Utilizzi U
group by U.Patologia, U.Farmaco, U.NumUtilizzi
having U.NumUtilizzi >= ALL (
		select U2.NumUtilizzi
        from Utilizzi U2
        where U2.Patologia = U.Patologia
)

--? Scrivere una query che restituisca nome, cognome e reddito dei pazienti di
--? sesso femminile che al 15 Giugno 2010 risultavano affetti, oltre alle eventuali
--? altre, da un’unica patologia cronica, con invalidità superiore al 50%, e non
--? l’avevano mai curata con alcun farmaco fino a quel momento.
select P.Nome, P.Cognome, P.Reddito
from Esordio E inner join Patologia PA on E.Patologia = PA.Nome
			   inner join Paziente P on E.Paziente = P.CodFiscale
where E.DataEsordio < '2010-06-15'
	and E.Cronica = 'si'
	and PA.Invalidita > 50
	and P.Sesso = 'F'
	and not exists (	-- non esiste una terapia per questa patologia
		select *
		from Terapia T
		where T.Paziente = E.Paziente
			and T.Patologia = E.Patologia
            and T.DataInizioTerapia < '2010-06-15'
	)
group by E.Paziente, P.Nome, P.Cognome, P.Reddito
having count(distinct E.Patologia) = 1	-- una sola patologia cronica


--? Scrivere una query che restituisca, per tutte le patologie, nessuna esclusa,
--? il nome della patologia e il numero di pazienti di età superiore a quarant’anni
--? che l’hanno contratta almeno due volte, la seconda delle quali con gravità
--? superiore alla prima, comunque sempre in forma non cronica.
--fix: diversa da quella di Pisto!!
select E.Patologia, count(distinct E.Paziente) as NumPazienti
from Esordio E inner join Paziente P on E.Paziente = P.CodFiscale
where P.DataNascita + interval 40 year > current_date()
	and not exists (	-- non deve esistere un esordio cronico di quella pat
		select *
        from Esordio E1
        where E.Paziente = E1.Paziente
			and E.Patologia = E1.Patologia
            and E.Cronica = 'si'
    )
    and exists ( -- deve esistere un esordio con gravita maggiore
		select *
        from Esordio E2
        where E.Paziente = E2.Paziente
			and E.Patologia = E2.Patologia
            and E.DataEsordio < E2.DataEsordio
            and E.Gravita < E2.Gravita
		)
group by E.Patologia


Scrivere una stored procedure che, ricevuto in ingresso il codice fiscale di un paziente e il nome di un prin-
cipio attivo, blocchi immediatamente tutte le terapie attualmente in corso, impostando la data di fine terapia
alla data corrente, qualora si stiano protraendo per oltre una settimana, e il paziente abbia già effettuato in
precedenza, comunque non oltre sei mesi prima, almeno tre terapie con lo stesso farmaco o con un farmaco
contenente lo stesso principio attivo, di cui almeno una con posologia superiore a tre compresse al giorno.
Al termine delle elaborazioni, la procedura deve restituire, nonché mostrare a video, un resoconto conte-
nente le seguenti informazioni sulle terapie bloccate: codice fiscale del paziente, farmaco, durata della tera-
pia interrotta, posologia, numero di terapie precedenti con posologia superiore a tre compresse al giorno.