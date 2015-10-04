<?php

// Retreive XML resource values for a game
// $Id: resource_xml.php 243 2014-07-13 14:55:45Z paul $

// Start page
require_once("../php/checklogin.php");

if ($username == '' or $username == 'FAIL' or $gameno == '' or (isset($RESOURCE['dead'])?$RESOURCE['dead']:'')!='N') exit;

// Set resource strings for queries
$res1 = "cash, interest, loan";
$res3 = "minerals, oil, grain, max_minerals, max_oil, max_grain";
$res5 = "nukes, nukes_left, lstars, ksats, neutron";
$res7 = "land_tech, water_tech, strategic_tech, resource_tech, espionage_tech";

// Set up XML element
$resourceXML = new SimpleXMLElement('<?xml version="1.0"?><RESOURCE></RESOURCE>');

// Change resource array if powername is not user
if ( (isset($_POST['powername'])?$_POST['powername']:$_SESSION['sp_powername']) != $_SESSION['sp_powername']) {
    // Get other power tech
    $result = $mysqli -> query("Select espionage_tech From sp_resource Where gameno=$gameno and powername='${_POST['powername']}' and dead='N'");
    // Proceed if a row is returned
    if ($result -> num_rows > 0) {
        $row = $result -> fetch_row();

        $res = 'powername';
        if ($row[0] < $RESOURCE['espionage_tech'])   $res .= ','.$res1;
        if ($row[0] < $RESOURCE['espionage_tech']-2) $res .= ','.$res3;
        if ($row[0] < $RESOURCE['espionage_tech']-4) $res .= ','.$res5;
        if ($row[0] < $RESOURCE['espionage_tech']-6) $res .= ','.$res7;

        $result = $mysqli -> query("Select $res From sp_resource Where gameno=$gameno and powername='${_POST['powername']}'") or die($mysqli->error);
        if ($result -> num_rows < 1) {$mysqli -> close(); echo "no resources"; exit;}
        $resource = $result -> fetch_assoc();
        $result -> close();
    } else {echo "no espionage"; exit;}
} else $resource = $RESOURCE;

// Send $resource to XML
foreach ($resource as $var => $val) $resourceXML -> addChild($var,$val);

echo $resourceXML->asXML();

// Close page
$mysqli -> close();
session_write_close();
?>
