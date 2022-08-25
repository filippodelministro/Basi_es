--? Considerato ciascun principio attivo, indicarne il nome e il costo medio 
--? al pezzo fra tutti i farmaci che lo contengono.
select F.PrincipioAttivo, avg(F.Pezzi / F.Costo) as CostoMedioPezzo
from Farmaco F
group by F.PrincipioAttivo



--? Indicare nome e cognome dei pazienti che hanno contratto almeno due volte 
--? tutte le patologie intestinali.
select E.Paziente
from Esordio E inner join Patologia P on E.Patologia = P.Nome
where P.ParteCorpo = 'Intestino'
	and exists (	-- cerco altri Esordi dello stesso paziente e stessa patologia, in data diversa
			select *
            from Esordio E1
            where E1.Patologia = E.Patologia
				and E1.Paziente = E.Paziente
                and E1.DataEsordio <> E.DataEsordio
    )
group by E.Paziente
having count(distinct E.Patologia) = (	-- aventi tutte le patologie dell'intestino
			select count(*)
			from Patologia 
			where ParteCorpo = 'Intestino'
)


--? Indicare le patologie esordite esclusivamente in forma cronica, curate 
--? con il farmaco Lyrica.
select T.Patologia
from Terapia T
where  T.Farmaco = 'Lyrica'
    and T.Patologia not in (
		select Patologia
		from Esordio
		where Cronica = 'no'
)
	


--todo: ======================================================================
--? Scrivere un trigger che, in risposta all’aggiornamento della gravità di 
--? un esordio, elimini l’esordio stesso, e ne inserisca un altro caratterizzato
--? dalla nuova gravità, dalla data dell’aggiornamento come data di esordio, 
--? e dagli stessi valori dell’esordio eliminato per i restanti attributi.
--todo: ======================================================================

--fix: ======================================================================
--? Indicare la specializzazione medica che, considerate le visite effettuate
--? dai suoi medici dall’anno 2010 a oggi, ha totalizzato ogni anno un numero
--? di pazienti visitati per ciascuna città mai inferiore all’anno precedente.
with 
VisiteACS as (
		select year(V.Data) as Anno, P.Citta, M.Specializzazione, count(*) as NumPaz
		from Paziente P inner join Visita V on P.CodFiscale = V.Paziente
						inner join Medico M on M.Matricola = V.Medico
		where year(V.Data) > 2009
		group by year(V.Data), P.Citta, M.Specializzazione
),
SpecNonMigliorate as (
		select V1.Specializzazione
		from VisiteACS V1 inner join VisiteACS V2 on V1.Citta = V2.Citta
												  and V1.Specializzazione = V2.Specializzazione
												  and V1.Anno = V2.Anno + 1
		where V1.NumPaz < V2.NumPaz
)

select distinct M.Specializzazione
from Visita V3 inner join Medico M on V3.Medico = M.Matricola
where M.Specializzazione not in (
		select *
        from SpecNonMigliorate
)
--fix: ======================================================================



