<?php
// Code to process a cash transfer
// $Id: process_banking.php 130 2013-05-12 11:39:20Z paul $

// Initialise
require_once("../php/checklogin.php");

// Stop if not ready
if ($username == '' or $username == 'FAIL' or $gameno == '0') exit;

// Stop and reload the page if randgen not matched (randgen is always 10 characters)
if ($RESOURCE['randgen'] == (isset($_POST['randgen'])?$_POST['randgen']:'*FAIL*')) {

    // Process loan
    if (isset($_POST['loanAmt'])) {
        $result = $mysqli -> query("call sr_change_loan($gameno, '$powername', ${_POST['loanAmt']})") or die($mysqli -> error);
        $result = $mysqli -> query("select * from sp_resource where gameno=$gameno and powername='$powername'");
        $RESOURCE = $result -> fetch_assoc();
        $result -> close();
        $RESOURCE['resultTitle'] = "Loan";
        $RESOURCE['resultText'] = "Loan application processed";
    }

    // Process cash transfer
    else if (isset($_POST['transferAmt'])) {
        $mysqli -> query("call sr_transfer_cash($gameno, '$powername', '${_POST['transferTo']}', ${_POST['transferAmt']})") or die($mysqli -> error);
        $result = $mysqli -> query("select * from sp_resource where gameno=$gameno and powername='$powername'");
        $RESOURCE = $result -> fetch_assoc();
        $result -> close();
        $RESOURCE['resultTitle'] = "Transfer";
        $RESOURCE['resultText'] = "Cash transfer processed";
    }

} else {
    // Randgen failure
    $RESOURCE['resultText'] = "An issue has occured, please refresh the page and try again.";
    $RESOURCE['resultTitle'] = "ERROR";
}

// Set up XML element & send to XML
$RESOURCE['cash_avail'] = floor(($RESOURCE['cash']-$RESOURCE['cash_transferred_in']+$RESOURCE['cash_transferred_out'])*$GAME['liquid_asset_percent']/100) + $RESOURCE['cash_transferred_in'] - $RESOURCE['cash_transferred_out'];
$returnXML = new SimpleXMLElement('<?xml version="1.0"?><MESSAGE></MESSAGE>');
foreach ($RESOURCE as $var => $val) $returnXML -> addChild($var,$val);
echo $returnXML->asXML();

?>