<?php

// $Id: worldcup_update.php 130 2013-05-12 11:39:20Z paul $
// L-Star update ajax

// Initialise
require("../php/checklogin.php");

// Stop if not ready
if ($username == '' or $username == 'FAIL') exit;

// Create initial record if required
$result = $mysqli -> query ("Select * From sp_worldcup Where userno=$userno");
if ($result -> num_rows < 1) $mysqli -> query ("Insert Into sp_worldcup (userno) Values ($userno);");

// Update POST variables in table
foreach ($_POST as $var=>$val) if ($val!='') $mysqli -> query ("Update sp_worldcup Set $var='$val' Where userno=$userno");

// Update IP variables in table
$_SESSION['check']="Update sp_worldcup Set ip='".$_SERVER['REMOTE_ADDR']."', hostname='".gethostbyaddr($_SERVER['REMOTE_ADDR'])."' Where userno = $userno;";
$mysqli -> query("Update sp_worldcup Set ip='".$_SERVER['REMOTE_ADDR']."', remote_addr='".gethostbyaddr($_SERVER['REMOTE_ADDR'])."' Where userno = $userno;");

// Get current values
$result = $mysqli -> query ("Select username, first_name, last_name, country, region From sp_users u Left Join sp_worldcup w On u.userno=w.userno Where u.userno=$userno");
$row = $result -> fetch_assoc();
$result -> close();

// Set up XML element
$wcXML = new SimpleXMLElement('<?xml version="1.0"?><WC></WC>');
foreach ($row as $var=>$val) $wcXML -> addChild($var,$val);
echo $wcXML->asXML();

// Close page
$mysqli -> close();
?>
