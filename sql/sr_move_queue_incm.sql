use asupcouk_asup;
Drop procedure if exists sr_move_queue_incm;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE
PROCEDURE  asupcouk_asup . sr_move_queue_incm  (sr_gameno INT)
BEGIN
sproc:BEGIN

-- Set up default income orders
-- $Id: sr_move_queue_incm.sql 242 2014-07-13 13:48:48Z paul $
DECLARE proc_name TEXT DEFAULT "SR_MOVE_QUEUE_INCM";
DECLARE sr_turnno INT DEFAULT 0;
DECLARE sr_phaseno INT DEFAULT 0;
DECLARE sr_userno INT;
DECLARE sr_mia INT;
DECLARE sr_balance INT;
DECLARE sr_incm INT;
DECLARE sr_pay_bank INT;
DECLARE sr_pay_comp INT;
DECLARE sr_pay_min_troops INT;
DECLARE sr_pay_all_troops INT;
DECLARE done INT DEFAULT 0;
DECLARE sr_order_xml TEXT DEFAULT '<PAYSALARIES>';
DECLARE sr_terrno INT DEFAULT 0;
DECLARE sr_terrname TEXT DEFAULT '';
DECLARE sr_major INT DEFAULT 0;
DECLARE sr_boomer INT DEFAULT 0;
DECLARE sr_minor INT DEFAULT 0;
DECLARE sr_cardno INT DEFAULT 0;
DECLARE sr_running CHAR(1);
DECLARE sr_restart_cost INT DEFAULT 0;
DECLARE sr_paid INT DEFAULT 0;
DECLARE sr_bond CHAR(1) DEFAULT 'N';
DECLARE sr_boomerno INT Default 0;
DECLARE sr_boomer_terrname TEXT;
DECLARE sr_boomer_terrno INT Default 0;
DECLARE sr_boomer_nukes INT Default 0;
DECLARE sr_boomer_neutron INT Default 0;
DECLARE sr_boomer_visible CHAR(1) Default 'N';
DECLARE sr_phase2_type TEXT;

DECLARE new_bal CURSOR FOR
Select userno
       ,mia
       ,cash
       ,(sup_terrs*200)+(terrs-sup_terrs)*100+sea_terrs*50
       ,interest
       ,active_comps*50
       ,forces*10
       ,troops*10
       ,boomer_money
From tmp_incm
;

DECLARE terrs CURSOR FOR
Select b.terrno, terrname, Case When Length(terrtype)=3 Then major Else 0 End
                         , Case When Length(terrtype)!=3 Then major Else 0 End
						 , minor
From sp_board b
Left Join sp_places p
On b.terrno=p.terrno
Where gameno=sr_gameno
 and userno=sr_userno
Order By major desc, minor desc;

DECLARE comps CURSOR FOR
Select c.cardno, running
From sp_cards c, sp_res_cards rc
Where gameno=sr_gameno
 and userno=sr_userno
 and c.cardno=rc.cardno
Order by res_amount desc;

DECLARE boomers CURSOR FOR
Select boomerno, bm.terrno, terrname, nukes, neutron, visible
From sp_boomers bm
Left Join sp_places pl On bm.terrno=pl.terrno
Where gameno=sr_gameno
 and userno=sr_userno
Order By boomerno;

DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

-- Check game is valid
IF (sr_gameno not in (Select gameno From sp_game Where phaseno!=9)) THEN
    Insert Into sp_old_orders (gameno, ordername, order_code)
    Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Invalid game or phase</Reason><Game>",sr_gameno,"</Game></FAIL>"));
    LEAVE sproc;
END IF;
Select turnno, phaseno, phase2_type Into sr_turnno, sr_phaseno, sr_phase2_type From sp_game Where gameno=sr_gameno;

