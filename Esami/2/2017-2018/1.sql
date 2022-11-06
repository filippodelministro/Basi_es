--? Scrivere una query che per tutte le parti del corpo, ne restituisca il nome, il numero di pazienti
--? di Pisa attualmente affetti da patologie a carico di essa, e qual è stata fra tali patologie la
--? meno contratta dagli stessi pazienti negli ultimi 10 anni
--? In caso di ex aequo, restituire NULL.
with EsordiMinimi as (
	select E.Patologia, PA.ParteCorpo, count(*) as NumEsordi
	from Esordio E inner join Patologia PA on E.Patologia = PA.Nome
				   inner join Paziente P on E.Paziente = P.CodFiscale
	where E.DataEsordio > current_date() - interval 10 year
		and P.Citta = 'Pisa'
	group by E.Patologia, PA.ParteCorpo
	having count(*) < all (
		select count(*)
		from Esordio E1 inner join Patologia PA1 on E1.Patologia = PA1.Nome
						inner join Paziente P1 on E1.Paziente = P1.CodFiscale
		where E1.DataEsordio > current_date() - interval 10 year
			and E1.Patologia <> E.Patologia
			and P1.Citta = 'Pisa'
			and PA1.ParteCorpo = PA.ParteCorpo
		group by E1.Patologia
	) 
)

select D.*, EM.Patologia
from (
	select PA.ParteCorpo, count(*) as NumEsordiInCorso
	from Esordio E inner join Patologia PA on E.Patologia = PA.Nome
				   inner join Paziente P on E.Paziente = P.CodFiscale               
	where E.DataGuarigione is null
		and P.Citta = 'Pisa'
	group by PA.ParteCorpo
) as D left outer join EsordiMinimi EM on D.ParteCorpo = EM.ParteCorpo
										


--? Implementare una business rule che consenta l’inserimento di nuove terapie con farmaci a base
--? di pantoprazolo solo se esse iniziano a seguito di una visita con un gastroenterologo
--? effettuata dal paziente non oltre due settimane prima, e il paziente abbia assunto prima
--? dell’inizio della nuova terapia solo farmaci a base di pantoprazolo per la patologia oggetto
--? di tale terapia.
drop trigger if exists insert_pantoprazolo;
delimiter $$
create trigger insert_pantoprazolo
before insert on Terapia for each row
begin
	declare princ_attivo varchar(50) default null;
    
    set princ_attivo = (
		select F.PrincipioAttivo
        from Farmaco F
        where F.NomeCommerciale = new.Farmaco
    );
    
    if (princ_attivo = 'Pantoprazolo') then		-- solo se il farmaco si basa su panto
		if not exists (		-- se non esiste visita specialistica INTERROMPO
			select *
            from Visita V inner join Medico M on V.Medico = M.Matricola
            where M.Specializzazione = 'Gastroenterologia'
				and V.Paziente = new.Paziente
                and V.Data > new.DataInizioTerapia - interval 2 week                
        ) then
			signal sqlstate '45000'
            set message_text = 'insert_pantoprazolo: Non esiste visita con gastroenterologo!'; 
        end if;
		if not exists (		-- se esistono terapie con altro princ_attivo INTERROMPO
			select *
            from Terapia T inner join Farmaco F on F.NomeCommerciale = T.Farmaco
            where T.Paziente = new.Paziente
				and T.Patologia = new.Patologia
				and F.PrincipioAttivo <> 'Pantoprazolo'
        ) then
			signal sqlstate '45000'
            set message_text = 'insert_pantoprazolo: Esiste terapia con princ_attivo diverso dal Pantoprazolo!'; 
        end if;
        
    end if;
end $$
delimiter ;



--? All’interno di una campagna per la riduzione del prezzo dei farmaci antidolorifici e analgesici
--? da banco, la casa farmaceutica MENARINI ha recentemente iniziato un’indagine sull’utilizzo
--? dei suoi farmaci Fastum e Vivin C al fine di commercializzarne versioni alternative caratterizzate
--? da nuovi dosaggi e differente numero di pezzi a confezione. MENARINI richiede con cadenza
--? irregolare un resoconto aggiornato nel quale si analizza per fascia d’età dei pazienti, la
--? posologia che per ciascuno dei due farmaci è stata in grado di risolvere più esordi con un’unica
--? terapia, qual è lo scostamento medio tra la posologia della terapia e il dosaggio consigliato,
--? quanti esordi con la posologia consigliata e qual è il tempo medio di durata di un esordio 
--? considerando quelli conclusi con guarigione. Per entrambi i farmaci, si vuole trovare anche il
--? farmaco preso in abbinamento (prima o dopo) e ha portato a più guarigioni e qual è stata in
--? questo caso la posologia con la quale il farmaco della MENARINI è stato assunto. Inserire 
--? questi dati in una materialized view e implementare il partial incremental refresh in modalità
--? deferred con cadenza settimanale. Implementare anche una stored procedure per sincronizzare
--? la materialized view con i raw data.


