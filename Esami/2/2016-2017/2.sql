--? Considerati i farmaci indicati per patologie di più settori medici, scrivere una query che 
--? restituisca il principio attivo di quelli impiegati, nell’ultimo semestre, solo per 
--? patologie di uno di tali settori medici, da non meno di tre pazienti, nel complesso.
with
FarmaciTarget as (
	select I.Farmaco
	from Indicazione I inner join Patologia PA on I.Patologia = PA.Nome
	group by I.Farmaco
	having count(distinct PA.SettoreMedico) > 1
)

select F.PrincipioAttivo
from Terapia T inner join Farmaco F on T.Farmaco = F.NomeCommerciale
where T.Farmaco in (select Farmaco from FarmaciTarget)
	and T.DataInizioTerapia > current_date() - interval 6 month
group by F.PrincipioAttivo
having count(distinct T.Paziente) > 2


--? Scrivere una stored function dose_therapy() che, ricevuto il codice fiscale di un paziente 
--? e una data di riferimento come parametri, restituisca: –1 se il paziente ha sempre assunto,
--? nelle sue terapie, i farmaci con posologia uguale al dosaggio consigliato nelle indicazioni,
--? a partire dalla data di riferimento; 0 se ci sono state eccezioni in misura non superiore
--? al 20% delle terapie, a partire dalla data di riferimento; 1 se il paziente ha sempre
--? utilizzato i farmaci con posologia superiore rispetto al dosaggio indicato, a partire
--? dalla data di riferimento. Nei rimanenti casi, non d’interesse, la function restituisce NULL.
drop function if exists dose_therapy;
delimiter $$
create function dose_therapy(
	_paziente char(50),
    _data date
)
returns int deterministic
begin
    declare visiteTot int default 0;
    declare visiteDiverse int default 0;
    
    set visiteDiverse = (
		select if(I.DoseGiornaliera <> T.Posologia, visiteDiverse + 1, visiteDiverse)
        from Terapia T inner join Indicazione I on T.Patologia = I.Patologia
												and T.Farmaco = I.Farmaco
        where T.Paziente = _paziente
			and T.DataInizioTerapia > _data
    );
    set visiteTot = (
		select count(*)
        from Terapia T inner join Indicazione I on T.Patologia = I.Patologia
												and T.Farmaco = I.Farmaco
        where T.Paziente = _paziente
			and T.DataInizioTerapia > _data
    );
    
	if visiteDiverse = 0 then
		return -1;
	elseif visiteDiverse > 0.2 * visiteTot then
		return 0;
	elseif visiteDiverse = visiteTot then
		return 1;
    end if;
    
    return null;
end $$
delimiter ;




--? Fra tutte le patologie a carico del fegato che comportano un’invalidità superiore al 
--? 70%, scrivere una query che indichi, qualora esista, quella patologia che, nel triennio 
--? 2013-2016, è stata curata con il più alto numero di principi attivi considerando, 
--? complessivamente, i pazienti di Milano, Roma e Napoli, ambosessi, di età superiore a cinquant’anni
--? che hanno contratto almeno una di tali patologie nello stesso triennio e che, prima dell’esordio
--? della prima di esse, non avevano mai contratto patologie epatiche, ad esclusione dell’ittero
--? fisiologico. Relativamente alla patologia sopra descritta, se esiste, la query deve anche indicare,
--? nello stesso record, la durata media delle terapie per principio attivo (considerando anche 
--? quelle attualmente in corso) per i pazienti di sesso maschile e per i pazienti di sesso
--? femminile, nonché la spesa totale in merito a ciascun principio attivo.
with
PatologieTarget as (
	select PA.Nome
	from Patologia PA
	where PA.Invalidita > 70 
		and PA.ParteCorpo = 'Fegato'
),
PazientiTarget as (
	select E.Paziente
    from Esordio E inner join Paziente P on E.Paziente = P.CodFiscale
    where (P.Citta = 'Roma' or P.Citta = 'Milano' or P.Citta = 'Napoli')
		and P.DataNascita < current_date() - interval 50 year
		and not exists (			-- nessuna patologia epatica precedente
			select *
            from Esordio E1
            where E1.Paziente = E.Paziente
				and E1.DataEsordio < E.DataEsordio
                and E.Patologia in (	
					select PA.Nome
                    from Patologia PA
                    where PA.SettoreMedico = 'Epatologia'
                )
        )
        or exists (					-- fatta esclusione per Ittero
			select *
            from Esordio E1
            where E1.Paziente = E.Paziente
				and E1.DataEsordio < E.DataEsordio
                and E1.Patologia = 'Ittero fisiologico'
        )
        and E.Patologia in (select Nome from PatologieTarget)
        and year(E.DataEsordio) between 2013 and 2016
),
TabTarget as (
	select T.Patologia, count(distinct F.PrincipioAttivo) as NumPrincAtt
	from Terapia T inner join Farmaco F on T.Farmaco = F.NomeCommerciale
	where T.Patologia in (select * from PatologieTarget)
		and T.Paziente in (select * from PazientiTarget)
        and year(T.DataInizioTerapia) between 2013 and 2016
	group by T.Patologia
)


select T.Patologia, F.PrincipioAttivo, P.Sesso,
	avg(datediff(ifnull(T.DataFineTerapia, current_date), T.DataInizioTerapia)) as DurataMedia,
    sum(((floor(((datediff(ifnull(T.DataFineTerapia, current_date), T.DataInizioTerapia)) * T.Posologia) / F.Pezzi)) + 1) * F.Costo) as CostoTot
from TabTarget TT inner join Terapia T on T.Patologia = TT.Patologia
				  inner join Farmaco F on T.Farmaco = F.NomeCommerciale
                  inner join Paziente P on T.Paziente = P.CodFiscale
where TT.NumPrincAtt = (
	select max(NumPrincAtt)
	from TabTarget
)
group by T.Patologia, F.NomeCommerciale, P.Sesso