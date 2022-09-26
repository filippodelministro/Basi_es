--?Indicare nome e cognome dei pazienti che hanno contratto 
--?tutte le patologie.
select P.Nome, P.Cognome
from Esordio E inner join Paziente P on E.Paziente = P.CodFiscale
group by E.Paziente
having count(distinct E.Patologia) = (
		select count(*)
        from Patologia P
)


--?Indicare nome e cognome del paziente visitato più volte mentre 
--?era affetto da almeno una patologia. Se più pazienti rispettano 
--?la suddetta condizione, indicarli tutti
with
VisiteMalati as (
		select E.Paziente, count(V.Data) as NumVisite
		from Esordio E inner join Visita V on E.Paziente = V.Paziente
		where (V.Data >= E.DataEsordio and V.Data < DataGuarigione)	-- guariti
			or
			(V.Data >= E.DataEsordio and E.DataGuarigione is null)	-- non guariti
		group by E.Paziente
)

select P.Nome, P.Cognome
from VisiteMalati VM inner join Paziente P on VM.Paziente = P.CodFiscale
where VM.NumVisite = (
		select max(NumVisite)
		from VisiteMalati
)


--?Indicare il nome delle patologie contratte esclusivamente dopo il compimento 
--?del sessantesimo anno di età.
with
MalattieEscludere as (
		select distinct E.Patologia
		from Paziente P inner join Esordio E on P.CodFiscale = E.Paziente
		where E.DataEsordio < P.DataNascita + interval 60 year
), 
MalattieIncludere as (
		select distinct E.Patologia
		from Paziente P inner join Esordio E on P.CodFiscale = E.Paziente
		where E.DataEsordio > P.DataNascita + interval 60 year
)

select Nome
from Patologia
where Nome not in (select * from MalattieEscludere)
	and Nome in (select * from MalattieIncludere)



--?Per ciascun settore medico, indicarne il nome e il costo totale dei farmaci 
--?oggetto di terapie effettuate nel triennio 2008-2010 per curare patologie contratte 
--?per la prima volta nello stesso periodo. Al costo dei farmaci sottrarre la 
--?percentuale di esenzione, ove prevista.

select P.SettoreMedico, 
		sum((floor((datediff(ifnull(T.DataFineTerapia, current_date()), T.DataInizioTerapia) * T.Posologia) / F.Pezzi) + 1) * F.Costo *(100 - P.PercEsenzione) / 100) as CostoTot
from TerapieTarget T inner join Farmaco F on T.Farmaco = F.NomeCommerciale
					 inner join Patologia P on T.Patologia= P.Nome
group by P.SettoreMedico