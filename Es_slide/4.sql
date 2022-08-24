
--*==================================================================================
--*									ES IN FONDO												
--*==================================================================================

--?Indicare incasso totale degli ultimi due anni, realizzato grazi alle visite dei medici cardiologi della clinica

--!Pistolesi
SELECT sum(M.Parcella) as TotIncassi
FROM Visita V inner join Medico M
	on V.Medico = M.Matricola
WHERE V.Data > date_sub(current_date(), interval 2 year)
	AND M.Specializzazione = 'Cardiologia'
    AND V.Mutuata = 0;

--*==================================================================================

--? Indicare il numero di pazienti di sesso femminile che, nel quindicesimo anno 
--? d’età, sono stati visitati, una o più volte, sempre dallo stesso ginecologo.

--!Pistolesi
SELECT count(distinct P.CodFiscale) as NumPazienti
FROM Visita V1 inner join Visita V2
	inner join Paziente P
		on V1.Paziente = P.CodFiscale
	inner join Medico M
		on V1.Medico = M.Matricola
WHERE P.Sesso = 'F'
	AND year(V1.Data) = year(P.DataNascita) + 15
    AND V1.Medico = V2.Medico
    AND V1.Paziente = V2.Paziente
    AND M.Specializzazione = 'Medicina Generale';


--!Pistolesi (meglio)
--cerco i pazienti che sono stati visitati da ginecologi nel 15simo anno di età
WITH visite_gin_15 as(					
	SELECT V.Paziente, V.Medico
    FROM Visita V inner join Medico M on V.Medico = M.Matricola
				  inner join Paziente P on V.Paziente = P.CodFiscale
    WHERE	P.Sesso = 'F'
			and M.Specializzazione = 'Ginecologia'
            and year(V.Data) = year(P.DataNascita) + 14
)

--prendo quelli che non sono stati visitati mai da più di un ginecologo
SELECT count(distinct VG1.Paziente)						
FROM visite_gin_15 VG1			
WHERE VG1.Paziente NOT IN (		            
            SELECT *
            FROM visite_gin_15 VG2
            WHERE VG2.Paziente = VG2.Paziente
            AND VG2.Medico <> VG1.Medico
);

--!Filippo
select count(distinct V.Paziente)
from Paziente P inner join Visita V on P.CodFiscale = V.Paziente
				inner join Medico M on M.Matricola = V.Medico
where P.Sesso = 'F'
	and M.Specializzazione = 'Medicina Generale'
    and V.Data > P.DataNascita + interval 14 year
    and V.Data < P.DataNascita + interval 16 year
group by V.Paziente
having count(*) >= 2;
    
--*==================================================================================
--? Indicare codice fiscale, nome e cognome ed età del paziente più anziano della
--? clinica, e il numero di medici dai quali è stato visitato.

--!Filippo
select distinct P1.CodFiscale, P1.Nome, P1.Cognome, year(current_date()) - year(P1.DataNascita) as Eta, count(distinct V.Medico) as NumMedici
from Paziente P1 inner join Visita V on P1.CodFiscale = V.Paziente
where P1.DataNascita = (
	select min(P.DataNascita)
	from Paziente P
)
group by V.Paziente     --senza questo non va il NumMedici!!


--*==================================================================================
--?Indicare nome e cognome dei pazienti che sono stati visitati non meno di due
--?volte da Rossi Mario.

--!Filippo
--Per ogni paziente voglio che ci siano almeno due visite con Mario Rossi
select P.Nome, P.Cognome
from Medico M inner join Visita V on M.Matricola = V.Medico
			  inner join Paziente P on P.CodFiscale = V.Paziente
where M.Nome = 'Mario'
	and M.Cognome = 'Rossi'
group by V.Paziente
having count(*) >= 2;

