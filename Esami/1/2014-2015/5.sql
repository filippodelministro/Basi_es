--? Scrivere una query che restituisca la parte del corpo maggiormente colpita da patologie 
--? con invalidità superiore al 70%. In caso di pari merito, restituire tutte le parti del
--? corpo.
select P.ParteCorpo, count(distinct P.Nome) as NumPat
from Patologia P
where P.Invalidita > 70
group by P.ParteCorpo
having count(distinct P.Nome) = (
	select max(D.NumPat) as MaxNumPat -- poi trovo il massimo
	from (	-- prima le conto
			select P.ParteCorpo, count(distinct P.Nome) as NumPat
			from Patologia P
			where P.Invalidita > 70
			group by P.ParteCorpo
	) as D 
)

--? Scrivere una query che restiuisca il numero di terapie iniziate da ciascun paziente in 
--? ogni mese dell’anno. Nel risultato devono comparire tutti i pazienti e tutti i mesi 
--? dell’anno.


--? Scrivere una query che restituisca, relativamente al mese di Giugno 2011, la percentuale 
--? d’incasso totale mensile dovuta alle visite nefrologiche.
--? Non si usino view, né derived table.
-- (ParcNefr / ParcTOT) * 100 
select sum(M.Parcella) / (
				select sum(M.Parcella)		-- parcella totale
				from Visita V inner join Medico M on V.Medico = M.Matricola
				where year(V.Data) = 2011 and month(V.Data) = 6
    ) * 100 as IncassoPerc
from Visita V inner join Medico M on V.Medico = M.Matricola
where M.Specializzazione = 'Nefrologia'	     -- parcella nefrologia
	and year(V.Data) = 2011
    and month(V.Data) = 6
    

--? Scrivere una stored procedure per l’inserimento di una nuova terapia. Nel caso in cui il 
--? paziente oggetto della terapia non abbia assunto in precedenza lo stesso principio attivo,
--? la terapia non deve essere inserita e deve essere restituito un messaggio di errore del
--? tipo: “Il paziente potrebbe essere allergico al principio attivo X”. Sostituire X con il
--? nome del principio attivo oggetto della terapia. La stored procedure non deve contenere
--? istruzioni di tipo CREATE.