<?php

// Update territory
// $Id: territory_update.php 101 2012-07-09 22:14:57Z paul $

// Start page
require_once("../php/checklogin.php");

// Stop if not ready
if ($username == '' or $username == 'FAIL' or $gameno == '0') exit;

// Set up XML element
$terrXML = new SimpleXMLElement('<?xml version="1.0"?><TERRITORY></TERRITORY>');
$TERRITORY = array();

foreach ($_POST as $param => $val) {
    $z = explode('-',$param);
    $terrno = isset($z[1])?$z[1]:'-1';
    $column = substr($z[0],4);
    if (isset($terrno) and isset($column) and isset($val) and substr($z[0],0,4)=="terr") {
        if ($column == 'LStar') {
            $mysqli -> query("update sp_lstars set terrno=0 where gameno=$gameno and userno=$userno and terrno=$terrno");
            $mysqli -> query("update sp_lstars set terrno=$terrno where gameno=$gameno and userno=$userno and terrno=0 limit $val");
        } else {
            if ($column == "Pass_Powername" and $val == "None") $query = "Update sp_board Set passuser = 0 Where gameno=$gameno and userno=$userno and terrno=$terrno";
            else if ($column == "Pass_Powername") $query = "Update sp_board Set passuser = (Select userno From sp_resource Where gameno=$gameno and powername='$val') Where gameno=$gameno and userno=$userno and terrno=$terrno";
            else $query = "Update sp_board Set $column = '$val' Where gameno=$gameno and userno=$userno and terrno=$terrno";
            $result = $mysqli -> query($query) or die ($mysqli -> error);
        }
        $TERRITORY[$param] = "$val";
    }
};

// Send $TERRITORY to XML
foreach ($TERRITORY as $var => $val) $terrXML -> addChild($var,$val);
echo $terrXML->asXML();

// Close page
$mysqli -> close();
?>
