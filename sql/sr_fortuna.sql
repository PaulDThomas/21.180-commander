use asupcouk_asup;
Drop procedure if exists sr_fortuna;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE PROCEDURE `asupcouk_asup`.`sr_fortuna` (sr_gameno INT)
BEGIN
sproc:BEGIN

-- Declare variables
-- $Id: sr_fortuna.sql 242 2014-07-13 13:48:48Z paul $
DECLARE proc_name TEXT Default "SR_FORTUNA";
DECLARE sr_turnno INT Default 0;
DECLARE sr_phaseno INT Default 0;
DECLARE rand INT Default 0;
DECLARE terrname VARCHAR(25) Default '';
DECLARE terrtype CHAR(4) Default '';
DECLARE pterrtype CHAR(4) Default '';
DECLARE terrno INT Default 0;
DECLARE sr_powername VARCHAR(15) Default '';
DECLARE sr_powername2 VARCHAR(15) Default '';
DECLARE sr_userno INT Default 0;
DECLARE minor INT Default 0;
DECLARE major INT Default 0;
DECLARE cardno INT Default 0;
DECLARE res_name CHAR(30);
DECLARE res_type CHAR(8);
DECLARE res_amt INT Default 0;
DECLARE res TEXT;
DECLARE res_sel INT Default 0;
DECLARE done INT Default 0;
DECLARE n INT Default 0;
DECLARE mkt_mv INT Default 0;
DECLARE kill_points INT Default 0;
DECLARE kill_minor INT Default 0;
DECLARE killed_minor INT Default 0;
DECLARE tribute INT Default 0;
DECLARE new_level INT Default 0;
DECLARE r1 INT Default 0;
DECLARE r2 INT Default 0;
DECLARE sr_message TEXT;
DECLARE sr_messages TEXT Default 'Messagenos: ';
DECLARE sr_cash INT Default 0;
DECLARE sr_loan INT Default 0;
DECLARE sr_minerals INT Default 0;
DECLARE sr_oil INT Default 0;
DECLARE sr_grain INT Default 0;
DECLARE sr_nukes INT Default 0;
DECLARE sr_nukes_left INT Default 0;
DECLARE sr_lstars INT Default 0;
DECLARE sr_ksats INT Default 0;
DECLARE sr_neutron INT Default 0;
DECLARE sr_worldcup INT Default 0;
DECLARE sr_players INT Default 0;

-- Declare cursors
-- Random territory (naughy people more likely)
DECLARE territ CURSOR FOR
Select p.terrname, p.terrtype, b.terrno
       ,Case
         When r.powername is null Then 'Locals'
         Else r.powername
        End
       ,b.minor
       ,b.major
       ,pw.terrtype
From sp_board b
Left Join sp_resource r On r.userno=b.userno and r.gameno=b.gameno
Left Join sp_places p On b.terrno=p.terrno
Left Join sp_powers pw On r.powername=pw.powername
Where b.gameno=sr_gameno
 and b.userno > -9
Order By
Case
 When naughty='Y' and major > 0 Then Rand()*3
 When naughty='Y' Then Rand()*2
 Else Rand()
End;

-- Random company
DECLARE market CURSOR FOR Select rc.cardno, rc.res_type, rc.res_amount, rc.res_name, Case When r.powername is null Then 'Locals' Else r.powername End, p.terrname
                          From sp_res_cards rc
                          Inner Join sp_cards c On rc.cardno=c.cardno
                          Inner Join sp_places p On rc.terrno=p.terrno
                          Left Join sp_resource r On r.userno=c.userno and c.gameno=r.gameno
                          Where c.gameno=sr_gameno
                          Order By Rand()
                          Limit 1;
-- Random power
DECLARE superpower CURSOR FOR Select r.powername, r.userno
                              From sp_resource r
                              Left Join sp_board b On r.userno=b.userno and r.gameno=b.gameno
                              Where r.gameno=sr_gameno
                               and r.dead != 'Y'
                              Order By Rand()
                              Limit 1
                              ;

-- Resources for UN report
DECLARE res CURSOR FOR Select userno, powername, cash, loan, minerals, oil, grain, nukes, lstars, ksats, neutron From sp_resource Where gameno=sr_gameno and dead='N';

DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;



