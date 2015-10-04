<?php
// $Id: communications_list.php 207 2014-03-27 18:53:02Z paul $
// Message list feed

// Initialise
require_once("../php/checklogin.php");
require_once("../php/utl_xml_table.php");

// Start XML
echo '<?xml version="1.0"?><comms>';

// Stop if no game number assigned
if ($gameno == 0) exit;

// Stop posts without a powername or failed randgen
if ( ($powername == '' or (isset($_POST['randgen'])?$_POST['randgen']:'') != $RESOURCE['randgen'])
    and isset($_POST['sndText'])
    ) {echo "<item>Communcation error, please refresh the page</item></comms>"; exit; }

// Process valid
else if (isset($_POST['comms_send']) and isset($_POST['sndText'])?$_POST['sndText']:'' != '') {
    $_SESSION['comms_first'] = 0;
    $messageDrop='';
    $who = '';
    if (isset($_POST['global'])) {
        $who = '<NoTo>Global</NoTo>';
    } else {
        foreach ($_POST as $key=>$val) if ($key != 'sndText' and $key != 'randgen' and substr($key,0,5)!='comms' ) $who .= '<Powername>'.strtr($key,'_',' ').'</Powername>';
    }
    if ($_POST['comms_send']=='anon') $who .= '<NoFrom>?</NoFrom>';
    $mysqli -> query("call sr_send_communication($gameno, '$powername', '$who', '".addslashes(htmlentities($_POST['sndText']))."')") or die ($mysqli->error);
    echo "<sndOK>$who</sndOK>";
}

// Set session message pointer
if (!isset($_SESSION['comms_first']) or isset($_POST['comms_first'])) { $_SESSION['comms_first'] = 0; }
$dt_format = (isset($_SESSION['dt_format'])?$_SESSION['dt_format']:'jS F Y h:i:s a');
$offset = isset($_SESSION['offset'])?$_SESSION['offset']:'0';

// Set message entries
$ent = isset($_POST['entries'])?$_POST['entries']:(isset($_SESSION['comms_entries'])?$_SESSION['comms_entries']:10);
// Process more and less arrows
if (isset($_POST['comms_fewer'])) {$ent = max(5,$ent/2);}
elseif (isset($_POST['comms_more'])) {$ent = $ent*2;}
$_SESSION['comms_entries'] = $ent;
echo "<showing>$ent</showing>";

// Need to be $_SESSION['sp_gameno'] for guest.php
$from = "From sp_messages m Left Join sp_game g On m.gameno=g.gameno Left Join sp_resource r On r.gameno=m.gameno and r.userno=m.userno Where m.gameno=$gameno and (m.userno in (0, $userno) or phaseno=9) and message like '<COMMS>%' ";
//$from = "From sp_messages m Left Join sp_game g On g.gameno=m.gameno Where m.gameno=$gameno and userno in (0, $userno)";

// Add in powername filters
if (isset($_POST['global'])?$_POST['global']:'' != '') {
    $from .= "and extractValue(message,'//Powername') like '%Global%'";
} else {
    $from .= "and (extractValue(message,'//Powername') like '%Global%' or (1 ";
    foreach ($_POST as $key=>$val) if ($key != 'sndText' and $key !='randgen' and substr($key,0,5)!='comms' ) $from .= "and extractValue(message,'//Powername') like '%$key%' ";
    $from .= "))";
}

// Process forwards and backwards arrows
if (isset($_POST['comms_older'])) {
    $_SESSION['comms_first'] = min($_SESSION['comms_first']+$ent, floor($_SESSION['comms_limit']/$ent)*$ent);
} elseif (isset($_POST['comms_newer'])) {
    $_SESSION['comms_first'] = max($_SESSION['comms_first']-$ent, 0);
}
echo "<first>${_SESSION['comms_first']}</first>";

// Highest message row
$query = "Select Distinct message_uts, message $from and to_email >= 0 Order By messageno desc";
$result = $mysqli -> query($query) or die ("Bad query syntax: ".$query);
$_SESSION['comms_limit'] = $result -> num_rows;
echo "<total>${_SESSION['comms_limit']}</total>";
$result -> close();

// Run message query for specified entries
$query = "Select Distinct message_uts, message $from and to_email >= 0 Order By messageno desc Limit ${_SESSION['comms_first']},$ent";
$result = $mysqli -> query($query) or die ("Bad query syntax: ".$query);
echo "<messages>";
if ($result->num_rows > 0) while ($row=$result->fetch_assoc()) {
    echo "<message><messageDate>".gmdate($dt_format, $row['message_uts'] - $offset*60)."</messageDate><messageText><![CDATA[".utl_xml_table($row['message'])."]]></messageText></message>";
}
echo "</messages>";
//echo "<qry><![CDATA[$query]]></qry>";

// Close result
$result -> close();
// Close connection
$mysqli -> close();
// Close session
session_write_close();

echo "</comms>";

?>