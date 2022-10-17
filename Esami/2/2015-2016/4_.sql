--? Scrivere una query che, considerata ciascuna parte del corpo, ne restituisca il nome, e i 
--? principi attivi contenuti in farmaci indicati solamente per la cura di patologie a 
--? carico di tale parte del corpo.
with
PATarget as (	-- PrincAtt indicati per Patologie di una sola ParteCorpo
	select F.PrincipioAttivo
	from Indicazione I inner join Farmaco F on F.NomeCommerciale = I.Farmaco
					   inner join Patologia PA on I.Patologia = PA.Nome
	group by F.PrincipioAttivo
	having count(distinct PA.ParteCorpo) = 1
)

select PA.ParteCorpo, F.PrincipioAttivo
from Indicazione I inner join Farmaco F on F.NomeCommerciale = I.Farmaco
				   inner join Patologia PA on I.Patologia = PA.Nome
where F.PrincipioAttivo in (select * from PATarget)
order by PA.ParteCorpo

--? Scrivere una query che elenchi nome e cognome dei pazienti oggi maggiorenni che, al 5 
--? Settembre 2015, erano stati visitati da tutti gli oculisti della clinica, tranne 
--? eventualmente uno, e, qualora esista, il cognome di tale oculista.
with
VisiteTarget as (
	select V.Paziente, V.Medico
	from Visita V inner join Paziente P on V.Paziente = P.CodFiscale
				  inner join Medico M on V.Medico = M.Matricola
	where M.Specializzazione = 'Oculistica'
		and P.DataNascita < current_date() - interval 18 year
),
PazTarget as (
	select VT.Paziente
	from VisiteTarget VT
	group by VT.Paziente
	having count(distinct VT.Medico) = (
		select count(*)
		from Medico
		where Specializzazione = 'Oculistica'
	)
	or count(distinct VT.Medico) = (
		select count(*)
		from Medico
		where Specializzazione = 'Oculistica'
	) - 1
),
Oculisti as (
	select *
    from Medico
    where Specializzazione = 'Oculistica'
),
Combinazioni as (   -- creo tutte le combinazioni tra Oculisti e PazTarget: po guardo se esiste una VisitaTarget
	select *
	from Oculisti O cross join PazTarget PT
)

-- controllo se esiste una VisitaTarget di tutte le combinazioni tra PT e Oculisti
select P.Nome, P.Cognome, D.Cognome as Medico
from Paziente P inner join PazTarget PT on P.CodFiscale = PT.Paziente
	left outer join (
	select C.Paziente, C.Nome, C.Cognome
	from VisiteTarget VT right outer join Combinazioni C on VT.Paziente = C.Paziente
														 and VT.Medico = C.Matricola
	where VT.Medico is null
) as D on PT.Paziente = D.Paziente




--? Scrivere una stored procedure report_spese che riceva in ingresso tre parametri: il 
--? codice fiscale di un paziente i, il nome di un settore medico s e un parametro booleano 
--? (tinyint) ssn. La stored procedure deve restituire la spesa totale e media giornaliera
--? sostenuta attualmente dal paziente p per le terapie in corso del settore medico s. Le 
--? spese sopra descritte sono calcolate in modo diverso dipendentemente dal valore di
--? ssn. In particolare, se ssn = 1 la stored procedure restituisce le varie spese al
--? netto della percentuale di esenzione, ove prevista, altrimenti l’esenzione è ignorata. 
--? Alla percentuale di esenzione associata alla patologia j, deve essere sommato un
--? coefficiente dipendente dal reddito del paziente e dal numero di patologie croniche 
--? attinenti al settore medico s, da cui è affetto il paziente i, secondo la seguente 
--? espressione:
--?     P_i,s = C_i,s /(0.01 · R_i )
--?     con
--?         R_i     => Reddito del paziente I
--?         C_i,s   => N# pat croniche del settore S del paziente I
drop procedure if exists report_spese;
delimiter $$
create procedure report_spese(
	in _codFiscale char(50),
    in _settoreMedico char(50),
    in _ssn tinyint,
	out spesaTot_ double,
    out mediaGiornaliera_ double
)
begin
	declare reddito int default 0;
    declare numCroniche int default 0;
    declare primoEsordio date;    
        
    set reddito = (
		select P.Reddito
        from Paziente P
        where P.CodFiscale = _codFiscale
    );
    set numCroniche = (
		select count(distinct E.Patologia)
        from Esordio E inner join Patologia PA on E.Patologia = PA.Nome
        where PA.SettoreMedico = _settoreMedico
			and E.Paziente = _codFiscale
			and E.Cronica = "si"
    );
    set primoEsordio = (	-- serve per calcolo della mediaGiornaliera_
		select min(E.DataEsordio)
        from Esordio E inner join Patologia PA on E.Patologia = PA.Nome
        where PA.SettoreMedico = _settoreMedico
			and E.Paziente = _codFiscale
			and E.Cronica = "si"
    );
    
    set spesaTot_ = (
		select sum((floor(datediff(current_date(), T.DataInizioTerapia)/F.Pezzi) + 1) * F.Costo 
					* if(_ssn = 1, 
						(100 - PA.PercEsenzione + (numCroniche/(0.01 * reddito))) / 100		-- esenzione (modificata secondo testo)
                        , 1
					))
		from Terapia T inner join Patologia PA on T.Patologia = PA.Nome
					   inner join Farmaco F on T.Farmaco = F.NomeCommerciale
		where T.Paziente = _codFiscale
			and PA.SettoreMedico = _settoreMedico
			and T.DataFineTerapia is null
    );
    
    set mediaGiornaliera_ = spesaTot_ / datediff(current_date(), primoEsordio);
    
end  $$
delimiter ;


set @spesaTot_ = 0;
set @mediaGiornaliera_ = 0;
call Clinica.report_spese("slq6", "Neurologia", 1, @spesaTot_, @mediaGiornaliera_);
select @spesaTot_, @mediaGiornaliera_;