-- Check game
IF sr_gameno not in (Select gameno From sp_game Where phaseno < 9) THEN
    Insert into sp_old_orders (gameno, ordername, order_code)
     Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Invalid Game</Reason><Gameno>",sr_gameno,"</Gameno></FAIL>"));
    LEAVE sproc;
END IF;
Select turnno, phaseno, worldcup Into sr_turnno, sr_phaseno, sr_worldcup From sp_game Where gameno=sr_gameno;
Select count(*) Into sr_players From sp_resource Where gameno=sr_gameno and dead='N';

-- Check for meteor swarm
Set rand = Coalesce(@sr_rand,Ceiling(Rand()*100));
IF @sr_debug="X" THEN Select sr_gameno, sr_turnno, sr_phaseno, rand; END IF;

IF rand <= 4 + Greatest(0,Case When sr_worldcup > 0 Then -12 + sr_turnno + sr_players Else 0 End) THEN

    -- Change ownership of each territory to Meteor
    Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, proc_name, Concat("<SUCCESS><Result>Meteor Swarm</Result></SUCCESS>"));
    -- Set up counting variable
    Set n = 1;
	Set sr_message = 'The world has suffered a disastrous meteor impact. The following territories have been hit:';
    -- Open cursor
    OPEN territ;
    read_loop: LOOP
        -- Change each territory individually
        FETCH FROM territ INTO terrname, terrtype, terrno, sr_powername, minor, major, pterrtype;
		Set sr_message = Concat(sr_message,Case When n > 1 Then ', ' Else ' ' End,terrname);
        Call sr_take_territory(sr_gameno, terrname, 'Meteor', 0, 0);
        -- Stop changing territories when there are none left, or enough have been done
        IF done THEN LEAVE read_loop; END IF;
        Set n = n+1;
        If n > rand THEN LEAVE read_loop; END IF;
    END LOOP;
    CLOSE territ;
	Set sr_message = Concat(sr_message,'.');
    Insert Into sp_message_queue (gameno, userno, message, to_email)
     Values (sr_gameno, 0, sr_message, 0);

    -- Leave fortuna now
    LEAVE sproc;
END IF;

-- Single company event
OPEN market;
FETCH FROM market Into cardno, res_type, res_amt, res_name, sr_powername, terrname;
-- Work out market change
Set mkt_mv = Case
              When res_amt < 4 Then Ceil(Rand()*6)
              Else Ceil(Rand()*6) + Ceil(Rand()*6)
             End;
-- Company extra production
IF rand/2=Floor(rand/2) THEN

    -- Move market down
    Call sr_move_market(sr_gameno, res_type, -mkt_mv);
    Set @sql_rtn = Concat("Select price Into @new_price From sp_market m, sp_prices p Where gameno=",sr_gameno," and m.",res_type,"_level=p.market_level");
    PREPARE sql_rtn FROM @sql_rtn;
    EXECUTE sql_rtn;
    DEALLOCATE PREPARE sql_rtn;

    -- Add resources to Superpower
    IF sr_powername != 'Locals' THEN
        Set @sql_upd = Concat("Update sp_resource Set ",res_type,"=",res_type,"+Ceil(",res_amt,"/2) Where gameno=",sr_gameno," and powername='",sr_powername,"'");
        PREPARE sql_upd From @sql_upd;
        EXECUTE sql_upd;
        DEALLOCATE PREPARE sql_upd;
    END IF;

    -- Old orders message
    Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<SUCCESS>"
            ,sf_fxml("Result","Company Extra")
            ,sf_fxml("Resource",res_type)
            ,sf_fxml("Amount",res_amt)
            ,sf_fxml("Company",res_name)
            ,sf_fxml("Superpower",sr_powername)
            ,sf_fxml("MarketChange",-mkt_mv)
            ,"</SUCCESS>"
            ));

    -- Add message to queue
    Insert Into sp_message_queue (gameno, userno, message, to_email)
     Values (sr_gameno, 0, Concat("Extra production at ",res_name
                                 ," in ",terrname,", "
                                 ,Case when sr_powername='Locals' Then 'The local population' Else sr_powername End
                                 ," has received extra ",res_type
                                 ,".  The market price for ",res_type
                                 ," moves down to ",@new_price," per unit.")
            , 0);

