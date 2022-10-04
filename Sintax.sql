--* Data Manipulation Language*--
--! INSERT
insert into Medico
values(...)             -- inserimento statico

insert into Medico
select ...              -- ciò che si inserisce deve avere la stessa
                        -- "forma" di Medico


--! DELETE
delete from Medico              -- con subquery
where Matricola in (
    select *
    from ( ... 
    
    ) as D
)

delete M1.*                     -- con join anticipato
from Medico M1 left outer join (
    select *
    from ...
) as D on M1.Matricola = D.Medico
where D.Qualcosa is null

--! UPDATE
-- aggiorna parcella di ogni medico con la media della sua spec
update Medico M inner join (
		select M.Specializzazione, avg(M.Parcella) as Media
		from Medico M
		group by M.Specializzazione
) as D on M.Specializzazione = D.Specializzazione
set M.Parcella = D.Media
--where         cond. eventuale

--* Data Definition Language *--
--! DROP
drop table nome_tab;

--! CREATE      
drop table if exists nome_tab;
create table if not exists nome_tab(
    var1 int,
    var2 varchar(100), 
    
    primary key (var1),
    unique(var2),             -- chiave candidata

    constraint nome_vincolo foreign key (var1)
    references nome_tab2(chiave_tab2)
    on update no action
              -- set default
              -- set null
              -- cascade
)engine=InnoDB default charset=latin1;


--! ALTER
alter table Paziente
add column nome_col integer not null default 0 after Citta;
    -- drop coloumn
    -- drop primary key
    -- add primary key
    -- add unique
update Paziente P
set VisiteMutuate = 0;

--==================================================================================

--! stored procedure
drop procedure if exists nome_proc;
delimiter $$
create procedure nome_proc(
	in _var1 int,
    inout var2 int ,
    out var3_ varchar(8)
)

begin
	set var2 = var2 + _var1;	-- restituisce comunque la somma in var2
		
    -- versione con IF	
    if var2%2 = 0 then
		set var3_ = 'pari';
    else
		set var3_ = 'dispari';
    end if;
    
    -- versione con CASE
    case 
		when var2 % 2 = 0 then set var3_ = 'pari';
        when var2 % 2 = 0 then set var3_ = 'dispari';
    end case;
end $$

delimiter ;

--! functions
drop function if exists nome_fun;
delimiter $$
create function nome_fun(
	_var1 int,		-- sono ingressi (implicito)
    _var2 int
)
returns int deterministic

begin
	declare ret int default 0;

	set ret = _var1 + _var2;
    return ret;
end $$

delimiter ;


------------------------------------------------------
--! trigger
drop trigger if exists nome_trigger;
delimiter $$
create trigger nome_trigger
before /*[after]*/ insert/*[update|delete]*/ on nome_tab for each row 
begin
    -- [...] ;
    signal sqlstate '45000'
    set message_text = 'Limite massimo visite mutuate!';
end $$
delimiter;


--! event
-- singolo              [eseguito una volta sola]
create event nome_event
on schedule at current_timestamp()
do
	update nome_tab T
    set T.qualcosa = 'qualcosasltro';

-- recurring            [eseguito ogni giorno alla data ora]
create event nome_event
on schedule every 1 day         -- every lo rende recurring
starts 'yyyy-mm-dd hh:mm:ss'
-- [ends] ...
do 
    update Paziente P
    set VisiteMutuate = (...)
-- [on completion preserve]     -- viene preservato dopo l'esecuzione, quindi rischedulato
-- NB: set event_scheduler = ON;

--==================================================================================

--! utilizzo cursori
--dentro proc
    -- [...]
begin
	-- var di appoggio
	declare finito int default 0;
    declare valore int default 0;
    
    -- cursore
    declare nome_cur cursor for
		select var_da_prendere					-- tabella su cui scorre il cursore
        from nome_tab;
    
    -- handler
    declare continue handler for not found		-- se finisce modifica 'finito'
		set finito = 1;
        
	-- ciclo fetch
    open nome_cur;
    ciclo: loop
		fetch nome_cur into valore;				-- devono essere dello stesso tipo!
        
		if finito = 1 then
			leave ciclo;
		end if;
        
        -- faccio cose con 'valore'

    end loop ciclo;
    close nome_cur;
end $$

--! handler per gestione errori
-- dentro una proc
    -- [...]
    
    declare esito integer default 0;		-- per controllo errori
    
    declare exit handler for sqlexception	-- in caso di errori gravi riporta 
    begin                                   -- tutto a stato precedente
		rollback;
        set esito = 1;
        select 'Si è verificato un errore!';
    end;

    -- [...]

--==================================================================================


--! cte
with NomeCTE as (
    select *
    from -- [...]

)

--! view
create or replace view nome_view as 
    select *
    from [...]
;

