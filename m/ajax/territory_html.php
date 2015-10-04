<?php

// HTML for a territory popup
// $Id: territory_html.php 237 2014-07-10 07:28:53Z paul $

// Initialise
require_once("../php/checklogin.php");
require_once("../php/utl_territory_form.php");

// Get territory number from POST
$terrno = isset($_POST['terrno'])?$_POST['terrno']:'0';

// Get information
$result = $mysqli -> query("Select * From sv_map Where gameno=$gameno and terrno=$terrno and info=1");
if ($result -> num_rows == 0) exit;
$TERRITORY = $result -> fetch_assoc();
$result -> close();

// Get L-Star slots
$result = $mysqli -> query("Select Sum(terrno=0), Sum(terrno=$terrno) From sp_lstars Where gameno=$gameno and userno=$userno");
$row = $result -> fetch_row();
$TERRITORY['lstar-slots'] = $row[1];
$TERRITORY['lstar-slots-available'] = $row[0]+$row[1];
$result -> close();

// Get Hidden Boomers
$result = $mysqli -> query("Select Sum(visible!='Y') From sp_boomers Where gameno=$gameno and userno=$userno and terrno=$terrno") or die($mysqli->error);
$row = $result -> fetch_row();
$TERRITORY['hidden-boomers'] = isset($row[0])?$row[0]:0;
$result -> close();

// Get forces array
if (strlen($TERRITORY['terrtype'])==3) {
    $terrList = array("Hidden Boomers"=>"hidden-boomers","Visible Boomers"=>"major","Navies"=>"minor");
} else {
    $terrList = array("Tanks"=>"major","Armies"=>"minor");
}

// Check for ROP
if ($TERRITORY['passuser']==$userno and $powername != '') {$terrList["Passage"]="granted"; $TERRITORY['granted']="Granted";}

// Get resource array
$resList = array("Minerals"=>"minerals","Oil"=>"oil","Grain"=>"grain");

// Final row list
$printList = array_merge(array("Superpower"=>"powername"),$terrList, $resList);

?>
<form id="terrForm" class="form-inline">
<table class='table table-condensed table-bordered'>
    <?php foreach ($printList as $label=>$col) {?><tr><td width='40%'><?php echo $label; ?></td><td><?php echo $TERRITORY[$col]; ?></td></tr><?php } ?>
    <?php if (isset($RESOURCE['lstars'])?$RESOURCE['lstars']:0 > 0) { ?><tr><td>L-Star slots</td><td><?php terrLStarBtn($TERRITORY) ?></td></tr><?php } ?>
    <?php
    // Add in user based parameters
    if ($TERRITORY['userno'] == $userno) { ?>
            <tr><td>Defense</td><td><?php terrDefenseBtn($TERRITORY) ?></td></tr>
            <?php if (strlen($TERRITORY['terrtype'])==4) { ?>
                <tr><td>Attack Tanks</td><td><?php terrAttMajBtn($TERRITORY) ?></td></tr>
            <?php } ?>
            <tr><td>Right of Passage</td><td><?php terrROPBtn($TERRITORY) ?></td></tr>
        <?php } ?>
</table>
</form>