-- Get income and costs from board
Drop Temporary Table If Exists tmp_incm;
Create Temporary Table tmp_incm As
Select r.userno
       ,Max(r.cash) As cash
       ,Max(r.interest) As interest
       ,Sum(Length(p.terrtype)=4) As terrs
       ,Count(r2.userno) As sup_terrs
       ,Sum(minor+major) As troops
       ,Sum((minor+major)>0) As forces
       ,c.comps
       ,c.active_comps
       ,Max(r.mia) as mia
       ,Sum(Length(p.terrtype)=3) As sea_terrs
       ,r.boomer_money
From sp_resource r
Left Join sp_board b On r.gameno=b.gameno and r.userno=b.userno
Left Join sp_places p On b.terrno=p.terrno
Left Join sp_powers w On p.terrtype=w.terrtype
Left Join sp_resource r2 On r2.gameno=r.gameno and w.powername=r2.powername
Left Join (Select userno, Count(cardno) as comps, Sum(running='Y') as active_comps From sp_cards Where gameno=sr_gameno Group By userno) c
 On c.userno=r.userno
Where r.gameno=sr_gameno
 and r.dead = 'N'
Group By r.userno, r.boomer_money
;

IF @sr_debug!='N' THEN
    Select *, "Initial Incm" from tmp_incm;
END IF;

