--? Scrivere una query che restituisca la parte del corpo maggiormente colpita da patologie 
--? con invalidità superiore al 70%. In caso di pari merito, restituire tutte le parti del
--? corpo.
select P.ParteCorpo, count(*) as NumPat
from Patologia P
where P.Invalidita > 70
group by P.ParteCorpo
having count(*) = (		-- prendo laddove il numPat è massimo
		select max(D.NumPat)	-- le conto e trovo il massimo
		from (
			select count(*) as NumPat
			from Patologia P
			where P.Invalidita > 70
			group by P.ParteCorpo
		) as D
)


--? Scrivere una query che restiuisca il numero di terapie iniziate da ciascun paziente in 
--? ogni mese dell’anno. Nel risultato devono comparire tutti i pazienti e tutti i mesi 
--? dell’anno.
with
TabTerapie as (
	select T.Paziente, month(T.DataInizioTerapia) as Mese, count(*) as NumTerapie
	from Terapia T
	group by T.Paziente, month(T.DataInizioTerapia)
),
Mesi as (
	select distinct(month(DataInizioTerapia)) as Mese
    from Terapia
)

select P.CodFiscale, M.Mese, ifnull(TT.NumTerapie, 0) as NumTerapie
from Paziente P cross join Mesi M
			    left outer join TabTerapie TT on M.Mese = TT.Mese
											  and TT.Paziente = P.CodFiscale


--? Scrivere una query che restituisca, relativamente al mese di Giugno 2011, la percentuale 
--? d’incasso totale mensile dovuta alle visite nefrologiche.
--? Non si usino view, né derived table.
-- (IncassoNefr / IncassoTot) * 100
select sum(M.Parcella) / (
		select sum(M.Parcella)
		from Visita V inner join Medico M on V.Medico = M.Matricola
		where year(V.Data) = 2011 and month(V.Data) = 6
) * 100 as IncassoPerc
from Visita V inner join Medico M on V.Medico = M.Matricola
where year(V.Data) = 2011 and month(V.Data) = 06
	and M.Specializzazione = 'Nefrologia'


--? Scrivere una stored procedure per l’inserimento di una nuova terapia. Nel caso in cui il 
--? paziente oggetto della terapia non abbia assunto in precedenza lo stesso principio attivo,
--? la terapia non deve essere inserita e deve essere restituito un messaggio di errore del
--? tipo: “Il paziente potrebbe essere allergico al principio attivo X”. Sostituire X con il
--? nome del principio attivo oggetto della terapia. La stored procedure non deve contenere
--? istruzioni di tipo CREATE.

drop procedure if exists proc;
delimiter $$
create procedure proc(
	in _paziente char(50),
    in _patologia char(50),
    in _dataEsordio date,
    in _farmaco char(50),
    in _dataInizioTerapia date,
    in _dataFineTerapia date,
    in _posologia int
)
begin
	declare princAttivo char(50) default null;
	declare frase char(255) default null;
    
    set princAttivo = (		-- trovo principio attivo del farmaco
		select F.PrincipioAttivo
        from Farmaco F
        where F.NomeCommerciale = _farmaco
    );
    set frase = "Il paziente potrebbe essere allergico al principio attivo";

	if not exists (			-- controllo che esista una terapia con quel principio attivo
		select *
        from Terapia T inner join Farmaco F on T.Farmaco = F.NomeCommerciale
        where T.Paziente = _paziente
			and F.PrincipioAttivo = princAttivo
    )
    then select concat(frase,' ', princAttivo) as ALERT;	-- se non c'è ALERT!
    else
		insert into Terapia values(_paziente, _patologia, _dataEsordio, _farmaco, _dataInizioTerapia, _dataFineTerapia, _posologia);
    end if;
	
end $$
delimiter ;









