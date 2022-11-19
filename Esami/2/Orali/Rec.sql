
--? paz che hanno contratto almeno due pat di Stomaco negli ultimi due anni restituire per ogni 
--? città di provenienza il paz con esordio più lungo (durata) in caso di parimerito restituire
--? exaequo

with
PazTarget as (
	select E.Paziente
    from Esordio E inner join Patologia PA on E.Patologia = PA.Nome
    where PA.ParteCorpo = 'Stomaco'
		-- and E.DataEsordio > current_date() - interval 2 year
    group by E.Paziente
    having count(distinct E.Patologia) > 1
),
Durate as (
	select E.Paziente, P.Citta, datediff(E.DataGuarigione, E.DataEsordio) as Durata
	from Esordio E inner join Patologia PA on E.Patologia = PA.Nome
				   inner join Paziente P on E.Paziente = P.CodFiscale
	where PA.ParteCorpo = 'Stomaco'
		-- and E.DataEsordio > current_date() - interval 2 year
		and E.Paziente in (select Paziente from PazTarget)
		and E.DataGuarigione is not null
)


select D2.Citta, D2.Paziente
from Durate D2 inner join (
	select DD.Citta, max(MaxDurata) as MaxDurataCitta
	from Durate D1 inner join (
		select D.Paziente, D.Citta, max(D.Durata) as MaxDurata
		from (select * from Durate) as D
		group by D.Paziente
	) as DD on D1.Citta = DD.Citta
	group by DD.Citta
) as DDD on D2.Citta = DDD.Citta
		  and D2.Durata = DDD.MaxDurataCitta



--? prendere tutti i paz di Pisa visitati almeno una volta nel mese di Gennaio del 2010;
--? eseguire con non-correlated subquery e correlated subquery

    -- correlated al posto delle non correlated: è sempre fattibile
    -- non correlated al posto delle correlated: non sempre è fattibile: quando c'è un riferimento 
    --    alla current-row per il calcolo di qualcosa (max, min ecc.)


-- correlated
select *
from Paziente P
where P.Citta = 'Pisa'
	and exists (
	select *
    from Visita V
    where V.Paziente = P.CodFiscale
		and month(V.Data) = 3
        and year(V.Data) = 2010
);

-- non correlated
select *
from Paziente P
where P.Citta = 'Pisa'
	and P.CodFiscale in (
		select V.Paziente
        from Visita V
		where month(V.Data) = 3
        and year(V.Data) = 2010
    );


--? tutte le visite degli ultimi 10 anni, e vogliamo, per ciascuna, il numero
--? medio di giorni consdierando la visita precedernte e successiva della
--? stessa specializzazione

select DD.Data, avg(DD.DistanzaGiorni) as MediaDistanza
from (
	select D.Data, datediff(D.VisitaSucc, D.VisitaPrec) as DistanzaGiorni
	from (
		select V.*,
			lead(V.Data, 1) over(partition by M.Specializzazione) as VisitaPrec,
			lag(V.Data, 1) over(partition by M.Specializzazione) as VisitaSucc
		from Visita V inner join Medico M on V.Medico = M.Matricola
		where V.Data > current_date() - interval 10 year
	) as D
	where D.VisitaPrec is not null
		and D.VisitaSucc is not null
	) as DD
group by DD.Data


--? Il numero di medici per ogni spec che abbia visitato tutti i pazienti della stessa città



-- =====================================================================================

/*
--? Quanti modi esistono per risolvere una query per la DIVISIONE?
    - Doppio not exists
    - Group by e having count = a tot


--? Posso usare indistintamente le correlated e non correlated subquery?
    correlated al posto delle non correlated: è sempre fattibile
    non correlated al posto delle correlated: non sempre è fattibile: quando c'è un riferimento 
       alla current-row per il calcolo di qualcosa (max, min ecc.)
*/


