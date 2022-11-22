--? Considerati i soli pazienti di Pisa e Firenze che hanno contratto al massimo una
--? patologia per settore medico (una o più volte), scrivere una query che, per ogni
--? paziente, restituisca il nome, il cognome, la città, il farmaco usato nel maggior
--? numero di terapie, considerando nel complesso le varie patologie, e la posologia
--? media. In caso di pari merito fra i farmaci usati da un paziente, completare il record
--? con valori NULL. 
with Utilizzi as (
	select T.Paziente, T.Farmaco, count(*) as NumUtilizzi, avg(T.Posologia) as Media
	from Terapia T
	group by T.Paziente, T.Farmaco
)

select U1.*
from Utilizzi U1 inner join (
	select U.Paziente, max(U.NumUtilizzi) as MaxUtilizzi
	from Utilizzi U
	group by U.Paziente
) as D on U1.Paziente = D.Paziente
	   and U1.NumUtilizzi = D.MaxUtilizzi
where U1.Paziente in (		-- pazienti target
	select distinct E.Paziente
	from Esordio E inner join Patologia PA on E.Patologia = PA.Nome
				   inner join Paziente P on E.Paziente = P.CodFiscale
	where (P.Citta = 'Pisa' or P.Citta = 'Firenze')
	group by E.Paziente, PA.SettoreMedico
	having count(distinct E.Patologia)
)


--? Considerate le terapie dei pazienti aventi reddito inferiore al reddito medio della loro
--? città, scrivere una query che, per ciascun paziente target, restituisca il codice fiscale, il
--? cognome, e la durata media delle terapie (oggi terminate) in cui, se avesse assunto il
--? farmaco più economico basato sullo stesso principio attivo del farmaco
--? effettivamente assunto, avrebbe ottenuto un risparmio sul costo totale della terapia
--? superiore al 50%, e a quanto sarebbe ammontato tale risparmio.”

with
FarmaciCheap as (
	select I1.Farmaco as FarmacoCheap, I1.Patologia, F1.Costo, F1.Pezzi
	from Indicazione I1 inner join Farmaco F1 on I1.Farmaco = F1.NomeCommerciale inner join (
		select I.Patologia, min(F.Costo) as CostoMinimo
		from Indicazione I inner join Farmaco F on I.Farmaco = F.NomeCommerciale
		group by I.Patologia
	) as D on I1.Patologia = D.Patologia
		   and F1.Costo = D.CostoMinimo
),
DuarataTerapia as (
	select T.Paziente, avg(datediff(T.DataFineTerapia, T.DataInizioTerapia)) as MediaDurata
	from Terapia T
	where T.DataFineTerapia is not null
	group by T.Paziente
)


select D.Paziente, D.Cognome, D.MediaDurata, D.CostoEff - D.CostoIp as Risparmio
from (
	select T.Paziente, P.Cognome, DT.MediaDurata,
			(floor(datediff(T.DataFineTerapia, T.DataInizioTerapia) * T.Posologia / F.Pezzi) + 1) * F.Costo as CostoEff,
			(floor(datediff(T.DataFineTerapia, T.DataInizioTerapia) * T.Posologia / FC.Pezzi) + 1) * FC.Costo as CostoIp
	from Terapia T inner join Farmaco F on T.Farmaco = F.NomeCommerciale
				   inner join FarmaciCheap FC on T.Patologia = FC.Patologia
				   inner join Paziente P on T.Paziente = P.CodFiscale
                   inner join DuarataTerapia DT on T.Paziente = DT.Paziente
	where T.Paziente in ( -- pazienti target
		select D.CodFiscale as Paziente
		from (
			select *, avg(P.Reddito) over (partition by P.Citta) as RedditoCitta
			from Paziente P
		) as D
	where D.Reddito < D.RedditoCitta
	)
		and T.DataFineTerapia is not null
		and T.Farmaco <> FC.FarmacoCheap
) as D
where D.CostoIp < 0.5 * D.CostoEff



--? Implementare una stored procedure che, presa in ingresso una data d e una città di
--? provenienza dei pazienti c, consideri i pazienti della città c e stampi una classifica
--? delle patologie, dove una patologia è in posizione tanto più alta quanto più è basso,
--? in media fra i pazienti di città c, il numero di giorni impiegati per guarire da tutte
--? le patologie (oggi concluse) dalle quali i pazienti di città c erano affetti in data d.
drop procedure if exists rank_patologie;
delimiter $$
create procedure rank_patologie(
	in dataSoglia date,
    in citta char(50)
)
begin
    select D.Patologia, rank() over(order by D.MediaDurata) as Classifica
	from (
		select E.Patologia, avg(datediff(E.DataGuarigione, E.DataEsordio)) as MediaDurata
		from Esordio E inner join Paziente P on E.Paziente = P.CodFiscale
		where E.DataEsordio < dataSoglia
			and E.DataGuarigione > dataSoglia
			and P.Citta = citta
		group by E.Patologia
	) as D;

