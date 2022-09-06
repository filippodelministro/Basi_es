--? Scrivere una query che cancelli le terapie in corso a base di pantoprazolo, iniziate più di 
--? due giorni fa, da pazienti di sesso femminile che avevano già assunto lo stesso farmaco
--? non meno di una settimana prima (con versione join equivalente, sapere cosa vuol dire
--? l’errore “the target table is not updatable”: sto cercando di fare un aggiornamento su
--? una derived table)
delete T4.*
from Terapia T4 left outer join 
(
		select *
		from Terapia T inner join Farmaco F on T.Farmaco = F.NomeCommerciale
					   inner join Paziente P on T.Paziente = P.CodFiscale
		where F.PrincipioAttivo = 'Pantoprazolo'
			and T.DataInizioTerapia < current_date() - interval 2 day
			and P.Sesso = 'F'
			and T.DataFineTerapia is null		-- in corso
			and exists (
					select *
					from Terapia T1
					where T1.Paziente = T.Paziente
						and T1.Farmaco = T.Farmaco
						and T1.DataInizioTerapia <> T.DataInizioTerapia
						and T1.DataFineTerapia < T.DataInizioTerapia
						and T1.DataFineTerapia >= T.DataInizioTerapia - interval 1 week
			)
			and not exists (
							select *
							from Terapia T2
							where T2.Paziente = T.Paziente
								and T2.Farmaco = T.Farmaco
								and T2.DataInizioTerapia <> T.DataInizioTerapia
								and T2.DataFineTerapia < T.DataInizioTerapia
								and T2.DataFineTerapia >= T.DataInizioTerapia - interval 1 week
			)
		) as D on T4.Paziente = D.Paziente
			   and T4.Patologia = D.Patologia
               and T4.DataEsordio = D.DataEsordio
               and T4.Farmaco = D.Farmaco
               and T4.DataInizioTerapia = D.DataInizioTerapia


--? Scrivere una query che restituisca la città dalla quale proviene il maggior numero di
--? pazienti che non hanno sofferto d’insonnia per un numero di giorni maggiore a quello
--? degli altri pazienti della loro città. In caso di pari merito restituire tutti gli
--? ex aequo



--? Scrivere una query che, considerati gli ultimi dieci anni, restituisca anno e mese (come 
--? numeri interi) in cui non è stata effettuata alcuna visita in una (e una sola) specializzazione
--? fra quelle aventi almeno due medici provenienti dalla stessa città. Il nome di tale
--? specializzazione deve completare il record.
select distinct year(V1.Data) as Anno, month(V1.Data) as Mese
from Visita V1 left outer join (
select year(V.Data) as Anno, month(V.Data) as Mese
from Visita V inner join Medico M on V.Medico = M.Matricola
where V.Data > current_date() - interval 10 year
	and M.Specializzazione in (		-- Specializzazioni aventi almeno due medici per ogni citta
		select distinct M.Specializzazione
		from Medico M
		where exists (				-- deve esistere un medico diverso con stessa Spec e stessa Citta
				select *			-- (si poteva fare anche con join (provato))
				from Medico M1
				where M.Matricola <> M1.Matricola
					and M.Specializzazione = M1.Specializzazione
					and M.Citta = M1.Citta
		)
    )
group by year(V.Data), month(V.Data)
having count(distinct M.Specializzazione) = 1
) as D on year(V1.Data) = D.Anno
	   and month(V1.Data) = D.Mese
where V1.Data > current_date() - interval 10 year
	and D.Anno is null
    

--? Scrivere una query che restituisca il nome commerciale dei farmaci che, in almeno un mese
--? del 2013, sono stati impiegati in terapie, iniziate e concluse in quel mese, tutte di 
--? durata inferiore a quelle iniziate e concluse nello stesso mese basate su un altro farmaco,
--? nell’ambito della cura di una stessa patologia. La query restituisca anche la patologia,
--? e le durate mensili medie delle terapie dei due farmaci per tale patologia, calcolate 
--? considerando i mesi in cui la condizione si è verificata.
with
TerapieTarget as (
		select *
		from Terapia T
		where year(T.DataInizioTerapia) = 2013
			and year(T.DataInizioTerapia) = 2013
			and month(T.DataInizioTerapia) = month(T.DataFineTerapia)
)