-- Work out orders for each Superpower
OPEN new_bal;
read_loop: LOOP
    FETCH FROM new_bal INTO sr_userno, sr_mia, sr_balance, sr_incm, sr_pay_bank, sr_pay_comp, sr_pay_min_troops, sr_pay_all_troops, sr_bond;
    IF done THEN LEAVE read_loop; END IF;
    Set sr_order_xml = Concat('<PAYSALARIES>'
                             ,sf_fxml('Income',Concat(sf_fxml('Credit',sr_incm),sf_fxml('BondValue',Case When sr_bond='N' and sr_turnno >= 3 Then (sr_turnno-3)*500+2000 Else 0 End)))
                             ,sf_fxml('Balance',sf_fxml('Credit',sr_balance))
                             );

    -- Pay bank loan
    IF sr_balance+sr_incm >= sr_pay_bank THEN
        Set sr_order_xml = Concat(sr_order_xml
                                 ,'<PayBank>'
                                 ,sf_fxml('Outstanding',sr_pay_bank)
                                 ,sf_fxml('Cost',sr_pay_bank)
                                 ,sf_fxml('Repay','0')
                                 ,Case When sr_bond='Y' Then sf_fxml('Bond','X') Else sf_fxml('Bond','N') End
                                 ,'</PayBank>'
                                 );
        Set sr_paid = sr_pay_bank;
    ELSE
        Set sr_order_xml = Concat(sr_order_xml
                                 ,'<PayBank>'
                                 ,sf_fxml('NotPaid','Y')
                                 ,sf_fxml('Outstanding',sr_pay_bank)
                                 ,sf_fxml('Cost','0')
                                 ,sf_fxml('Repay','0')
                                 ,Case When sr_bond='Y' Then sf_fxml('Bond','X') Else sf_fxml('Bond','N') End
                                 ,'</PayBank>'
                                 );
        Set sr_paid = 0;
    END IF;

    -- Add to XML to pay troops while there is still money...
    OPEN terrs;
    inner_loop: LOOP
        FETCH FROM terrs INTO sr_terrno, sr_terrname, sr_boomer, sr_major, sr_minor;
        IF done THEN Set done=0; LEAVE inner_loop; END IF;
        -- Pay everyone if there is enough money
        IF sr_balance+sr_incm-sr_paid >= (sr_major+sr_minor)*10 THEN
            Set sr_order_xml = Concat(sr_order_xml
                                     ,'<PayTroops>'
                                     ,sr_terrname
                                     ,sf_fxml('Terrno',sr_terrno)
                                     ,sf_fxml('Boomers',sr_boomer)
                                     ,sf_fxml('Major',sr_major)
                                     ,sf_fxml('Minor',sr_minor)
                                     ,sf_fxml('Outstanding',(sr_major+sr_minor)*10)
                                     ,sf_fxml('Cost',(sr_major+sr_minor)*10)
                                     ,'</PayTroops>'
                                     );
            Set sr_paid = sr_paid + (sr_major+sr_minor)*10;
        ELSEIF sr_balance+sr_incm-sr_paid >= sr_major or sr_minor THEN
            Set sr_order_xml = Concat(sr_order_xml
                                     ,'<PayTroops>'
                                     ,sr_terrname
                                     ,sf_fxml('Terrno',sr_terrno)
                                     ,sf_fxml('Boomers',sr_boomer)
                                     ,sf_fxml('Major',Case When sr_major>0 Then 1 Else 0 End)
                                     ,sf_fxml('Minor',Case When sr_minor>0 and sr_major=0 Then 1 Else 0 End)
                                     ,sf_fxml('Outstanding',(sr_major+sr_minor)*10)
                                     ,sf_fxml('Cost',(sr_major or sr_minor)*10)
                                     ,'</PayTroops>'
                                     );
            Set sr_paid = sr_paid+10;
        ELSE
            Set sr_order_xml = Concat(sr_order_xml
                                     ,'<PayTroops>'
                                     ,sr_terrname
                                     ,sf_fxml('Terrno',sr_terrno)
                                     ,sf_fxml('Boomers',sr_boomer)
                                     ,sf_fxml('Major',0)
                                     ,sf_fxml('Minor',0)
                                     ,sf_fxml('Outstanding',(sr_major+sr_minor)*10)
                                     ,sf_fxml('Cost',0)
                                     ,'</PayTroops>'
                                     );
        END IF;
    END LOOP;
    CLOSE terrs;

    -- Add to XML to pay all companies
    Select company_restart_cost Into sr_restart_cost From sp_game Where gameno=sr_gameno;
    OPEN comps;
    inner_loop: LOOP
        FETCH FROM comps INTO sr_cardno, sr_running;
        IF done THEN Set done=0; LEAVE inner_loop; END IF;
        IF sr_balance+sr_incm-sr_paid >= 50 THEN
            Set sr_order_xml = Concat(sr_order_xml
                                     ,'<PayCompany>'
                                     ,sf_fxml('Cardno',sr_cardno)
                                     ,sf_fxml('Running',sr_running)
                                     ,sf_fxml('Outstanding',Case When sr_running='Y' Then 50 Else 50+sr_restart_cost End)
                                     ,sf_fxml('Cost',Case When sr_running='Y' Then 50 Else 0 End)
                                     ,'</PayCompany>'
                                     );
            Set sr_paid = sr_paid + Case When sr_running='Y' Then 50 Else 0 End;
        ELSE
            Set sr_order_xml = Concat(sr_order_xml
                                     ,'<PayCompany>'
                                     ,sf_fxml('NotPaid','Y')
                                     ,sf_fxml('Cardno',sr_cardno)
                                     ,sf_fxml('Running','N')
                                     ,sf_fxml('Outstanding',Case When sr_running='Y' Then 50 Else 50+sr_restart_cost End)
                                     ,sf_fxml('Cost',0)
                                     ,'</PayCompany>'
                                     );
        END IF;
    END LOOP;
    CLOSE comps;

	-- Add boomer positions
	OPEN boomers;
    inner_loop: LOOP
        FETCH FROM boomers INTO sr_boomerno, sr_boomer_terrno, sr_boomer_terrname, sr_boomer_nukes, sr_boomer_neutron, sr_boomer_visible;
        IF done THEN Set done=0; LEAVE inner_loop; END IF;
		Set sr_order_xml = Concat(sr_order_xml
								 ,'<Boomer>'
								 ,sf_fxml('Number',sr_boomerno)
								 ,sf_fxml('Terrname',sr_boomer_terrname)
								 ,sf_fxml('Terrno',sr_boomer_terrno)
								 ,sf_fxml('Nukes',sr_boomer_nukes)
								 ,sf_fxml('Neutron',sr_boomer_neutron)
								 ,sf_fxml('Visible',sr_boomer_visible)
								 ,'</Boomer>'
								 );
	END LOOP;
    CLOSE boomers;

    -- Add phase 2 orders
    IF sr_phase2_type='Choose 1' THEN
        Set sr_order_xml = Concat(sr_order_xml, sf_fxml('P_A',Concat(sf_fxml('Phase','5'),sf_fxml('Cost','0'))));
    ELSEIF sr_phase2_type='Choose 2' THEN
        Set sr_order_xml = Concat(sr_order_xml, sf_fxml('P_A',Concat(sf_fxml('Phase','3'),sf_fxml('Cost','0'))));
        Set sr_order_xml = Concat(sr_order_xml, sf_fxml('P_B',Concat(sf_fxml('Phase','5'),sf_fxml('Cost','0'))));
    ELSE
        Set sr_order_xml = Concat(sr_order_xml, sf_fxml('P_A',Concat(sf_fxml('Phase','3'),sf_fxml('Cost','0'))));
        Set sr_order_xml = Concat(sr_order_xml, sf_fxml('P_B',Concat(sf_fxml('Phase','5'),sf_fxml('Cost','0'))));
        Set sr_order_xml = Concat(sr_order_xml, sf_fxml('P_C',Concat(sf_fxml('Phase','6'),sf_fxml('Cost','0'))));
    END IF;


    -- Complete XML
    Set sr_order_xml = Concat(sr_order_xml,'</PAYSALARIES>');

    -- Add XML into orders table
    Insert Into sp_orders (gameno, turnno, phaseno, userno, ordername, order_code)
     Values (sr_gameno, sr_turnno, 1, sr_userno, 'SR_ORDERXML', sr_order_xml);

    -- Add ORDSTAT into orders table
    Insert Into sp_orders (gameno, turnno, phaseno, userno, ordername, order_code)
     Values (sr_gameno, sr_turnno, 1, sr_userno, 'ORDSTAT',
             Case When sr_mia < 3 Then "Waiting for orders"
             Else "Orders received"
             End
             );

