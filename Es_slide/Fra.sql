
--?Indicare la matricola dei medici che hanno effettuato più del 20% delle visite annue
--?della loro specializzazione in almeno due anni fra il 2010 e il 2020.
--?[Suggerimento: nel select, è possibile inserire espressioni (quindi si possono usare +,-,*,/).
--?Per esempio, se voglio restituire il reddito annuale di tutti i pazienti della clinica, posso scrivere:
--?SELECT P.Reddito*12 FROM Paziente P;

with
--numero di visite per specializzazione anno per anno
VisiteSpec as (
		select M.Specializzazione, year(V.Data) as Anno, count(*) as NumVisiteSpec
		from Visita V inner join Medico M on V.Medico = M.Matricola
		group by M.Specializzazione, year(V.Data)
),
--numero di visite per medico anno per anno, proietto anche la Specializzazione
--per poter fare join
VisiteMed as (
		select V.Medico, M.Specializzazione, year(V.Data) as Anno, count(*) as NumVisiteMed
		from Visita V inner join Medico M on V.Medico = M.Matricola
		group by V.Medico, year(V.Data)
)

select VM.Medico
from VisiteSpec VS inner join VisiteMed VM on VS.Specializzazione = VM.Specializzazione and VS.Anno = VM.Anno
where VS.Anno between 2010 and 2020
	and VM.NumVisiteMed > 0.2 * VS.NumVisiteSpec
group by VM.Medico
having count(distinct VM.Anno) > 1


--?Fra tutte le città da cui provengono più di tre pazienti con reddito superiore a 1000 
--?Euro, indicare quelle da cui provengono almeno due pazienti che sono stati visitati 
--?più di una volta al mese, nel corso degli ultimi 10 anni.

with
--impongo condizione sul reddito
CittaTarget1 as (
		select P.Citta
		from Paziente P
		where P.Reddito > 1000
		group by P.Citta
		having count(*) > 3
),
--impongo condizione sul numero di visite
CittaTarget2 as (
		select year(V.Data) as Anno, month(V.Data) as Mese, V.Paziente, count(*) as NumVisite, P.Citta
		from Visita V inner join Paziente P on V.Paziente = P.CodFiscale
		where V.Data > current_date() - interval 10 year
		group by year(V.Data), month(V.Data), V.Paziente
		having count(*) > 1
)

select Citta
from CittaTarget1 natural join CittaTarget2     --join su Citta che tanto hanno entrambe le tab


--?Indicare nome e cognome dei pazienti visitati almeno una volta da tutti 
--?i cardiologi di Pisa nel primo trimestre del 2015
select V.Paziente, P.Nome, P.Cognome
from Visita V inner join Paziente P on V.Paziente = P.CodFiscale
			  inner join Medico M on V.Medico = M.Matricola
where month(V.Data) < 4
    and year(V.Data) = 2015
    and M.Citta = 'Pisa'
    and M.Specializzazione = 'Cardiologia'
group by V.Paziente
having count(distinct V.Medico) = (
	select count(*)
	from Medico M
	where M.Citta = 'Pisa'
		and M.Specializzazione = 'Cardiologia'
)
