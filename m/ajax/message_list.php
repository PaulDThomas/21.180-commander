<?php

// $Id: message_list.php 207 2014-03-27 18:53:02Z paul $
// Message list feed

// Initialise
require_once("../php/checklogin.php");
require_once("../php/utl_xml_table.php");

// Stop if no game number assigned
if ($gameno == 0) exit;

// Stop posts without a powername or failed randgen
if ( ($powername == '' or (isset($_POST['randgen'])?$_POST['randgen']:'') != $RESOURCE['randgen'])
    and isset($_POST['sndText'])
    ) {echo "Message feed error:*$powername*".(isset($_POST['randgen'])?$_POST['randgen']:'')."*".$RESOURCE['randgen']; exit; }

// Process valid
else if (isset($_POST['sndText'])) {
    $_SESSION['message_first'] = 0;
    $messageDrop='';
    $who = '';
    foreach ($_POST as $key=>$val) if ($key != 'sndText' and $key != 'randgen') $who .= '<Powername>'.strtr($key,'_',' ').'</Powername>';
    $mysqli -> query("call sr_send_communication($gameno, '$powername', '$who', '".addslashes(htmlentities($_POST['sndText']))."')") or die ($mysqli->error);
}

else if (isset($_POST['messageRead']) and isset($powername)) {
	$mysqli -> query("Update sp_resource Set last_message_uts=unix_timestamp() Where gameno=$gameno and powername='$powername';") or die ($mysqli->error);
}

// Get last read message uts
$result = $mysqli -> query("Select last_message_uts From sp_resource Where gameno=$gameno and powername='$powername';") or die ($mysqli->error);
if ($result -> num_rows > 0) {$row = $result -> fetch_row(); $lastMessageUTS=isset($row[0])?$row[0]:0;}
else $lastMessageUTS=time();
$result -> close();

// Get message drop value
$messageDrop = isset($_POST['messageDropValue'])?$_POST['messageDropValue']:'All';

// Check to view other Superpower messages
$result = $mysqli -> query("Select userno From sp_resource Where gameno=$gameno and powername='$messageDrop' and espionage_tech <= ".(isset($RESOURCE)?$RESOURCE['espionage_tech']:-9)."-9");
if ($result -> num_rows > 0) {$row = $result -> fetch_row(); $userno=$row[0];}
$result -> close();

// Set session message pointer
if (!isset($_SESSION['message_first']) or isset($_POST['message_first'])) { $_SESSION['message_first'] = 0; }
$dt_format = (isset($_SESSION['dt_format'])?$_SESSION['dt_format']:'jS F Y h:i:s a');
$offset = isset($_SESSION['offset'])?$_SESSION['offset']:'0';

// Set message entries
$ent = isset($_POST['entries'])?$_POST['entries']:(isset($_SESSION['message_entries'])?$_SESSION['message_entries']:10);
// Process more and less arrows
if (isset($_POST['message_fewer'])) {$ent = max(5,$ent/2);}
elseif (isset($_POST['message_more'])) {$ent = $ent*2;}
$_SESSION['message_entries'] = $ent;

// Need to be $_SESSION['sp_gameno'] for guest.php
$from = "From sp_messages m Left Join sp_game g On m.gameno=g.gameno Left Join sp_resource r On r.gameno=m.gameno and r.userno=m.userno Where m.gameno=$gameno and (m.userno in (0, $userno) or phaseno=9)";
//$from = "From sp_messages m Left Join sp_game g On g.gameno=m.gameno Where m.gameno=$gameno and userno in (0, $userno)";

// Add in search text
if (isset($_POST['messageSearch'])) $from .= " and message like '%${_POST['messageSearch']}%'";

// Add in messageDrop
if ($messageDrop == 'Build reports') $from .= " and message like '<BUILDREPORT>%'";
else if ($messageDrop == 'Battle reports') $from .= " and (message like '<FIGHT>%' or message like '<LSTAR>%' or message like '<WARHEADS>%')";
else if ($messageDrop == 'Communication') $from .= " and message like '<COMMS>%'";
else if ($messageDrop == 'UN reports') $from .= " and (message like '<UNREPORT>%' or message like '<BRIBES>%')";
else if ($messageDrop == 'Salvage reports') $from .= " and message like '<DEADPOWER>%'";

// Highest message row
$result = $mysqli -> query ("Select Count(*) $from;") or die($mysqli -> error);
if ($result -> num_rows > 0) $row = $result -> fetch_row();
$_SESSION['message_limit'] = isset($row[0])?$row[0]:0;
$result -> close();

// Process forwards and backwards arrows
if (isset($_POST['message_older'])) {
    $_SESSION['message_first'] = min($_SESSION['message_first']+$ent, floor($_SESSION['message_limit']/$ent)*$ent);
} elseif (isset($_POST['message_newer'])) {
    $_SESSION['message_first'] = max($_SESSION['message_first']-$ent, 0);
}

// Run message query for specified entries
$query = "Select Distinct message_uts, message, to_email $from Order By messageno desc Limit ${_SESSION['message_first']},$ent";
$result = $mysqli -> query($query) or die ("Bad query syntax: ".$query);

if ($result->num_rows > 0) while ($row=$result->fetch_assoc()) {
?>
    <li>
        <div class="messageDate"<?php if ($row['message_uts'] > $lastMessageUTS) echo " style='font-style:normal;font-weight:bold;color:brown'"; ?>><?php echo gmdate($dt_format, $row['message_uts'] - $offset*60); ?></div>
        <div class="messageText"<?php if ($row['to_email'] < 0) echo " style='font-style:italic;color:blue'"; ?>><?php echo utl_xml_table($row['message']); ?></div>
    </li>
<?php
}

// Close result
$result -> close();
// Close connection
$mysqli -> close();
// Close session
session_write_close();

?>
