--? Nome e Cognome dei pazienti che hanno una terapia, ma nessuna visita
select P.*
from Paziente P inner join Terapia T on P.CodFiscale = T.Paziente
				left outer join Visita V on T.Paziente = V.Paziente
where V.Paziente is null