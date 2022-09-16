--? Considerati i soli pazienti di Pisa e Firenze che hanno contratto al massimo una
--? patologia per settore medico (una o più volte), scrivere una query che, per ogni
--? paziente, restituisca il nome, il cognome, la città, il farmaco usato nel maggior
--? numero di terapie, considerando nel complesso le varie patologie, e la posologia
--? media. In caso di pari merito fra i farmaci usati da un paziente, completare il record
--? con valori NULL. 
with
MaxUtilizzi as (
		select D.Paziente, max(D.NumUtilizzi) as Utilizzi
		from (
				select T.Paziente, T.Farmaco, count(*) as NumUtilizzi
				from Terapia T
				group by T.Paziente, T.Farmaco
		) as D
		group by D.Paziente
),
PazientiTarget as (
		select *
		from Paziente P
		where (P.Citta = 'Pisa' or P.Citta = 'Firenze')
			and P.CodFiscale not in (	-- escludo i paz che hanno più pat per Settore Medico
				select D.Paziente
				from (
						select E.Paziente, P.SettoreMedico
						from Esordio E inner join Patologia P on E.Patologia = P.Nome
						group by E.Paziente, P.SettoreMedico
						having count(distinct E.Patologia) > 1
				) as D
		)
)

select P.Nome, P.Cognome, P.Citta, T.Farmaco, count(*) as Utilizzi, avg(T.Posologia) as PosMedia
from Terapia T inner join Paziente P on T.Paziente = P.CodFiscale
where T.Paziente in (
		select PT.CodFiscale
		from PazientiTarget PT
)
group by T.Paziente, T.Farmaco
having count(*) >= (
		select Utilizzi
		from MaxUtilizzi
		where Paziente = T.Paziente
)


--? Considerate le terapie dei pazienti aventi reddito inferiore al reddito medio della loro
--? città, scrivere una query che, per ciascun paziente target, restituisca il codice fiscale, il
--? cognome, e la durata media delle terapie (oggi terminate) in cui, se avesse assunto il
--? farmaco più economico basato sullo stesso principio attivo del farmaco
--? effettivamente assunto, avrebbe ottenuto un risparmio sul costo totale della terapia
--? superiore al 50%, e a quanto sarebbe ammontato tale risparmio.”
with
PazientiTarget as (
		select P1.CodFiscale
		from Paziente P1
		where P1.Reddito < (
				select avg(P.Reddito) as RedditoMedio
				from Paziente P
				where P.Citta = P1.Citta
		)
), 
FarmaciCheap as (
		select F1.NomeCommerciale, F1.PrincipioAttivo, F1.Costo, F1.Pezzi
		from Farmaco F1 inner join (
				select F.PrincipioAttivo, min(F.Costo) CostoMinimo
				from Farmaco F
				group by F.PrincipioAttivo
		) as D on F1.PrincipioAttivo = D.PrincipioAttivo
		where F1.Costo = D.CostoMinimo
)

select D.Paziente, avg(datediff(D.DataFineTerapia, D.DataInizioTerapia)) as MediaDurata, sum(D.CostoEffettivo-D.CostoIpotetico) as Diff
from (
		select T.Paziente, T.DataInizioTerapia, T.DataFineTerapia, T.Posologia, /*F.Pezzi, FC.Pezzi F.Costo, FC.Costo,*/
				((floor(datediff(T.DataFineTerapia, T.DataInizioTerapia)*T.Posologia/F.Pezzi) + 1) * F.Costo) as CostoEffettivo,
				((floor(datediff(T.DataFineTerapia, T.DataInizioTerapia)*T.Posologia/FC.Pezzi) + 1) * FC.Costo) as CostoIpotetico
		from Terapia T inner join Farmaco F on T.Farmaco = F.NomeCommerciale
					   inner join FarmaciCheap FC on F.PrincipioAttivo = FC.PrincipioAttivo 
		where T.Paziente in (
				select CodFiscale
				from PazientiTarget
		)
			and T.DataFineTerapia is not null
			and
				((floor(datediff(T.DataFineTerapia, T.DataInizioTerapia)*T.Posologia/F.Pezzi) + 1) * F.Costo) /
				((floor(datediff(T.DataFineTerapia, T.DataInizioTerapia)*T.Posologia/FC.Pezzi) + 1) * FC.Costo) > 2
		) as D
group by D.Paziente


--? Implementare una stored procedure che, presa in ingresso una data d e una città di
--? provenienza dei pazienti c, consideri i pazienti della città c e stampi una classifica
--? delle patologie, dove una patologia è in posizione tanto più alta quanto più è basso,
--? in media fra i pazienti di città c, il numero di giorni impiegati per guarire da tutte
--? le patologie (oggi concluse) dalle quali i pazienti di città c erano affetti in data d.
drop procedure if exists proc;
delimiter $$
create procedure proc(
		in _citta varchar(50),
        in _data date
)
begin
		with
		PatologieTarget as (
				select E.Patologia
				from Esordio E inner join Paziente P on E.Paziente = P.CodFiscale
				where E.DataEsordio < _data
					and E.DataGuarigione > _data
					and P.Citta = _citta
		)

		select E.Patologia, rank () over (order by avg(datediff(E.DataGuarigione, E.DataEsordio))) as Posizione
		from Esordio E inner join PatologieTarget PT on E.Patologia = PT.Patologia
					   inner join Paziente P on E.Paziente = P.CodFiscale
		where E.DataGuarigione is not null
			and P.Citta = _citta
		group by E.Patologia;
end $$
delimiter ;


--? Creare una materialized view SpesaVisite che, per ogni paziente visitato da almeno un
--? medico di tutte le città, in almeno due specializzazioni, contenga il nome e cognome
--? del paziente, il numero totale di medici da cui è stato visitato, e la spesa complessiva
--? sostenuta per tali visite. Se mutuate, le visite hanno un costo di 38 Euro. Popolare 
--? la materialized view e scrivere il codice per mantenerla in sync con i raw data.


--? Scrivere una stored procedure che sposti, in una tabella di archivio con stesso schema
--? di Esordio, gli esordi di patologie gastriche conclusi con guarigione, relativi a pazienti
--? che non hanno contratto, precedentemente all'esordio, patologie gastriche, ma che ne
--? hanno curate con successo almeno due successivamente.