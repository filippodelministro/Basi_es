--?Indicare nome e cognome dei pazienti che hanno contratto 
--?tutte le patologie.
select P.Nome, P.Cognome
from Paziente P inner join (
		select E.Paziente
		from Esordio E 
		group by E.Paziente
		having count(distinct E.Patologia) = (
				select count(*)
				from Patologia
		)
) as D on P.CodFiscale = D.Paziente

--?Indicare nome e cognome del paziente visitato più volte mentre 
--?era affetto da almeno una patologia. Se più pazienti rispettano 
--?la suddetta condizione, indicarli tutti
with VisiteMalati as (
		select V.Paziente, count(*) as NumVisite
		from Visita V inner join Esordio E on V.Paziente = E.Paziente
		where V.Data >= E.DataEsordio 
			and V.Data <= E.DataGuarigione
		group by V.Paziente
)

select P.Nome, P.Cognome
from VisiteMalati VM inner join Paziente P on VM.Paziente = P.CodFiscale
where VM.NumVisite >= ALL (
		select max(VM1.NumVisite)
        from VisiteMalati VM1
)

--?Indicare il nome delle patologie contratte esclusivamente dopo il compimento 
--?del sessantesimo anno di età.
-- bisogna fare join con Esordio per evitare le patologie che non sono mai state contratte
select P1.Nome
from Patologia P1 inner join Esordio E1 on P1.Nome = E1.Patologia 
where Nome not in (
		select distinct E.Patologia
		from Esordio E inner join Paziente P
		where E.DataEsordio < P.DataNascita + interval 60 year
)


--?Per ciascun settore medico, indicarne il nome e il costo totale dei farmaci 
--?oggetto di terapie effettuate nel triennio 2008-2010 per curare patologie contratte 
--?per la prima volta nello stesso periodo. Al costo dei farmaci sottrarre la 
--?percentuale di esenzione, ove prevista.
select D.SettoreMedico, sum(Costo) as CostoTot
from (
		select P.SettoreMedico, sum(F.Costo * ((F.Pezzi % T.Posologia) + 1)) as Costo
		from Patologia P inner join Terapia T on P.Nome = T.Patologia
						 inner join Farmaco F on F.NomeCommerciale = T.Farmaco
		where year(T.DataInizioTerapia) between 2008 and 2010
			and year(T.DataFineTerapia) between 2008 and 2010
			and T.Patologia in (		-- cond sulle patologie contratte per la prima volta nel triennio target
					select T1.Patologia
						from Terapia T1
						where T1.Patologia not in (	-- escludo tutte quelle contratte prima del 2008
								select T.Patologia
								from Terapia T
								where year(T.DataEsordio) < 2008
						)		
							and year(T.DataEsordio) < 2011
							and year(T.DataFineTerapia) < 2011
			)
		group by P.SettoreMedico, T.Posologia, F.NomeCommerciale 
) as D
group by D.SettoreMedico
