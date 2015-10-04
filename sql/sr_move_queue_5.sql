use asupcouk_asup;
Drop procedure if exists sr_move_queue_5;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

DELIMITER $$

CREATE PROCEDURE  asupcouk_asup . sr_move_queue_5  (sr_gameno INT)
BEGIN
sproc:BEGIN

-- Process build orders
-- $Id: sr_move_queue_5.sql 242 2014-07-13 13:48:48Z paul $
DECLARE proc_name TEXT DEFAULT "SR_MOVE_QUEUE_5";
DECLARE sr_turnno INT DEFAULT 0;
DECLARE sr_phaseno INT DEFAULT 0;
DECLARE last_userno INT;
DECLARE sr_userno INT;
DECLARE sr_powername TEXT DEFAULT '';
DECLARE last_powername TEXT DEFAULT '';
DECLARE done INT DEFAULT 0;
DECLARE sr_terrno INT DEFAULT 0;
DECLARE sr_terrname TEXT DEFAULT '';
DECLARE sr_terrtype TEXT DEFAULT '';
DECLARE sr_cash INT DEFAULT 0;
DECLARE sr_spend INT DEFAULT 0;

DECLARE sr_minerals INT DEFAULT 0;
DECLARE sr_oil INT DEFAULT 0;
DECLARE sr_grain INT DEFAULT 0;
DECLARE sr_max_minerals INT DEFAULT 0;
DECLARE sr_max_oil INT DEFAULT 0;
DECLARE sr_max_grain INT DEFAULT 0;
DECLARE sr_nukes INT DEFAULT 0;
DECLARE sr_nukes_left INT DEFAULT 0;
DECLARE sr_lstars INT DEFAULT 0;
DECLARE sr_ksats INT DEFAULT 0;
DECLARE sr_neutron INT DEFAULT 0;
DECLARE sr_land_tech INT DEFAULT 0;
DECLARE sr_water_tech INT DEFAULT 0;
DECLARE sr_strategic_tech INT DEFAULT 0;
DECLARE sr_resource_tech INT DEFAULT 0;
DECLARE sr_espionage_tech INT DEFAULT 0;
DECLARE sr_land_tech_gain INT DEFAULT 0;
DECLARE sr_water_tech_gain INT DEFAULT 0;
DECLARE sr_strategic_tech_gain INT DEFAULT 0;
DECLARE sr_resource_tech_gain INT DEFAULT 0;
DECLARE sr_espionage_tech_gain INT DEFAULT 0;

DECLARE sr_land_res INT DEFAULT 0;
DECLARE sr_water_res INT DEFAULT 0;
DECLARE sr_strategic_res INT DEFAULT 0;
DECLARE sr_resource_res INT DEFAULT 0;
DECLARE sr_espionage_res INT DEFAULT 0;

DECLARE sr_nukes_built INT DEFAULT 0;
DECLARE sr_lstars_built INT DEFAULT 0;
DECLARE sr_ksats_built INT DEFAULT 0;
DECLARE sr_neutron_built INT DEFAULT 0;

DECLARE sr_tank_tech_level INT DEFAULT 0;
DECLARE sr_boomer_tech_level INT DEFAULT 0;
DECLARE sr_nuke_tech_level INT DEFAULT 0;
DECLARE sr_lstar_tech_level INT DEFAULT 0;
DECLARE sr_ksat_tech_level INT DEFAULT 0;
DECLARE sr_neutron_tech_level INT DEFAULT 0;

DECLARE sr_max_minerals_built INT DEFAULT 0;
DECLARE sr_max_oil_built INT DEFAULT 0;
DECLARE sr_max_grain_built INT DEFAULT 0;

DECLARE sr_minerals_spend INT DEFAULT 0;
DECLARE sr_oil_spend INT DEFAULT 0;
DECLARE sr_grain_spend INT DEFAULT 0;

DECLARE sr_major INT DEFAULT 0;
DECLARE sr_minor INT DEFAULT 0;
DECLARE sr_current_userno INT DEFAULT 0;

