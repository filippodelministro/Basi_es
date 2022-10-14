--? Scrivere una query che restituisca nome e cognome del medico che, al 31/12/2014, 
--? aveva visitato un numero di pazienti superiore a quelli visitati da ciascun medico 
--? della sua stessa specializzazione.

with
VisiteSpec as (
	select V.Medico, M.Specializzazione, count(*) as NumVisite
	from Visita V inner join Medico M on V.Medico = M.Matricola
	where year(V.Data) < 2015
	group by M.Matricola
)

select M.Nome, M.Cognome, M.Specializzazione, VS1.NumVisite
from Medico M inner join VisiteSpec VS1 on M.Matricola = VS1.Medico 
			  inner join (
	select VS.Specializzazione, max(VS.NumVisite) as MaxVisite
	from VisiteSpec VS
	group by VS.Specializzazione
) as D on VS1.Specializzazione = D.Specializzazione
	   and D.MaxVisite = VS1.NumVisite

--oppure => uso partition

select distinct M.Nome, M.Cognome
from Medico M inner join VisiteSpec VS1 on M.Matricola = VS1.Medico
			  inner join (
select VS.Specializzazione, max(VS.NumVisite) over(partition by VS.Specializzazione) as MaxVisite
from VisiteSpec VS
) as D on VS1.Specializzazione = D.Specializzazione
	   and VS1.NumVisite = D.MaxVisite


--? Scrivere una query che restituisca per ciascun principio attivo, il nome del principio
--? attivo e il nome commerciale di ogni farmaco utilizzato almeno una volta per tutte
--? le patologie per le quali è indicato. Il risultato è formato da 
--? row(PrincipioAttivo , NomeCommerciale ), una per ogni farmaco che rispetta la condizione.
select F.PrincipioAttivo, F.NomeCommerciale
from Farmaco F inner join (
	select T.Farmaco
	from Terapia T
	group by T.Farmaco
	having count(distinct T.Patologia) = (
		select count(I.Patologia)
		from Indicazione I
		where I.Farmaco = T.Farmaco
	)
) as D on F.NomeCommerciale = D.Farmaco


--? Scrivere un trigger che impedisca l’inserimento di due terapie consecutive per lo stesso paziente,
--? caratterizzate dallo stesso farmaco, con una posologia superiore al doppio rispetto alla precedente.

drop trigger if exists trig;
delimiter $$
create trigger trig
before insert on Terapia for each row
begin
	declare ultima_data date default null;
    declare ultimo_farmaco char(50) default null;
    declare ultima_posologia int default null;
    
    set ultima_data = (
		select max(T.DataInizioTerapia)
        from Terapia T
        where T.Paziente = new.Paziente
    );
	set ultimo_farmaco = (
		select T.Farmaco
        from Terapia T
        where T.Paziente = new.Paziente
			and T.DataInizioTerapia = ultima_data
    );
	set ultima_posologia = (
		select T.Posologia
        from Terapia T
        where T.Paziente = new.Paziente
			and T.DataInizioTerapia = ultima_data
    );

	if(new.Farmaco = ultimo_farmaco and new.Posologia > 2 * ultima_posologia) then
		signal sqlstate '45000'
        set message_text = 'Terapia non consentita!';       
	end if;

end $$
delimiter ;


--? Al termine di Febbraio 2015, come ogni anno, le parcelle dei medici della clinica saranno aggiornate.
--? La percentuale di aumento della parcella di un medico è pari alla percentuale di terapie
--? prescritte dal medico nel 2014 che hanno condotto il paziente alla guarigione, rispetto a
--? tutte le terapie da egli/ella prescritte nello stesso anno. Assumere che il medico che
--? prescrive una terapia a un paziente sia il medico, la cui specializzazione è uguale al
--? settore medico della patologia oggetto della terapia, dal quale il paziente è stato visitato
--? da meno tempo prima dell’inizio della terapia stessa. Scrivere una stored procedure 
--? aggiorna_parcelle che prenda come argomento un anno (in questo caso il 2014) e aggiorni,
--? come descritto, la parcella di tutti i medici.
drop procedure if exists aggiorna_parcelle;
delimiter $$
create procedure aggiorna_parcella (in _anno int)
begin
drop temporary table if exists Successi;
create temporary table Successi (
	Matricola char(50) not null,
    TotSuccessi int not null,
    TotPrescrizioni int not null,
    primary key(Matricola)
);

insert into Successi
select D.Matricola, sum(D.Successo) as Successi, count(*) as TotPrescrizioni
from (
		select M.Matricola, if(year(E.DataGuarigione) = _anno, 1, 0) as Successo
		from Terapia T inner join Visita V on T.Paziente = V.Paziente
					   inner join Patologia PA on T.Patologia = PA.Nome
					   inner join Medico M on M.Specializzazione = PA.SettoreMedico
                       inner join Esordio E on E.DataEsordio = T.DataEsordio
											and E.Paziente = T.Paziente
                                            and E.Patologia = T.Patologia
		where year(T.DataInizioTerapia) = _anno
			and not exists (
				select *
				from Visita V2 inner join Medico M2 on V2.Medico = M2.Matricola
				where V2.Paziente = T.Paziente
					and M2.Specializzazione = M.Specializzazione
					and V2.Data between V.Data and T.DataInizioTerapia
			)
) as D
group by D.Matricola;

update Medico M natural join Successi S
set M.Parcella = M.Parcella + (S.TotSuccessi/S.TotPrescrizioni);

drop temporary table Successi;
	
end $$
delimiter ;
