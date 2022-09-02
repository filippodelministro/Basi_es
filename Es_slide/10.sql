Argomenti:
    - Funzione if()
    - Funzione ifnull()
    - Costrutto case
    - Materializd view
        · on demand refresh
        · immediate refresh
        · deferred refresh

--*==================================================================================
--*									ES SLIDE										
--*==================================================================================


--? Per ciascun otorinolaringoiatra, indicarne la matricola e il numero di visite mutuate e
--? non mutuate
select V.Medico, sum(if(V.Mutuata = 1, 1, 0)) as Mutuate, sum(if(V.Mutuata = 0, 1, 0)) as NonMutuate
from Visita V inner join Medico M on V.Medico = M.Matricola
where M.Specializzazione = 'Otorinolaringoiatria'
group by V.Medico


--? Per ciascun otorinolaringoiatra, indicarne la matricola e un attributo contenente L se il
--? numero di visite dell’anno corrente è inferiore a 5, oppure M se è superiore (o uguale) a
--? 5 ma inferiore (o uguale) a 10, oppure H se è superiore a 10.
select V.Medico, case 
						when count(*) < 5 then 'L'
                        when count(*) between 5 and 10 then 'M'
                        when count(*) > 10 then 'H'
				 end as Indice
from Visita V inner join Medico M on V.Medico = M.Matricola
where M.Specializzazione = 'Otorinolaringoiatria'
	and year(V.Data) = year(current_date())
group by V.Medico


--? Per ciascun otorinolaringoiatra, nessuno escluso, indicarne la matricola, il numero di
--? visite effettuate nell’anno in corso e un attributo pari alla matricola se il medico ha
--? effettuato almeno una visita nell’anno in corso, altrimenti pari a -1.
select M.Matricola, count(*), ifnull(D.Matricola, -1)
from Medico M left outer join (
		select *
        from Visita V inner join Medico M1 on V.Medico = M1.Matricola
        where M1.Specializzazione = 'Otorinolaringoiatria'
			and year(V.Data) = 2011
) as D on D.Medico = M.Matricola
where M.Specializzazione = 'Otorinolaringoiatria'
group by M.Matricola


--? Per ogni paziente nessuno escluso, indicarne il nome, il cognome e il
--? numero di volte che è stato visitato dal dottor Amaranti.
select P.CodFiscale, if(count(*) = 1 -- questo sarà per tutti i paz ì 1 perchè si raggruppa per P.CodFiscale: controllo che non
									 -- non faccia join con D
					and D.Paziente is null, 0, count(*)) as NumVisite
from Paziente P left outer join (
		select *
        from Visita V inner join Medico M on V.Medico = M.Matricola
        where M.Cognome = 'Amaranti'
)as D on P.CodFiscale = D.Paziente
group by P.CodFiscale

--? Creare una materialized view MV_RESOCONTO avente funzione di reporting,
--? contenente, per ogni specializzazione medica della clinica, il numero di visite
--? effettuate, il numero di pazienti visitati, l’incasso totale relativo al mese in corso, e la
--? matricola del medico che ha visitato più pazienti.
--? Implementare l’on demand refresh, l’immediate refresh e il deferred refresh.