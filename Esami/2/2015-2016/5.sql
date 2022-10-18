--? Scrivere una query che blocchi, cancellandole, le terapie in corso basate sul farmaco 
--? Broncho-Vaxom, iniziate più di tre giorni fa, da pazienti pediatrici (età inferiore a 
--? 12 anni) attualmente affetti da broncospasmo. A cancellazione avvenuta, restituire, come 
--? result set, il codice fiscale dei pazienti oggetto di blocco.



--? Introdurre una ridondanza SpesaGiornaliera nella tabella PAZIENTE per mantenere l’attuale
--? spesa giornaliera in farmaci di ciascun paziente. Nel computo, si ignorino le patologie con
--? diritto di esenzione. Scrivere il codice per creare, popolare e mantenere costantemente 
--? aggiornata la ridondanza.


--? Considerato ogni medico avente parcella inferiore alla parcella media di almeno altre due 
--? specializzazioni oltre alla sua, scrivere una query che restituisca, per ciascuna 
--? specializzazione medica della clinica, nessuna esclusa, il nome della specializzazione,
--? la matricola del medico con il più alto numero di visite mutuate realizzate nel mese in 
--? corso, e l’ammontare dell’incasso derivante dalle sue visite mutuate. In caso di pari merito,
--? restituire l’incasso di ciascun medico ex aequo di ogni specializzazione. L’importo pagato
--? dal paziente per una visita specialistica mutuata è calcolato da una stored function 
--? ticket(), di cui si richiede il codice, e corrisponde al ticket derivante dalla fascia di
--? reddito annuale del paziente: 
--?     € 36.15 per redditi fino a € 36,152;
--?     € 50.00 per redditi tra € 36,153 e € 100,000;
--?     € 70.00 per redditi superiori a € 100,000.
drop function if exists ticket;
delimiter $$
create function ticket(_codFiscale char(50))
returns double deterministic
begin
	declare reddito int default 0;
	declare ret double default 0;

    set reddito = (
		select Reddito * 12
        from Paziente
        where CodFiscale = _codFiscale
    );
    
    if(reddito < 36152) then
		set ret = 36.15;
    elseif (reddito < 100000) then
		set ret = 50;
    else 
		set ret = 70;
	end if;
    
    return ret;
end $$
delimiter ;


with
MediaSpec as (
	select M.Specializzazione, avg(M.Parcella) as Media
	from Medico M
	group by M.Specializzazione
),
MediciTarget as (
	select M1.*
    from Medico M1 inner join (
		select M.Matricola
		from Medico M cross join MediaSpec MS
		where M.Specializzazione <> MS.Specializzazione
			and M.Parcella < MS.Media
		group by M.Matricola
		having count(distinct MS.Specializzazione) > 1 
	) as D on M1.Matricola = D.Matricola
),
VisiteMed as (
	select MT.Matricola, MT.Specializzazione, count(*) as NumVisite,
			sum(ticket(V.Paziente)) as TotIncassi
	from Visita V inner join MediciTarget MT on V.Medico = MT.Matricola
	where month(V.Data) = month(current_date())
		-- and V.Mutuata = 1
	group by MT.Matricola
)


select VM.*
from VisiteMed VM natural join Medico M
where VM.NumVisite = (
	select max(VM1.NumVisite)
    from VisiteMed VM1
    where VM1.Specializzazione = VM.Specializzazione
)
