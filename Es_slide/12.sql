Argomenti:
    - Analytics
        · ranking
            · rank()   [desc] 
            · dense_rank()
        · windowing
    - over()
        · partition by
        · order by
        · --todo: window
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