end $$
delimiter ;

call rank_patologie('2000-01-01', 'Pisa')


--? Creare una materialized view SpesaVisite che, per ogni paziente visitato da almeno un
--? medico di tutte le città, in almeno due specializzazioni, contenga il nome e cognome
--? del paziente, il numero totale di medici da cui è stato visitato, e la spesa complessiva
--? sostenuta per tali visite. Se mutuate, le visite hanno un costo di 38 Euro. Popolare 
--? la materialized view e scrivere il codice per mantenerla in sync con i raw data.
drop table if exists SpesaVisite;
create table SpesaVisite(
	Nome char(50),
    Cognome char(50),
    NumMedici int,
    Spesa double
)engine=InnoDB default charset = latin1;

insert into SpesaVisite
select P.Nome, P.Cognome, count(distinct V.Medico) as NumMedici, sum(if(V.Mutuata = 1, 38, M.Parcella)) as Spesa
from Visita V inner join Medico M on V.Medico = M.Matricola
			  inner join Paziente P on V.Paziente = P.CodFiscale
group by V.Paziente
having count(distinct M.Specializzazione) > 1 
	and count(distinct M.Citta) = (
		select count(distinct M1.Citta)
		from Medico M1
	);

drop trigger if exists update_SpesaVisite;
delimiter $$
create trigger update_SpesaVisite
after insert on Visita for each row
begin
	declare parcella int default 0;
    set parcella = (
		select if(V.Mutuata = 1, 38, M.Parcella)
        from Visita V inner join Medico M on V.Medico = M.Matricola
        where M.Matricola = new.Medico
			and V.Data = new.Data
    );
    
	update SpesaVisite SV1 inner join (
		select P.Nome, P.Cognome
        from Visita V inner join Paziente P on P.CodFiscale = V.Paziente
		where V.Paziente = new.Paziente
    ) as D on SV1.Nome = D.Nome
		   and SV1.Cognome = D.Cognome
	set SV1.Spesa = SV1.Spesa + parcella;

end $$
delimiter ;


--? Scrivere una stored procedure che sposti, in una tabella di archivio con stesso schema
--? di Esordio, gli esordi di patologie gastriche conclusi con guarigione, relativi a pazienti
--? che non hanno contratto, precedentemente all'esordio, patologie gastriche, ma che ne
--? hanno curate con successo almeno due successivamente.

drop table if exists ArchivioEsordio;
create table ArchivioEsordio(
	Paziente char(50),
    Patologia char(50),
    DataEsordio date,
    DataGuarigione date,
    Gravita int,
    Cronica char(50),
    EsordiPrecedenti int
)Engine=InnoDB default charset = latin1;

-- drop procedure update_ArchivioEsordio;			-- sposta i record target da Esordio a ArchvioEsordio
delimiter $$
create procedure update_ArchivioEsordio()
begin
	insert into ArchivioEsordio
	select E.*
	from Esordio E inner join Patologia PA on E.Patologia = PA.Nome
	where PA.SettoreMedico = 'Gastroenterologia'
		and E.DataGuarigione is not null
		and not exists (		-- non esistono Esordi gastrici precedenti
			select *
			from Esordio E1 inner join Patologia PA1 on E1.Patologia = PA1.Nome
			where PA1.SettoreMedico = 'Gastroenterologia'
				and E1.DataEsordio < E.DataEsordio
				and E1.Paziente = E.Paziente
		)
		and exists (		-- Esistono 2 esordi gastrici guariti
			select *
			from Esordio E2 inner join Patologia PA2 on E2.Patologia = PA2.Nome
			where PA2.SettoreMedico = 'Gastroenterologia'
				and E2.DataEsordio > E.DataEsordio
				and E2.Paziente = E.Paziente
				and E2.DataGuarigione is not null
				and exists (
					select *
					from Esordio E3 inner join Patologia PA3 on E3.Patologia = PA3.Nome
					where PA3.SettoreMedico = 'Gastroenterologia'
						and E3.DataEsordio > E.DataEsordio
						and E3.Paziente = E.Paziente
						and E3.DataGuarigione is not null
				)
		);

	delete E1.*
	from Esordio E1 left outer join (
		select *
		from ArchivioEsordio 
	) as D on E1.Paziente = D.Paziente
		   and E1.Patologia = D.Patologia
		   and E1.DataEsordio = D.DataEsordio
	where D.Paziente is not null;
end $$

-- primo build
call update_ArchivioEsordio();

-- ogni volta che si aggiorna Esordio si controlla se ci sono record
-- target nuovi, e nel caso si aggiorna l'archvio 
-- drop trigger if exists trigger_update_ArchivioEsordio;	
create trigger trigger_update_ArchivioEsordio
after update on Esordio for each row 
begin
	call update_ArchivioEsordio();
end $$
delimiter ;



