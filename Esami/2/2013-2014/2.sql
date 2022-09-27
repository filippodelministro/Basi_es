--? Indicare il nome dei farmaci mai assunti prima dei venti anni d’età
select NomeCommerciale
from Farmaco
where NomeCommerciale not in (
		select distinct T.Farmaco
		from Terapia T inner join Paziente P on T.Paziente = P.CodFiscale
		where T.DataInizioTerapia < P.DataNascita + interval 20 year
)


--? Indicare nome e cognome dei pazienti che hanno curato sempre la stessa patologia con lo stesso
--? farmaco, per tutte le patologie contratte.
select distinct P.Nome, P.Cognome
from Paziente P -- inner join Terapia T on P.CodFiscale = T.Paziente	-- join per prendere paz che hanno terapie
where P.CodFiscale not in (		-- escludo i Pazienti con più di un farmaco per patologia
		select D.Paziente
		from (
				select T.Paziente, T.Patologia
				from Terapia T
				group by T.Paziente, T.Patologia
				having count(T.Farmaco) > 1
		) as D
)



--? Indicare nome e cognome dei medici che, con gli incassi delle visite del biennio 2009-2010, hanno
--? superato il reddito mensile medio dei pazienti visitati nello stesso periodo da tutti i medici.
with
VisiteTarget as (
		select *
		from Visita V
		where year(V.Data) between 2009 and 2010
)

select M.*, sum(M.Parcella) as IncassoMed
from VisiteTarget VT inner join Medico M on VT.Medico = M.Matricola
group by VT.Medico
having sum(M.Parcella) > (
		select avg(P.Reddito) as RedditoMedio
		from Paziente P
		where P.CodFiscale in (
				select distinct VT.Paziente 
				from VisiteTarget VT
		)
)
