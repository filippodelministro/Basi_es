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



Negli ultimi mesi, la direzione della clinica è interessata al fenomeno della resistenza alle terapie per la pa-
tologia influenzale. I pazienti target sono gli anziani aventi più di ottanta anni, affetti da almeno due pato-
logie croniche. Dato un paziente target, interessano i suoi esordi di influenza degli ultimi tre anni. Conside-
rato un esordio i , sia T il numero di terapie effettuate per curarlo, e sia d ij la durata
� T della terapia j relativa
all’esordio i . La resistenza della patologia nell’esordio i è espressa da: r i = T 1 j=1 d ij . Supponendo che
gli esordi di influenza del paziente considerato siano E , se è r 1 < r 2 < · · · < r E , allora vi è una resistenza
ai farmaci per il trattamento dell’influenza, e il tasso di resistenza è quantificabile come
T DR = � E
r
2
i=1 (r i − r)
,
� E
dove r = E 1 i=1 r i . Scrivere una function per il calcolo del T DR , e il codice per il deferred full refresh
mensile di una materialized view contenente il codice fiscale di un paziente e il relativo T DR .



