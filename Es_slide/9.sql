Argomenti:
    - Trigger (before & after)
    - Business rule (gestiti da trigger)
    - Event (normali o recurring)
        · set global event_scheduler = on;
    - DDL
        · create
        · alter
        · drop

--*==================================================================================
--*									ES SLIDE										
--*==================================================================================

--? Gestire un attributo ridondante nella tabella Paziente contenente
--? la data nella quale un paziente è stato visitato l’ultima volta.
drop trigger if exists trig;
create trigger trig
after insert on Visita for each row
	update Paziente
    set UltimaVisita = current_date()
    where CodFiscale = new.Paziente
 

--? Scrivere un trigger che, ogni volta che viene inserita una nuova visita, 
--? se essa è mutuata imposti l’attributo Ticket in base alle fasce di reddito annue
--? - ticket pari a euro 36.15 se reddito fra euro 0 ed euro 15,000
--? - ticket pari a euro 45.25 se reddito fra euro 15,000 ed euro 25,000
--? - ticket pari a 50.00 euro se reddito oltre 25,000 euro.
--? Se la visita non è mutuata, inserire NULL.
drop trigger if exists trig;
delimiter $$

create trigger trig
before insert on Visita		-- before perchè va messo prima di inserire la Visita 
for each row		

begin
    -- trovo intanto il reddito annuo del paziente
    set @reddito_annuo = (
			select Reddito * 12
            from Paziente 
            where CodFiscale = new.CodFiscale
    );

	-- controllo fascia di reddito e setto ticket (solo se mutuata)
    if(new.Mutuata = 1) then
		if(@reddito_annuo between 0 and 14999) then
			set new.Ticket = 36.15;
        elseif (@reddito_annuo between 15000 and 25000) then
			set new.Ticket = 45.25;
        else
			set new.Ticket = 50;
		end if;
    else
		set new.Ticket = null;
	end if;
    
    
end $$
delimiter ;


--? Aggiungere un attributo ridondante alla tabella Paziente che contenga il
--? numero di vistite mutuate effettuate
-- Questo aggiunge una colonna: se lo voglio aggiornare ogni volta devo scrivere
-- un trigger!!
alter table Paziente
	add column VisiteMutuate integer not null default 0;

update Paziente P
set P.VisiteMutuate = (
		select count(*)
        from Visite V
        where V.Paziente = P.CodFiscale
			and V.Mutuata = 1
)


--?Implementare il trigger che mantiene aggiornato l’attributo ridondante nella
--?tabella Paziente, contenente il numero di vistite mutuate effettuate.
drop trigger if exists trig;
delimiter $$
create trigger trig
after insert on Visita for each row

begin
	if (Mutuata = 1) then
		update Paziente
        set VisiteMutuate = VisiteMutuate + 1
			where CodFiscale = new.Paziente;
    end if;
end $$
delimiter ;


--? Ogni mese, le visite non mutuate di un medico non devono superare quelle 
--? mutuate.
drop trigger if exists trig;

delimiter $$
create trigger trig
before insert on Visita for each row
begin
	
    -- conta i due tipi di visita ...
    set @visite_mutuate = (
		select count(*)
        from Visita V
        where V.Medico = new.Medico
			and year(V.Data) = year(new.Data)
			and month(V.Data) = month(new.Data)
            and V.Mutuata = 1
    );
    set @visite_non_mutuate = (
		select count(*)
        from Visita V
        where V.Medico = new.Medico
			and year(V.Data) = year(new.Data)
			and month(V.Data) = month(new.Data)
            and V.Mutuata = 0
    );
	
    -- ... e li confronta
	if (@visite_mutuate >= @visite_non_mutuate) then
		signal sqlstate '45000'
        set message_text = 'Limite massimo visite mutuate!';
    end if;
end $$
delimiter ;

--? Creare e mantenere giornalmente aggiornata una ridondanza nella
--? tabella Medico contenente, per ciascuno, il totale di visite effettuate.
drop event if exists evento;
create event evento on schedule every 1 day		-- recurring (every day)
starts '2016-05-22 23:55:00'		-- prima esecuzione
-- ENDS ‘data_ora’					-- si può stabilire anche la fine
do
	update Medico
    -- conta ogni giorno le visite di oggi e le aggiunge
	set VisiteEffettuate = VisiteEffettuate + (
			select count(*) 
			from Visita V
			where V.Medico = Matricola
				and V.Data = current_date
	);