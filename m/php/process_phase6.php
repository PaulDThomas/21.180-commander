<?php

// Process orders from phase 6
// $Id: process_phase6.php 107 2012-08-23 00:06:26Z paul $

//? Assume no bad submits

// All info should be in the SR_ORDERXML
$result = $mysqli -> query ("select order_code From sp_orders Where gameno=$gameno and phaseno=$phaseno and ordername='SR_ORDERXML'") or die ("PROCESS_PHASE6:1:"+$mysqli->error);
if ($result -> num_rows > 0) $row = $result -> fetch_assoc();
$result -> close();

libxml_use_internal_errors(true);
$orderxml = SimpleXML_Load_String((isset($row['order_code']))?$row['order_code']:'<TRANSACTION></TRANSACTION>');

if ($_POST['transaction']=='Accept') {
    $ordersOK = 'Y';
    // Check transaction
    foreach ($_POST as $key=>$val) if (!in_array($key,array('randgen','PROCESS','transaction','Accepted'))) {
        if ($val != $orderxml -> $key) $ordersOK = 'N';
    }
    // Accept or reject
    $orderxml -> Accepted = $_POST['Accepted'];
    $row['order_code'] = $orderxml -> asXML();
    $mysqli -> query("Update sp_orders Set order_code = '${row['order_code']}' Where gameno=$gameno and phaseno=$phaseno and ordername='SR_ORDERXML'") or die ("PROCESS_PHASE6:2:"+$mysqli->error);

} else {
    // Update ORDERXML
    foreach ($_POST as $key=>$val) if ($key != 'randgen' and $key != 'PROCESS') $orderxml -> $key = $val;

    // Put XML back into the table
    $row['order_code'] = $orderxml -> asXML();
    $mysqli -> query("Delete From sp_orders Where gameno=$gameno and userno=$userno and phaseno=$phaseno and ordername='SR_ORDERXML'") or die ("PROCESS_PHASE6:3:"+$mysqli->error);
    if ($_POST['Amount'] > 0 or $_POST['Resource']='Pass') $mysqli -> query("Insert Into sp_orders (gameno, turnno, phaseno, userno, ordername, order_code) Values ($gameno, $turnno, $phaseno, $userno, 'SR_ORDERXML', '${row['order_code']}')") or die ("PROCESS_PHASE6:4:"+$mysqli->error);
}

// Set orders to submitted
// Always move the queue
require_once("utl_multi_query.php");
$query_out = utl_multi_query("set @sr_debug='Y';call sr_move_queue_transaction($gameno); set @sr_debug='N';");

?>