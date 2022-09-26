--?Calcolo età
select year(current_date) - year(P.DataNascita) as Età
from Paziente P

--==================================================================================

--? Parcella minima e chi la detiene per ogni specializzazione      //USO DERIVED TABLE
select M.Specializzazione, D.ParcellaMinima, M.Cognome
from Medico M natural join (
		select M1.Specializzazione, min(M1.Parcella) as ParcellaMinima
        from Medico M1
        group by M1.Specializzazione 
)as D
where M.Parcella = D.ParcellaMinima

--? Costo totale delle terapie (d'insonnia), esenzione compresa
select 
        (floor(
            (
                datediff(                                               -- conto i giorni di Terapia
                        ifnull(T.DataFineTerapia, current_date()),      -- se non è terminata, fino ad oggi
                        T.DataInizioTerapia
                        ) * T.Posologia         -- moltiplico per posologia e trovo num pasticche totali
            ) / F.Pezzi)                -- divido per per Pezzi per sapere numero di scatole
        + 1)                            -- ne prendo la parte intera più uno (0,6 -> 1)
        * F.Costo                       -- moltiplico per costo, e viene il costo totale
        * (100 - P.PercEsenzione) / 100       -- levo esenzione
from Terapia T inner join Farmaco F on T.Farmaco = F.NomeCommerciale
			   inner join Patologia P on T.Patologia = P.Nome
where T.Patologia = 'Insonnia'