-- Company explosion
ELSE
    -- Move market down
    Call sr_move_market(sr_gameno, res_type, mkt_mv);
    Set @sql_rtn = Concat("Select price Into @new_price From sp_market m, sp_prices p Where gameno=",sr_gameno," and m.",res_type,"_level=p.market_level");
    PREPARE sql_rtn FROM @sql_rtn;
    EXECUTE sql_rtn;
    DEALLOCATE PREPARE sql_rtn;

    -- Change company status to not working
    Update sp_cards c Set running='N' Where c.gameno=sr_gameno and c.cardno=cardno;

    -- Old orders message
    Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<SUCCESS>"
                   ,sf_fxml("Result","Company Explosion")
                   ,sf_fxml("Resource",res_type)
                   ,sf_fxml("Amount",res_amt)
                   ,sf_fxml("Company",res_name)
                   ,sf_fxml("Superpower",sr_powername)
                   ,sf_fxml("MarketChange",mkt_mv)
                   ,"</SUCCESS>"
                   )
            );

    -- Add message to queue
    Insert Into sp_message_queue (gameno, userno, message)
     Values (sr_gameno, 0, Concat("Explosion at ",res_name
                                 ," in ",terrname
                                 ," owned by ",sr_powername
                                 ,".  The company will need repairs.  The market price for "
                                 ,res_type," moves up to "
                                 ,@new_price," per unit."
                                 )
             );

END IF;
CLOSE market;

--
-- Second random event
--

-- Natural Disaster
IF rand <= 50 THEN
    -- Find number of minor troops to kill
    Set kill_points = Ceil(Rand()*4)+1;
    Set kill_minor = Floor(Ceil(Rand()*6)/kill_points);
    If kill_minor > 0 Then
        OPEN territ;
        FETCH territ into terrname, terrtype, terrno, sr_powername, minor, major, pterrtype;
        If minor > 0 Then
            Set killed_minor=Least(kill_minor, minor);
            Call sr_take_territory(sr_gameno, terrname, sr_powername, major, minor-killed_minor);

            -- Add message to queue
            Insert Into sp_message_queue (gameno, userno, message, to_email)
             Values (sr_gameno, 0, Concat("Natural disaster in ",terrname,".  "
                                         ,sr_powername," has lost "
                                         ,sf_format_troops(terrtype,0, killed_minor)," to the elements. "
                                         ,sf_format_troops(terrtype,major, minor-killed_minor)
                                         ,Case When minor-killed_minor+major = 1 Then " remains" Else " remain" End," in the territory.")
                    ,0);
            END IF;
        CLOSE territ;
    END IF;

    -- Old orders message
    Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<SUCCESS>"
                   ,"<Result>Natural Disaster</Result>"
                   ,"<KillMinor>",kill_minor,"</KillMinor>"
                   ,"<Terrname>",terrname,"</Terrname>"
                   ,"<Powername>",sr_powername,"</Powername>"
                   ,"<InitialMinor>",minor,"</InitialMinor>"
                   ,"<RemainingMinor>",Greatest(0,minor-kill_minor),"</RemainingMinor>"
                   ,"</SUCCESS>"
                   )
            );

-- Terrorist attack on resource card
ELSEIF rand <= 60 THEN
    -- Get powername to attack
    OPEN superpower;
    FETCH superpower INTO sr_powername, sr_userno;
    CLOSE superpower;
    -- Randomly select resource to remove
    Set res_sel = Ceil(Rand()*12);
    Set res = Case
               When res_sel <=  3 Then 'Minerals'
               When res_sel <=  6 Then 'Oil'
               When res_sel <=  9 Then 'Grain'
               When res_sel <= 10 Then 'Max_Minerals'
               When res_sel <= 11 Then 'Max_Oil'
               Else 'Max_Grain'
              End
                    ;
    Set res_amt = Floor(Ceil(Rand()*6/Case When res_sel<9 Then 3 Else 5 End));
    Set @sql_upd = Concat("Update sp_resource Set ",res,"=",res,"-",res_amt," where gameno=",sr_gameno," and powername='",sr_powername,"'");
    PREPARE sql_upd From @sql_upd;
    EXECUTE sql_upd;
    DEALLOCATE PREPARE sql_upd;

    -- Add message to queue
    Insert Into sp_message_queue (gameno, userno, message, to_email)
     Values (sr_gameno, 0, Concat("Terrorists attack ",sr_powername," and manage to destroy "
                                 ,res_amt," ",sf_format(res)
                                 )
            ,0);
    -- Old orders message
    Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<SUCCESS>"
                   ,"<Result>Terrorist Attack</Result>"
                   ,"<Powername>",sr_powername,"</Powername>"
                   ,"<Resource>",res_sel,"</Resource>"
                   ,"<Amount>",res_amt,"</Amount>"
                   ,"</SUCCESS>"
                   ));


