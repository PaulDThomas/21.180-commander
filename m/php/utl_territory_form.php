<?php

// Territory update utilities
// $Id: utl_territory_form.php 99 2012-06-30 13:48:54Z paul $

function terrDefenseBtn($TERRITORY) { ?>
<select name="terrDefense-<?php echo $TERRITORY['terrno']; ?>" class="input-small terrVal def" data-start="<?php echo $TERRITORY['defense']; ?>" >
    <?php $list = array("Defend","Resist","Surrender");
    foreach ($list as $val) echo '<option '.($TERRITORY['defense']==$val?'selected':'').">$val</option>";
    ?>
</select>
<?php }

function terrAttMajBtn($TERRITORY) { ?>
<select name="terrAttack_Major-<?php echo $TERRITORY['terrno']; ?>" class="input-small terrVal am" data-start="<?php echo $TERRITORY['attack_major']; ?>">
    <?php $list = array("Yes","No");
    foreach ($list as $val) echo '<option '.($TERRITORY['attack_major']==$val?'selected':'').">$val</option>";
    ?>
</select>
<?php }

function terrROPBtn ($TERRITORY) { global $mysqli; ?>
<select name="terrPass_Powername-<?php echo $TERRITORY['terrno']; ?>" class="input-medium terrVal rop" data-start="<?php echo $TERRITORY['passusername']; ?>">
    <?php $list = array("0"=>"None");
    $result = $mysqli -> query("Select powername From sp_resource Where gameno=${TERRITORY['gameno']} and userno!=${TERRITORY['userno']} and dead='N'") or die($mysqli->error);
    while ($row = $result -> fetch_row()) $list[] = $row[0];
    $result -> close();
    foreach ($list as $val) echo '<option '.($TERRITORY['passusername']==$val?'selected':'').">$val</option>";
    ?>
</select>
<?php }

function terrLStarBtn ($TERRITORY) { global $mysqli;
?><select name="terrLStar-<?php echo $TERRITORY['terrno']; ?>" class="input-medium terrVal lstar" data-start="<?php echo $TERRITORY['lstar-slots']; ?>">
    <?php for ($i=0;$i<=$TERRITORY['lstar-slots-available'];$i++) echo '<option '.($TERRITORY['lstar-slots']==$i?'selected':'').">$i</option>"; ?>
</select>
<?php }

function buildTerrOptions ($gameno,$userno,$type,$selected) {
    global $mysqli;
    $result = $mysqli -> query("Select * From sv_map_build Where gameno=$gameno and build_userno=$userno");
    if ($result -> num_rows > 0) {
        while ($row = $result -> fetch_assoc())
            if ($type == "ANY"
                or ($type=="LAND" and strlen($row['terrtype'])==4)
                or ($type=="SEA" and strlen($row['terrtype'])==3) )
                    echo "<option value='${row['terrno']}' ".(($selected==$row['terrno'])?"selected ":"").">${row['terrname']}</option>";
    } else echo "<option value='0'>None</option>";
    $result -> close();
}

?>
