--? Scrivere una query che restituisca il nome commerciale dei farmaci a base di ketoprofene
--? usati da almeno la metà dei pazienti di almeno due città per curare solo la contrattura in
--? età compresa fra 40 e 50 anni (inclusi) all’inizio della terapia, indipendentemente dalle
--? terapie effettuate da ciascuno in altre fasce d’età.
select T.Farmaco
from Terapia T inner join Farmaco F on T.Farmaco = F.NomeCommerciale
where F.NomeCommerciale in (
	select D.Farmaco
	from (
			select T1.Farmaco, P1.Citta
			from Terapia T1 inner join Paziente P1 on T1.Paziente = P1.CodFiscale
			group by T1.Farmaco, P1.Citta
			having count(distinct T1.Paziente) >= 0.5 * (
				select count(*)
				from Paziente P2
				where P2.Citta = P1.Citta
			)
	) as D
	group by D.Farmaco
	having count(D.Citta) > 1
)
	and T.Farmaco in (
		select F.NomeCommerciale
        from Farmaco F
        where F.PrincipioAttivo = 'Ketoprofene'
    )
    and T.Paziente in (
		select P.CodFiscale
        from Paziente P
        where current_date() between P.DataNascita + interval 40 year and P.DataNascita + interval 50 year
    )
    and T.Patologia = 'Contrattura'


--? Implementare una stored procedure avg_ill_visit() che, dato un paziente p e una specializzazione
--? medica s, restituisca in uscita il numero medio di giorni trascorsi tra l’esordio di una
--? patologia non cronica della specializzazione s e la visita immediatamente successiva del
--? paziente p con un medico della clinica avente specializzazione s.


--? Implementare una analytic function efficiente (tramite un solo select statement con variabili
--? user-defined) che, per ciascuna visita v dal 2010 a oggi, restituisca la matricola del medico
--? m che l’ha effettuata, la data in cui è stata effettuata, e la matricola del medico della
--? stessa specializzazione e della stessa città di m che ha eseguito la visita temporalmente
--? più prossima alla visita v, fra quelle precedenti, indipendentemente dal paziente visitato.
--? Scrivere in un commento di quale analytic function si tratta fra quelle viste a lezione.