-- Publish communications
ELSEIF rand <= 65 THEN
    -- Choose messages
    OPEN superpower;
    FETCH superpower INTO sr_powername, sr_userno;
    CLOSE superpower;

	-- Get messages to leak
	Drop Temporary Table if exists tmp_leaks;
    Create Temporary Table tmp_leaks As
    Select messageno, rand() as r, sf_fxml('Powername',Concat(ExtractValue(message,'/COMMS/From/Powername'),' *Leaked*')) as newfrom
    From sp_messages
	Where gameno=sr_gameno and userno=sr_userno 
     and ExtractValue(message,'/COMMS/From/Powername') != ''
     and ExtractValue(message,'/COMMS/From/Powername') not like  '%Leaked%'
    ;

	-- Update message table
	Update sp_messages m
    Left Join tmp_leaks l
    On m.messageno=l.messageno and r<0.34
    Set userno=0
        ,message=UpdateXML(message,'/COMMS/From',sf_fxml('From',newfrom))
	Where l.messageno is not null
	;

	-- Add message to queue
    Insert Into sp_message_queue (gameno, userno, to_email, message)
     Values (sr_gameno, 0, 0, Concat("Messages belonging to ",sr_powername," have been revealed on the internet.  All powers now have access to them."));

	-- Clean up
	Select Group_Concat(messageno order by messageno separator ',') Into sr_messages From tmp_leaks Where r<0.34;
    Drop Temporary Table tmp_leaks;

    -- Old orders message
    Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<SUCCESS>"
                   ,"<Result>Leak</Result>"
                   ,"<Powername>",sr_powername,"</Powername>"
                   ,"<MessageNos>",sr_messages,"</MessageNos>"
                   ,"</SUCCESS>"
                   ));


-- Tribute from territory
ELSEIF rand <= 70 THEN
    -- Calculate amount
    Set tribute = Ceil(Rand()*6) * Ceil(Rand()*4) * 100;
    -- Select territory, has to be land, can not be Superpowers home territory
    Set done=0;
    OPEN territ;
    read_loop: LOOP
        -- Change each territory individually
        FETCH FROM territ INTO terrname, terrtype, terrno, sr_powername, minor, major, pterrtype;
        IF done THEN
            LEAVE sproc;
        ELSEIF (Length(terrtype)=4 and terrtype != pterrtype and sr_powername != 'Locals') THEN
            LEAVE read_loop;
        END IF;
    END LOOP;

    -- Pay tribute
    Update sp_resource r Set r.cash=r.cash+tribute Where gameno=sr_gameno and r.powername=sr_powername;

    -- Add message to queue
    Insert Into sp_message_queue (gameno, userno, message, to_email)
     Values (sr_gameno, 0, Concat("Local Warlords in ",terrname," pay tribute of "
                                 ,tribute," to ",sr_powername,"."
                                 )
            ,0);
    -- Old orders message
    Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<SUCCESS>"
                   ,"<Result>Tribute</Result>"
                   ,"<Powername>",sr_powername,"</Powername>"
                   ,"<Territory>",terrname,"</Territory>"
                   ,"<Amount>",tribute,"</Amount>"
                   ,"</SUCCESS>"
                   ));


-- Territory rebellion
ELSEIF rand <= 75 THEN
    -- Select territory, can not be Superpowers home territory
    Set done=0;
    OPEN territ;
    read_loop: LOOP
        -- Change each territory individually
        FETCH FROM territ INTO terrname, terrtype, terrno, sr_powername, minor, major, pterrtype;
        IF done THEN
            LEAVE sproc;
        ELSEIF terrtype != pterrtype and sr_powername != 'Locals' THEN
            LEAVE read_loop;
        END IF;
    END LOOP;

    -- Add message to queue
    Insert Into sp_message_queue (gameno, userno, message, to_email)
     Values (sr_gameno, 0, Concat("Local "
                                 ,Case
                                   When Length(terrtype)=3 Then 'Pirates'
                                   Else 'Warlords'
                                  End
                                 ," in ",terrname," declare independence."
                                 )
            ,0);

    -- Change ownership to locals
    Call sr_take_territory(sr_gameno, terrname, 'Warlord', major, minor);

    -- Old orders message
    Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<SUCCESS>"
                   ,"<Result>Rebellion</Result>"
                   ,"<Powername>",sr_powername,"</Powername>"
                   ,"<Territory>",terrname,"</Territory>"
                   ,"</SUCCESS>"
                   ));


