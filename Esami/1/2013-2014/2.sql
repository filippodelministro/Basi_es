--? Indicare il nome dei farmaci mai assunti prima dei venti anni d’età
select distinct T1.Farmaco
from Terapia T1
where T1.Farmaco not in (		-- escludo i farmaci assunti prima dei 20 anni
		select T.Farmaco
		from Terapia T inner join Paziente P on T.Paziente = P.CodFiscale
		where T.DataInizioTerapia < P.DataNascita + interval 20 year
)


--? Indicare nome e cognome dei pazienti che hanno curato sempre la stessa patologia con lo stesso
--? farmaco, per tutte le patologie contratte.
select distinct P.Nome, P.Cognome
from Terapia T1 inner join Paziente P on T1.Paziente = P.CodFiscale
where T1.Paziente not in (		-- escludo pazienti che hanno più farmaci fissata una patologia
		select D.Paziente
		from (
				select T.Paziente, T.Patologia
				from Terapia T inner join Paziente P on T.Paziente = P.CodFiscale
				group by T.Paziente, T.Patologia
				having count(distinct T.Farmaco) > 1
		) as D
)

--? Indicare nome e cognome dei medici che, con gli incassi delle visite del biennio 2009-2010, hanno
--? superato il reddito mensile medio dei pazienti visitati nello stesso periodo da tutti i medici.
with 
IncassoMedici as (
		select V.Medico, sum(M.Parcella) as Incasso
		from Medico M inner join Visita V on M.Matricola = V.Medico
		where year(V.Data) between 2009 and 2010
        group by V.Medico
),
RedditoMedio as (
		select avg(Reddito) as Reddito
		from Paziente P inner join Visita V on P.CodFiscale = V.Paziente
		where year(V.Data) between 2009 and 2010
)
select *
from IncassoMedici IM inner join RedditoMedio RM on IM.Incasso > RM.Reddito 
					  inner join Medico M on M.Matricola = IM.Medico
