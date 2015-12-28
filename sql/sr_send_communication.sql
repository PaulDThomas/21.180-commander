use asupcouk_asup;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
Drop procedure if exists sr_send_communication;

DELIMITER $$

CREATE PROCEDURE `asupcouk_asup`.`sr_send_communication` (sr_gameno INT, sr_powername VARCHAR(15), sr_to_xml TEXT, sr_message TEXT)
BEGIN
sproc:BEGIN

-- Procedure to send messages
-- $Id: sr_send_communication.sql 242 2014-07-13 13:48:48Z paul $
DECLARE proc_name TEXT DEFAULT "SR_SEND_COMMUNICATION";
DECLARE sr_userno INT DEFAULT 0;
-- DECLARE sr_to_userno INT DEFAULT 0;
DECLARE sr_to_powername VARCHAR(15);
DECLARE header TEXT;
DECLARE sr_turnno INT DEFAULT 0;
DECLARE sr_phaseno INT DEFAULT 0;
DECLARE i INT DEFAULT 1;
DECLARE message TEXT;
DECLARE sr_white_comms_level INT;
DECLARE sr_grey_comms_level INT;
DECLARE sr_black_comms_level INT;
DECLARE sr_yellow_comms_level INT;
DECLARE sr_espionage INT DEFAULT 0;

-- Check game and phase
IF sr_gameno not in (Select gameno From sp_game) THEN
    Insert into sp_old_orders (gameno, ordername, order_code)
     Values (sr_gameno, proc_name
            ,Concat(sf_fxml("FAIL",
                            Concat(sf_fxml("Reason","Invalid game")
                                  ,sf_fxml("Gameno",sr_gameno)
                                  )
                           )
                    )
            );
    LEAVE sproc;
END IF;
Select turnno, phaseno, white_comms_level, grey_comms_level, black_comms_level, yellow_comms_level 
Into sr_turnno, sr_phaseno, sr_white_comms_level, sr_grey_comms_level, sr_black_comms_level, sr_yellow_comms_level 
From sp_game 
Where gameno=sr_gameno
;

-- Check From Powername
IF sr_powername not in (Select powername From sp_resource Where gameno=sr_gameno and (dead='N' or sr_phaseno=9)) THEN
    Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, proc_name
            ,Concat(sf_fxml("FAIL",
                            Concat(sf_fxml("Reason","Invalid From Powername")
                                  ,sf_fxml("Gameno",sr_gameno)
                                  ,sf_fxml("Powername",sr_powername)
                                  )
                            )
                    )
            );
    LEAVE sproc;
END IF;
Select userno, espionage_tech
Into sr_userno, sr_espionage  
From sp_resource 
Where gameno=sr_gameno 
 and powername=sr_powername
;

IF @sr_debug!='N' THEN 
   Select sr_powername, sr_espionage, sr_white_comms_level, sr_grey_comms_level, sr_black_comms_level
          ,sr_yellow_comms_level, sr_to_xml;
END IF;

-- Check black (no from) comms are available
IF extractValue(sr_to_xml,'/NoFrom') != '' and sr_espionage < sr_black_comms_level THEN
    Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, proc_name
            ,Concat(sf_fxml("FAIL",
                            Concat(sf_fxml("Reason","Low tech for No From")
                                  ,sf_fxml("Gameno",sr_gameno)
                                  ,sf_fxml("Espionage",sr_espionage)
                                  ,sf_fxml("BlackCommsLevel",sr_black_comms_level)
                                  ,sf_fxml("Powername",sr_powername)
                                  ,sr_to_xml
                                  )
                            )
                    )
            );
    LEAVE sproc;
END IF;

