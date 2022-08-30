
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


--?Selezionare nome e cognome dei medici la cui parcella è superiore 
--?alla media delle parcelle della loro specializzazione e che, 
--?nell'anno 2011, hanno visitato almeno un paziente che non avevano 
--?mai visitato prima


with 
MediaParcSpec as (
		select M.Specializzazione, avg(M.Parcella) as Media
		from Medico M inner join Visita V on M.Matricola = V.Medico
		group by M.Specializzazione
),
MediciTarget1 as (
		select M.Matricola
		from Medico M inner join MediaParcSpec MPS on M.Specializzazione = MPS. Specializzazione 
												  and M.Parcella > MPS.Media  
),
--conta tutti i paziente, 2011 escluso
NumPazPrima as (
		select V.Medico, count(distinct V.Paziente) as NumPaz
		from Visita V
		where year(V.Data) < 2011
		group by V.Medico
),
--conta tutti i paziente, 2011 compreso
NumPazDopo as (
		select V.Medico, count(distinct V.Paziente) as NumPaz
		from Visita V
		where year(V.Data) <= 2011
		group by V.Medico
),
MediciTarget2 as (
		select NPP.Medico
		from NumPazPrima NPP inner join NumPazDopo NPD on NPP.Medico = NPD.Medico
													   and NPD.NumPaz > NPP.NumPaz
)

select M.Nome, M.Cognome
from MediciTarget1 MT1 inner join MediciTarget2 MT2 on MT1.Matricola = MT2.Medico
					   inner join Medico M on MT2.Medico = M.Matricola



--?scrivere una query che restituisca nome e cognome del medico che, 
--?al 31/12/2014, aveva visitato un numero di pazienti superiore a quelli 
--?visitati da ciascun medico della sua specializzazione
-- numero di pazienti per ogni medico: salvo anche la spec per fare join dopo (nel periodo target)
with VisiteMed as (
		select V.Medico, M.Specializzazione, count(distinct V.Paziente) as NumPaz
		from Medico M inner join Visita V on M.Matricola = V.Medico
		where year(V.Data) < 2015
		group by V.Medico
)
-- per ogni spec, proietto i medici che hanno un NumPaz maggiore di tutti i medici della stessa spec
select VM1.Medico, M.Nome, M.Cognome, M.Specializzazione, VM1.NumPaz
from VisiteMed VM1 inner join Medico M on VM1.Medico = M.Matricola
group by VM1.Medico, VM1.Specializzazione, VM1.NumPaz
having VM1.NumPaz > ALL(
		select VM.NumPaz 
		from VisiteMed VM
		where VM.Specializzazione = VM1.Specializzazione
			and VM.Medico <> VM1.Medico
)

--?Scrivere una query che restituisca il codice fiscale dei pazienti che 
--?sono stati visitati sempre dal medico avente la parcella più alta, in 
--?tutte le specializzazioni. Se, anche per una sola specializzazione, non 
--?vi è un unico medico avente la parcella più alta, la query non deve 
--?restituire alcun risultato.

with MediciCostosi as (
		select D.Specializzazione, D.Matricola
        from (
				select M1.Matricola, M1.Specializzazione, M1.Parcella
				from Medico M1
				group by M1.Matricola, M1.Specializzazione, M1.Parcella
				having M1.Parcella >= ALL (		-- parcella più alta per ogni spec
						select Parcella M
						from Medico M
						where M.Specializzazione = M1.Specializzazione
				)
        ) as D
        group by D.Specializzazione, D.Matricola, D.Parcella
        having count(distinct D.Matricola) = 1	-- si può avere al massimo un medico con 
												-- parcella più alta per ogni spec
)

select D.Paziente
from Paziente P inner join (
		select V.Paziente, M.Specializzazione
		from Visita V inner join Medico M on M.Matricola = V.Medico
		where V.Paziente NOT IN (	-- escludo pazienti che hanno visite con medici NON target
				select distinct V.Paziente
				from Visita V left outer join MediciCostosi MC on V.Medico = MC.Matricola
				where MC.Matricola is null
		)
		group by V.Paziente, M.Specializzazione
		having count(distinct M.Specializzazione) = (				-- ogni paziente deve avere una visita con 
				select count(distinct M1.Specializzazione)			-- almeno un medico per ogni spec
				from Medico M1
		)
) as D on P.CodFiscale = D.Paziente


--*==================================================================================
--*								ES PIÙ COMPLESSI										
--*==================================================================================
--? Al termine di Febbraio 2015, come ogni anno, le parcelle dei medici della
--? clinica saranno aggiornate. La percentuale di aumento della parcella è pari alle
--? percentuale di terapie prescritte dal medico nel 2014 che hanno condotto il 
--? paziente alla guarigione, rispetto a tutte le terapie da egli/ella prescritte
--? nello stesso anno. Assumere che il medico che prescrive una terapia a un paziente
--? sia il medico, la cui specializzazione è uguale al settore medico della patologia
--? oggetto della terapia, dal quale il paziente è stato visitato da meno tempo prima 
--? dell'inizio della terapia stessa. Scrivere una stored procedure aggiorna_parcelle 
--? che prenda come argomento un anno (in questo caso il 2014) e aggiorni, come descritto,
--? la parcella di tutti i medici



--? Scrivere una stored procedure report_spese che riceve in ingresso 3 parametri:
--? il codice fiscale di un paziente i, il nome di un settore medico s e un parametro
--? booleano (tinyint) ssn. La stored procedure deve restiturire la spesa totale e
--? media giornaliera sostenuta attualmente dal paziente p per le terapie