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


