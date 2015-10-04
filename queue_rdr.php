<?php

/*
** Description  : Process game queue options and redirect to correct page
**
** Script name  : queue_rdr.php
** Author       : Paul Thomas
** Date         : 9th Feburary 2004
**
** $Id: queue_rdr.php 274 2015-02-03 08:56:38Z paul $
**
*/

// Start page
require_once("m/php/checklogin.php");
require_once("m/php/newq_x_params.php");

// Redirect if not ready
if ($username == '' or $username == 'FAIL') {
    header("Location:login.php");
}

// Process Taken Opening
// Need to move this to a re-direct page
if (isset($_GET['gamerevolution']) and isset($_GET['powername'])) {
//    $gameno = isset($_POST['gameno'])?$_POST['gameno']:0;
//    $powername = isset($_POST['powername'])?$_POST['powername']:0;
//    $mysqli -> query("call sr_revolution($gameno, '$powername', $userno)");
//    $_SESSION['sp_gameno'] = $gameno;
    header("Location:game.php");
//    exit;
}

// Process queue buttons
else if ((isset($_POST['PROCESS'])?$_POST['PROCESS']:'') == 'Join') {
    $mysqli -> query("Delete From sp_newq Where userno = $userno");
    $mysqli -> query("Insert Into sp_newq (players, advance_uts, userno) Values (${_POST['players']}, ${_POST['advance_uts']}, $userno)") or die ("QRDR:1 ".$mysqli->error);
    header("Location:queue.php");
} else if ((isset($_POST['PROCESS'])?$_POST['PROCESS']:'') == 'In queue') {
    $mysqli -> query("Delete From sp_newq Where players=${_POST['players']} and advance_uts=${_POST['advance_uts']} and userno=$userno") or die ("QRDR:2 ".$mysqli->error);
    header("Location:queue.php");
} else if ((isset($_POST['PROCESS'])?$_POST['PROCESS']:'') == 'Create') {
    $mysqli -> query("Delete From sp_newq Where userno = $userno") or die ("QRDR:3 ".$mysqli->error);
    $query = "Insert Into sp_newq_params (players, advance_uts, phase2_type, newq_description";
    foreach ($newq_xml->Parameter as $val) {$query .= ",$val->Name";}
    $query .= ") Values (${_POST['players']},${_POST['advance_uts']},'${_POST['phase2_type']}','${_POST['newq_description']}'";
    foreach ($newq_xml->Parameter as $val) {$query .= ",'".$_POST["$val->Name"]."'";}
    $query .= ")";
    $mysqli -> query($query) or die ("QRDR:4: Query='".$query."'<br/>".$mysqli -> error);
    $mysqli -> query("Insert Into sp_newq (players, advance_uts, userno) Values (${_POST['players']}, ${_POST['advance_uts']}, $userno)") or die ("QRDR:5 ".$mysqli->error);
    header("Location:queue.php");
}

// Delete any redundant queue parameter sets
$mysqli -> query("Delete From sp_newq_params Where not exists (Select * From sp_newq nq Where nq.players=sp_newq_params.players and nq.advance_uts=sp_newq_params.advance_uts)") or die ("QRDR:6 ".$mysqli->error);

$mysqli -> close();
?>ss
If you are not redirected, please click <a href="queue.php">here</a>.