-- Nuclear terrorists
ELSEIF rand <= 77 THEN
    -- Select territory, must be Superpowers home territory
    Set done=0;
    OPEN territ;
    read_loop: LOOP
        -- Change each territory individually
        FETCH FROM territ INTO terrname, terrtype, terrno, sr_powername, minor, major, pterrtype;
        IF done THEN
            LEAVE sproc;
        ELSEIF terrtype = pterrtype THEN
            LEAVE read_loop;
        END IF;
    END LOOP;

	-- Select power to lose nukes and update
	Select powername, userno, nukes Into sr_powername2, sr_userno, sr_nukes From sp_resource Where gameno=sr_gameno Order By nukes desc, rand() Limit 1;
	Set r1=Ceil(Rand()*3), r2=Least(sr_nukes, r1);
	Update sp_resource Set nukes=nukes-r2, nukes_left=Greatest(0,nukes_left-r1+r2) Where gameno=sr_gameno and powername=sr_powername2;
	Select nukes, nukes_left Into sr_nukes, sr_nukes_left From sp_resource Where gameno=sr_gameno and powername=sr_powername2;

    -- Add global message to queue
    Insert Into sp_message_queue (gameno, userno, to_email, message)
     Values (sr_gameno, 0, 0
            ,Concat("Terrorists have unleased a dirty bomb in ",terrname,", after stealing "
                    ,Case When r2>1 Then Concat(r2," nukes ") When r2=1 Then "1 nuke " Else "" End
					,Case When r2>0 and r1-r2>0 Then "and " Else "" End
                    ,Case When r1-r2>0 Then Concat(r1-r2," nuclear material ") Else "" End
					,"from ",sr_powername2,"."
					)
            );

    -- Add stolen message to queue
    Insert Into sp_message_queue (gameno, userno, to_email, message)
     Values (sr_gameno, sr_userno, -1
            ,Concat("Terrorists have stolen "
                    ,Case When r2>1 Then Concat(r2," nukes ") When r2=1 Then "1 nuke " Else "" End
					,Case When r2>0 and r1-r2>0 Then "and " Else "" End
                    ,Case When r1-r2>0 Then Concat(r1-r2," nuclear material ") Else "" End
					,"from you. You now have "
                    ,Case When sr_nukes>1 Then Concat(r2," nukes ") When r2=1 Then "1 nuke " Else "0 nukes " End
					,"and ",sr_nukes_left," nuclear material."
					)
            );

    -- Change ownership to nuked
    Call sr_take_territory(sr_gameno, terrname, 'Nuke', 0, 0);

    -- Old orders message
    Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<SUCCESS>"
                   ,sf_fxml("Result","DirtyBomb")
                   ,sf_fxml("Territory",terrname)
                   ,sf_fxml("PreviousPowername",sr_powername)
                   ,sf_fxml("NukePowername",sr_powername2)
                   ,sf_fxml("NukesUsed",r2)
                   ,sf_fxml("NuclearMaterialUsed",r2-r1)
                   ,sf_fxml("NukesLeft",sr_nukes)
                   ,sf_fxml("NuclearMaterialLeft",sr_nukes_left)
                   ,"</SUCCESS>"
                   ));


-- Espionage up
ELSEIF rand <= 85 THEN
        -- Select power
        OPEN superpower;
        FETCH superpower INTO sr_powername, sr_userno;
        CLOSE superpower;

        -- Update resource table
        Update sp_resource r Set r.espionage_tech=r.espionage_tech+1 Where r.gameno=sr_gameno and r.powername=sr_powername;
        Select espionage_tech Into new_level From sp_resource r Where r.gameno=sr_gameno and r.powername=sr_powername;

    -- Add message to queue
    Insert Into sp_message_queue (gameno, userno, message, to_email)
     Values (sr_gameno, sr_userno, Concat("Your spy network achieves a major breakthrough."
                                    ," Your new Espionage level is ",new_level
                                    )
            ,0);

    -- Old orders message
    Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<SUCCESS>"
                   ,"<Result>EspionageUp</Result>"
                   ,"<Powername>",sr_powername,"</Powername>"
                   ,"<NewLevel>",new_level,"</NewLevel>"
                   ,"</SUCCESS>"
                   ));