END LOOP;
CLOSE new_bal;

-- Clean up
-- Select * from tmp_incm;
Drop Temporary Table tmp_incm;
-- /* */
END sproc;
END
$$

Delimiter ;
/*
Drop Temporary Table If Exists tmp_incm;
Delete from sp_orders Where gameno=48;
Delete from sp_old_orders;
Delete from sp_messages;
Update sp_game Set turnno=3, phaseno=7, process=null Where Gameno=48;
Update sp_resource Set loan=2000, interest=200,cash=10000,boomer_money='N' Where userno=3227 and gameno=48;
Update sp_resource Set loan=3000,cash=50 Where userno=3239 and gameno=48;
Update sp_cards Set running=Case When rand() < 0.25 Then 'N' Else 'Y' End Where gameno=48 and userno=3227;
Call sr_take_territory(48,'Nanling','China',0,200);
Call sr_move_queue(48,'N');

Select o.userno
    ,ExtractValue(order_code, 'Count(//NotPaid)') As NotPaid
    ,ExtractValue(order_code, 'Sum(//Credit)') as to_spend
    ,ExtractValue(order_code, 'Sum(/PAYSALARIES/Income/Credit)') as income
    ,ExtractValue(order_code, 'Sum(/PAYSALARIES/Balance/Credit)') as balance
    ,ExtractValue(order_code, 'Sum(//Cost)') as to_pay
    ,ExtractValue(order_code, 'Sum(/PAYSALARIES/PayCompany/Cost)') as comps
    ,ExtractValue(order_code, 'Sum(/PAYSALARIES/PayTroops/Cost)') as troops
    ,ExtractValue(order_code, 'Sum(/PAYSALARIES/PayBank/Cost)') as bank
    ,interest
From sp_orders o
Left Join sp_resource r
On o.userno=r.userno and o.gameno=r.gameno
Where ordername = 'SR_ORDERXML'
 and o.gameno=48
;

select * from sp_orders where gameno=48 and phaseno=1;
select * from sp_resource where gameno=48;
*/
