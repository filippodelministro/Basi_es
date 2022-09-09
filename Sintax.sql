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

--fix: non funziona cosi
--! CREATE      
drop table if exists nome_tab;
create table if not exists nome_tab(
    nomevar1 int,
    nomevar2 varchar(100)   
    
    primary key (nomevar1)
    unique(...)             -- chiave candidata

    constraint nome_vincolo foreign key (nomevar1)
    references nome_tab2(chiave_tab2)
    on update no action;
        
)engine=InnoDB default charset=latin1;


--! ALTER
alter table Paziente
add column nome_col integer not null default 0;
    -- drop coloumn
    -- drop primary key
    -- add primary key
    -- add unique
update Paziente P
set VisiteMutuate = (...)

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
end $$
delimiter;


--! event
-- singolo
create event nome_event
-- on schedule at on schedule at current_timestamp()
on schedule every 6 month
starts current_timestamp 
do
	update nome_tab T
    set T.qualcosa = 'qualcosasltro';

-- [on completion preserve] 

-- recurring
create event nome_event
on schedule every 1 day         -- every lo rende recurring
starts 'yyyy-mm-dd hh:mm:ss'
-- [ends] ...
do 
    update Paziente P
    set VisiteMutuate = (...)
-- [on completion preserve] 
-- NB: set event_scheduler = ON;

--==================================================================================

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
    nomevar1 int,
    nomevar2 varchar(100)
    
    primary key (nomevar1)
)engine=InnoDB default charset=latin1;


--! materialized view 
-- è a tutti gli effetti una tabella
drop table if exists nome_mv;
create table if not exists nome_mv(
    nomevar1 int,
    nomevar2 varchar(100)   
    
    primary key (nomevar1)
    unique(...)             -- chiave candidata        
)engine=InnoDB default charset=latin1;

insert into nome_mv
select ...
    -- si possono anche utilizzare view (NON CTE???)

--==================================================================================

--! full refresh (on-demand)
drop procedure if exists refresh_MV
delimiter $$
create procedure refresh_MV (out esito integer)
begin

    declare esito integer default 0;		-- per controllo errori    
    declare exit handler for sqlexception	-- in caso di errori gravi riporta 
    begin                                   -- tutto a stato precedente
		rollback;
        set esito = 1;
        select 'Si è verificato un errore!';
    end;

    -- droppiamo la tabella e la rifacciamo (flushing)
    truncate table nome_mv;

    -- full refresh
    insert into nome_mv
    select *
        -- [...]

end $$
delimiter ;

--! full refresh (immediate)
drop trigger if exists nome_trigger;
delimiter $$
create trigger nome_trigger
after insert nome_tab for each row
begin

    -- [...]

end $$
delimiter;


--todo: 
--! full refresh (deferred)
------------------------------------------------------

--! LOG TABLE
create table nomeMV_log(
    istante timestamp not null default current_timestamp,
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
        NEW.nomevar1,
        NEW.nomevar2,
        -- [...]
    )

end $$
delimiter;


--! incremental refresh
drop procedure if exists incremental_refresh
delimiter $$
create procedure incremental_refresh(
    in metodo varchar(255),
    in istante_soglia timestamp,
    out esito integer    
)
begin
    if metodo = 'rebuild' then
        begin
            call refresh_MV(@es)    -- chiama la proc che fa full refresh

            if @es = 1 then         -- controlla che sia tutto OK
                set esito = 1;
            end if;
        end;

    elseif metodo = 'complete' or metoto = 'partial' then
        begin
            replace into nome_mv
            select *
            from (
                select *
                from nomeMV_log N1 inner join Medico M on N1.Medico = M.Matricola

            )
        end;
end $$
delimiter;


