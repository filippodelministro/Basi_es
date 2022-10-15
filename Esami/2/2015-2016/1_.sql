--? Scrivere una query che elimini tutti gli esordi di otite contratta e curata con successo
--? prima di cinque anni fa, relativi ai soli pazienti che hanno contratto nuovamente,
--? negli ultimi cinque anni, la stessa patologia.
delete E2.*
from Esordio E2 natural join (
	select *
	from Esordio E
	where E.Patologia = 'Otite' 	-- tutti i paz di Otite che la hanno curata 5 anni fa
		and E.DataGuarigione < current_date() - interval 5 year
		and exists (				-- per cui esiste un esordio di otite negli ultimi 5 anni
			select *
			from Esordio E1
			where E1.Paziente = E.Paziente
				and E1.Paziente = E.Patologia
				and E1.DataEsordio > current_date - interval 5 year
		)
)


--? Scrivere una query che, considerati i soli pazienti affetti da ipertensione cronica da
--? almeno dieci anni trattata al massimo con due farmaci diversi, indichi il nome commerciale
--? del farmaco mediamente più utilizzato per curare le altre patologie cardiache croniche.
--? In caso di pari merito, il risultato deve essere vuoto.
with
PazientiTarget as (
	select E.Paziente
	from Esordio E natural join Terapia T
	where E.Patologia = 'Ipertensione'
		and E.Cronica = 'si'
		and E.DataEsordio < current_date() - interval 10 year
	group by E.Paziente
	having count(distinct T.Farmaco) < 3
),
Utilizzi as (
	select T.Patologia, T.Farmaco, count(*) over (partition by T.Patologia, T.Farmaco) as Utilizzi
	from Terapia T natural join PazientiTarget PT
				   natural join Esordio E
				   inner join Patologia PA on E.Patologia = PA.Nome
	where E.Patologia <> 'Ipertensione'
		and PA.ParteCorpo = 'Cuore'
		and E.Cronica = 'si'
)

select U.Farmaco
from Utilizzi U
group by U.Farmaco
having avg(U.Utilizzi) > all (
	select avg(U1.Utilizzi)
    from Utilizzi U1
    where U1.Farmaco <> U.Farmaco
    group by U1.Farmaco
)