select TT3.Patologia, TT3.Farmaco, avg(datediff(TT3.DataFineTerapia, TT3.DataInizioTerapia)) over(partition by TT3.Farmaco) as DurataF1,
					  TT4.Farmaco, avg(datediff(TT4.DataFineTerapia, TT4.DataInizioTerapia)) over(partition by TT4.Farmaco) as DurataF2
from TerapieTarget TT3 inner join TerapieTarget TT4 on TT4.Patologia = TT3.Patologia
													and TT4.Farmaco <> TT3.Farmaco
where TT3.Farmaco not in (
			select TT1.Farmaco -- *, datediff(TT2.DataFineTerapia, TT2.DataInizioTerapia)as DurataTT2, datediff(TT1.DataFineTerapia, TT1.DataInizioTerapia) as DurataTT1
			from TerapieTarget TT1 inner join TerapieTarget TT2 on TT1.Patologia = TT2.Patologia
																and TT1.Farmaco <> TT2.Farmaco
			where datediff(TT2.DataFineTerapia, TT2.DataInizioTerapia) < datediff(TT1.DataFineTerapia, TT1.DataInizioTerapia)
)


--? Scrivere una query che consideri le specializzazioni della clinica e il primo trimestre degli 
--? ultimi 10 anni, e per ciascuna restituisca il nome della specializzazione, l’anno, e la 
--? differenza percentuale fra l’incasso ottenuto nel primo trimestre di tale anno con le visite
--? non mutuate e quelle realizzate nel primo trimestre dell’anno precedente.
-- fare con partition by???
with 
Incassi as (
		select year(V.Data) as Anno, M.Specializzazione, sum(M.Parcella) as incasso
		from Visita V inner join Medico M on V.Medico = M.Matricola
		where V.Mutuata = 0
			and month(V.Data) <= 3
		group by year(V.Data), M.Specializzazione
)

select I1.Specializzazione, I1.Anno, -- I1.Incasso, I2.Incasso as IncassoPrec,
								((I1.Incasso-I2.Incasso)/((I1.Incasso+I2.Incasso)/2))*100 as DiffPerc
from Incassi I1 cross join Incassi I2 on I1.Anno = I2.Anno + 1
									  and I1.Specializzazione = I2.Specializzazione
where I1.Anno >= year(current_date()) - 10


--? Scrivere una query che consideri gli esordi di gastrite nei bimestri Febbraio-Marzo degli 
--? ultimi dieci anni, e restituisca in quali di questi anni più del 40% degli esordi del
--? bimestre Febbraio-marzo hanno riguardato, nel complesso, pazienti di Pisa e Roma, rispetto
--? al totale degli esordi di gastrite dello stesso bimestre.
with
EsordiTarget as (
		select year(E.DataEsordio) as Anno, count(*) as NumEsordi
		from Esordio E inner join Paziente P on E.Paziente = P.CodFiscale
		where E.Patologia = 'Gastrite'
			and year(E.DataEsordio) >= year(current_date()) - 10
		   -- and (month(E.DataEsordio) = 2 or month(E.DataEsordio) = 3)
		   and (P.Citta = 'Pisa' or P.Citta = 'Roma')
		group by year(E.DataEsordio)
),
EsordiTot as (
		select year(E.DataEsordio) as Anno, count(*) as NumEsordi
		from Esordio E inner join Paziente P on E.Paziente = P.CodFiscale
		where E.Patologia = 'Gastrite'
			and year(E.DataEsordio) >= year(current_date()) - 10
		   -- and (month(E.DataEsordio) = 2 or month(E.DataEsordio) = 3)
		group by year(E.DataEsordio)
)

