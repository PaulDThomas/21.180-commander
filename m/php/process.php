<?php

// Orders processing junction
// $Id: process.php 183 2014-01-13 20:44:15Z paul $

// Remove all POST if randgen not matched (randgen is always 10 characters)
if ($RESOURCE['randgen'] != (isset($_POST['randgen'])?$_POST['randgen']:'*FAIL*')) {
    foreach($_POST as $key=>$val) unset($_POST[$key]);
    header("location:index.php");
    //echo "Out of sync orders";
    exit;
    }

// Process pre-pass if necessary
if (isset($_POST['Prepass']) ? $_POST['Prepass'] : '' == 'Pass') {
    $mysqli -> query("Update sp_orders Set order_code='Passed' Where gameno=$gameno and userno=$userno and turnno=$turnno and phaseno=$phaseno and ordername='ORDSTAT'");
    $mysqli -> query("Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code) Values ($gameno, $userno, $turnno, $phaseno, 'SR_PREPASS', 'Pre-pass')");
}

// Process force pass if necessary
else if (isset($_POST['Force']) ? $_POST['Force'] : '' == 'Force') {
    // Add OLD ORDERS force information
    $forceXML = new SimpleXMLElement("<?xml version='1.0'?><FORCE><Forcer>$powername/$userno</Forcer></FORCE>");
    $result = $mysqli -> query("Select powername, userno, username From sv_current_orders Where gameno=$gameno and order_code like 'Waiting%'") or die ($mysqli -> error);
    if ($result -> num_rows > 0) {
        while ($row = $result -> fetch_assoc()) $forceXML -> addChild(str_replace(" ","",$row['powername']),$row['userno'].'/'.$row['username']);
        $result -> close();
    }
    $mysqli -> query("Insert Into sp_old_orders (gameno, turnno, phaseno, userno, ordername, order_code) Values ($gameno, $turnno, $phaseno, $userno, 'FORCE', '".$forceXML->asXML()."')");
    require_once("utl_multi_query.php");
    $query_out = utl_multi_query("set @sr_debug='Y';call sr_move_queue($gameno);set @sr_debug='N';");
}

// Process resign
else if (isset($_POST['Resign']) ? $_POST['Resign'] : '' == 'yes') {
    $mysqli -> query("Update sp_resource Set mia=5 Where gameno=$gameno and userno=$userno;");
    unset($_SESSION['sp_gameno']);
    unset($_SESSION['sp_powername']);
    $mysqli -> close();
    header("location:index.php");
    echo "Resign";
    exit;
}

// Call next script
else {
    $mysqli -> query("Update sp_game set process=1 where gameno=$gameno;");
    require_once ("m/php/process_phase$phaseno.php");
    $mysqli -> query("Update sp_game set process=null where gameno=$gameno;");
}

// Get updated RESOURCE parameters
$result = $mysqli -> query("Select * From sp_resource Where gameno=$gameno and userno=$userno") or die("PROCESS:1".$mysqli -> error.(isset($query_out)?$query_out:''));
$RESOURCE = $result -> fetch_assoc();
$result -> close();

// Get updated GAME parameters
$result = $mysqli -> query("Select * From sp_game Where gameno=$gameno") or die("PROCESS:2 - Select * From sp_game Where gameno=$gameno :".$mysqli -> error);
$GAME = $result -> fetch_assoc();
$result -> close();
$turnno = $GAME['turnno'];
$phaseno = $GAME['phaseno'];


?>
