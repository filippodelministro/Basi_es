--? Considerate le patologie gastroenteriche, scrivere una query che restituisca il nome 
--? commerciale dei farmaci utilizzati da almeno un paziente in almeno due terapie relative
--? alla stessa patologia, e il numero di tali pazienti per ciascuno di tali farmaci.
select D.Farmaco, count(distinct D.Paziente) as NumPaziente
from (
	select T.Paziente, T.Patologia, T.Farmaco
	from Terapia T inner join Patologia PA on T.Patologia = PA.Nome
	where PA.SettoreMedico = 'Gastroenterologia'
	group by T.Paziente, T.Patologia, T.Farmaco
	having count(distinct T.DataInizioTerapia) > 1
) as D
group by D.Farmaco


--? Implementare una business rule che consenta l’inserimento di una visita mutuata relativa a
--? un settore medico solamente se il paziente non è attualmente in terapia con un farmaco
--? indicato per patologie dello stesso settore medico e le sue visite mutuate effettuate
--? con medici specialisti di quel settore medico, dall’inizio dell’anno, non superino del 
--? 20% le visite non mutuate.
drop trigger if exists trig;
delimiter $$
create trigger trig
before insert on Visita for each row
begin
	declare terapieInCorso int default 0;
	declare visiteNonMutSpec int default 0;
    declare visiteMutSpec int default 0;
    declare settoreMed char(50) default null;
    
    if (new.Mututata = 1) then
		set settoreMed = (			-- trovo settore medico
			select M.Specializzazione
			from Medico M
			where M.Matricola = new.Medico
		);
		set terapieInCorso = (		-- deve essere 0
			select count(*)
			from Terapia T
			where T.Paziente = new.Paziente
				and T.DataFineTerapia is null
				and T.Farmaco in (
					select I.Farmaco
					from Patologia PA inner join Indicazione I on PA.Nome = I.Patologia
					where PA.SettoreMedico = settoreMed
				)
		);
		set visiteNonMutSpec = (
			select count(*) 
			from Visita V inner join Medico M on V.Medico = M.Matricola
			where year(V.Data) = year(new.Data)
				and V.Mutuata = 0
				and M.Specializzazione = settoreMed
		);
		set visiteMutSpec = (
			select count(*) 
			from Visita V inner join Medico M on V.Medico = M.Matricola
			where year(V.Data) = year(new.Data)
				and V.Mutuata = 1
				and M.Specializzazione = settoreMed
		);

		if (terapieInCorso <> 0 or (visiteMutSpec >= visiteNonMutSpec * 0.2)) then
				signal sqlstate '45000'
				set message_text = 'Impossibile inserimento visita';
		end if;
	end if;
end $$
delimiter ;


--? Implementare una stored procedure healthy_patients_in_period() che, ricevute in ingresso due
--? date _from e _to, restituisca, come result set, il codice fiscale dei pazienti che nel lasso 
--? di tempo compreso fra le due date risultavano sani, ovverosia, non avevano patologie in 
--? essere. Inoltre, per ogni paziente del risultato, la stored procedure deve restituire 
--? da quanto tempo (in giorni) il paziente risultava sano prima di _from e per quanto tempo 
--? (in giorni) lo è stato dopo _to. Si presti attenzione al fatto che in generale gli
--? esordi possono sovrapporsi temporalmente e che quindi, in un dato istante, un paziente
--? può essere affetto da più patologie. Si gestiscano i contesti di errore dovuti a input 
--? non validi, interrompendo forzatamente l’elaborazione.
drop procedure if exists healthy_patients_in_period;
delimiter $$
create procedure healthy_patients_in_period(
	in _from date,
    in _to date
)
begin   
	if (_from > _to) then
		signal sqlstate '45000'
        set message_text = 'ATTENZIONE: Valori di ingresso non validi';
    end if;
 
    with
    GiorniSalutePrima as (
		select D.Paziente, datediff(_from, UltimoEsordio) as GiorniSalutePrima
		from (
			select E.Paziente, max(E.DataEsordio) as UltimoEsordio
			from Esordio E
			where E.DataEsordio < _from
			group by E.Paziente
		) as D
    ),
    GiorniSaluteDopo as (
		select D.Paziente, datediff(PrimoEsordio, _to) as GiorniSaluteDopo
		from (
			select E.Paziente, min(E.DataEsordio) as PrimoEsordio
			from Esordio E
			where E.DataEsordio > _to
			group by E.Paziente
		) as D
    )

	select P.CodFiscale,
		ifnull(GSP.GiorniSalutePrima, null) as GiorniSalutePrima, 
		ifnull(GSD.GiorniSaluteDopo, null) as GiorniSaluteDopo
    from Paziente P left outer join GiorniSalutePrima GSP on P.CodFiscale = GSP.Paziente
					left outer join GiorniSaluteDopo GSD on P.CodFiscale = GSD.Paziente
    where P.CodFiscale not in (
		select distinct E.Paziente
		from Esordio E
		where (E.DataEsordio between _from and _to)
            or (E.DataGuarigione between _from and _to)
            or (E.DataEsordio < _from and E.DataGuarigione > _to)
            or (E.DataEsordio < _from and E.DataGuarigione is null)
    );
	
end $$
delimiter ;

call Clinica.healthy_patients_in_period('2010-01-01', '2013-01-01');

