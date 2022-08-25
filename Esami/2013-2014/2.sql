--? Indicare il nome dei farmaci mai assunti prima dei venti anni d’età



--? Indicare nome e cognome dei pazienti che hanno curato sempre la stessa patologia con lo stesso
--? farmaco, per tutte le patologie contratte.


--? Indicare nome e cognome dei medici che, con gli incassi delle visite del biennio 2009-2010, hanno
--? superato il reddito mensile medio dei pazienti visitati nello stesso periodo da tutti i medici.


-- ================================================================
--                          SOLUZIONI   
-- ================================================================

/*Indicare il nome dei farmaci mai assunti prima dei venti anni d’età*/

select distinct T.Farmaco
from Terapia T 
where not exists (

	select *
    from Terapia T1 inner join Paziente P1 on T1.Paziente = P1.CodFiscale
    where T1.Farmaco = T.Farmaco and (year(T1.DataInizioTerapia)-year(P1.DataNascita)) <= 20

)

/*Indicare nome e cognome dei pazienti che hanno curato sempre la stessa patologia con lo stesso
farmaco, per tutte le patologie contratte.*/ 

with TerapieOnce as (
	select D.Paziente, count(distinct D.Patologia) as NumPatologie, D.Nome, D.Cognome
	from (
		select T.Paziente, T.Patologia, P.Nome, P.Cognome
		from Terapia T inner join Paziente P on T.Paziente = P.CodFiscale
		group by T.Paziente, T.Patologia
		having count(distinct T.Farmaco) = 1
	) as D
	group by D.Paziente
), TerapieAll as (

	select T.Paziente, count(distinct T.Patologia) as TotPatologie
    from Terapia T
    group by T.Paziente

)


select TO1.Nome, TO1.Cognome
from TerapieOnce TO1 natural join TerapieAll TA
where TO1.NumPatologie = TA.TotPatologie

/*Indicare nome e cognome dei medici che, con gli incassi delle visite del biennio 2009-2010, hanno
superato il reddito mensile medio dei pazienti visitati nello stesso periodo da tutti i medici.*/

with RedditoMensileMedio as (

	select avg(D.Reddito) as RedditoMedio
    from (
		select V.Paziente, P.Reddito
		from Paziente P inner join Visita V on P.CodFiscale = V.Paziente
		where year(V.Data) between 2009 and 2010
		group by V.Paziente
		having count(distinct V.Medico) = (
											select count(*)
											from Medico M
										) 
        ) as D

), IncassiMedici as (

	select V.Medico, sum(M.Parcella) as Incasso, M.Nome, M.Cognome
    from Medico M inner join Visita V on M.Matricola = V.Medico
    where year(V.Data) between 2009 and 2010
    group by V.Medico

)


select IM.Nome, IM.Cognome
from IncassiMedici IM cross join RedditoMensileMedio RMM
where IM.Incasso > RMM.RedditoMedio