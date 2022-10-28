--? Considerata ciascuna città di provenienza dei medici, scrivere una query che restituisca il 
--? nome della città, il numero di pazienti che sono stati visitati dal medico di tale città che 
--? ne ha visitati di più rispetto agli altri medici della stessa città, e la matricola di tale 
--? medico. In caso di pari merito, restituire tutti gli ex aequo.


--? Aggiungere un attributo booleano DirittoEsenzione alla tabella ESORDIO contenente true se
--? il paziente ha contratto nella vita tutte le patologie con invalidità inferiore al 20%
--? relative allo stesso settore medico della patologia dell’esordio, ma mai con gravità superiore
--? a quella della patologia dell’esordio. Implementare poi il trigger che imposta l’attributo
--? DirittoEsenzione all’atto dell’inserimento di un nuovo esordio.


--? Con l’arrivo dell’estate, l’incidenza e la gravità degli episodi d’insonnia tendono ad acuirsi.
--? Si stima che tre persone su cinque soffrano di tale patologia nel periodo estivo. Per 
--? combatterla, un numero considerevole di persone si affida a rimedi alternativi. Quando però
--? la patologia riduce la qualità della vita, il ricorso ai farmaci tradizionali diviene inevitabile.
--? Relativamente alle città in cui la stima della casistica risulta quest’anno verificata, si
--? desidera produrre un report relativo ai farmaci EN e Tavor, tipicamente usati per trattare
--? l’insonnia di una certa entità. Il report è contenuto in una materialized view REPORT_INSONNIA .
--? Ogni record contiene il nome della città, il numero di casi d’insonnia ivi in corso, il numero 
--? totale di casi ivi registrati dall’inizio dell’estate, il nome di uno dei due farmaci oggetto
--? del report e un indicatore di efficacia definito come, dove è il farmaco, è l’insieme delle
--? terapie basate su , mentre e rappresentano posologia e durata, rispettivamente. Si richiede di:
--?     i) effettuare il build della materialized view al 1° Giugno 2016;
--?     ii) scrivere il codice per la gestione della log table;
--?     iii) implementare l’incremental refresh di tipo partial, in modalità on demand.
--? T f
--? f p i d i
--? feff icacia f = P
--? i2T f p i d i / P
--? i2T f p i


-- creo tabella del report
CREATE TABLE REPORT_INSONNIA(		
	Citta CHAR(50) NOT NULL,
     CasiInCorso INT,
     CasiRegistrati INT,
     Farmaco CHAR(50) NOT NULL,
     Efficacia FLOAT,
     PRIMARY KEY(Citta)
) ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- procedura per il calcolo dell'efficacia
DROP PROCEDURE IF EXISTS Calcola_Efficacia;
DELIMITER $$
CREATE PROCEDURE Calcola_Efficacia(IN _farmaco CHAR(50))
	BEGIN
		DECLARE _efficacia FLOAT DEFAULT 0;
          DECLARE finito INT DEFAULT 0;
          DECLARE _posologia INT DEFAULT 0;
          DECLARE _durata INT DEFAULT 0;
          DECLARE _num INT DEFAULT 0;
          DECLARE _den INT DEFAULT 0;
          
          DECLARE scanTerapie CURSOR FOR(
			SELECT T.Posologia, DATEDIFF(T.DataInizioTerapia, T.DataInizioTerapia) AS Durata
               FROM Terapia T
               WHERE T.Farmaco = _farmaco
				AND T.DataFineTerapia IS NOT NULL
          );
          
          DECLARE CONTINUE HANDLER FOR NOT FOUND
			SET finito = 1;
               
		OPEN scanTerapie;
          ciclo: LOOP
			FETCH scanTerapie INTO _posologia, _durata;
               IF finito = 1 THEN
				LEAVE ciclo;
			ELSE
				SET _num = _num + _posologia * _durata;
                    SET _den = _den + _posologia;
               END IF;
          END LOOP;
          CLOSE scanTerapie;
          
          SELECT _num / _den;
     END $$
