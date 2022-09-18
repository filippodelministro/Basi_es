--? Scrivere una query che restituisca le patologie gastriche che, in pazienti di età compresa
--? tra i 40 e 50 (entrambi compiuti), negli ultimi tre anni, si sono manifestate una o più
--? volte, ma solo d'estate.
select distinct E.Patologia
from Esordio E inner join Patologia PA on E.Patologia = PA.Nome
where PA.SettoreMedico = 'Gastroenterologia'
	and E.DataEsordio > current_date() - interval 3 year
    and E.Patologia not in (	-- non siano tra quelle che hanno esordi NON in estate
		select E.Patologia
		from Esordio E
		where month(E.DataEsordio) not in ('6','7','8')		--  condizione Estate
	)
	and E.Paziente in (			-- todo: condizione sui pazienti da fare
		select P.CodFiscale
        from Paziente	
    )




--? Implementare un analytic efficiente (tramite select statement con variabili user-defined) che,
--? dato un farmaco, ne restituisca il nome commerciale e il codice fiscale del primo paziente
--? che lo ha utilizzato