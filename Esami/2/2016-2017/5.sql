
--? Considerate tutte le città di provenienza dei pazienti, scrivere una query che restituisca
--? la patologia mediamente più contratta, fra tutte le città, da pazienti al di sotto dei 50
--? anni d’età. In caso di pari merito, restituire tutti gli ex aequo.
with PatologieTarget as (
	select distinct E.Patologia, count(*) over (partition by E.Patologia) as NumEsordi
	from Esordio E inner join Paziente P on E.Paziente = P.CodFiscale
	where P.Citta in (
		select distinct P.Citta
		from Paziente P
		where P.DataNascita > current_date() - interval 50 year
	)
)

select Patologia
from PatologieTarget
where NumEsordi = (
	select max(PT.NumEsordi)
	from PatologieTarget PT 
)

--? Implementare una analytic function efficiente (tramite un select statement con variabili
--? user-defined) che effettui il dense rank dei medici in base al totale di pazienti visitati,
--? da ognuno, nel quadriennio 2013-2016. Il result set deve contenere il dense rank value e 
--? la matricola del medico. Non si usino istruzioni CREATE. 
SELECT IF (
		@tot = D.Visite
          ,
          @rank := @rank
				+ LEAST(0, @tot := D.Visite)
          ,
          @rank := @rank + 1
				+ LEAST(0, @tot := D.Visite)
	) AS RankValue,
     D.Medico
     -- D.Visite
FROM (
		SELECT V.Medico, COUNT(*) AS Visite
		FROM Visita V
		WHERE YEAR(V.data) BETWEEN 2013 AND 2016
		GROUP BY V.Medico
		ORDER BY Visite DESC
	) AS D,
     (SELECT (@tot := 0 + LEAST(0, @rank := 0))) AS N;


--? Implementare una stored procedure all_drugs()che riceva in ingresso un principio attivo p e
--? un settore medico s, consideri i farmaci basati su p, e restituisca il numero totale di
--? pazienti che, per curare patologie del settore medico s, nel corso della vita li hanno
--? assunti tutti o tutti tranne quello in generale meno usato nelle terapie per patologie del
--? settore medico s. Il parametro OUT della stored procedure deve essere unico, contenente il
--? valore cumulativo dei pazienti sopra descritti.
drop procedure if exists all_drugs;
delimiter $$
create procedure all_drugs(
	in _princAtt char(50),
    in _settMedico char(50),
    out numPaz_ int
)
begin
	with
    FarmaciTarget as (
		select F.NomeCommerciale as Farmaco, count(*) as NumTerapie
		from Patologia PA inner join Indicazione I on PA.Nome = I.Patologia
						  inner join Farmaco F on I.Farmaco = F.NomeCommerciale
						  inner join Terapia T on T.Patologia = PA.Nome
											   and I.Farmaco = T.Farmaco
		where PA.SettoreMedico = _settMedico
			and F.PrincipioAttivo = _princAtt
		group by F.NomeCommerciale
	),
    FarmaciTargetUtilizzati as (
		select *
		from FarmaciTarget FT1
		where FT1.Farmaco not in ( 
			select FT.Farmaco
			from FarmaciTarget FT
			where FT.NumTerapie = (
				select min(NumTerapie)
				from FarmaciTarget
			)
		)
    )
    
	select count(*) into numPaz_
		from (
			select T.Paziente
			from Terapia T
			where T.Farmaco in (select Farmaco from FarmaciTargetUtilizzati)
			group by T.Paziente
			having count(distinct T.Farmaco) = (
				select count(*)
				from FarmaciTargetUtilizzati
			)
		) as D;


end $$
delimiter ;

set @a = 0;
call Clinica.all_drugs('Ketoprofene', 'Ortopedia', @a);

select @a