DELIMITER ;


-- popolo la tabella del report (a partire da data indicata)
INSERT INTO REPORT_INSONNIA(
	SELECT DISTINCT P.Citta, (
			SELECT COUNT(*)
               FROM Esordio E
				INNER JOIN
                    Paziente P1 ON E.Paziente = P1.CodFiscale
               WHERE P1.Citta = P.Citta
				AND E.Patologia = 'Insonnia'
                    AND E.DataGuarigione IS NULL
          ) AS CasiInCorso, (
			SELECT COUNT(*)
               FROM Esordio E
				INNER JOIN
                    Paziente P1 ON E.Paziente = P1.CodFiscale
               WHERE P1.Citta = P.Citta
				AND E.Patologia = 'Insonnia'
                    AND E.DataEsordio > '2016-06-21'	-- inizio estate 
		) AS CasiRegistrati,
		'Tavor',
          Calcola_Efficacia('Tavor')
     FROM Paziente P
);


-- LOG: salvo attraverso trigger ogni volta che si inserisce in Esorido
-- salvanto solamente i pazienti nuovi perchè mi interessa solo il numero di
-- pazienti
CREATE TABLE REPORT_INSONNIA_LOG(
	Istante TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
     Paziente CHAR(50) NOT NULL,
     PRIMARY KEY(Istante)
) ENGINE = InnoDB DEFAULT CHARSET = latin1;

DROP TRIGGER IF EXISTS Refresh_Log_REPORT_INSONNIA;
DELIMITER $$
CREATE TRIGGER Refresh_Log_REPORT_INSONNIA
AFTER INSERT ON Esordio FOR EACH ROW
	BEGIN
		INSERT INTO REPORT_INSONNIA_LOG(Paziente) VALUES(NEW.Paziente);
     END $$
DELIMITER ;


-- partial incremental refresh on demand: si fa con una procedura in cui viene indicata la data di
-- soglia fino a cui refreshare; 
DROP PROCEDURE IF EXISTS Partial_Incremental_Refresh_REPORT_INSONNIA;
DELIMITER $$
CREATE PROCEDURE Partial_Incremental_Refresh_REPORT_INSONNIA(IN _soglia TIMESTAMP)
	BEGIN
		DECLARE _paziente CHAR(50) DEFAULT '';
          DECLARE _istante TIMESTAMP DEFAULT '0000-00-00 00:00:00';
          DECLARE finito INTEGER DEFAULT 0;
          
          -- fa scansione del LOG 
          DECLARE scanLog CURSOR FOR(
			SELECT Istante, Paziente
               FROM REPORT_INSONNIA_LOG
          );
          
          DECLARE CONTINUE HANDLER FOR NOT FOUND
			SET finito = 1;
               
		OPEN scanLog;
          ciclo: LOOP
			FETCH scanLog INTO _istante, _paziente;
               IF finito = 1 THEN
				LEAVE ciclo;
			ELSE 
                -- aggiorna solo fino al timestamp di soglia
				IF _istante <= _soglia THEN
					UPDATE REPORT_INSONNIA
                         SET CasiInCorso = CasiInCorso + 1,     -- incrementa i casi
						CasiRegistrati = CasiRegistrati + 1,    
						Efficacia = Calcola_Efficacia('Tavor')
					WHERE Citta = (
						SELECT P.Citta
						FROM Paziente P
                              WHERE P.CodFiscale = _paziente
					);

                -- elimina dal LOG quelli appena aggiornati                         
					DELETE FROM REPORT_INSONNIA_LOG
                         WHERE Istante = _istante;
                         
                         SELECT 'Aggiornamento completato.' AS Messaggio;
                    END IF;
               END IF;
          END LOOP;
          CLOSE scanLog;
     END $$
DELIMITER ;
