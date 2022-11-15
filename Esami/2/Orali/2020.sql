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

with TerapieTarget as (
	select T.Patologia, T.Farmaco, month(T.DatainizioTerapia) as Mese, datediff(T.DataFineTerapia, T.DataInizioTerapia) as Durata
	from Terapia T
	where year(T.DataInizioTerapia) = 2013
		and month(T.DataInizioTerapia) = month(T.DataFineTerapia)
), 
Confronto as (
	select T1.Patologia, T1.Farmaco as Farmaco1, T1.Durata as Durata1, T2.Farmaco as Farmaco2, T2.Durata as Durata2
	from TerapieTarget T1 inner join TerapieTarget T2 on T1.Patologia = T2.Patologia
													  and T1.Farmaco <> T2.Farmaco
													  and T1.Mese = T2.Mese
	where T1.Durata < T2.Durata
)

select C.Patologia, C.Farmaco1, C.Farmaco2, avg(C.Durata1) as Media1, avg(C.Durata2) as Media2
from Confronto C
group by C.Patologia, C.Farmaco1, C.Farmaco2



--? Scrivere una query che consideri le specializzazioni della clinica e il primo trimestre degli 
--? ultimi 10 anni, e per ciascuna restituisca il nome della specializzazione, l’anno, e la 
--? differenza percentuale fra l’incasso ottenuto nel primo trimestre di tale anno con le visite
--? non mutuate e quelle realizzate nel primo trimestre dell’anno precedente.
with
Incasso as (
	select year(V.Data) as Anno, M.Specializzazione, sum(M.Parcella) as IncassoTot
	from Visita V inner join Medico M on V.Medico = M.Matricola
	where month(V.Data) < 4
        and V.Mutuata = 0
	group by year(V.Data), M.Specializzazione
)	
																					-- Diff perc = (|x-y|/((x+y)/2))*100
select I1.Specializzazione, I1.Anno, I1.IncassoTot, I2.Anno as AnnoPrec, I2.IncassoTot as IncassoPrec, ((I1.IncassoTot-I2.IncassoTot)/((I1.IncassoTot+I2.IncassoTot)/2))*100 as DiffPerc
from Incasso I1 left outer join Incasso I2 on I1.Specializzazione = I2.Specializzazione
									       and I1.Anno = I2.Anno + 1
where I1.Anno >= year(current_date()) - 10
order by I1.Specializzazione, I1.Anno


--? Scrivere una query che consideri gli esordi di gastrite nei bimestri Febbraio-Marzo degli 
--? ultimi venti anni, e restituisca in quali di questi anni più del 40% degli esordi del
--? bimestre Febbraio-marzo hanno riguardato, nel complesso, pazienti di Pisa e Roma, rispetto
--? al totale degli esordi di gastrite dello stesso bimestre.
with
GastriteTot as (
	select year(E.DataEsordio) as Anno, count(*) as NumEsordi
	from Esordio E
	where E.Patologia = 'Gastrite'
		and month(E.DataEsordio) in ('2', '3')
		and year(E.DataEsordio) > year(current_date()) - 20
	group by year(E.DataEsordio)
),
GastriteCitta as (
	select year(E.DataEsordio) as Anno, count(*) as NumEsordi
	from Esordio E inner join Paziente P on E.Paziente = P.CodFiscale
	where E.Patologia = 'Gastrite'
		and month(E.DataEsordio) in ('2', '3')
		and year(E.DataEsordio) > year(current_date()) - 20
        and (P.Citta = 'Pisa' or P.Citta = 'Roma')
	group by year(E.DataEsordio)
)

select G.Anno -- , G.NumEsordi as EsordiTot, GC.NumEsordi as EsordiTarget
from GastriteTot G inner join GastriteCitta GC on G.Anno = GC.Anno
where GC.NumEsordi > 0.4 * G.NumEsordi
order by G.Anno


--? Scrivere una stored procedure che sposti, in una tabella di archivio con stesso schema di
--? Esordio, gli esordi di patologie gastriche conclusi con guarigione, relativi a pazienti che
--? non hanno contratto, precedentemente all’esordio, patologie gastriche, ma che ne hanno
--? curate con successo almeno due successivamente.
drop table if exists ARCHIVIO_ESORDI;
create table ARCHIVIO_ESORDI(
	Paziente char(50),
    Patologia char(50),
    DataEsordio date,
    DataGuarigione date,
    Gravita int,
    Cronica char(50),
    EsordiPrecedenti int,
	primary key(Paziente, Patologia, DataEsordio)
)Engine = InnoDB default charset = latin1;

