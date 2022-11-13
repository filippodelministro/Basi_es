--? Scrivere una query che cancelli le terapie in corso a base di pantoprazolo, iniziate più di 
--? due giorni fa, da pazienti di sesso femminile che avevano già assunto lo stesso farmaco
--? non meno di una settimana prima (con versione join equivalente, sapere cosa vuol dire
--? l’errore “the target table is not updatable”: sto cercando di fare un aggiornamento su
--? una derived table)
delete TT.*
from Terapia TT left outer join (
select T.*
from Terapia T inner join Farmaco F on T.Farmaco = F.NomeCommerciale
			   inner join Paziente P on T.Paziente = P.CodFiscale
where F.PrincipioAttivo = 'Pantoprazolo'
	and P.Sesso = 'F'
    and T.DataInizioTerapia < current_date() - interval 2 day
	and exists (		-- esiste una Terapia stesso farmaco, stesso paziente, prima di una settimana
	select *
    from Terapia T2
    where T2.Paziente = T.Paziente
		and T2.Farmaco = T.Farmaco
        and T2.DataFineTerapia < T.DataInizioTerapia - interval 1 week
)
	and not exists (	-- e non esiste per entro la settimana
	select *		
    from Terapia T1 
    where T1.Paziente = T.Paziente
		and T1.Farmaco = T.Farmaco
        and T1.DataFineTerapia > T.DataInizioTerapia - interval 1 week
)
) as D on TT.Paziente = D.Paziente
	   and TT.Farmaco = D.Farmaco
       and TT.DataEsordio = D.DataEsordio
       and TT.DataInizioTerapia = D.DataInizioTerapia
       and TT.Patologia = D.Patologia
where TT.Paziente is null


--? Scrivere una query che restituisca la città dalla quale proviene il maggior numero di
--? pazienti che non hanno sofferto d’insonnia per un numero di giorni maggiore a quello
--? degli altri pazienti della loro città. In caso di pari merito restituire tutti gli
--? ex aequo
with
EsordiInsonnia as (
	select D.Paziente, sum(D.NumGiorni) as TotGiorni, D.Citta
	from (
		select E.Paziente, datediff(ifnull(E.DataGuarigione, current_date()), E.DataEsordio) as NumGiorni, P.Citta
        -- select E.Paziente, datediff(E.DataGuarigione, E.DataEsordio) as NumGiorni, P.Citta
		from Esordio E inner join Paziente P on P.CodFiscale = E.Paziente
		where E.Patologia = 'Insonnia'
			-- and E.DataGuarigione is not null
		group by E.Paziente, E.DataEsordio, E.DataGuarigione
	) as D
	group by D.Paziente
	order by D.Citta
)

select EI1.Citta -- , count(distinct EI1.Paziente) as NumPazienti
from EsordiInsonnia EI1 inner join EsordiInsonnia EI2 on EI1.Citta = EI2.Citta
where EI1.Paziente <> EI2.Paziente
	and EI1.TotGiorni < EI2.TotGiorni
group by EI1.Citta
having count(distinct EI1.Paziente) >= all (
	select count(distinct EI1.Paziente)
	from EsordiInsonnia EI1 inner join EsordiInsonnia EI2 on EI1.Citta = EI2.Citta
	where EI1.Paziente <> EI2.Paziente
		and EI1.TotGiorni < EI2.TotGiorni
	group by EI1.Citta
)


--? Scrivere una query che, considerati gli ultimi dieci anni, restituisca anno e mese (come 
--? numeri interi) in cui non è stata effettuata alcuna visita in una (e una sola) specializzazione
--? fra quelle aventi almeno due medici provenienti dalla stessa città. Il nome di tale
--? specializzazione deve completare il record.
with
SpecTarget as (
	select distinct M1.Specializzazione
	from Medico M1
	where M1.Citta in (
		select M.Citta
		from Medico M
		group by M.Citta
		having count(distinct M.Matricola) > 1
	)
),

