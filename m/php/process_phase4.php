<?php

// Process orders from phase 4
// $Id: process_phase4.php 252 2014-08-24 21:18:23Z paul $

// CHANGE THIS ALL!!!
// Pass needs to move queue
// Every other call needs to handle it's own queue movement like SATELLITE, eventually...

// Get processing action
$Action = isset($_POST['Action'])?$_POST['Action']:'';

// Change orders to processed or pass if the right person is processing
if ($Action == 'Pass') {
    $query = "call sr_4_pass($gameno,'$powername');";


// Assume no bad submits, all the rest of the actions
} else if ($Action == 'March') {
    $query = "call sr_4_move_land($gameno, '$powername', '${_POST['terr_from']}', '${_POST['terr_to']}', ${_POST['Tanks']}, ${_POST['Armies']});";
} else if ($Action == 'Sail') {
    $query = "call sr_4_move_water($gameno, '$powername', '${_POST['sea_from']}', '${_POST['sea_to']}', ${_POST['Boomers']}, ${_POST['Navies']});";
} else if ($Action == 'Fly') {
    $query = "call sr_4_move_fly($gameno, '$powername', '${_POST['terr_from']}', '${_POST['terr_to']}', ${_POST['Tanks']}, ${_POST['Armies']});";
} else if ($Action == 'Transport') {
    if ($_POST['sea_to']=='-- Select --') $_POST['sea_to']=$_POST['sea_from'];
    $query = "call sr_4_move_transport($gameno, '$powername', '${_POST['terr_from']}', '${_POST['sea_from']}', '${_POST['sea_to']}', '${_POST['terr_to']}', ${_POST['Tanks']}, ${_POST['Armies']}, ${_POST['Boomers']}, ${_POST['Navies']});";
} else if ($Action == 'Ground') {
    $query = "call sr_4_attack_land($gameno, '$powername', '${_POST['terr_from']}', '${_POST['terr_to']}', ${_POST['Tanks']}, ${_POST['Armies']}, '${_POST['att_major']}');";
} else if ($Action == 'Naval') {
    $query = "call sr_4_attack_naval($gameno, '$powername', '${_POST['sea_from']}', '${_POST['sea_to']}', ${_POST['Boomers']}, ${_POST['Navies']}, '${_POST['att_major']}');";
} else if ($Action == 'Aerial') {
    $query = "call sr_4_attack_aerial($gameno, '$powername', '${_POST['terr_from']}', '${_POST['terr_to']}', 0, ${_POST['Armies']}, '${_POST['att_major']}');";
} else if ($Action == 'Amphibious') {
    if ($_POST['sea_to']=='-- Select --') $_POST['sea_to']=$_POST['sea_from'];
    $query = "call sr_4_attack_amphib($gameno, '$powername', '${_POST['terr_from']}', '${_POST['sea_from']}', '${_POST['sea_to']}', '${_POST['terr_to']}', ${_POST['Tanks']}, ${_POST['Armies']}, ${_POST['Boomers']}, ${_POST['Navies']}, '${_POST['att_major']}');";
} else if ($Action == 'Land') {
    $_POST['sea_to'] = ($_POST['sea_to']!="-- Select --")?$_POST['sea_to']:$_POST['sea_from'];
    $query = "call sr_4_attack_coastal($gameno, '$powername', '${_POST['sea_from']}', '${_POST['sea_to']}', '${_POST['terr_to']}', ${_POST['Navies']});";
} else if ($Action == 'Sea') {
    $_POST['terr_to'] = ($_POST['terr_to']!="-- Select --")?$_POST['terr_to']:$_POST['terr_from'];
    $query = "call sr_4_attack_coastal($gameno, '$powername', '${_POST['terr_from']}', '${_POST['terr_to']}', '${_POST['sea_to']}', ${_POST['Armies']});";
} else if ($Action == 'Ambush') {
    $query = "call sr_4_attack_ambush($gameno, '$powername', '${_POST['ambushBoomer']}', '${_POST['att_major']}');";
} else if ($Action == 'Boomer') {
    $i = 1;
    $war_array = '';
    while (isset($_POST['target'.$i])) {
        $terrname = $_POST['target'.$i];
        $nukes = $_POST['target'.$i.'_nukes'];
        $neutron = $_POST['target'.$i.'_neutron'];
        if ($terrname != '-- None --' and ($nukes + $neutron > 0)) $war_array .= "<TARGET><terrname>$terrname</terrname><nuke>$nukes</nuke><neutron>$neutron</neutron></TARGET>";
        $i++;
    }
    $query = "call sr_4_boomer_fire($gameno, '$powername', ${_POST['launchBoomer']}, '$war_array');";
} else if ($Action == 'Warhead') {
    $i = 1;
    $war_array = '';
    while (isset($_POST['target'.$i])) {
        $terrname = $_POST['target'.$i];
        $nukes = $_POST['target'.$i.'_nukes'];
        $neutron = $_POST['target'.$i.'_neutron'];
        if ($terrname != '-- None --' and ($nukes + $neutron > 0)) $war_array .= "<TARGET><terrname>$terrname</terrname><nuke>$nukes</nuke><neutron>$neutron</neutron></TARGET>";
        $i++;
    }
    $query = "call sr_4_warheads($gameno, '$powername', '$war_array');";
} else if ($Action == 'Space') {
    $query = "call sr_4_spaceblast($gameno, '$powername', '${_POST['space_nukes']}');";
}

// Process query
require_once("utl_multi_query.php");
$query_out = utl_multi_query("set @sr_debug='Y'; select 'BEFORE', powername, userno, minerals, oil, grain from sp_resource where gameno=$gameno; $query select 'AFTER', powername, userno, minerals, oil, grain from sp_resource where gameno=$gameno; set @sr_debug='N';");
// Email output to admin
$mysqli -> query("insert into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code) values ($gameno,$userno,$turnno,$phaseno,'PHASE4_DEBUG','".addslashes($query_out)."');") or die("INSERT_QUERY_OUT:".$mysqli->error);

?>