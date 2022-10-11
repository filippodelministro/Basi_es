--? Scrivere una query che restituisca la dose giornaliera media dei farmaci
--? indicati per la cura di sole patologie intestinali.


--? Scrivere una query che restituisca, per il sesso maschile e per quello
--? femminile, rispettivamente, il numero di pazienti attualmente affetti da
--? ipertensione, trattata con lo stesso farmaco da più di venti anni.


--? Scrivere una query che, considerate le sole patologie muscolari, elimini gli
--? esordi conclusi con guarigione relativi a pazienti che hanno contratto, e
--? curato con successo, almeno due di tali patologie.

--? Eliminare esordi di sole patologie muscolari, che hanno una guarigione, di
--? pazienti che hanno già guarito due volte tali patologie



Negli ultimi mesi, la direzione della clinica è interessata al fenomeno della resistenza alle terapie per la pa-
tologia influenzale. I pazienti target sono gli anziani aventi più di ottanta anni, affetti da almeno due pato-
logie croniche. Dato un paziente target, interessano i suoi esordi di influenza degli ultimi tre anni. Conside-
rato un esordio i , sia T il numero di terapie effettuate per curarlo, e sia d ij la durata
� T della terapia j relativa
all’esordio i . La resistenza della patologia nell’esordio i è espressa da: r i = T 1 j=1 d ij . Supponendo che
gli esordi di influenza del paziente considerato siano E , se è r 1 < r 2 < · · · < r E , allora vi è una resistenza
ai farmaci per il trattamento dell’influenza, e il tasso di resistenza è quantificabile come
T DR = � E
r
2
i=1 (r i − r)
,
� E
dove r = E 1 i=1 r i . Scrivere una function per il calcolo del T DR , e il codice per il deferred full refresh
mensile di una materialized view contenente il codice fiscale di un paziente e il relativo T DR .