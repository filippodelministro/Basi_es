--? Per valutare il dimensionamento del personale, la direzione della clinica è interessata a
--? conoscere, per ogni medico, nessuno escluso, il numero di volte in cui non ha effettuato
--? visite per un'intera settimana (dal lunedì al venerdì), in ogni mese, nessuno escluso, 
--? unitamente alla percentuale di visite effettuate dal medico in quel mese, rispetto al 
--? totale di visite effettuate nello stesso mese dai medici della sua specializzazione. 

--? Creare una materialized view ReportVisite per contenere queste informazioni. Scrivere 
--? poi il codice per l'incremental refresh in modalità deferred, con cadenza semestrale. 

--? La funzione dayofweek(d) restituisce il giorno della settimana di una data d, da 1 (
--? domenica) a 7 (sabato).



create or replace view VisiteMedico as(
		select V.Medico, M.Specializzazione, year(V.Data) as Anno, month(V.Data) as Mese, count(*) as NumVisite
		from Visita V inner join Medico M on V.Medico = M.Matricola
		group by V.Medico, year(V.Data), month(V.Data) 
);
create or replace view VisiteSpec as (
		select V.Medico, M.Specializzazione, year(V.Data) as Anno, month(V.Data) as Mese, count(*) as NumVisite
		from Visita V inner join Medico M on V.Medico = M.Matricola
		group by V.Medico, M.Specializzazione, year(V.Data), month(V.Data) 
);
create or replace view  VisiteRiassunto as (
		select VM.Medico, VM.Anno, VM.Mese, VM.NumVisite as NumVisiteMed, VS.NumVisite as NumVisiteSpec
		from VisiteMedico VM inner join VisiteSpec VS on VM.Specializzazione = VS.Specializzazione
);
create or replace view  SettimaneVuote as (
		select D.Medico, D.Anno, D.Mese, count(*) as NumSettimane
		from (
				-- medici che hanno settimane senza visita
				select V.Medico, year(V.Data) as Anno, month(V.Data) as Mese, week(V.Data) as Settimana
				from Visita V
				where dayofweek(V.Data) <> 1
					and dayofweek(V.Data) <> 7
				group by V.Medico, year(V.Data), month(V.Data), week(V.Data)
				having count(*) < 1
		) as D
		group by D.Medico, D.Anno, D.Mese
);

drop table if exists ReportVisite;
delimiter $$
create table if not exists ReportVisite(
	Medico char(50),
    Anno int,
    Mese int,
    NumVisiteMed int,
    NumVisiteSpec int,
    SettimaneVuote int,
    
    primary key (Medico, Anno, Mese)
)Engine=InnoDB default charset = latin1;
begin
	insert into ReportVisite
		select VR.*, ifnull(NumSettimane, 0) as SettimaneVuote
		from VisiteRiassunto VR left outer join SettimaneVuote SV on VR.Medico = SV.Medico
																  and VR.Anno = SV.Anno
																  and VR.Mese = SV.Mese;
end $$
delimiter ;

/*
create event nome_event
on schedule every 6 month
do
	update ReportVisite R
     -- [...]
*/

