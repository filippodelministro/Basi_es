--? Considerate le sole visite otorinolaringoiatriche, scrivere una query che restituisca il 
--? numero di pazienti, ad oggi maggiorenni, che sono stati visitati solo da otorini di 
--? Firenze durante il primo trimestre del 2015.
select count(distinct V.Paziente) as NumPazienti
from Paziente P inner join Visita V on V.Paziente = P.CodFiscale
				inner join Medico M on V.Medico = M.Matricola
where P.DataNascita < current_date() - interval 18 year
	and M.Specializzazione = 'Otorinolaringoiatria'
    and year(V.Data) = '2015' and month(V.Data) between 1 and 3
    and P.CodFiscale not in (
		select V.Paziente
		from Visita V inner join Medico M on V.Medico = M.Matricola
		where M.Specializzazione = 'Otorinolaringoiatria'
			and M.Citta <> 'Firenze'
			and year(V.Data) = '2015'
			and month(V.Data) between 1 and 3
)


--? Implementare una stored function therapy_failures()che riceva in ingresso il codice fiscale
--? di un paziente e il nome commerciale di un farmaco e restituisca, solo se esiste, il settore
--? medico con il più alto numero di terapie iniziate dal paziente nel mese scorso, terminate
--? senza guarigione nello stesso mese.


Con il continuo susseguirsi di nuovi contagi, la direzione della clinica si è resa recentemente disponibile a
prestare i suoi dati per analizzare i casi di meningite in pazienti toscani, in particolare, di Pisa e Firenze, che
si sono manifestati a partire dal mese di Ottobre 2015, nonostante tali pazienti si fossero sottoposti a vacci-
nazione con il farmaco Menjugate, nei sei mesi precedenti all’esordio. All’interno del database, le vaccina-
zioni per una patologia sono registrate come terapie legate a un esordio fittizio del paziente, avvenuto in da-
ta 0000-00-00, caratterizzato dalla patologia oggetto di vaccinazione. Per ogni nuovo caso di meningite
che coinvolge un paziente della clinica, il database contiene un normale esordio. Nell’analisi dei contagi,
per ogni caso di meningite, interessano la città di provenienza del paziente, la data di esordio e il numero di
giorni trascorsi dalla vaccinazione. Inoltre, per ogni caso, è importante conoscere il numero medio di giorni
trascorsi fra esordio e vaccinazione fino a quel momento, considerando i pazienti della stessa città. Questi
dati sono necessari alla casa farmaceutica Novartis (produttrice di Menjugate) per analisi statistiche sui
contagi e indagini eziologiche dell’acuirsi della virulenza della patologia. Si richiede di: i) creare uno snap-
shot contenente tutte le informazioni d’interesse per la casa farmaceutica; ii) popolare lo snapshot; iii) im-
plementare il deferred full refresh a cadenza settimanale.