--? Scrivere una query che restituisca le patologie gastriche che, in pazienti di età compresa fra 40 e 50 anni
--? (entrambi compiuti), negli ultimi 20 anni, si sono manifestate una o più volte, ma solo d'estate
select distinct E.Patologia
from Esordio E
where E.Paziente in (
	select P.CodFiscale
    from Paziente P
    where current_date between P.DataNascita + interval 40 year and P.DataNascita + interval 50 year 
)
	and E.Patologia in (
		select PA.Nome
		from Patologia PA
		where PA.SettoreMedico = 'Gastroenterologia'
)
	and E.DataEsordio > current_date() - interval 20 year
    and month(E.DataEsordio) between 6 and 8				-- solo d'estate


--? Implementare un analytic function efficiente (tramite select statement con var user defined) che, dato un
--? farmaco, ne restituisca il nome commerciale e il codice fiscale del primo paziente che lo ha utilizzato
drop function if exists primo_paziente;
delimiter $$
create function primo_paziente(
	_farmaco char(50)
)
returns char(50) deterministic
begin
	declare ret char(50) default null;
    
	select T.Paziente
	from Terapia T
	where T.Farmaco = 'Lyrica'
	order by T.DataInizioTerapia
	limit 1
		into ret;

	return ret;
end $$
delimiter ;


--? Il tasso di incidenza della patologie è un informazione di vitale importanza. E' soprattutto grazie al suo
--? monitoraggio che il MdS riesca a identificare trend di contagio, consentendo una gestione tempestiva delle
--? criticità e una sensibilizzazione sempre più efficace, oggi agevlata dalla risonanza dei moderni social media.
--? In un contesto come questo, si richiede di dotare il DB della clinica di una MV TASSO_INCIDENZA contentente,
--? per patologia e città, il nome della patologia, il nome della città e il tasso di incidenza stagionale, 
--? degli ultmi 20 anni, ciascuno in una colonna. Il tasso di incidenza stagionale di una patologia P in una
--? città C nella stagione S si esprime come
--? 		J = (A_p,c,s/N_c)^k
--? 			· A_p,c,s : numero di pazienti per città C che hanno contratto patologia P in S
--? 			· N_c     : numero di pazienti per città C
--? 			· k = E_p,c,s/A_p,c,s se A_p,c,s != 0, altrimenti = 1
--? 			· E_p,c,s : numero di esordi della patologia P in C in S
--? 
--? Implementare stored function per calcolo incidenza stagionale  			