select ET.Anno
from EsordiTarget ET inner join EsordiTot E on ET.Anno = E.Anno
where ET.NumEsordi > 0.4 * E.NumEsordi

--? Scrivere una stored procedure che sposti, in una tabella di archivio con stesso schema di
--? Esordio, gli esordi di patologie gastriche conclusi con guarigione, relativi a pazienti che
--? non hanno contratto, precedentemente all’esordio, patologie gastriche, ma che ne hanno
--? curate con successo almeno due successivamente.
drop procedure if exists proc;
delimiter $$
create procedure proc()
begin
	drop table if exists Tab;
    create table Tab(
		Paziente char(50) not null,
        Patologia char(50) not null,
        DataEsordio date not null,
        DataGuarigione date not null,
        Gravita int,
        Cronica char(50),
        EsordiPrecedenti int	,
        primary key(Paziente, Patologia, DataEsordio)
    )Engine=InnoDB default charset=latin1;

	insert into Tab
    select E.*
	from Esordio E inner join Patologia P on E.Patologia = P.Nome
	where P.SettoreMedico = 'Gastroenterologia'
		and E.DataGuarigione is not null
		and not exists (		-- non ci sono patologie gastriche precedenti
				select *
				from Esordio E1 inner join Patologia P1 on E1.Patologia = P1.Nome
				where E1.DataEsordio < E.DataEsordio 
					and P1.SettoreMedico = P.SettoreMedico
					and E1.Paziente = E.Paziente 
		)
	and (
		select count(*)
		from Esordio E2 inner join Patologia P2 on E2.Patologia = P2.Nome
		where E2.Paziente = E.Paziente
			and E2.DataEsordio > E.DataEsordio
			and E2.DataGuarigione is not null 
			and P2.SettoreMedico = P.SettoreMedico
	) >= 2;
   
end $$
delimiter ;

--? Considerato ogni medico (detto target) avente parcella superiore alla parcella media di
--? almeno una specializzazione diversa dalla sua, scrivere una query che, per ciascuna 
--? specializzazione medica, nessuna esclusa, restituisca il nome della specializzazione,
--? la matricola del medico (fra i medici target) che ha effettuato il minor numero di visite
--? non mutuate nel mese scorso (rispetto ai medici della sua specializzazione), e il
--? relativo incasso. In caso di pari merito, restituire tutti gli ex aequo.
with
VisiteSpec as (
		select D.Specializzazione, min(D.NumVisite) as MinNumVisite
		from (
				select M.Matricola, M.Specializzazione, count(*) as NumVisite
				from Medico M inner join Visita V on M.Matricola = V.Medico
                where V.Mutuata = '0'
					-- and month(V.Data) = month(current_date())
                    -- and year(V.Data) = year(current_date())
                group by M.Matricola, M.Specializzazione
		) as D
		group by D.Specializzazione
),
MediciTarget as (
		select *
		from Medico M
		group by M.Matricola
		having avg(M.Parcella) > (
				select avg(M1.Parcella)
				from Medico M1
				where M1.Specializzazione <> M.Specializzazione
		)
),
TabTarget as(
		select M.Matricola, sum(M.Parcella) as Incasso
		from Medico M inner join Visita V on M.Matricola = V.Medico
					  inner join VisiteSpec VS on VS.Specializzazione = M.Specializzazione
		where M.Matricola in (
		select D1.Matricola
		from(
				select *
				from Medico M
				group by M.Matricola
				having avg(M.Parcella) > (
						select avg(M1.Parcella)
						from Medico M1
						where M1.Specializzazione <> M.Specializzazione
						)
				) as D1
		)
		group by M.Matricola, VS.MinNumVisite
		having count(*) = VS.MinNumVisite
)

select M.Specializzazione, TT.*
from Medico M inner join TabTarget TT on M.Matricola = TT.Matricola