-- Espionage down
ELSEIF rand <= 90 THEN
    -- Select power
    OPEN superpower;
    FETCH superpower INTO sr_powername, sr_userno;
    CLOSE superpower;

    -- Update resource table
    Update sp_resource r Set r.espionage_tech=r.espionage_tech-1 Where r.gameno=sr_gameno and r.powername=sr_powername;
    Select espionage_tech Into new_level From sp_resource r Where r.gameno=sr_gameno and r.powername=sr_powername;

    -- Add message to queue
    Insert Into sp_message_queue (gameno, userno, message, to_email)
     Values (sr_gameno, sr_userno, Concat("You have been double crossed by a senior spy."
                                    ," Your new Espionage level is ",new_level
                                    )
            ,0);
    Insert Into sp_message_queue (gameno, userno, message, to_email)
     Values (sr_gameno, 0, Concat("Double agent from ",sr_powername," exposes secrets to the world.")
            ,0);

    -- Old orders message
    Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<SUCCESS>"
                   ,"<Result>EspionageDown</Result>"
                   ,"<Powername>",sr_powername,"</Powername>"
                   ,"<NewLevel>",new_level,"</NewLevel>"
                   ,"</SUCCESS>"
                   ));


-- UN research
ELSE
    Set done=0, sr_message='';
    Select Ceil(rand()*9), Ceil(rand()*8) Into r1, r2;
    Set r2=r2 + Case When r2 >= r1 Then 1 Else 0 End;
    OPEN res;
    read_loop: LOOP
        FETCH FROM res Into sr_userno, sr_powername, sr_cash, sr_loan, sr_minerals, sr_oil, sr_grain, sr_nukes, sr_lstars, sr_ksats, sr_neutron;
        IF done THEN LEAVE read_loop; END IF;
        IF @sr_debug='Y' THEN Select "FORTUNA - UN REPORT", sr_userno, sr_powername, r1, r2; END IF;
        Set sr_message = Concat(sr_message
                               ,sf_fxml("Powername"
                                       ,Concat(sf_fxml('Superpower',sr_powername)
                                              ,Case
                                                When r1=1 Then sf_fxml("Cash",sr_cash)
                                                When r1=2 Then sf_fxml("Loan",sr_loan)
                                                When r1=3 Then sf_fxml("Minerals",sr_minerals)
                                                When r1=4 Then sf_fxml("Oil",sr_oil)
                                                When r1=5 Then sf_fxml("Grain",sr_grain)
                                                When r1=6 Then sf_fxml("Nukes",sr_nukes)
                                                When r1=7 Then sf_fxml("L-Stars",sr_lstars)
                                                When r1=8 Then sf_fxml("K-Sats",sr_ksats)
                                                When r1=9 Then sf_fxml("Neutron",sr_neutron)
                                               End
                                              ,Case
                                                When r2=1 Then sf_fxml("Cash",sr_cash)
                                                When r2=2 Then sf_fxml("Loan",sr_loan)
                                                When r2=3 Then sf_fxml("Minerals",sr_minerals)
                                                When r2=4 Then sf_fxml("Oil",sr_oil)
                                                When r2=5 Then sf_fxml("Grain",sr_grain)
                                                When r2=6 Then sf_fxml("Nukes",sr_nukes)
                                                When r2=7 Then sf_fxml("L-Stars",sr_lstars)
                                                When r2=8 Then sf_fxml("K-Sats",sr_ksats)
                                                When r2=9 Then sf_fxml("Neutron",sr_neutron)
                                               End)
                                       )
                               );
    END LOOP;
    Close res;
    Set sr_message = sf_fxml('UNREPORT',sr_message);
    Insert Into sp_old_orders (gameno, turnno, phaseno, ordername, order_code) Values (sr_gameno, sr_turnno, sr_phaseno, proc_name, sf_fxml("SUCCESS",'UN Report'));
    Insert Into sp_message_queue (gameno, message) Values (sr_gameno, sr_message);

END IF;
END sproc;
END
$$

Delimiter ;

