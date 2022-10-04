--? Indicare nome e cognome di ciascun medico che ha visitato tutti i pazienti
--? della sua città.
select M.Nome, M.Cognome
from Visita V inner join Medico M on V.Medico = M.Matricola
		      inner join Paziente P on V.Paziente = P.CodFiscale
where M.Citta = P.Citta
group by V.Medico, M.Citta
having count(distinct V.Paziente) = (
		select count(*)
        from Paziente P1
        where P1.Citta = M.Citta
)
              
--? Indicare nome e cognome dei pazienti che hanno avuto, anche solo per un 
--? giorno, più terapie in corso contemporaneamente.
select distinct P.Nome, P.Cognome
from Terapia T inner join Paziente P on T.Paziente = P.CodFiscale
where exists (	-- terapia iniziata dopo e finita dopo
		select *
        from Terapia T1
        where T1.Paziente = T.Paziente
			and T1.Farmaco <> T.Farmaco
            and T1.Patologia <> T.Patologia
			and T1.DataInizioTerapia > T.DataInizioTerapia
            and T1.DataFineTerapia > T.DataFineTerapia
)
or exists (		-- terapia iniziata dopo e finita prima
		select *
        from Terapia T1
        where T1.Paziente = T.Paziente
			and T1.Farmaco <> T.Farmaco
            and T1.Patologia <> T.Patologia
			and T1.DataInizioTerapia > T.DataInizioTerapia
            and T1.DataFineTerapia < T.DataFineTerapia
)
or exists (		-- terapia iniziata prima ma non finita
		select *
        from Terapia T1
        where T1.Paziente = T.Paziente
			and T1.Farmaco <> T.Farmaco
            and T1.Patologia <> T.Patologia
			and T1.DataInizioTerapia < T.DataInizioTerapia
            and T1.DataFineTerapia is null
)
or exists (		-- terapia iniziata prima e finita dopo
		select *
        from Terapia T1
        where T1.Paziente = T.Paziente
			and T1.Farmaco <> T.Farmaco
            and T1.Patologia <> T.Patologia
			and T1.DataInizioTerapia < T.DataInizioTerapia
            and T1.DataFineTerapia > T.DataFineTerapia
)
or exists (		-- terapia iniziata prima e finita dopo
		select *
        from Terapia T1
        where T1.Paziente = T.Paziente
			and T1.Farmaco <> T.Farmaco
            and T1.Patologia <> T.Patologia
			and T1.DataInizioTerapia < T.DataInizioTerapia
            and T1.DataFineTerapia > T.DataFineTerapia
)


--? Indicare il reddito massimo fra quelli di tutti i pazienti che, nell’
--? anno 2011, hanno effettuato esattamente tre visite, ognuna delle quali 
--? con un medico avente specializzazione diversa dagli altri.
select max(Reddito) as RedditoMax
from Paziente
where CodFiscale in (
		select V.Paziente
		from Visita V inner join Medico M on V.Medico = M.Matricola
		where year(V.Data) = 2011
		group by V.Paziente
		having count(distinct M.Specializzazione) = 3
			and count(distinct V.Data) = 3
)


--? Creare un vincolo di integrità generico (mediante un trigger) per impedire 
--? che un medico possa visitare mensilmente più di due volte lo stesso 
--? paziente, qualora all’atto delle due visite già effettuate in un dato 
--? mese dal medico sul paziente, quest’ultimo non fosse affetto da alcuna 
--? patologia.

drop trigger if exists trig;
delimiter $$
create trigger trig
before insert on Visita for each row
begin
	declare ok_visite bool default false;
    declare ok_esordio bool default false;
    
    if exists (
		select *
        from Visita V
        where V.Paziente = new.Paziente
			and V.Medico = new.Medico
            and year(V.Data) = year(current_date())
            and month(V.Data) = month(current_date())
            and exists (	-- esiste un altra Visita (stessi parametri) in data diversa
				select *
                from Visita V1
                where V1.Paziente = new.Paziente
					and V1.Medico = new.Medico
					and year(V1.Data) = year(current_date())
					and month(V1.Data) = month(current_date())
					and V1.Data <> V.Data
            )
    ) 
		then set ok_visite = true;
    end if;

	if exists (     -- esiste un Esordio
		select *
        from Esordio E
        where E.Paziente = new.Paziente
			and year(E.DataEsordio) = year(current_date())
            and month(E.DataEsordio) = month(current_date())
    ) 
        then set ok_esordio = true;
    end if;
    
    -- se esistono le visite, ma non l'Esordio, non posso inserire
    if (ok_visite = true and ok_esordio <> true) then
		signal sqlstate '45000'
        set message_text = 'Limite visite senza Esordi!';
    end if;
    
end $$
delimiter ;





--? Considerato ciascun farmaco per la cura di patologie gastroenterologiche,
--? indicato per più di una patologia, ma di fatto assunto per curare un’unica
--? patologia per oltre il 60% delle terapie basate su di esso iniziate negli 
--? ultimi cento anni, mantenere nella tabella INDICAZIONE la sola indicazione
--? del farmaco considerato riguardante tale unica patologia, eliminando 
--? tutte le altre.
with
FarmaciTarget as (
		select I.Farmaco
		from Patologia P inner join Indicazione I on P.Nome = I.Patologia
		where P.SettoreMedico = 'Gastroenterologia'
			and I.Farmaco in (	-- Farmaci usati per una sola Patologia
				select T.Farmaco
				from Patologia P inner join Terapia T on P.Nome = T.Patologia
				where P.SettoreMedico = 'Gastroenterologia'
				group by T.Farmaco
				having count(distinct T.Patologia) = 1
		)
		group by I.Farmaco
		having count(distinct I.Patologia) > 1	-- aventi Indicazione per più di una patologia
)

delete I1.*
from Indicazione I1 left outer join (
		select T.Farmaco, T.Patologia
		from Terapia T
		where T.Farmaco in (
			select *
			from FarmaciTarget
		)
		group by T.Farmaco, T.Patologia
) as D on I1.Farmaco = D.Farmaco
	   and I1.Patologia = D.Patologia
where I1.Patologia is null

