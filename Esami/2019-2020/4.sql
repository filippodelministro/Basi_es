--? Scrivere una query che restituisca codice fiscale, cognome ed età (anni compiuti)
--? dei pazienti di Pisa e Roma che hanno trattato la rinite solo con farmaci a base
--? di ambroxolo o mometasone fuorato.
select distinct P.CodFiscale, P.Cognome, year(current_date()) - year(P.DataNascita) as Età
from Terapia T inner join Paziente P on T.Paziente = P.CodFiscale
where T.Patologia = 'Rinite'
	and (P.Citta = 'Pisa' or P.Citta = 'Roma')
	and T.Paziente not in (		-- escludo tutti quelli che hanno usato un PrincipioAttivo diverso dai target
		select T.Paziente
		from Terapia T inner join Farmaco F on T.Farmaco = F.NomeCommerciale
		where T.Patologia = 'Rinite'
			and F.PrincipioAttivo <> 'Ambroxolo'
            and F.PrincipioAttivo <> 'Mometasone fuorato'
)

--? Implementare una business rule che consenta di inserire una nuova terapia solo se
--? le precedenti dello stesso esordio sono terminate. Se la nuova terapia si basa
--? su un farmaco già assunto nell’esordio, essa non deve seguire immediatamente
--? la terapia precedente con lo stesso farmaco, e la sua posologia non deve superare
--? di oltre il 20% la posologia media delle precedenti terapie dello stesso esordio
--? con lo stesso farmaco.
drop trigger if exists inserimento_terapia;
delimiter $$
create trigger inserimento_terapia
before insert on Terapia for each row
begin
	declare esiste bool default false;
	declare data_ultima date default null;
    declare farmaco_ultima varchar(50) default '';
	declare posologia_media float default 0;

    if exists (
			select *
			from Terapia T
            where T.Paziente = new.Paziente
				and T.Patologia = new.Patologia
                and T.DataEsordio = new.DataEsordio
				and T.DataFineTerapia is null
    ) then set esiste = true;
    end if;
    set data_ultima = (
			select max(T.DataFineEsordio)
            from Terapia T
            where T.Paziente = new.Paziente
				and T.Patologia = new.Patologia
                and T.DataEsordio = new.DataEsordio
    );
    set farmaco_ultima = (
			select T.Farmaco
            from Terapia T
            where T.Paziente = new.Paziente
				and T.Patologia = new.Patologia
                and T.DataEsordio = new.DataEsordio
                and T.DataFineTerapia = data_ultima
    );
    set posologia_media = (
		select avg(T.Posologia)
		from Terapia T
		where T.Paziente = new.Paziente
			and T.Patologia = new.Patologia
            and T.Farmaco = new.Farmaco
			and T.DataEsordio = new.DataEsordio
    );
    
    if esiste = true then
		signal sqlstate '45000' set message_text = 'Esiste Terapia non finita! Cojone';
	elseif (new.Farmaco = farmaco_ultima) then
        signal sqlstate '45000' set message_text = 'Errore Farmaco!';
	elseif (new.Posologia >= 0.2 * posologia_media) then
		 signal sqlstate '45000' set message_text = 'Errore Posologia!';
    end if;
    
end $$
delimiter ;

--? Lo stress lavoro-correlato è stato recentemente inserito nell’elenco delle patologie 
--? dall’Organizzazione Mondiale della Sanità (OMS), dopo dieci anni di dibattiti sul tema.
--? Lo stomaco è uno degli organi bersaglio della somatizzazione dello stress, e l’OMS ha
--? richiesto alla clinica di fornire un report periodico per eseguire un’analisi dettagliata
--? dei casi delle più frequenti patologie stress-correlate a carico dello stomaco: la
--? gastrite e il reflusso gastroesofageo. A tale scopo, creare una materialized view
--? StreesStomachDiseas contenente, per gli esordi di entrambe le patologie, il
--? nome della patologia, il codice fiscale del paziente, la gravità, la data dell’esordio,
--? i giorni trascorsi dall’esordio precedente della stessa patologia dello stesso
--? paziente, la differenza di gravità con esso, una stringa contenente i farmaci che
--? il paziente ha assunto nell’esordio precedente della stessa patologia (separati da
--? virgola), e il numero medio di giorni fra la data d’inizio dell’esordio e la data
--? d’inizio dell’ultimo esordio della stessa patologia di tutti gli altri pazienti della
--? stessa città. Implementare il complete incremental refresh in modalità on demand