--! temporary table
create temporary table if not exists nome_tab(
    var1 int,
    var2 varchar(100),
    
    primary key (var1),
    unique(var2),             -- chiave candidata

    constraint nome_vincolo foreign key (var1)
    references nome_tab2(chiave_tab2)
    on update no action
              -- set default
              -- set null
              -- cascade
)engine=InnoDB default charset=latin1;


--! materialized view 
-- è a tutti gli effetti una tabella
drop table if exists nome_MV;
create table if not exists nome_MV(
    var1 int,
    var2 varchar(100),
    
    primary key (var1),
    unique(var2),             -- chiave candidata

    constraint nome_vincolo foreign key (var1)
    references nome_tab2(chiave_tab2)
    on update no action
              -- set default
              -- set null
              -- cascade
)engine=InnoDB default charset=latin1;

insert into nome_MV
select ...
    -- si possono anche utilizzare view (NON CTE???)

--==================================================================================
-- Ad una certa aggiornano la MV a partire dai RawData: ci sono tre modi per farlo che sono
--     - deferred => event
--     - on demand => procedure
--     - immediate => trigger: è l'unico a mantenere la MV in sync con i Raw Data

--! on-demand refresh (full)
drop procedure if exists full_refresh
delimiter $$
create procedure full_refresh()
begin

    --* nell nuove slide non c'è questa parte
    -- declare esito integer default 0;		-- per controllo errori    
    -- declare exit handler for sqlexception	-- in caso di errori gravi riporta 
    -- begin                                   -- tutto a stato precedente
	-- 	rollback;
    --     set esito = 1;
    --     select 'Si è verificato un errore!';
    -- end;

    -- droppiamo la tabella e la rifacciamo (flushing)
    truncate table nome_MV;

    -- full refresh
    insert into nome_MV
    select *
        -- [...]    è come ripopolare la tabella

end $$
delimiter ;


--! deferred refresh (full)
drop event if exists deferred_refresh
delimiter $$
create event deferred_refresh
on schedule every 1 month
starts '2020-10-10 23:00:00'
do
begin
    call full_refresh();    -- chiama la proc del full refresh
end $$
delimiter ;

--! immediate refresh (sync)
drop trigger if exists immediate_refresh;
delimiter $$
create trigger immediate_refresh
after insert nome_MV for each row
begin

    -- declare var [...]

    update nome_MV
    set [...]
nome_tab
end $$
delimiter;

------------------------------------------------------
--!INCREMENTAL REFRESH
-- La MV non viene aggiornata del tutto, ma solo la parte non aggiornata, per fare questo
-- è necessario il LOG, che memorizza le modifiche sui Raw Data
--     - partial => aggiorna usando solo parte del LOG 
--     - complete => aggiorna usando tutto il LOG
--     - rebuild => distrugge e ricostruisce


-- Il LOG contiene informazioni utili per poter aggiornare la MV: utilizzando solo dati già
-- presenti nella MV e nel LOG

--todo:
--* PROGETTAZIONE LOG TABLE:
    -- 1. 

--! LOG TABLE
create table nomeMV_log(
    istante timestamp not null default current_timestamp,   -- serve sempre per incremental refresh
    nomevar1 char(50) not null,
    nomevar2 int not null,
    -- [...]

    primary key (istante)
)engine=InnoDB default charset=latin1;

--! trigger di push
delimiter $$
drop trigger if exists nome_triggerPush $$
create trigger nome_triggerPush
after insert/*[update|delete]*/ on nome_tab for each row 
begin
    declare [...];

    insert into nomeMV_log values(
        current_timestamp,      
        new.nomevar1,
        new.nomevar2,
        -- [...]
    )

end $$
delimiter;


--! incremental refresh
drop procedure if exists incremental_refresh
delimiter $$
create procedure incremental_refresh(
    in metodo varchar(255),         -- viene passato il metodo (rebuild/complete/partial)
    in istante_soglia timestamp,
    out esito integer    
)
begin
    if metodo = 'rebuild' then
        begin
            call full_refresh()    -- chiama la proc che fa full refresh

            --* ci potrebbe esser bisogno di un esito del full refresh => full_refresh(@es)
            -- if @es = 1 then         -- controlla che sia tutto OK
            --     set esito = 1;
            -- end if;
        
        end;

    elseif metodo = 'complete' or metodo = 'partial' then
        begin
            replace into nome_MV
            select [...] -- come è fatta la MV
            from (
                select *
                from nomeMV_log N1 inner join Medico M on N1.Medico = M.Matricola
                where Istante <= if(metodo = 'complete', current_timestamp, istante_soglia)
                    -- [...]
            )

            if(metodo = 'complete') then
                truncate table nomeMV_log
            else
                delete from nomeMV_log
                    where Istante <= istante_soglia
            end if;
            
        end;
end $$
delimiter;


--todo
--! partial refresh 
delimiter $$
drop procedure if exists on_demand_refresh_MV $$
create procedure on_demand_refresh_MV(_fino_a date)
begin

    with aggr_LOG as (...)

end $$
delimiter ;


--==================================================================================



