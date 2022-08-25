Esercizio 1 (7 punti)
Scrivere una query che restituisca il nome commerciale di ciascun farmaco utilizzato da almeno un pazien-
te per curare tutte le patologie per le quali è indicato.
Esercizio 2 (7 punti)
Scrivere una query che restituisca il numero di pazienti visitati solo da medici specializzati in cardiologia o
neurologia, almeno due volte per ciascuna delle due specializzazioni. Si scriva la query senza usare viste.
Esercizio 3 (9 punti)
Creare una business rule che permetta di inserire un nuovo farmaco F e le relative indicazioni, qualora non
vi siano già più di due farmaci di cui almeno uno basato sullo stesso principio attivo, aventi, ciascuno,
un’indicazione per una stessa patologia per la quale F è indicato. Supporre che per prima cosa sia inserito il
farmaco, dopodiché siano inserite le varie indicazioni.
Esercizio 4 (10 punti)
Un paziente effettua una visita di accertamento quando, dopo essere stato visitato inizialmente da un medi-
co, desidera avere anche il parere di un altro medico della stessa specializzazione, dal quale si fa visitare
senza iniziare, nel frattempo, alcuna terapia per la cura di patologie inerenti tale specializzazione. In gene-
rale, dopo una visita iniziale, un paziente può effettuare più visite di accertamento, posticipando ulterior-
mente l’inizio della terapia. Creare una materialized view A CCERTAMENTO contenente codice fiscale, nome
e cognome dei pazienti che, nell’ultimo trimestre, relativamente ad almeno una visita iniziale, hanno effet-
tuato una o più visite di accertamento, quante ne hanno effettuate per ogni visita iniziale, e il cognome del
medico che ha effettuato tale visita iniziale. Gestire la materialized view mediante deferred refresh con ca-
denza trimestrale.