drop procedure if exists sposta_ARCHIVIO_ESORDI;
delimiter $$
create procedure sposta_ARCHIVIO_ESORDI()
begin 

	-- inserisco i record target
	insert into ARCHIVIO_ESORDI
		select *
		from Esordio E
		where E.Patologia = 'Gastrite'
			and E.DataGuarigione is not null
			and not exists (		-- non esistono gastriti precedenti
				select *
				from Esordio E1
				where E1.Paziente = E.Paziente
					and E1.Patologia = 'Gastrite'
					and E1.DataEsordio < E.DataEsordio
			)
			and exists (		-- ma esistono gastriti successive curate
				select *
				from Esordio E2
				where E2.Paziente = E.Paziente
					and E2.Patologia = 'Gastrite'
					and E2.DataEsordio > E.DataEsordio
					and E2.DataGuarigione is not null
        );
	
    -- e gli elimino da Esordio
    delete EE.*
    from Esordio EE inner join (
		select *
		from Esordio E
		where E.Patologia = 'Gastrite'
			and E.DataGuarigione is not null
			and not exists (		
				select *
				from Esordio E1
				where E1.Paziente = E.Paziente
					and E1.Patologia = 'Gastrite'
					and E1.DataEsordio < E.DataEsordio
			)
			and exists (	drop table if exists ARCHIVIO_ESORDI;
create table ARCHIVIO_ESORDI(
	Paziente char(50),
    Patologia char(50),
    DataEsordio date,
    DataGuarigione date,
    Gravita int,
    Cronica char(50),
    EsordiPrecedenti int,
	primary key(Paziente, Patologia, DataEsordio)
)Engine = InnoDB default charset = latin1;

drop procedure if exists sposta_ARCHIVIO_ESORDI;
delimiter $$
create procedure sposta_ARCHIVIO_ESORDI()
begin 

	-- inserisco i record target
	insert into ARCHIVIO_ESORDI
		select *
		from Esordio E
		where E.Patologia = 'Gastrite'
			and E.DataGuarigione is not null
			and not exists (		-- non esistono gastriti precedenti
				select *
				from Esordio E1
				where E1.Paziente = E.Paziente
					and E1.Patologia = 'Gastrite'
					and E1.DataEsordio < E.DataEsordio
			)
			and exists (		-- ma esistono gastriti successive curate
				select *
				from Esordio E2
				where E2.Paziente = E.Paziente
					and E2.Patologia = 'Gastrite'
					and E2.DataEsordio > E.DataEsordio
					and E2.DataGuarigione is not null
        );
	
    -- e gli elimino da Esordio
    delete EE.*
    from Esordio EE inner join (
		select *
		from Esordio E
		where E.Patologia = 'Gastrite'
			and E.DataGuarigione is not null
			and not exists (		
				select *
				from Esordio E1
				where E1.Paziente = E.Paziente
					and E1.Patologia = 'Gastrite'
					and E1.DataEsordio < E.DataEsordio
			)
			and exists (		-- ma esistono gastriti successive curate
				select *
				from Esordio E2
				where E2.Paziente = E.Paziente
					and E2.Patologia = 'Gastrite'
					and E2.DataEsordio > E.DataEsordio
					and E2.DataGuarigione is not null
        )
	) as D on EE.Paziente = D.Paziente
		   and EE.Patologia = D.Patologia
           and EE.DataEsordio = D.DataEsordio;
end $$
delimiter ;

call sposta_ARCHIVIO_ESORDI();	-- ma esistono gastriti successive curate
				select *
				from Esordio E2
				where E2.Paziente = E.Paziente
					and E2.Patologia = 'Gastrite'
					and E2.DataEsordio > E.DataEsordio
					and E2.DataGuarigione is not null
        )
	) as D on EE.Paziente = D.Paziente
		   and EE.Patologia = D.Patologia
           and EE.DataEsordio = D.DataEsordio;
end $$
delimiter ;

call sposta_ARCHIVIO_ESORDI();


--? Considerato ogni medico (detto target) avente parcella superiore alla parcella media di
--? almeno una specializzazione diversa dalla sua, scrivere una query che, per ciascuna 
--? specializzazione medica, nessuna esclusa, restituisca il nome della specializzazione,
--? la matricola del medico (fra i medici target) che ha effettuato il minor numero di visite
--? non mutuate nel mese scorso (rispetto ai medici della sua specializzazione), e il
--? relativo incasso. In caso di pari merito, restituire tutti gli ex aequo.

				
-- ongni medico avente Parcella maggiore di una media delle parcella
-- di altre Specializzazioni 
with
MediciTarget as (
	select *		
	from Medico M
	where M.Parcella > any (
		select avg(M1.Parcella)
		from Medico M1
		where M1.Specializzazione <> M.Specializzazione
		group by M1.Matricola
	)
),
VisiteTarget as (
	select MT.Matricola, MT.Specializzazione, count(*) as NumVisite, Sum(MT.Parcella) as Incasso
	from Medico M left outer join Visita V on V.Medico = M.Matricola
				  inner join MediciTarget MT on V.Medico = MT.Matricola
	where V.Mutuata = 0
	group by MT.Matricola, MT.Specializzazione
)
select *
from VisiteTarget VT
where VT.NumVisite = (
	select min(VT1.NumVisite)
	from VisiteTarget VT1
	where VT1.Specializzazione = VT.Specializzazione
)


--? Scrivere una query che restituisca la matricola e cognome dei cardiologi che, al 20 Ottobre
--? 2010, avevano visitato tutti i pazienti di almeno una città dalla quale provenissero almeno
--? due pazienti che al tempo erano under 60 e affetti da almeno una patologia cardiaca cronica.

with
CittaTarget as (
	select distinct P.Citta
	from Paziente P
	where P.DataNascita < '2010-10-20' - interval 60 year
		and exists (
			select *
			from Esordio E inner join Patologia PA on E.Patologia = PA.Nome
			where E.Paziente = P.CodFiscale
				and E.Cronica = 'si'
				and PA.SettoreMedico = 'Cardiologia'
		)
	group by P.Citta
    having count(distinct P.CodFiscale) > 1
)

select V.Medico
from Visita V inner join Medico M on V.Medico = M.Matricola
			  inner join Paziente P on V.Paziente = P.CodFiscale
where M.Specializzazione = 'Cardiologia'
group by V.Medico
having exists (
	select P1.Citta
	from Visita V1 inner join Paziente P1 on V1.Paziente = P1.CodFiscale
	where V1.Medico = V.Medico
		and V1.Data < '2010-10-20'
		and P1.Citta in (select * from CittaTarget)
	group by P1.Citta
	having count(distinct V1.Paziente) = (
		select count(P2.CodFiscale)
		from Paziente P2
		where P2.Citta = P1.Citta
	)
)
    
    
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
