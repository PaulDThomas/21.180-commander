<?php

// Process orders from phase 7
// $Id: process_phase7.php 107 2012-08-23 00:06:26Z paul $

//? Assume no bad submits
$_SESSION['work']="ing";
// Buy the card, or assume pass
require_once("utl_multi_query.php");
if ((isset($_POST['CardNo'])?$_POST['CardNo']:-1) > 0) {
    $query_out = utl_multi_query("set @sr_debug='Y';call sr_acquire_comp($gameno, ${_POST['CardNo']}, '$powername');set @sr_debug='N';");
} else {
    $mysqli -> query("Update sp_orders Set order_code='Passed' Where gameno=$gameno and userno=$userno and turnno=$turnno and phaseno=$phaseno and ordername='ORDSTAT'") or die($mysqli->error);
    require_once("utl_multi_query.php");
    $query_out = utl_multi_query("set @sr_debug='Y';call sr_move_queue($gameno);set @sr_debug='N';");
}
?>