-- Check grey (no to) comms are available
IF extractValue(sr_to_xml,'/NoTo') != '' and sr_espionage < sr_grey_comms_level THEN
    Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, proc_name
            ,Concat(sf_fxml("FAIL",
                            Concat(sf_fxml("Reason","Low tech for No To")
                                  ,sf_fxml("Gameno",sr_gameno)
                                  ,sf_fxml("Espionage",sr_espionage)
                                  ,sf_fxml("greyCommsLevel",sr_grey_comms_level)
                                  ,sf_fxml("Powername",sr_powername)
                                  ,sr_to_xml
                                  )
                            )
                    )
            );
    LEAVE sproc;
END IF;

-- Check yellow (wrong from) comms are available
IF extractValue(sr_to_xml,'/SendAs') != '' and sr_espionage < sr_yellow_comms_level THEN
    Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, proc_name
            ,Concat(sf_fxml("FAIL",
                            Concat(sf_fxml("Reason","Low tech for Send As")
                                  ,sf_fxml("Gameno",sr_gameno)
                                  ,sf_fxml("Espionage",sr_espionage)
                                  ,sf_fxml("YellowCommsLevel",sr_yellow_comms_level)
                                  ,sf_fxml("Powername",sr_powername)
                                  ,sr_to_xml
                                  )
                            )
                    )
            );
    LEAVE sproc;
END IF;

-- Check white (private) comms are available
IF extractValue(sr_to_xml,'/NoTo') = '' 
   and extractValue(sr_to_xml,'/NoFrom') = '' 
   and extractValue(sr_to_xml,'/SendAs') = '' 
   and sr_espionage < sr_white_comms_level THEN
    Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, proc_name
            ,Concat(sf_fxml("FAIL",
                            Concat(sf_fxml("Reason","Low tech for white comms")
                                  ,sf_fxml("Gameno",sr_gameno)
                                  ,sf_fxml("Espionage",sr_espionage)
                                  ,sf_fxml("WhiteCommsLevel",sr_white_comms_level)
                                  ,sf_fxml("Powername",sr_powername)
                                  ,sr_to_xml
                                  )
                            )
                    )
            );
    LEAVE sproc;
END IF;

-- Check not yellow and black comms at same time
IF extractValue(sr_to_xml,'/NoFrom') != '' 
   and extractValue(sr_to_xml,'/SendAs') != '' THEN
    Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, proc_name
            ,Concat(sf_fxml("FAIL",
                            Concat(sf_fxml("Reason","Send As and No From at the same time")
                                  ,sf_fxml("Gameno",sr_gameno)
                                  ,sf_fxml("Powername",sr_powername)
                                  ,sr_to_xml
                                  )
                            )
                    )
            );
    LEAVE sproc;
END IF;

-- Start header, with From
IF extractValue(sr_to_xml,'/NoFrom') != '' THEN
	Set header = Concat(sf_fxml("From",Concat(sf_fxml('RealPowername',sf_format(sr_powername)),sf_fxml('Powername','?'))),'<To>');
ELSEIF extractValue(sr_to_xml,'/SendAs') != '' THEN
	Set header = Concat(sf_fxml("From",Concat(sf_fxml('RealPowername',sf_format(sr_powername)),sf_fxml('Powername',extractValue(sr_to_xml,'/SendAs')))),'<To>');
ELSE 
	Set header = Concat(sf_fxml("From",sf_fxml('Powername',sf_format(sr_powername))),'<To>');
END IF;

-- Build TO information
Create Temporary Table tmp_mess (powername text, userno int);
IF extractValue(sr_to_xml,'/NoTo')!='' THEN 
	-- Insert valid powers into send table
	Insert Into tmp_mess Values (extractValue(sr_to_xml,'/NoTo'), 0);
	Set header = Concat(header, sf_fxml('Powername','Global'));
