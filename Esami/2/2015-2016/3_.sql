--? Scrivere una query che restituisca, se esiste, la città dalla quale proviene il maggior 
--? numero di pazienti che hanno contratto l’acufene un numero di volte maggiore o uguale a
--? quello degli altri pazienti della loro città.

with 
EsordiTarget as (
	select P.Citta, E.Paziente, count(*) as NumEsordi
	from Esordio E inner join Paziente P on E.Paziente = P.CodFiscale
	where E.Patologia = 'Dolore'
	group by P.Citta, E.Paziente
),
EsordiCitta as (
	select ET1.Citta, count(*) as CasiTarget
	from EsordiTarget ET1 inner join EsordiTarget ET2 on ET1.Citta = ET2.Citta
	where ET1.Paziente <> ET2.Paziente
		and ET1.NumEsordi >= ET2.NumEsordi
	group by ET1.Citta
)

select *
from EsordiCitta EC
where EC.CasiTarget >= (
	select max(CasiTarget)
    from EsordiCitta
)

