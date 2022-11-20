
--? paz che hanno contratto almeno due pat di Stomaco negli ultimi due anni restituire per ogni 
--? città di provenienza il paz con esordio più lungo (durata) in caso di parimerito restituire
--? exaequo

with
PazTarget as (
	select E.Paziente
    from Esordio E inner join Patologia PA on E.Patologia = PA.Nome
    where PA.ParteCorpo = 'Stomaco'
		-- and E.DataEsordio > current_date() - interval 2 year
    group by E.Paziente
    having count(distinct E.Patologia) > 1
),
Durate as (
	select E.Paziente, P.Citta, datediff(E.DataGuarigione, E.DataEsordio) as Durata
	from Esordio E inner join Patologia PA on E.Patologia = PA.Nome
				   inner join Paziente P on E.Paziente = P.CodFiscale
	where PA.ParteCorpo = 'Stomaco'
		-- and E.DataEsordio > current_date() - interval 2 year
		and E.Paziente in (select Paziente from PazTarget)
		and E.DataGuarigione is not null
)


select D2.Citta, D2.Paziente
from Durate D2 inner join (
	select DD.Citta, max(MaxDurata) as MaxDurataCitta
	from Durate D1 inner join (
		select D.Paziente, D.Citta, max(D.Durata) as MaxDurata
		from (select * from Durate) as D
		group by D.Paziente
	) as DD on D1.Citta = DD.Citta
	group by DD.Citta
) as DDD on D2.Citta = DDD.Citta
		  and D2.Durata = DDD.MaxDurataCitta



--? prendere tutti i paz di Pisa visitati almeno una volta nel mese di Gennaio del 2010;
--? eseguire con non-correlated subquery e correlated subquery

    -- correlated al posto delle non correlated: è sempre fattibile
    -- non correlated al posto delle correlated: non sempre è fattibile: quando c'è un riferimento 
    --    alla current-row per il calcolo di qualcosa (max, min ecc.)


-- correlated
select *
from Paziente P
where P.Citta = 'Pisa'
	and exists (
	select *
    from Visita V
    where V.Paziente = P.CodFiscale
		and month(V.Data) = 3
        and year(V.Data) = 2010
);

-- non correlated
select *
from Paziente P
where P.Citta = 'Pisa'
	and P.CodFiscale in (
		select V.Paziente
        from Visita V
		where month(V.Data) = 3
        and year(V.Data) = 2010
    );


--? tutte le visite degli ultimi 10 anni, e vogliamo, per ciascuna, il numero
--? medio di giorni consdierando la visita precedernte e successiva della
--? stessa specializzazione

select DD.Data, avg(DD.DistanzaGiorni) as MediaDistanza
from (
	select D.Data, datediff(D.VisitaSucc, D.VisitaPrec) as DistanzaGiorni
	from (
		select V.*,
			lead(V.Data, 1) over(partition by M.Specializzazione) as VisitaPrec,
			lag(V.Data, 1) over(partition by M.Specializzazione) as VisitaSucc
		from Visita V inner join Medico M on V.Medico = M.Matricola
		where V.Data > current_date() - interval 10 year
	) as D
	where D.VisitaPrec is not null
		and D.VisitaSucc is not null
	) as DD
group by DD.Data


--? Il numero di medici per ogni spec che abbia visitato tutti i pazienti della stessa città

--? Selezionare i pazienti di Pisa e Roma che nel primo trimestre del 2010 sono stati visitati
--? solo dal Verdi o solo dal Rossi, e dire quante sono le visite
select V1.Paziente, V1.Medico, D.NumVisite
from Visita V1 inner join (
	select V.Paziente, count(*) as NumVisite
	from Visita V
	where V.Paziente in (	-- pazienti di Roma o Pisa
		select P.CodFiscale
		from Paziente P 
		where P.Citta = 'Pisa' or P.Citta = 'Roma'
	)
	and V.Medico in (		-- medico Rossi o Verdi
		select M.Matricola
		from Medico M
		where M.Cognome = 'Rossi' or M.Cognome = 'Verdi'
	)
    and year(V.Data) = 2010
	and month(V.Data) < 4
	group by V.Paziente
	having count(distinct V.Medico) = 1
) as D on V1.Paziente = D.Paziente
	and year(V1.Data) = 2010
	and month(V1.Data) < 4


--? Quali sono i pazienti che in un anno degli ultimi dieci, hanno atteso al più tre mesi
--? prima di farsi visitare da un otorino dopo la precedente visita da un otorino (negli
--? ultimi dieci anni)with
Otorini as (
	select Matricola
    from Medico
    where Specializzazione = 'Otorinolaringoiatria'
),
VisiteOtorinoTarget as (
select *
from Visita V
where V.Medico in (select * from Otorini)
	and V.Data > current_date() - interval 10 year
)

select VO1.Paziente
from VisiteOtorinoTarget VO1 inner join VisiteOtorinoTarget VO2 on VO1.Paziente = VO2.Paziente
													and VO1.Data > VO2.Data
                                                    and year(VO1.Data) = year(VO2.Data)
where VO1.Data > VO2.Data + interval 3 month 


--? vincolo che permetta di inserire una visita mutuata solo se il paziente ha o ha avuto,
--? almeno un esordio del settoreMedico del medico del quale si sta inserendo una visita,
--? nell'ultimo mese
drop trigger if exists check_visita_mutuata;
delimiter $$
create trigger check_visita_mutuata
before insert on Visita for each row
begin
	declare settMedico char(50) default null;
    
    if(new.Mutuata = 1) then
		set settMedico = (		-- specializzazione del medico che sta inserendo visita
			select Specializzazione
			from Medico
			where Matricola = new.Medico
		);
		
		if not exists (				-- se non esiste Esordio interrompo l'inserimento
			select *
			from Esordio E inner join Patologia PA on E.Patologia = PA.Nome
			where PA.SettoreMedico = settMedico 
				and E.DataEsordio > current_date() - interval 1 month
				and E.Paziente = new.Paziente
		) then 
			signal sqlstate '45000'
				set message_text = 'check_visita_mutuata: impossibile inserire visita!';
		else 
			insert into Visita values (new.Medico, new.Paziente, new.Data, new.Mutuata);
        end if;
    end if;
end $$
delimiter ;



-- =====================================================================================

/*
--? Quanti modi esistono per risolvere una query per la DIVISIONE?
    - Doppio not exists
    - Group by e having count = a tot


--? Posso usare indistintamente le correlated e non correlated subquery?
    correlated al posto delle non correlated: è sempre fattibile
    non correlated al posto delle correlated: non sempre è fattibile: quando c'è un riferimento 
       alla current-row per il calcolo di qualcosa (max, min ecc.)


--? Se non avessimo l'having clause, potremmo comunque esprimere tutte le espressioni di SQL
--? oppure no?
    Si può fare ma è molto più complesso: la having clause serve appunto per semplificare la
    processazione


*/

