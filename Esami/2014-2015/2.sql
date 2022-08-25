Esercizio 1 (7 punti)
Scrivere una query che, considerate le sole terapie finalizzate alla cura di patologie cardiache, restituisca,
per ciascuna di esse, il nome della patologia e il farmaco più utilizzato per curarla. La soluzione proposta
deve presupporre che, data una patologia cardiaca, tale farmaco possa non essere unico.
Esercizio 2 (7 punti)
Scrivere una query che restituisca nome, cognome e reddito dei pazienti di sesso femminile che al 15 Giu-
gno 2010 risultavano affetti, oltre alle eventuali altre, da un’unica patologia cronica, con invalidità superio-
re al 50%, e non l’avevano mai curata con alcun farmaco fino a quel momento.
Esercizio 3 (9 punti)
Scrivere una query che restituisca, per tutte le patologie, nessuna esclusa, il nome della patologia e il nume-
ro di pazienti di età superiore a quarant’anni che l’hanno contratta almeno due volte, la seconda delle quali
con gravità superiore alla prima, comunque sempre in forma non cronica.
Esercizio 4 (10 punti)
Scrivere una stored procedure che, ricevuto in ingresso il codice fiscale di un paziente e il nome di un prin-
cipio attivo, blocchi immediatamente tutte le terapie attualmente in corso, impostando la data di fine terapia
alla data corrente, qualora si stiano protraendo per oltre una settimana, e il paziente abbia già effettuato in
precedenza, comunque non oltre sei mesi prima, almeno tre terapie con lo stesso farmaco o con un farmaco
contenente lo stesso principio attivo, di cui almeno una con posologia superiore a tre compresse al giorno.
Al termine delle elaborazioni, la procedura deve restituire, nonché mostrare a video, un resoconto conte-
nente le seguenti informazioni sulle terapie bloccate: codice fiscale del paziente, farmaco, durata della tera-
pia interrotta, posologia, numero di terapie precedenti con posologia superiore a tre compresse al giorno.