ELSE 
	-- Check all To powernames, first add to a temporary table
	Set i=1;
	read_loop: LOOP
		Set sr_to_powername = extractValue(sr_to_xml,Concat('/Powername[',i,']'));
		IF sr_to_powername='' Then LEAVE read_loop; END IF;

		-- Fail on bad powername
		IF sr_to_powername not in (Select powername From sp_resource Where gameno=sr_gameno and (dead='N' or sr_phaseno=9) and powername!=sr_powername) THEN
			Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
			 Values (sr_gameno, sr_turnno, sr_phaseno, proc_name
					,Concat(sf_fxml("FAIL",
									Concat(sf_fxml("Reason","Invalid To Powername")
										  ,sf_fxml("Gameno",sr_gameno)
										  ,sf_fxml("Powername",sr_powername)
										  ,sf_fxml("Powername",sr_to_xml)
										  )
									)
							)
					);
			Drop Temporary Table tmp_mess;
			LEAVE sproc;
		ELSE
			-- Insert valid powers into send table
			Insert Into tmp_mess Select sr_to_powername, userno From sp_resource Where gameno=sr_gameno and powername=sr_to_powername;
			Set header = Concat(header, sf_fxml('Powername',sr_to_powername));
			Set i=i+1;
		END IF;
	END LOOP;
END IF;

-- Post messages to everyone, update will messageno after insert
Set header = Concat(header,'</To>');
Set sr_message = sf_fxml('COMMS',Concat(header,sf_fxml('Text',sr_message)));

Insert Into sp_messages (gameno, userno, message) values (sr_gameno, sr_userno, sr_message);
Set sr_message = updateXML(sr_message,'/COMMS/Text',Concat(sf_fxml('messageno',last_insert_id()),sf_fxml('Text',extractValue(sr_message,'/COMMS/Text'))));
Update sp_messages Set message=sr_message Where messageno=last_insert_id();

Set sr_message = updateXML(sr_message,'//RealPowername','');
Insert Into sp_messages (gameno, userno, to_email, message) Select sr_gameno, userno, -1, sr_message From tmp_mess;

Drop Temporary Table If Exists tmp_mess;
/* */
END sproc;
END
$$

Delimiter ;

/*
Drop Temporary Table if exists tmp_mess;

Delete From sp_old_orders;
Delete From sp_messages;

-- Bad game
call sr_send_communication(-1,'Europe','<Powername>China</Powername>','One');

-- Bad From power
call sr_send_communication(183,'South americas','<Powername>China</Powername>','Two');

-- Bad To power
call sr_send_communication(183,'Europe','<Powername>China</Powername><Powername>south america</Powername>','Three');

update sp_resource set espionage_tech=-1 where gameno=183 and userno=3227;
update sp_game set white_comms_level=1, grey_comms_level=1, black_comms_level=1, yellow_comms_level=1 where gameno=183;
-- Fail on tech
call sr_send_communication(183,'Europe','<Powername>China</Powername><Powername>Africa</Powername>','Four');
call sr_send_communication(183,'Europe','<Powername>China</Powername><NoFrom>?</NoFrom>','Five');
call sr_send_communication(183,'Europe','<NoTo>?</NoTo>','Six');
call sr_send_communication(183,'Europe','<Powername>China</Powername><SendAs>Africa</SendAs>','Seven');

-- Fail on black/yellow
update sp_resource set espionage_tech=5 where gameno=183 and userno=3227;
call sr_send_communication(183,'Europe','<Powername>China</Powername><SendAs>Africa</SendAs><NoFrom>?</NoFrom>','Eight');

-- Working
call sr_send_communication(183,'Europe','<Powername>China</Powername><Powername>Africa</Powername>','White Four');
call sr_send_communication(183,'Europe','<Powername>China</Powername><NoFrom>?</NoFrom>','Black Five');
call sr_send_communication(183,'Europe','<NoTo>?</NoTo>','Grey Six');
call sr_send_communication(183,'Europe','<Powername>China</Powername><SendAs>Africa</SendAs>','Yellow Seven');
call sr_send_communication(183,'Europe','<NoTo>?</NoTo><SendAs>Africa</SendAs>','Yellow Grey Eight');

-- */;