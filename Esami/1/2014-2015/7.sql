--todo: ======================================================================
--? Scrivere una query che restituisca nome e cognome del medico che, al 31/12/2014, 
--? aveva visitato un numero di pazienti superiore a quelli visitati da ciascun medico 
--? della sua stessa specializzazione.
--todo: ======================================================================


--? Scrivere una query che restituisca per ciascun principio attivo, il nome del principio
--? attivo e il nome commerciale di ogni farmaco utilizzato almeno una volta per tutte
--? le patologie per le quali è indicato. Il risultato è formato da 
--? row(PrincipioAttivo , NomeCommerciale ), una per ogni farmaco che rispetta la condizione.

Scrivere un trigger che impedisca l’inserimento di due terapie consecutive per lo stesso paziente, caratteriz-
zate dallo stesso farmaco, con una posologia superiore al doppio rispetto alla precedente.

Al termine di Febbraio 2015, come ogni anno, le parcelle dei medici della clinica saranno aggiornate. La
percentuale di aumento della parcella di un medico è pari alla percentuale di terapie prescritte dal medico
nel 2014 che hanno condotto il paziente alla guarigione, rispetto a tutte le terapie da egli/ella prescritte nel-
lo stesso anno. Assumere che il medico che prescrive una terapia a un paziente sia il medico, la cui specia-
lizzazione è uguale al settore medico della patologia oggetto della terapia, dal quale il paziente è stato visi-
tato da meno tempo prima dell’inizio della terapia stessa.
Scrivere una stored procedure aggiorna_parcelle che prenda come argomento un anno (in questo ca-
so il 2014) e aggiorni, come descritto, la parcella di tutti i medici.