DECLARE sr_major_built INT DEFAULT 0;
DECLARE sr_minor_built INT DEFAULT 0;
DECLARE sr_boomers_built_total INT DEFAULT 0; -- Only used for cash totals
DECLARE sr_boomerno_new INT;
DECLARE sr_major_built_total INT DEFAULT 0;
DECLARE sr_minor_built_total INT DEFAULT 0;

DECLARE sr_orderxml TEXT DEFAULT '';
DECLARE sr_reportxml TEXT DEFAULT '<BUILDREPORT>';
DECLARE sr_old_orderxml TEXT DEFAULT '';

DECLARE sr_amt INT DEFAULT 0;
DECLARE sr_val INT DEFAULT 0;
DECLARE sr_initial INT DEFAULT 0;
DECLARE sr_rand INT DEFAULT 0;
DECLARE sr_pct DOUBLE DEFAULT 0;
DECLARE i INT DEFAULT 0;
DECLARE res TEXT;
DECLARE resdesc TEXT;

DECLARE terrs CURSOR FOR
Select mb.build_userno, terrno, terrname, terrtype, order_code, major, minor, powername, mb.userno
From sv_map_build mb
Join sp_resource r On mb.gameno=r.gameno and mb.build_userno=r.userno
Join sp_orders o On mb.gameno=o.gameno and mb.build_userno=o.userno and o.ordername='SR_ORDERXML'
Where mb.gameno=sr_gameno
Order By mb.build_userno
 ,Length(terrtype) desc
 ,terrname
;

DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

-- Check game is valid
IF (sr_gameno not in (Select gameno From sp_game Where phaseno=5)) THEN
    Insert Into sp_old_orders (gameno, ordername, order_code)
    Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Invalid game or phase</Reason><Game>",sr_gameno,"</Game></FAIL>"));
    LEAVE sproc;
END IF;
Select turnno, phaseno, tank_tech_level, boomer_tech_level, nuke_tech_level, lstar_tech_level, ksat_tech_level, neutron_tech_level
Into sr_turnno, sr_phaseno, sr_tank_tech_level, sr_boomer_tech_level, sr_nuke_tech_level, sr_lstar_tech_level, sr_ksat_tech_level, sr_neutron_tech_level
From sp_game Where gameno=sr_gameno;

