Argomenti:
    - Stored Procedure
    - Costrutto IF
    - Istruzioni iterative
        · while do
        · repeat .. until
        · loop (iterate, leave)
    - Cursori
    - Handler (continue, exit)
    - Stored function
    - concat()


--*==================================================================================
--*									ES SLIDE										
--*==================================================================================


--? Scrivere una stored procedure che stampi la parcella media di una
--? specializzazione specificata come parametro
drop procedure if exists parcella_media_spec;

delimiter $$
create procedure parcella_media_spec(in _specializzazione varchar(100))
begin
	select avg(M.Parcella) as ParcMedia
    from Medico M
    where M.Specializzazione = _specializzazione;
end $$
delimiter ;


--? Scrivere una stored procedure che restituisca il numero di pazienti
--? visitati da medici di una data specializzazione, ricevuta come parametro
drop procedure if exists proc2;

delimiter $$
create procedure proc2(
		in _specializzazione varchar(100),
		out num_pazienti_ int			
)
begin
	select count(distinct V.Paziente) into num_pazienti_
    from Medico M inner join Visita V on M.Matricola = V.Medico
    where M.Specializzazione = _specializzazione;
end $$
delimiter ;

-- chiamata
call proc2('Cardiologia', @tot);
select @tot;

--? Supporre di avere una variabile user-defined @data_backup_cardiologia
--? contenente la data in cui è stato effettuato il backup delle visite della cardiologia.
--? Scrivere una stored procedure che ricavi la data della visita più recente della cardiologia
--? e, se diversa da @data_backup_cardiologia, effettui il backup e aggiorni la variabile.
drop procedure if exists proc3;

delimiter $$
create procedure proc3(inout data_backup_cardiologia date)
begin

	select if(D.UltimaVisita <> data_backup_cardiologia, D.UltimaVisita, data_backup_cardiologia) into data_backup_cardiologia 
    from (
			select max(V.Data) as UltimaVisita
			from Visita V inner join Medico M on V.Medico = M.Matricola
			where M.Specializzazione = 'Cardiologia'
	) as D;

end $$
delimiter ;


--? Scrivere una stored procedure che restituisca la data in cui un paziente, il cui 
--? codice fiscale è passato come parametro, è stato visitato per la prima volta, e
--? il nome e cognome del medico che lo ha visitato in tale circostanza. In caso di 
--? più medici, per semplicità, selezionarne uno.
drop procedure if exists proc4;

delimiter $$
create procedure proc4(in _cod_fiscale varchar(100),
						out DataPrimaVisita date,
                        inout NomeMedico varchar(100),
                        inout CognomeMedico varchar(100)
)
begin

	select V1.Data, M.Nome, M.Cognome into DataPrimaVisita, NomeMedico, CognomeMedico
    from Visita V1 inner join Medico M on V1.Medico = M.Matricola
    where V1.Data = (
			select min(V.Data)
			from Visita V
			where V.Paziente = _cod_fiscale
    );
    
end $$
delimiter ;


--? Scrivere una stored procedure che riceve in ingresso un intero i
--? e stampa a video i primi i interi separati da virgola, in ordine crescente

--! sol con WHILE
drop procedure if exists proc1;

delimiter $$
create procedure proc1(in _num int)
begin
	declare s varchar(255) default '1';		-- 's' inizialmente è questo
    declare i int default 2;
    
    while i <= _num do	                -- lo fa per _num volte
		set s = concat(s, ', ', i);		-- ogni volta concatena a 's' qualcosa
		set i = i + 1;
	end while;
    select s;						    -- poi stampa s
end $$  

delimiter ; 

--! sol con WHILE
drop procedure if exists proc1;

delimiter $$
create procedure proc1(in _num int)
begin
	declare s varchar(255) default '1';		-- 's' inizialmente è questo
    declare i int default 2;
    
    repeat -- lo fa per _num volte
		set s = concat(s, ', ', i);		-- ogni volta concatena a 's' qualcosa
		set i = i + 1;
	until i > _num end repeat;
    select s;						-- poi stampa s
end $$

delimiter ; 

-- chiamata
call proc_while(6);

--? Scrivere una stored procedure che riceve in ingresso un intero i
--? e stampa a video i primi i interi dispari, separati da virgola

--? Scrivere una stored procedure che restituisca il codice fiscale dei pazienti
--? visitati da un solo medico per una data specializzazione, organizzati in una
--? stringa formattata del tipo “codFiscale1, codFiscale2, ... , codFiscaleN”
drop procedure if exists proc;

delimiter $$
create procedure proc(in specializzazione varchar(255),
					  out codFiscali varchar(255)
)
begin
	declare finito integer default 0;
    declare codFiscale varchar(255) default "";
    
    declare cursoreCod cursor for
		select V.Paziente
        from Visita V inner join Medico M on V.Medico = M.Matricola
        where M.Specializzazione = specializzazione
        group by V.Paziente
        having count(distinct V.Medico) = 1;
        
	declare continue handler for not found
		set finito = 1;

	set codFiscali = "";	-- minchie che skilla Goigochea
	open cursoreCod;
    
    preleva: loop
		fetch cursoreCod into codFiscale;
        if finito = 1 then
			leave preleva;
        end if;
        
        set codFiscali = concat(codFiscale, '-', codFiscali);
		
    end loop preleva;
    
    close cursoreCod;
end $$
delimiter ;

--? Scrivere una function che, preso in ingresso un numero di visite effettuate da un
--? medico, restituisca: ‘low’ se il numero di visite è inferiore a 20; ‘medium’ se il numero
--? di visite è compreso fra 20 e 50; ‘high’ se il numero di visite supera 50.
delimiter $$
drop function if exists rank_;

create function rank_(totVisite int)
returns varchar(6) deterministic
begin
	declare ranking varchar(6) default "0";
    
    case
		when totVisite < 20 then 
			set ranking = 'low';
		when totVisite between 20 and 50 then
			set ranking = 'medium';
		when totVisite > 50 then
			set ranking = 'high';
	end case;

    return ranking;
end $$
delimiter ;


--? Scrivere una stored procedure che restituisca la posizione in classifica nel mese in
--? corso di un medico, passato come parametro, sfruttando la function rank()