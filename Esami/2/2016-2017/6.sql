--? Scrivere una query che restituisca il codice fiscale dei pazienti che hanno assunto Lyrica
--? nel 1998 solo per curare patologie precedentemente già curate con successo da almeno un altro
--? paziente della stessa città.
select T.Paziente
from Terapia T inner join Paziente P on T.Paziente = P.CodFiscale
where T.Farmaco = 'Lyrica'
	and year(T.DataInizioTerapia) = '1998'
    and exists (
		select *
        from Terapia T1 inner join Paziente P1 on T1.Paziente = P1.CodFiscale
        where P1.Citta <> P.Citta
			and T1.Patologia = T.Patologia
            and T1.Farmaco = T.Farmaco
            and T1.DataInizioTerapia < T.DataInizioTerapia
    )
	


--? Implementare una business rule che consenta aumenti di prezzo dei farmaci a base di
--? paracetamolo non superiori al 5% del prezzo medio attuale dei farmaci basati sullo
--? stesso principio attivo.
drop trigger if exists modifica_prezzo;
delimiter $$
create trigger modifica_prezzo
before update on Farmaco for each row
begin
    declare media_paracetamolo double default 0;
	set media_paracetamolo = (
		select avg(F.Costo) 
		from Farmaco F
		where F.PrincipioAttivo = 'paracetamolo'
	);
    
	-- il costo modificato non deve superare il 5% del costo medio
	if (new.Costo - old.Costo > media_paracetamolo * 0.05) then 
		signal sqlstate '45000'
			set message_text = 'modifica prezzo non consentita!';
    end if;

end $$
delimiter ;





--? Implementare una analytic function efficiente (tramite select statement con variabili
--? user-defined) per ottenere il cognome dei medici aventi rank = 1 e rank = 2 in una
--? classifica in cui un medico ottiene un rank tanto più alto quante più visite ha effettuato
--? rispetto agli altri medici della sua specializzazione. Scrivere, in un commento, di quale
--? analytic function si tratta, fra quelle viste a lezione.