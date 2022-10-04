--? Nome e Cognome dei pazienti che hanno una terapia, ma nessuna visita
select P.*
from Paziente P inner join Terapia T on P.CodFiscale = T.Paziente
				left outer join Visita V on T.Paziente = V.Paziente
where V.Paziente is null


--? Per i farmaci gastroenterologici, che sono indicati per più di una patologia,
--? eliminare da Indicazione, la patologia che utilizza di meno quel farmaco
with
Utilizzi as (
	select T.Farmaco, T.Patologia, count(*) as NumUtilizzi
	from Terapia T
	where T.Farmaco in (
			select I.Farmaco
			from Patologia P inner join Indicazione I on P.Nome = I.Patologia
			where P.SettoreMedico = 'Gastroenterologia'
			group by I.Farmaco
			having count(distinct I.Patologia) > 1
	)
	group by T.Farmaco, T.Patologia
)

delete  I.*
from Indicazione I left outer join (
		select U.Farmaco, U.Patologia
		from Utilizzi U
		where U.NumUtilizzi <= all (
			select U1.NumUtilizzi
			from Utilizzi U1
		)
) as D on I.Farmaco = D.Farmaco
	   and I.Patologia = D.Patologia
where D.Patologia is not null