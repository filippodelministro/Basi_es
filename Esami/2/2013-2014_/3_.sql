--? Considerato ciascun principio attivo, indicarne il nome e il costo medio 
--? al pezzo fra tutti i farmaci che lo contengono.
select F.PrincipioAttivo, avg(F.Costo/F.Pezzi) as CostoMedio
from Farmaco F
group by F.PrincipioAttivo

--? Indicare nome e cognome dei pazienti che hanno contratto almeno due volte 
--? tutte le patologie cuore.
with
PatCuore as (
		select Nome 
		from Patologia 
		where ParteCorpo = 'Cuore'
)

select P.Nome, P.Cognome
from Esordio E inner join PatCuore PC on E.Patologia = PC.Nome
			   inner join Paziente P on E.Paziente = P.CodFiscale
where exists (
	select *
    from Esordio E1
    where E1.Paziente = E.Paziente
		and E1.Patologia = E.Patologia
        and E1.DataEsordio <> E.DataEsordio
)
group by E.Paziente
having count(distinct E.Patologia) = (
	select count(*)
    from PatCuore
)


--? Indicare le patologie esordite esclusivamente in forma cronica, curate 
--? con il farmaco Lyrica.
select E.Patologia
from Esordio E inner join Terapia T on E.Patologia = T.Patologia
where E.Patologia not in (
	select Patologia
	from Esordio
	where Cronica = 'no'
)
	and T.Farmaco = 'Lyrica'


--? Scrivere un trigger che, in risposta all’aggiornamento della gravità di 
--? un esordio, elimini l’esordio stesso, e ne inserisca un altro caratterizzato
--? dalla nuova gravità, dalla data dell’aggiornamento come data di esordio, 
--? e dagli stessi valori dell’esordio eliminato per i restanti attributi.



--? Indicare la specializzazione medica che, considerate le visite effettuate
--? dai suoi medici dall’anno 2010 a oggi, ha totalizzato ogni anno un numero
--? di pazienti visitati per ciascuna città mai inferiore all’anno precedente.
with
TabTarget as (
		select year(V.Data) as Anno, M.Specializzazione, P.Citta, count(*) as NumVisite
		from Visita V inner join Medico M on V.Medico = M.Matricola
					  inner join Paziente P on V.Paziente = P.CodFiscale
		where year(V.Data) > 2009
		group by year(V.Data), M.Specializzazione, P.Citta
)

select distinct Specializzazione
from Medico
where Specializzazione not in (
		select distinct T1.Specializzazione
		from TabTarget T1 inner join TabTarget T2 on T1.Anno = T2.Anno - 1
												  and T1.Specializzazione = T2.Specializzazione
												  and T1.Citta = T2.Citta
		where T1.NumVisite > T2.NumVisite
)