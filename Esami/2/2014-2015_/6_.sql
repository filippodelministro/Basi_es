--? Scrivere una query che restituisca la dose giornaliera media dei farmaci
--? indicati per la cura di sole patologie intestinali.
select I.Farmaco, avg(I.DoseGiornaliera) as PosMedia
from Patologia PA inner join Indicazione I on PA.Nome = I.Patologia
where PA.ParteCorpo = 'Intestino'
	and I.Farmaco not in (
		select I.Farmaco
		from Patologia PA inner join Indicazione I on PA.Nome = I.Patologia
		where PA.ParteCorpo <> 'Intestino'
)
group by I.Farmaco

--? Scrivere una query che restituisca, per il sesso maschile e per quello
--? femminile, rispettivamente, il numero di pazienti attualmente affetti da
--? ipertensione, trattata con lo stesso farmaco da più di venti anni.
select P.Sesso, count(distinct P.CodFiscale) as NumPaz
from Esordio E inner join Paziente P on E.Paziente = P.CodFiscale
where E.Patologia = 'Ipertensione'
	and E.DataGuarigione is null
    and exists (
		select *
        from Terapia T
        where T.Paziente = E.Paziente
			and T.Patologia = E.Patologia
            and T.DataEsordio= E.DataEsordio
            and T.DataFineTerapia is null
            and T.DataInizioTerapia < current_date() - interval 20 year
    )
group by P.Sesso



--? Scrivere una query che, considerate le sole patologie muscolari, elimini gli
--? esordi conclusi con guarigione relativi a pazienti che hanno contratto, e
--? curato con successo, almeno due di tali patologie.
with
PatologieMuscolari as (
	select Nome
    from Patologia
    where ParteCorpo = 'Muscoli'
)

delete E2.*
from Esordio E2 natural join (	-- elimio tutti esordi che fanno join
	-- cioè tutti gli esordi di patologie muscolarui di Pazienti che
    -- hanno più di due guarigioni per le patologie muscolari
		select E.Paziente
		from Esordio E
		where E.Patologia in (select * from PatologieMuscolari)
			and E.DataGuarigione is not null
		group by E.Paziente
		having count(distinct E.Patologia) > 1
) as D
where E2.Patologia in (select * from PatologieMuscolari)
	and E2.DataGuarigione is not null

