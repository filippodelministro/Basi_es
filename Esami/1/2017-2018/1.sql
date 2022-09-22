--? Scrivere una query che per tutte le parti del corpo, ne restituisca il nome, il numero di pazienti
--? di Pisa attualmente affetti da patologie a carico di essa, e qual è stata fra tali patologie la
--? meno contratta dagli stessi pazienti dall’inizio dell’anno in corso al termine del mese scorso.
--? In caso di ex aequo, restituire NULL.


--? Implementare una business rule che consenta l’inserimento di nuove terapie con farmaci a base
--? di pantoprazolo solo se esse iniziano a seguito di una visita con un gastroenterologo
--? effettuata dal paziente non oltre due settimane prima, e il paziente abbia assunto prima
--? dell’inizio della nuova terapia solo farmaci a base di pantoprazolo per la patologia oggetto
--? di tale terapia.


--? All’interno di una campagna per la riduzione del prezzo dei farmaci antidolorifici e analgesici
--? da banco, la casa farmaceutica M ENARINI ha recentemente iniziato un’indagine sull’utilizzo
--? dei suoi farmaci Fastum e Vivin C al fine di commercializzarne versioni alternative caratterizzate
--? da nuovi dosaggi e differente numero di pezzi a confezione. MENARINI richiede con cadenza
--? irregolare un resoconto aggiornato nel quale si analizza per fascia d’età dei pazienti, la
--? posologia che per ciascuno dei due farmaci è stata in grado di risol vere più esordi con un’unica
--? terapia, qual è lo scostamento medio tra la posologia della terapia e il dosaggio consigliato,
--? quanti esordi con la posologia consigliata e qual è il tempo medio di durata di un esordio 
--? considerando quelli conclusi con guarigione. Per entrambi i farmaci, si vuole trovare anche il
--? farmaco preso in abbinamento (prima o dopo) e ha portato a più guarigioni e qual è stata in
--? questo caso la posologia con la quale il farmaco della M ENARINI è stato assunto. Inserire 
--? questi dati in una materialized view e implementare il partial incremental refresh in modalità
--? deferred con cadenza settimanale. Implementare anche una stored procedure per sincronizzare
--? la materialized view con i raw data.