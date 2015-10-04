<?php

// Update initial orders
// $Id: orders_phase0_update.php 177 2013-12-28 16:07:52Z paul $

// Start page
require_once("../php/checklogin.php");
// Set up XML element
$initXML = new SimpleXMLElement('<?xml version="1.0"?><INITIAL></INITIAL>');
$INITIAL = array();

// Stop if not ready
if ($username == '' or $username == 'FAIL' or $gameno == '0' or $phaseno != '0') {
    $initXML -> addChild('success','Orders failed, please refresh the page');
    $xmlstring = $initXML->asXML();
} else {
    $initXML -> addChild('success','Orders received');
    foreach ($_POST as $param => $val) {
        $z = explode('-',$param);
        $key = $z[0];
        $initXML -> addChild($key,$val);
    };
    // Get string
    $xmlstring = $initXML->asXML();
    // Update orders
    $mysqli -> query("Update sp_orders set order_code = '$xmlstring' Where gameno=$gameno and userno=$userno and ordername='SR_ORDERXML'");
    $mysqli -> query("Update sp_orders set order_code = 'Orders received' Where gameno=$gameno and userno=$userno and ordername='ORDSTAT'");
}

// Send $INITIAL to XML
echo $xmlstring;

// Close page
$mysqli -> close();
?>
