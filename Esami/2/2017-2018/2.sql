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

drop procedure if exists avg_ill_visit;
delimiter $$
create procedure avg_ill_visit(
	in _paziente char(50),
    in _settMedico char(50),
	out media_ double
)
begin
	set media_ = (
		select avg(DD.PrimaVisita) as Media
        from (
			select D.DataEsordio, min(D.Diff) as PrimaVisita
			from (
				select E.DataEsordio, V.Data, datediff(V.Data, E.DataEsordio)as Diff
				from Esordio E inner join Patologia PA on E.Patologia = PA.Nome
							   inner join Visita V on E.Paziente = V.Paziente
							   inner join Medico M on V.Medico = M.Matricola
				where PA.SettoreMedico = _settMedico
					and E.Paziente = _paziente
					and E.Cronica = 'no'
					and PA.SettoreMedico = M.Specializzazione
					and E.DataEsordio < V.Data
				group by E.DataEsordio, V.Data
			) as D
			group by D.DataEsordio
		) as DD
	);
end $$
delimiter ;

set @media = 0;
call avg_ill_visit('bbc4', 'Cardiologia', @media);
select @media;
