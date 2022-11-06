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

--? Medico che ha fatto più visite per ogni specializzazione
--! questo NON mette gli ex-aequo nel result set
select V.Medico, M.Specializzazione, count(*) as NumVisite
from Visita V inner join Medico M on V.Medico = M.Matricola
group by V.Medico
having count(*) > all (
	select count(*)
    from Visita V1 inner join Medico M1 on V1.Medico = M1.Matricola
    where M1.Specializzazione = M.Specializzazione
		and V1.Medico <> V.Medico
    group by V1.Medico
)

--! questo mette gli ex-aequo nel result set    (cambia l'= nell subquery)
select V.Medico, M.Specializzazione, count(*) as NumVisite
from Visita V inner join Medico M on V.Medico = M.Matricola
group by V.Medico
having count(*) >= all (
	select count(*)
    from Visita V1 inner join Medico M1 on V1.Medico = M1.Matricola
    where M1.Specializzazione = M.Specializzazione
		-- and V1.Medico <> V.Medico   questo non serve
    group by V1.Medico
)


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


--? Conta per ogni medico il numero di terapie con Guarigione e il numero totale di terapie
--? prescritte: considera il medico che prescrive come l'ultimo ad aver visitato nella
--? stessa specializzazione
select M.Matricola, if(year(E.DataGuarigione) = _anno, 1, 0) as Successo    -- in questo caso aggiunge se la guarigione è nello stesso anno
		from Terapia T inner join Visita V on T.Paziente = V.Paziente
					   inner join Patologia PA on T.Patologia = PA.Nome
					   inner join Medico M on M.Specializzazione = PA.SettoreMedico
                       inner join Esordio E on E.DataEsordio = T.DataEsordio
											and E.Paziente = T.Paziente
                                            and E.Patologia = T.Patologia
		where year(T.DataInizioTerapia) = _anno      -- data una V.Data e una T.DataInizioTerapia, non deve esistere
			and not exists (                         -- una seconda visita compresa tra le due date, dello stesso paziente
				select *                             -- con un medico della stessa specializzazione
				from Visita V2 inner join Medico M2 on V2.Medico = M2.Matricola
				where V2.Paziente = T.Paziente
					and M2.Specializzazione = M.Specializzazione
					and V2.Data between V.Data and T.DataInizioTerapia
			)