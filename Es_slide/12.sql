Argomenti:
    - Analytics
        · ranking
            · rank()   [desc] 
            · dense_rank()
        · windowing
            · lead(), lag()
    - over()
        · partition by
        · order by
        · window
    - CTE

--*==================================================================================
--*									ES SLIDE										
--*==================================================================================

--? Scrivere una query che indichi, per ogni cardiologo, la matricola, la 
--? parcella, e la parcella media della sua specializzazione
select M.Matricola, M.Parcella, avg(M.Parcella) over()  -- fa la media delle parcella sulla partizione
from Medico M                                           -- che in questo caso è dei Cardiologi
where M.Specializzazione = 'Cardiologia'


--? Scrivere una query che indichi, per ogni medico, la matricola, la
--? specializzazione la parcella, e la parcella media della sua specializzazione
select M.Matricola, M.Specializzazione, M.Parcella, 
        avg(M.Parcella) over(
                            partition by M.Specializzazione
                            ) as MediaSpec
from Medico M


--? Assegnare un numero a ogni medico nella sua specializzazione
select M.Matricola, M.Specializzazione, 
        row_number() over(
                            partition by M.Specializzazione
                         ) as num
from Medico M


--? Effettuare una classifica della convenienza dei medici dipendentemente dalla
--? loro parcella. Restituire matricola, cognome, e posizione in classifica.
select M.*,
		rank() over(order by M.Parcella ) as Convenienza
from Medico M

select M.*,
		rank() over(
                    partition by M.Specializzazione, -- partizionati per Spec
                    order by M.Parcella              -- oridinati per Parcella
                ) as Convenienza
from Medico M

--? Effettuare una classifica dei medici di ogni specializzazione
--? dipendentemente dalla loro parcella, partendo dalla più alta. Restituire
--? matricola, cognome, specializzazione, parcella e posizione nella classifica.
-- definisco la window su cui lavora il rank in un secondo momento
select M.Matricola, M.Cognome, M.Specializzazione, rank() over w
from Medico M
window w as (partition by M.Specializzazione order by M.Parcella desc);


--? Restituire, per ciascuna visita, matricola del medico, codice fiscale del paziente,
--? data, e data della visita successiva del paziente con un medico della stessa 
--? specializzazione
--intopata con il case perchè più carina    
select V.Medico, V.Paziente, V.Data, M.Specializzazione, 
                             (case
								when (lead(V.Data) over(partition by V.Paziente, M.Specializzazione)) is null then '\t--'
                                else lead(V.Data) over(partition by V.Paziente, M.Specializzazione)
                             end
                             ) as successiva
from Visita V inner join Medico M on V.Medico = M.Matricola


--? Per ogni medico, restituire la sua matricola, il cognome, la parcella, e la
--? percentuale di medici con parcella minore o uguale


--*==================================================================================
--*									ALTRE										
--*==================================================================================
--? indicare, per ogni paziente, la sua ultima Visita e la sua penultima
select V1.Paziente, max(V2.Data) as Ultima, max(V1.Data) as Penultima
from Visita V1 inner join Visita V2 on V1.Paziente = V2.Paziente
									and V1.Data < V2.Data
where V1.Data not in(
		select max(V.Data)
		from Visita V
		where V.Paziente = V1.Paziente
)
group by V1.Paziente