-- Get orders for each possibility
Set done=0;
Set last_userno=0;
OPEN terrs;
read_loop: LOOP
    FETCH FROM terrs INTO sr_userno, sr_terrno, sr_terrname, sr_terrtype, sr_orderxml, sr_major, sr_minor, sr_powername, sr_current_userno;
    IF @sr_debug = 'X' THEN Select done, last_userno, sr_userno, sr_terrno, sr_terrname, sr_terrtype; END IF;

    -- Add report if not first run through
    IF done or (last_userno > 0 and last_userno != sr_userno) THEN
        -- Update resource totals from troop build
        Select sr_minerals_spend+sr_major_built_total+Ceil(sr_minor_built_total/3)
               ,sr_oil_spend+sr_major_built_total+Ceil(sr_minor_built_total/3)
               ,sr_grain_spend+sr_major_built_total+Ceil(sr_minor_built_total/3)
               ,sr_spend+sr_major_built_total*500+sr_boomers_built_total*500+sr_minor_built_total*100
        Into sr_minerals_spend, sr_oil_spend, sr_grain_spend, sr_spend
        ;
        -- Complete report
        Set sr_reportxml = Concat(sr_reportxml
                                 ,'</BuildTroops>'
                                 ,sf_fxml('Cash',Concat(sf_fxml('Spend',sr_spend),sf_fxml('Remaining',sr_cash-sr_spend)))
                                 ,sf_fxml('Minerals',Concat(sf_fxml('Spend',sr_minerals_spend),sf_fxml('Remaining',sr_minerals-sr_minerals_spend)))
                                 ,sf_fxml('Oil',Concat(sf_fxml('Spend',sr_oil_spend),sf_fxml('Remaining',sr_oil-sr_oil_spend)))
                                 ,sf_fxml('Grain',Concat(sf_fxml('Spend',sr_grain_spend),sf_fxml('Remaining',sr_grain-sr_grain_spend)))
                                 ,'</BUILDREPORT>'
                                 );
        -- Complete log
        Set sr_old_orderxml = Concat(sr_old_orderxml
                                    ,sf_fxml('Userno',Concat(sf_fxml('Cash',Concat(sf_fxml('Spend',sr_spend),sf_fxml('Remaining',sr_cash-sr_spend)))
                                                            ,sf_fxml('Minerals',Concat(sf_fxml('Spend',sr_minerals_spend),sf_fxml('Remaining',sr_minerals-sr_minerals_spend)))
                                                            ,sf_fxml('Oil',Concat(sf_fxml('Spend',sr_oil_spend),sf_fxml('Remaining',sr_oil-sr_oil_spend)))
                                                            ,sf_fxml('Grain',Concat(sf_fxml('Spend',sr_grain_spend),sf_fxml('Remaining',sr_grain-sr_grain_spend)))
                                                            ,sf_fxml('Major',sr_major_built_total)
                                                            ,sf_fxml('Minor',sr_minor_built_total)
                                                            )
                                             )
                                    );
        -- Update resource card
        Update sp_resource
        Set cash=cash-sr_spend
            ,minerals=minerals-sr_minerals_spend
            ,oil=oil-sr_oil_spend
            ,grain=grain-sr_grain_spend
            ,nukes=nukes+sr_nukes_built
            ,nukes_left=nukes_left-sr_nukes_built
            ,lstars=lstars+sr_lstars_built
            ,ksats=ksats+sr_ksats_built
            ,neutron=neutron+sr_neutron_built
            ,max_minerals=max_minerals+sr_max_minerals_built
            ,max_oil=max_oil+sr_max_oil_built
            ,max_grain=max_grain+sr_max_grain_built
            ,land_tech=land_tech+sr_land_tech_gain
            ,water_tech=water_tech+sr_water_tech_gain
            ,strategic_tech=strategic_tech+sr_strategic_tech_gain
            ,resource_tech=resource_tech+sr_resource_tech_gain
            ,espionage_tech=espionage_tech+sr_espionage_tech_gain
        Where gameno=sr_gameno
         and userno=last_userno
        ;
        -- Add message for user
        Insert Into sp_messages (gameno, userno, message) Values (sr_gameno, last_userno, sr_reportxml);
    END IF;

    -- Stop processing when all records have been run through
    IF done THEN LEAVE read_loop; END IF;

    -- Standard build actions
    IF sr_userno != last_userno THEN

        -- Set up new variables
        Select '<BUILDREPORT>',0,0,0, 0
               ,0,0,0
               ,0,0,0
               ,0,0,0,0
               ,0,0,0,0,0
        Into sr_reportxml,sr_spend, sr_major_built_total, sr_minor_built_total, sr_boomers_built_total
             ,sr_minerals_spend, sr_oil_spend, sr_grain_spend
             ,sr_max_minerals_built, sr_max_oil_built, sr_max_grain_built
             ,sr_nukes_built, sr_lstars_built, sr_ksats_built, sr_neutron_built
             ,sr_land_tech_gain, sr_water_tech_gain, sr_strategic_tech_gain, sr_resource_tech_gain, sr_espionage_tech_gain
        ;
        Select cash, minerals, oil, grain, max_minerals, max_oil, max_grain
               , nukes, nukes_left, lstars, ksats, neutron
               , land_tech, water_tech, strategic_tech, resource_tech, espionage_tech
        Into sr_cash, sr_minerals, sr_oil, sr_grain, sr_max_minerals, sr_max_oil, sr_max_grain
             , sr_nukes, sr_nukes_left, sr_lstars, sr_ksats, sr_neutron
             , sr_land_tech, sr_water_tech, sr_strategic_tech, sr_resource_tech, sr_espionage_tech
        From sp_resource Where gameno=sr_gameno and userno=sr_userno
        ;

        IF @sr_debug!="N" THEN Select "New build", last_userno, sr_userno, sr_reportxml, sr_spend, sr_major_built_total, sr_minor_built_total; END IF;

        -- Nukes
        Set sr_reportxml = Concat(sr_reportxml,'<Strategic>');
        Set sr_val = extractValue(sr_orderxml,'/BUILD/Strategic/nukes');
        IF sr_val > 0 and sr_strategic_tech >= sr_nuke_tech_level and sr_cash-sr_spend >= sr_val*500 and sr_val <= sr_minerals-sr_minerals_spend and sr_val <= sr_nukes_left THEN
            Set sr_nukes_built = sr_val;
            Set sr_spend = sr_spend + sr_val * 500;
            Set sr_minerals_spend = sr_minerals_spend + sr_val;
            IF @sr_debug='B' THEN Select "Nukes:", sr_val, sr_strategic_tech, sr_nuke_tech_level, sr_cash, sr_spend, sr_minerals_spend; END IF;
            Set sr_reportxml = Concat(sr_reportxml
                                     ,'<Nukes>'
                                     ,sf_fxml('Built',sr_nukes_built)
                                     ,sf_fxml('Now',sr_nukes+sr_nukes_built)
                                     ,sf_fxml('Left',sr_nukes_left-sr_nukes_built)
                                     ,'</Nukes>'
            );
            Set sr_old_orderxml = Concat(sr_old_orderxml
                                        ,'<Nukes>'
                                        ,sf_fxml('User',sr_userno)
                                        ,sf_fxml('Built',sr_nukes_built)
                                        ,sf_fxml('Now',sr_nukes+sr_nukes_built)
                                        ,sf_fxml('Left',sr_nukes_left-sr_nukes_built)
                                        ,'</Nukes>'
                                        );
        ELSEIF sr_val > 0 THEN
            Set sr_old_orderxml = Concat(sr_old_orderxml
                                        ,sf_fxml('FAIL',Concat('Nukes'
                                                              ,sf_fxml('Requested',sr_val)
                                                              ,sf_fxml('Cash',sr_cash-sr_spend)
                                                              ,sf_fxml('Tech',sr_strategic_tech)
                                                              ,sf_fxml('TechReq',sr_nuke_tech_level)
                                                              ,sf_fxml('Minerals',sr_minerals-sr_minerals_spend)
                                                              )
                                                )
                                        );
        END IF;

        -- Neutron
        Set sr_val = extractValue(sr_orderxml,'/BUILD/Strategic/neutron');
        IF sr_val > 0 and sr_strategic_tech >= sr_neutron_tech_level and sr_cash-sr_spend >= sr_val*500 and sr_val <= sr_minerals-sr_minerals_spend THEN
            Set sr_neutron_built = sr_val;
            Set sr_spend = sr_spend + sr_val * 500;
            Set sr_minerals_spend = sr_minerals_spend + sr_val;
            IF @sr_debug='B' THEN Select "Neutron:", sr_val, sr_strategic_tech, sr_nuke_tech_level, sr_cash, sr_spend, sr_minerals_spend; END IF;
            Set sr_reportxml = Concat(sr_reportxml
                                     ,'<Neutron>'
                                     ,sf_fxml('Built',sr_neutron_built)
                                     ,sf_fxml('Now',sr_neutron+sr_val)
                                     ,'</Neutron>'
            );
            Set sr_old_orderxml = Concat(sr_old_orderxml
                                        ,'<Neutron>'
                                        ,sf_fxml('User',sr_userno)
                                        ,sf_fxml('Built',sr_neutron_built)
                                        ,sf_fxml('Now',sr_neutron+sr_val)
                                        ,'</Neutron>'
                                        );
        END IF;

        -- L-Stars
        Set sr_val = extractValue(sr_orderxml,'/BUILD/Strategic/lstars');
        IF sr_val > 0 and sr_strategic_tech >= sr_lstar_tech_level and sr_cash-sr_spend >= sr_val*1000 and sr_val*2 <= sr_minerals-sr_minerals_spend THEN
            Set sr_lstars_built = sr_val;
            Set sr_spend = sr_spend + sr_val * 1000;
            Set sr_minerals_spend = sr_minerals_spend + 2*sr_val;
            IF @sr_debug='B' THEN Select "L-Stars:", sr_val, sr_strategic_tech, sr_nuke_tech_level, sr_cash, sr_spend, sr_minerals_spend; END IF;
            Set sr_reportxml = Concat(sr_reportxml
                                     ,'<L-Stars>'
                                     ,sf_fxml('Built',sr_lstars_built)
                                     ,sf_fxml('Now',sr_lstars+sr_val)
                                     ,'</L-Stars>'
            );
            Set sr_old_orderxml = Concat(sr_old_orderxml
                                        ,'<LStars>'
                                        ,sf_fxml('User',sr_userno)
                                        ,sf_fxml('Built',sr_lstars_built)
                                        ,sf_fxml('Now',sr_lstars+sr_val)
                                        ,'</LStars>'
                                        );
        END IF;

        -- K-Sats
        Set sr_val = extractValue(sr_orderxml,'/BUILD/Strategic/ksats');
        IF sr_val > 0 and sr_strategic_tech >= sr_ksat_tech_level and sr_cash-sr_spend >= sr_val*1000 and sr_val*2 <= sr_minerals-sr_minerals_spend THEN
            Set sr_ksats_built = sr_val;
            Set sr_spend = sr_spend + sr_val * 1000;
            Set sr_minerals_spend = sr_minerals_spend + 2*sr_val;
            IF @sr_debug='B' THEN Select "K-Sats:", sr_val, sr_strategic_tech, sr_nuke_tech_level, sr_cash, sr_spend, sr_minerals_spend; END IF;
            Set sr_reportxml = Concat(sr_reportxml
                                     ,'<K-Sats>'
                                     ,sf_fxml('Built',sr_ksats_built)
                                     ,sf_fxml('Now',sr_ksats+sr_val)
                                     ,'</K-Sats>'
            );
            Set sr_old_orderxml = Concat(sr_old_orderxml
                                        ,'<KSats>'
                                        ,sf_fxml('User',sr_userno)
                                        ,sf_fxml('Built',sr_ksats_built)
                                        ,sf_fxml('Now',sr_ksats+sr_val)
                                        ,'</KSats>'
                                        );
        END IF;
        Set sr_reportxml = Concat(sr_reportxml,'</Strategic>');

        -- Build storage
        Set sr_reportxml = Concat(sr_reportxml,'<Storage>');
        Set sr_val = extractValue(sr_orderxml,'/BUILD/Storage/max_Minerals');
        IF sr_val > 0 and sr_cash-sr_spend >= sr_val*150 THEN
            Set sr_max_minerals_built = sr_val;
            Set sr_spend = sr_spend + sr_val * 150;
            Set sr_reportxml = Concat(sr_reportxml,'<Minerals>',sf_fxml('Built',sr_max_minerals_built),sf_fxml('Now',sr_max_minerals+sr_val),'</Minerals>');
            Set sr_old_orderxml = Concat(sr_old_orderxml,'<MaxMinerals>',sf_fxml('User',sr_userno),sf_fxml('Built',sr_max_minerals_built),sf_fxml('Now',sr_max_minerals+sr_val),'</MaxMinerals>');
        END IF;
        Set sr_val = extractValue(sr_orderxml,'/BUILD/Storage/max_Oil');
        IF sr_val > 0 and sr_cash-sr_spend >= sr_val*150 THEN
            Set sr_max_oil_built = sr_val;
            Set sr_spend = sr_spend + sr_val * 150;
            Set sr_reportxml = Concat(sr_reportxml,'<Oil>',sf_fxml('Built',sr_max_oil_built),sf_fxml('Now',sr_max_oil+sr_val),'</Oil>');
            Set sr_old_orderxml = Concat(sr_old_orderxml,'<MaxOil>',sf_fxml('User',sr_userno),sf_fxml('Built',sr_max_oil_built),sf_fxml('Now',sr_max_oil+sr_val),'</MaxOil>');
        END IF;
        Set sr_val = extractValue(sr_orderxml,'/BUILD/Storage/max_Grain');
        IF sr_val > 0 and sr_cash-sr_spend >= sr_val*150 THEN
            Set sr_max_grain_built = sr_val;
            Set sr_spend = sr_spend + sr_val * 150;
            Set sr_reportxml = Concat(sr_reportxml,'<Grain>',sf_fxml('Built',sr_max_grain_built),sf_fxml('Now',sr_max_grain+sr_val),'</Grain>');
            Set sr_old_orderxml = Concat(sr_old_orderxml,'<MaxGrain>',sf_fxml('User',sr_userno),sf_fxml('Built',sr_max_grain_built),sf_fxml('Now',sr_max_grain+sr_val),'</MaxGrain>');
        END IF;
        Set sr_reportxml = Concat(sr_reportxml,'</Storage>');

        -- Research
        Set i=1;
        Set sr_reportxml = Concat(sr_reportxml,'<Research>');
        research_loop: LOOP
            -- Get values for this research
            Set res = Case When i=1 Then 'strategic' When i=2 Then 'land' When i=3 Then 'water' When i=4 Then 'resource' When i=5 Then 'espionage' Else '' End;
            Set resdesc = Case When i=1 Then 'Strategic' When i=2 Then 'Army' When i=3 Then 'Naval' When i=4 Then 'Resource' When i=5 Then 'Espionage' Else '' End;
            Set sr_amt = extractValue(sr_orderxml,Concat('/BUILD/Research/',res,'/Amt'));
            Set sr_val = extractValue(sr_orderxml,Concat('/BUILD/Research/',res,'/Val'));
            Set sr_pct = Coalesce(Floor(100*sqrt(sr_val / (sr_amt*sr_amt * (Case When i=1 Then 4000 When i<=3 Then 3000 Else 2500 End)))),0);

            -- Process order if cash is available
            IF sr_val <= sr_cash-sr_spend and sr_val > 0 THEN
                Set sr_spend = sr_spend + sr_val;
                Set sr_rand = Ceil(Rand()*100);
                -- Get initial resource value
                IF i=1 THEN Set sr_initial=sr_strategic_tech;
                ELSEIF i=2 THEN Set sr_initial=sr_land_tech;
                ELSEIF i=3 THEN Set sr_initial=sr_water_tech;
                ELSEIF i=4 THEN Set sr_initial=sr_resource_tech;
                ELSEIF i=5 THEN Set sr_initial=sr_espionage_tech;
                END IF;
                -- Update resource gain if success
                IF sr_rand <= sr_pct THEN
                    IF i=1 THEN Set sr_strategic_tech_gain=sr_amt;
                    ELSEIF i=2 THEN Set sr_land_tech_gain=sr_amt;
                    ELSEIF i=3 THEN Set sr_water_tech_gain=sr_amt;
                    ELSEIF i=4 THEN Set sr_resource_tech_gain=sr_amt;
                    ELSEIF i=5 THEN Set sr_espionage_tech_gain=sr_amt;
                    END IF;
                END IF;
                -- Set report information
                Set sr_reportxml = Concat(sr_reportxml
                                         ,'<',resdesc,'>'
                                         ,sf_fxml('Spend',sr_val)
                                         ,sf_fxml('Levels',Concat(sr_initial,'+',sr_amt))
                                         ,sf_fxml('Success',Case When sr_rand<=sr_pct Then 'Yes' Else 'No' End)
                                         ,sf_fxml('NewLevel',Case When sr_rand<=sr_pct Then sr_initial+sr_amt Else sr_initial End)
                                         ,'</',resdesc,'>'
                                         );
                -- Set log information
                Set sr_old_orderxml = Concat(sr_old_orderxml
                                            ,sf_fxml('Success',Concat('Research'
                                                                     ,sf_fxml('Userno',sr_userno)
                                                                     ,sf_fxml('Cash',sr_cash)
                                                                     ,sf_fxml('Spent',sr_spend)
                                                                     ,sf_fxml('Tech',res)
                                                                     ,sf_fxml('Initial',sr_initial)
                                                                     ,sf_fxml('Spend',sr_val)
                                                                     ,sf_fxml('Levels',sr_amt)
                                                                     ,sf_fxml('Percent',sr_pct)
                                                                     ,sf_fxml('Roll',sr_rand)
                                                                     )
                                                     )
                                            );
            ELSEIF sr_val > 0 THEN
                Set sr_old_orderxml = Concat(sr_old_orderxml
                                            ,sf_fxml('FAIL',Concat('Research'
                                                                  ,sf_fxml('Userno',sr_userno)
                                                                  ,sf_fxml('Cash',sr_cash)
                                                                  ,sf_fxml('Spent',sr_spend)
                                                                  ,sf_fxml('Tech',res)
                                                                  ,sf_fxml('Value',sr_val)
                                                                  ,sf_fxml('Amount',sr_amt)
                                                                  )
                                                    )
                                            );
            END IF;

            IF @sr_debug!='N' THEN Select i, res, sr_reportxml, sr_amt, sr_val, sr_pct, sr_cash, sr_spend; END IF;

            -- End current research, move on
            Set i=i+1;
            IF i=6 THEN LEAVE research_loop; END IF;
        END LOOP;
        Set sr_reportxml = Concat(sr_reportxml,'</Research>');

        -- Add start of build troops XML
        Set sr_reportxml = Concat(sr_reportxml,'<BuildTroops>');

        Set last_userno = sr_userno;
        Set last_powername = sr_powername;
    END IF;


    -- Build in territories
    Set sr_major_built = Case
                          When Length(sr_terrtype)=4 and sr_land_tech < sr_tank_tech_level Then 0
                          When Length(sr_terrtype)=3 and sr_water_tech < sr_boomer_tech_level Then 0
                          Else Coalesce(extractValue(sr_orderxml,Concat("/BUILD/BuildTroops/Major[../Terrno='",sr_terrno,"']")),0)
						 End;
    Set sr_minor_built = extractValue(sr_orderxml,Concat("/BUILD/BuildTroops/Minor[../Terrno='",sr_terrno,"']"));
    IF @sr_debug='B' THEN Select "BUILDING in TERR", sr_terrno, sr_terrname, sr_userno, sr_major, sr_major_built, sr_major_built_total, sr_minor, sr_minor_built, sr_minor_built_total; END IF;

	-- Need check that ok to build tanks or boomers
    IF (sr_major_built > 0 or sr_minor_built > 0)
	   and (sr_major_built+sr_major_built_total) + Ceil((sr_minor_built+sr_minor_built_total)/3) <= Least(sr_minerals-sr_minerals_spend, sr_oil-sr_oil_spend, sr_grain-sr_grain_spend)
       and (sr_major_built+sr_major_built_total)*500 + ((Length(sr_terrtype)=3)*sr_major_built+sr_boomers_built_total)*500 + (sr_minor_built+sr_minor_built_total)*100 <= sr_cash - sr_spend
        THEN
        -- Update totals
        Set sr_major_built_total=sr_major_built_total+sr_major_built;
        Set sr_minor_built_total=sr_minor_built_total+sr_minor_built;
		IF Length(sr_terrtype)=3 THEN Set sr_boomers_built_total=sr_boomers_built_total+sr_major_built; END IF;
        -- -- -- Set sr_spend=sr_spend + sr_major_built *500 + sr_minor_built*100;
        -- Update board, ensure user is correct in case of building in seas
		IF Length(sr_terrtype)=3 and sr_major_built >= 1 THEN
			Set i=0;
			WHILE (i<sr_major_built) DO
				Select Coalesce(Max(boomerno)+1,1) Into sr_boomerno_new From sp_boomers Where gameno=sr_gameno and userno=sr_userno;
				Insert Into sp_boomers (gameno, userno, boomerno, terrno) Values (sr_gameno, sr_userno, sr_boomerno_new, sr_terrno);
				Set i=i+1;
			END WHILE;
			IF @sr_debug='B' THEN Select * From sp_boomers Where gameno=sr_gameno and terrno=sr_terrno; END IF;
		END IF;
        IF sr_current_userno!=sr_userno THEN
            call sr_take_territory(sr_gameno, sr_terrname, sr_powername, sr_major_built, sr_minor_built);
        ELSE
            Update sp_board Set major=major+sr_major_built, minor=minor+sr_minor_built Where gameno=sr_gameno and terrno=sr_terrno;
        END IF;
        -- Update message
        Set sr_reportxml = Concat(sr_reportxml
                                 ,'<Territory>',sr_terrname
                                 ,Case When Length(sr_terrtype)=4 and sr_major_built > 0 Then sf_fxml('Tanks',Concat(sf_fxml('Build',sr_major_built),sf_fxml('Now',sr_major+sr_major_built))) Else '' End
                                 ,Case When Length(sr_terrtype)=4 and sr_minor_built > 0 Then sf_fxml('Armies',Concat(sf_fxml('Build',sr_minor_built),sf_fxml('Now',sr_minor+sr_minor_built))) Else '' End
                                 ,Case When Length(sr_terrtype)=3 and sr_major_built > 0 Then sf_fxml('Boomers',Concat(sf_fxml('Build',sr_major_built),sf_fxml('Now',sr_major+sr_major_built))) Else '' End
                                 ,Case When Length(sr_terrtype)=3 and sr_minor_built > 0 Then sf_fxml('Navies',Concat(sf_fxml('Build',sr_minor_built),sf_fxml('Now',sr_minor+sr_minor_built))) Else '' End
                                 ,'</Territory>'
                                 );

        -- Update log
        Set sr_old_orderxml = Concat(sr_old_orderxml
                                    ,'<BuildTroops>'
                                    ,sf_fxml('Terrno',sr_terrno)
                                    ,sf_fxml('Terrname',sr_terrname)
                                    ,sf_fxml('User',sr_userno)
                                    ,sf_fxml('BuiltMajor',sr_major_built)
                                    ,sf_fxml('NowMajor',sr_major+sr_major_built)
                                    ,sf_fxml('BuiltMinor',sr_minor_built)
                                    ,sf_fxml('NowMinor',sr_minor+sr_minor_built)
                                    ,'</BuildTroops>'
                                    );

    ELSEIF (sr_major_built > 0 or sr_minor_built > 0) THEN
        -- Add log entry
        Set sr_old_orderxml = Concat(sr_old_orderxml
                                    ,sf_fxml('FAILBuildTroops',Concat(
                                            sf_fxml('Terrno',sr_terrno)
                                            ,sf_fxml('Terrname',sr_terrname)
                                            ,sf_fxml('Userno',sr_userno)
                                            ,sf_fxml('Cash',Concat(sr_cash,'-',sr_spend))
                                            ,sf_fxml('Minerals',Concat(sr_minerals,'-',sr_minerals_spend))
                                            ,sf_fxml('Oil',Concat(sr_oil,'-',sr_oil_spend))
                                            ,sf_fxml('Grain',Concat(sr_grain,'-',sr_grain_spend))
                                            ,sf_fxml('MajorBuilt',sr_major_built_total)
                                            ,sf_fxml('MinorBuilt',sr_minor_built_total)
                                            ,sf_fxml('MajorRequest',sr_major_built)
                                            ,sf_fxml('MinorRequest',sr_minor_built)
                                            ))
                                    );
    END IF;

END LOOP;
CLOSE terrs;

-- Check L-Star slots
Call sr_check_lstar_slots(sr_gameno);

-- Add in success log entry
Insert Into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
Value (sr_gameno, sr_turnno, sr_phaseno, proc_name, sf_fxml('SUCCESS',sr_old_orderxml))
;

-- /* */
END sproc;
END
$$

Delimiter ;