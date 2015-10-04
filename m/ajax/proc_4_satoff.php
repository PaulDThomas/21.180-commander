<?php

// Satellite offensive processing...
// $Id: proc_4_satoff.php 243 2014-07-13 14:55:45Z paul $

// Start page
require_once("../php/checklogin.php");

// Stop if not ready
if ($username == ''
    or $username == 'FAIL'
    or $gameno == '0'
    or (isset($_POST['randgen'])?$_POST['randgen']:'*FAIL')!=$RESOURCE['randgen']) exit;

// Look for STOP
if (isset($_POST['lstarStop'])) {
    $mysqli -> query("update sp_orders set order_code='Orders processed' Where gameno=${_SESSION['sp_gameno']} and userno=${_SESSION['sp_userno']} and ordername='ORDSTAT' and order_code='Orders processing'");
    $mysqli -> query("call sr_move_queue($gameno)");
    echo "<LSTAR><STOP>Stop</STOP></LSTAR>";
    $mysqli -> close();
    exit;
}

// Look for refresh
else if (isset($_POST['getCurrent'])) {
    $query = "Select message From sp_message_queue Where gameno=$gameno and userno=-7 and ExtractValue(message,'/LSTAR/AttPowername')='$powername';";
    $result = $mysqli -> query($query) or die ("<FAIL>".$mysqli->error."</FAIL>");;
    if ($result -> num_rows > 0) {
        $row = $result -> fetch_row();
        echo $row[0];
        $result -> close();
    }
    $mysqli -> close();
    exit;
}

// Process $_POST  attack orders
else {
    $query = "call sr_4_lstar_battle($gameno, '$powername', '${_POST['def_power']}')";
    $result = $mysqli -> query($query) or die ("<FAIL>".$mysqli->error."</FAIL>");
    if ($result->num_rows > 0) $row = $result -> fetch_row() or die ("<FAIL>".$mysqli->error."</FAIL>");
    else $row[0]='<FAIL>No rows returned, check orders log</FAIL>';
    $result -> close();

    // Send output back
    echo '<?xml version="1.0"?>';
    echo $row[0];
    $mysqli -> close();
} ?>