<?php
// XML Response to request for available territories
// $Id: distance_xml.php 103 2012-08-01 07:38:38Z paul $

// Start page
require_once("../php/checklogin.php");

if ($username == '' or $username == 'FAIL' or $gameno == '' or $RESOURCE['dead']!='N') exit;

// GET cheat - remove before production!
$terrname = isset($_POST['terrname'])?$_POST['terrname']:$_GET['terrname'];
$action = isset($_POST['Action'])?$_POST['Action']:$_GET['Action'];

// Set up XML element
$rXML = new SimpleXMLElement("<?xml version='1.0'?><TERRITORY>$terrname</TERRITORY>");

// Get queries territory information
$result = $mysqli -> query("Select terrno, terrtype From sp_places Where terrname='$terrname'") or die($mysqli->error);
$row = $result -> fetch_assoc() or die("Invalid territory:".$terrname);
$rXML -> TerrNo = $row['terrno'];
$rXML -> TerrType = $row['terrtype'];
$terrtype = $row['terrtype'];
$result -> close();

// Add information for territories
$result = $mysqli -> query("call sr_distance($gameno, '$powername', '$terrname', '$action', @distance)");
if ($result -> num_rows > 0) while ($row = $result -> fetch_assoc()) {
    /*
    // Update actions when it is All to correct one
    if ($action!='All') $Action = $action;
    else {
        if ($row['powername'] != $powername and strlen($row['terrtype'])!=strlen($terrtype)) $Action = 'Coastal';
        else if ($row['powername'] != $powername and $row['powername'] != 'Neutral' and strlen($terrtype)==3) $Action = 'Naval';
        else if ($row['powername'] != $powername and $row['powername'] != 'Neutral') $Action = 'Ground';
        else if (strlen($row['terrtype'])!=strlen($terrtype)) $Action = 'Transport';
        else if (strlen($terrtype)==3) $Action = 'Sail';
        else $Action = 'March';
    }*/
    // Create to XML element
    if (!isset($rXML -> {$action})) $rXML -> {$action} = '';
    $terrto = $rXML -> {$action} -> addChild('option',"${row['terrname']}");
    $terrto -> addAttribute('TerrNo',$row['terrno']);
    $terrto -> addAttribute('Major',$row['major']);
    $terrto -> addAttribute('Minor',$row['minor']);
    $terrto -> addAttribute('Powername',$row['powername']);
    $terrto -> addAttribute('TerrType',$row['terrtype']);
    $terrto -> addAttribute('Distance',$row['cost']);
} else {
    if (!isset($rXML -> {$action})) $rXML -> {$action} = '';
    $rXML -> {$action} -> addChild('option','None');
}
$result -> close();

// Send to XML string
echo $rXML -> asXML();

// Close page
$mysqli -> close();
session_write_close();
?>