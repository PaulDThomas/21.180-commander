<?php
// Boomer movement
// $Id: orders_phase1_boomer.php 244 2014-07-13 16:44:49Z paul $

// See if there are any boomers
$result = $mysqli -> query("Select Count(boomerno) From sp_boomers Where gameno=$gameno and userno=$userno") or die ($mysqli->error);
$row = $result -> fetch_row();
$boomers = $row[0];
$result -> close();

// Print options if required...
if ($boomers > 0) {?>
<div class="row-fluid" style="padding-top:20px">
  <div class="span4"><h3>Boomer positioning</h3></div>
  <div class="span8"></div>
</div><!-- Row -->
<div class="row-fluid" style="padding-top:20px">
  <div class="span3">Territory</div>
  <div class="span2">Nukes</div>
  <div class="span2">Neutron</div>
  <div class="span3">Move to</div>
  <div class="span2">Visible</div>
</div><!-- Row -->

<?php
// Get available destinations
$result = $mysqli -> query("
Select pl.terrname, pl.terrno, Case When userno=$userno Then 'OK' Else 'x' End As visok
From sp_board b
Left Join sp_places pl On b.terrno=pl.terrno
Where b.gameno=$gameno
 and b.userno > -9
 and Length(terrtype)=3
Order by 1
 ") or die ($mysqli -> error);
while ($row = $result -> fetch_assoc()) {$PLACES["${row['terrno']}"]=$row;}
$result -> close();
// Get boomer information
$result = $mysqli -> query("
Select Distinct bm.boomerno, bm.terrno, pl.terrname, bm.nukes, bm.neutron
    ,Case bm.visible When 'Y' Then 'Yes' When 'N' Then 'No' Else bm.visible End As visible
    ,Case When Max(b.terrno) is not null and bm.visible='Y' Then 'Port' Else '' End As port
From sp_boomers bm
Left Join sp_places pl On bm.terrno=pl.terrno
Left Join sp_border br On bm.terrno=br.terrno_from
Left Join sp_powers pw On pw.powername='$powername'
Left Join sp_places pl2 On br.terrno_to=pl2.terrno and pl2.terrtype=pw.terrtype
Left Join sp_board b On b.gameno=bm.gameno and b.terrno=pl2.terrno and b.userno=$userno
Where bm.gameno=$gameno
 and bm.userno=$userno
Group By 1,2,3,4,5,6
") or die ($mysqli -> error);
while ($row = $result -> fetch_assoc()) { ?>
    <div class="row-fluid"><div class="control-group boomerRow">
        <div class="span3" align="left"><?php echo $row['terrname']; $order = $orderxml -> xpath("/PAYSALARIES/Boomer[Number/text()='${row['boomerno']}']"); ?></div>
        <div class="span2"><?php
        echo $row['nukes'];
        if ($row['port']=='Port' and $RESOURCE['nukes']>0 and $row['nukes']+$row['neutron']<2) {
            $nukes = $order[0]->Nukes-$row['nukes'];
            echo " + <input type='number' min='0' "
                 ."max='".min(2-$row['nukes']-$row['neutron'],$RESOURCE['nukes'])."' "
                 ."id='BNKx${row['boomerno']}' data-there='${row['nukes']}' data-avail='${RESOURCE['nukes']}' "
                 ."class='input-mini boomerNuke' style='width:25px' value='$nukes' />"
                 ;
        } ?>
            <input class='boomerNukeHidden' name='BNK<?php echo $row['boomerno'];?>' id='BNK<?php echo $row['boomerno'];?>' type='hidden' value='<?php echo $order[0]->Nukes; ?>'/>
        </div>
        <div class="span2"><?php
        echo $row['neutron'];
        if ($row['port']=='Port' and $RESOURCE['neutron']>0 and $row['nukes']+$row['neutron']<2) {
            $neutron = $order[0]->Neutron-$row['neutron'];
            echo " + <input type='number' min='0' "
                 ."max='".min(2-$row['nukes']-$row['neutron'],$RESOURCE['neutron'])."' "
                 ."id='BNEx${row['boomerno']}' data-there='${row['neutron']}' data-avail='${RESOURCE['neutron']}'"
                 ."class='input-mini boomerNeutron' style='width:25px' value='$neutron' />"
                 ;
        } ?>
            <input class='boomerNeutronHidden' name='BNE<?php echo $row['boomerno'];?>' id='BNE<?php echo $row['boomerno'];?>' type='hidden' value='<?php echo $order[0]->Neutron; ?>'/>
        </div>

        <div class="span3">
            <select name='<?php echo "BT${row['boomerno']}"; ?>' id='<?php echo "BT${row['boomerno']}"; ?>' class='input-medium boomerTerrname'>
                <?php foreach($PLACES as $n) { echo "<option".(($order[0]->Terrname==$n['terrname'])?' selected':'')." data-terrno='${n['terrno']}' data-visok='${n['visok']}'>${n['terrname']}</option>"; } ?>
            </select>
            <input class='boomerTerrnoHidden' name='<?php echo "BTn${row['boomerno']}"; ?>' id='<?php echo "BTn${row['boomerno']}"; ?>' type='hidden' value='<?php echo $order[0]->Terrno; ?>'/>
        </div>

        <div class="span2">
            <?php $visok = $PLACES[(string)$order[0]->Terrno]["visok"]; ?>
            <div class='boomerVisibleText' <?php echo ($visok=='OK')?'style="display:none"':''; ?>><?php echo ($order[0]->Visible=='Y')?'Yes':'No'; ?></div>
            <select name='<?php echo "BV${row['boomerno']}"; ?>' id='<?php echo "BV${row['boomerno']}"; ?>' class='input-mini boomerVisibleSelect' <?php echo ($visok=='OK')?'':'style="display:none"'; ?>>
                <option value="Y"<?php if ($order[0]->Visible=='Y') echo " selected";?>>Yes</option>
                <option value="N"<?php if ($order[0]->Visible!='Y') echo " selected";?>>No</option>
            </select>
        </div>
    </div></div><!-- Row -->
<?php }
} ?>