AnniMesiTarget as (
	select year(V.Data) as Anno, month(V.Data) as Mese
	from Visita V inner join Medico M on V.Medico = M.Matricola
	-- where V.Data > current_date() - interval 10 year
	group by year(V.Data), month(V.Data)
	having count(distinct M.Specializzazione) = (select count(*) from SpecTarget) - 1
)

select distinct M.Specializzazione, A1.Anno, A1.Mese
from AnniMesiTarget A1 inner join Visita V on A1.Anno = year(V.Data)
										   and A1.Mese = month(V.Data)
					   inner join Medico M on V.Medico = M.Matricola
					   right outer join SpecTarget ST on M.Specializzazione = ST.Specializzazione
where ST.Specializzazione is null

--? Scrivere una query che restituisca il nome commerciale dei farmaci che, in almeno un mese
--? del 2013, sono stati impiegati in terapie, iniziate e concluse in quel mese, tutte di 
--? durata inferiore a quelle iniziate e concluse nello stesso mese basate su un altro farmaco,
--? nell’ambito della cura di una stessa patologia. La query restituisca anche la patologia,
--? e le durate mensili medie delle terapie dei due farmaci per tale patologia, calcolate 
--? considerando i mesi in cui la condizione si è verificata.



--? Scrivere una query che consideri le specializzazioni della clinica e il primo trimestre degli 
--? ultimi 10 anni, e per ciascuna restituisca il nome della specializzazione, l’anno, e la 
--? differenza percentuale fra l’incasso ottenuto nel primo trimestre di tale anno con le visite
--? non mutuate e quelle realizzate nel primo trimestre dell’anno precedente.
--? fare con partition by???
--? Scrivere una query che consideri gli esordi di gastrite nei bimestri Febbraio-Marzo degli 
--? ultimi dieci anni, e restituisca in quali di questi anni più del 40% degli esordi del
--? bimestre Febbraio-marzo hanno riguardato, nel complesso, pazienti di Pisa e Roma, rispetto
--? al totale degli esordi di gastrite dello stesso bimestre.


--? Scrivere una stored procedure che sposti, in una tabella di archivio con stesso schema di
--? Esordio, gli esordi di patologie gastriche conclusi con guarigione, relativi a pazienti che
--? non hanno contratto, precedentemente all’esordio, patologie gastriche, ma che ne hanno
--? curate con successo almeno due successivamente.

--? Considerato ogni medico (detto target) avente parcella superiore alla parcella media di
--? almeno una specializzazione diversa dalla sua, scrivere una query che, per ciascuna 
--? specializzazione medica, nessuna esclusa, restituisca il nome della specializzazione,
--? la matricola del medico (fra i medici target) che ha effettuato il minor numero di visite
--? non mutuate nel mese scorso (rispetto ai medici della sua specializzazione), e il
--? relativo incasso. In caso di pari merito, restituire tutti gli ex aequo.



--? Scrivere una query che restituisca la matricola e cognome dei cardiologi che, al 20 Ottobre
--? 2010, avevano visitato tutti i pazienti di almeno una città dalla quale provenissero almeno
--? due pazienti che al tempo erano under 60 e affetti da almeno una patologia cardiaca cronica.

    
    
--? Scrivere una query che restituisca gli anni (target) in cui, nel trimestre Gennaio-Marzo,
--? fra tutte le patologie, è stata solo l’influenza a far registrare un aumento di più del
--? 10% degli esordi rispetto al totale degli esordi della stessa patologia nello stesso
--? trimestre dell’anno precedente, e qual è stato il mese del trimestre che ha fatto
--? registrare il maggior aumento in termini di persone contagiate, per ogni anno target.



--? Scrivere una query che restituisca le patologie che, in almeno due degli ultimi trenta
--? anni, si sono manifestate almeno una volta in tutti i mesi del primo trimestre dell’
--? anno, in almeno due pazienti.


--? Modificare le parcelle dei medici della cardiologia e dell’otorinolaringoiatria,
--? facendo sı̀ che ogni medico abbia la parcella pari alla sua parcella attuale moltiplicata
--? per (0.05*n), dove n è il numero di visite di pazienti provenienti dalla stessa città
--? del medico, visitati negli ultimi trenta anni.
