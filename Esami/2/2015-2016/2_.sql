--? Scrivere una query che restituisca le patologie curate sempre con il farmaco 
--? meno costoso fra tutti quelli indicati. Se, data una patologia, esiste più di un 
--? farmaco meno costoso, questi possono essere stati usati intercambiabilmente.
with
Costi as (
	select I.Patologia, min(F.Costo)  as CostoMin
	from Indicazione I inner join Farmaco F on I.Farmaco = F.NomeCommerciale
	group by I.Patologia
)

select T.Patologia
from Terapia T inner join Farmaco F on T.Farmaco = F.NomeCommerciale
			   inner join Costi C on C.Patologia = T.Patologia
								  and C.CostoMin = F.Costo
group by T.Patologia
having count(*) = (
		select count(*)
        from Terapia T2
        where T2.Patologia = T.Patologia
)


--? Modificare la tabella ESORDIO aggiungendo un attributo EsordiPrecedenti contenente
--? il numero di esordi precedenti di patologie dello stesso paziente relative allo
--? stesso settore medico, curati con successo. L’attributo EsordiPrecenti deve essere
--? aggiornato ogni cinque giorni, a partire dal 1° Luglio 2015 alle ore 6:00 del 
--? mattino. Implementare l’incremental full refresh dell’attributo EsordiPrecedenti 
--? scrivendo: 
--?     i) il codice di gestione della log table; 
--?     ii) il recurring event che realizza la funzionalità di refresh.

-- LOG delle guarigioni: salva le modifiche per poter fare refresh: le modifiche 
-- si aggiornano con il trigger sotto!
create table Log_Guarigioni (
	Paziente char(50) not null,
    Patologia char(50) not null,
    DataEsordio date not null,
    primary key(Paziente, Patologia, DataEsordio)
);

drop trigger if exists push_log;	
delimiter $$
create trigger push_log
after update on Esordio for each row
begin
	if(new.DataGuarigione is not null and old.DataGuarigione is null) then
		insert into LogGuarigioni values (
			new.Paziente,
            new.Patologia,
            new.DataEsordio
        );
	end if;
end $$

-- evento che aggiorni gli Esordi: scorro il log e per ogni paziente che trovo nel LOG
-- incremento il numero di EsordiPrecedenti per il relativo SettoreMedico
drop event if exists AggiornamentoEsordi $$
create event AggiornamentoEsordi 
on schedule every 5 day
starts '2015-07-01 06:00:00'    
do
begin
	declare _paziente char(50) default null;
    declare _patologia char(50) default null;
    declare _dataEsordio date default null;
    declare _settoreMedico char(50) default null;
    declare finito int default 0;
    
    declare guarigioni cursor for	-- scorre il LOG
		select *
		from Log_Guarigioni LG
		order by LG.Paziente, LG.Patologia, LG.DataEsordio;

	declare continue handler for not found
		set finito = 1;

	open guarigioni;
    
    scan: loop
		fetch guarigioni into _paziente, _patologia, _dataEsordio;
        
        if finito = 1 then
			leave scan;
        end if;
		
        set _settoreMedico = (  -- calcolo il SettoreMedico a partire dalla patologia
			select SettoreMedico
            from Patologia
            where Nome = _patologia
        );

        -- modifico la tabella Esordio        
        update Esordio E inner join Patologia PA on E.Patologia = PA.Nome
        set EsordiPrecedenti = EsordiPrecedenti + 1
        where E.Paziente = _paziente
			and PA.SettoreMedico = _settoreMedico
            and E.DataEsordio > _dataEsordio;	-- esordi da aggiornare

    end loop scan;
    
    close guarigioni;
	truncate Log_Guarigioni;	-- elimina perchè è full refresh
end $$
delimiter ;


--? Considerati i soli pazienti di Pisa e Roma attualmente affetti da al più tre patologie
--? gastroenterologiche croniche, ognuno di essi visitato, negli ultimi venti anni,
--? almeno tre volte da un gastroenterologo di città diversa dalla sua, scrivere una
--? query che restituisca il numero di tali pazienti che, dopo essersi fatti visitare, 
--? negli anni, da almeno un altro gastroenterologo, hanno effettuato l’ultima visita
--? nuovamente dal gastroenterologo iniziale, trascorso un tempo inferiore a sei mesi
--? dalla prima visita.

with
PazTarget as (
	select *
	from Paziente P
	where (P.Citta = 'Pisa' or P.Citta = 'Roma') 
		and P.CodFiscale not in (	-- affetti al più da 3 Pat gastro in forma cronica 
		select E.Paziente
		from Esordio E inner join Patologia PA on E.Patologia = PA.Nome
		where PA.SettoreMedico = 'Gastroenterologia'
			and E.Cronica  = 'si'
			and E.DataGuarigione is null
		group by E.Paziente
		having count(distinct E.Patologia) > 3
	)
		and P.CodFiscale in (		-- e visitati tre volte da Gastroent. diversi di diversa città
			select V.Paziente
			from Visita V inner join Medico M on V.Medico = M.Matricola
			where M.Citta <> P.Citta
				and M.Specializzazione = 'Gastroenterologia'
				and V.Data > current_date() - interval 20 year
			group by V.Paziente
			having count(distinct V.Data) > 3
		)
),
Gastro as (
	select *
    from Medico M
    where M.Specializzazione = 'Gastroenterologia'
),
PrimeVisite as (
	select V1.*
	from Visita V1 inner join Gastro G on V1.Medico = G.Matricola
				   inner join (
		select V.Paziente, min(V.Data) as PrimaData
		from Visita V inner join Gastro G on V.Medico = G.Matricola
		where V.Paziente in (
				select CodFiscale
				from PazTarget
		)
		group by V.Paziente
	) D on V1.Paziente = D.Paziente
		and V1.Data = D.PrimaData
),
UltimeVisite as (
	select V1.*
	from Visita V1 inner join Gastro G on V1.Medico = G.Matricola
				   inner join (
		select V.Paziente, max(V.Data) as PrimaData
		from Visita V inner join Gastro G on V.Medico = G.Matricola
		where V.Paziente in (
				select CodFiscale
				from PazTarget
		)
		group by V.Paziente
	) D on V1.Paziente = D.Paziente
		and V1.Data = D.PrimaData
)

select count(*) as NumPazientiTarget
from PrimeVisite PV inner join UltimeVisite UV on PV.Paziente = UV.Paziente
											   and PV.Medico = UV.Medico
where datediff(UV.Data, PV.Data) < 30*6		-- hanno ultima visita entro i 6 mesi dalla prima visita