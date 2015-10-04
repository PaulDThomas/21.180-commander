<!-- $Id: orders_phase4.php 252 2014-08-24 21:18:23Z paul $ -->
<h1>Move and Attack
    <?php
    if (strstr($_SERVER['SCRIPT_NAME'],'/ma.php')) {echo " <small>View Costs</small>"; $status['order_code'] = ''; }
    else {
        $result = $mysqli -> query("Select order_code, ordername From sp_orders Where gameno=$gameno and userno=$userno and turnno=$turnno and phaseno=4 and ordername in ('ORDSTAT','MA_000') Order By ordername Limit 1");
        if ($result -> num_rows > 0) {$status = $result -> fetch_assoc(); if ($status['order_code']!='Waiting for orders') echo " <small>${status['order_code']}</small>"; }
        $result -> close();

        // Check for select options already chosen
        $result = $mysqli -> query("Select order_code, ordername From sp_orders Where gameno=$gameno and userno=$userno and turnno=$turnno and phaseno=$phaseno and ordername in ('Action','def_power','def_terr','att_terr')");
        if ($result -> num_rows > 0) while ($row = $result -> fetch_assoc()) echo "<input type='hidden' id='input-${row['ordername']}' value=${row['order_code']} />";
    }
    ?>
</h1>

<?php // Get available hidden boomers for assaults
$result = $mysqli -> query("Select Count(*) From sp_boomers Where gameno=$gameno and userno=$userno and visible='N'") or die ($mysqli->error);
$row = $result -> fetch_row();
$RESOURCE['boomers']=$row[0];
$result -> close();
?>
<?php // Get available boomers with warheads for launches
$result = $mysqli -> query("Select Count(*) From sp_boomers Where gameno=$gameno and userno=$userno and (nukes>0 or neutron>0)") or die ($mysqli->error);
$row = $result -> fetch_row();
$RESOURCE['boomers_head']=$row[0];
$result -> close();
?>

<form id="orderForm" class="form-horizontal" method="post">
<input type="hidden" name="randgen" id="randgen" value="<?php echo $RESOURCE['randgen']; ?>" />
<div class="row-fluid" style="padding-top:10px">
    <div class="span4">Action</div>
    <div class="span8 control-group">
        <select name="Action" id="Action" class="input-large">
            <option value="Pass">Pass</option>
            <?php if (!strpos($status['order_code'],'retaliation')) { ?>
                <option value="March">March</option>
                <option value="Sail">Sail</option>
                <option value="Fly">Fly</option>
                <option value="Transport">Transport</option>
            <?php } ?>
            <?php if ($status['order_code']!='Waiting for redeploy') { ?>
                <option value="Ground">Ground assault</option>
                <option value="Naval">Naval assault</option>
                <option value="Aerial">Aerial assault</option>
                <option value="Amphibious">Amphibious assault</option>
                <option value="Land">Sea to land bombardment</option>
                <option value="Sea">Land to sea bombardment</option>
                <?php if ($RESOURCE['boomers']>0) { ?>
                    <option value="Ambush">Boomer ambush</option>
                <?php } ?>
                <?php if ($RESOURCE['boomers_head']>0) { ?>
                    <option value="Boomer">Launch Boomer Warheads</option>
                <?php } ?>
                <?php if ($RESOURCE['nukes']>0 and !strpos($status['order_code'],'retaliation')) { ?><option value="Space">Space Blast</option><?php } ?>
                <?php if ($RESOURCE['nukes']>0 or $RESOURCE['neutron']>0) { echo "<option value='Warhead' data-nukes='${RESOURCE['nukes']}' data-neutron='${RESOURCE['neutron']}'>Launch warheads</option><?php } ?>"; } ?>
                <?php if ($RESOURCE['ksats']>0) { ?><option value="Satellite">Satellite offensive</option><?php } ?>
            <?php } ?>
        </select>
    </div>
</div>

<div class="row-fluid terrRow" style="display:none">
    <div class="span4">Territory from</div>
    <div class="span4 control-group">
        <select name="terr_from" id="terr_from" class="input-medium">
            <option>-- Select --</option>
            <?php // Get all home territories
                $result = $mysqli -> query("Select * From sv_map Where info=1 and gameno=$gameno and userno=$userno and Length(terrtype)=4 and (major>0 or minor>0) Order By terrname");
                while ($row = $result -> fetch_assoc()) echo "<option major='${row['major']}' minor='${row['minor']}' terrtype='${row['terrtype']}'>${row['terrname']}</option>";
                $result -> close();
            ?>
        </select>
    </div>
    <div class="span4" id="terr_from_info"></div>
</div>
<div class="row-fluid seaRow" style="display:none">
    <div class="span4">Sea from</div>
    <div class="span4 control-group">
        <select name="sea_from" id="sea_from" class="input-medium"><option>-- Select --</option></select>
        <select id="startSeaFrom" style="display:none">
            <?php // Get all home territories
                $result = $mysqli -> query("Select * From sv_map Where info=1 and gameno=$gameno and userno=$userno and Length(terrtype)=3 and (major>0 or minor>0) Order By terrname");
                while ($row = $result -> fetch_assoc()) echo "<option major='${row['major']}' minor='${row['minor']}' terrtype='${row['terrtype']}'>${row['terrname']}</option>";
                $result -> close();
            ?>
        </select>
    </div>
    <div class="span4" id="sea_from_info"></div>
</div>
<div class="row-fluid seaRow" style="display:none">
    <div class="span4">Sea to</div>
    <div class="span4 control-group"><select name="sea_to" id="sea_to" class="input-medium"><option>-- Select --</option></select></div>
    <div class="span4" id="sea_to_info"></div>
</div>
<div class="row-fluid terrRow" style="display:none">
    <div class="span4">Territory to</div>
    <div class="span4 control-group"><select name="terr_to" id="terr_to" class="input-medium"><option>-- Select --</option></select></div>
    <div class="span4" id="terr_to_info"></div>
</div>
<div class="row-fluid majorRow" style="display:none">
    <div class="span4" id="attMajorName"></div>
    <div class="span4 control-group"><select name="att_major" id="att_major" class="input-medium"><option value='Y'>Yes</option><option value='N'>No</option></select></div>
    <div class="span4"></div>
</div>

<?php if ($RESOURCE['boomers']>0) { ?>
<div class="ambushRow" style="display:none">
<div class="row-fluid">
  <div class="span6"><h4>Territory</h4></div>
    <div class="span3">Nukes</div>
    <div class="span3">Neutron</div>
</div>
<div class="row-fluid">
  <div class="span6 control-group">
        <select name="ambushBoomer" id="ambushBoomer" class="input-large">
            <option data-ambushok='OK' data-terrno='' data-minor='' data-major='' data-terrtype='' data-distance='' data-powername='' data-nukes='' data-neutron=''>-- Select --</option>
            <?php
        if (strpos($status['order_code'],'retaliation')>0) {
            $result = $mysqli -> query("Select order_code From sp_orders where gameno=$gameno and userno=$userno and ordername='MA_000_user'") or die ($mysqli->error);
            $row = $result -> fetch_row();
            $retuserno=$row[0];
            $result -> close();
        } else {
            $retuserno=0;
        }
        $result = $mysqli -> query("Select * From sp_boomers bm Left Join sv_map m On bm.gameno=m.gameno and bm.terrno=m.terrno Where info=1 and bm.gameno=$gameno and bm.userno=$userno and m.userno>-9 and m.userno!=$userno and bm.visible='N' Order By m.terrname") or die ($mysqli->error);
        while ($row = $result -> fetch_assoc())
            echo "<option value='${row['boomerno']}' "
                         ."class='boomerOption' "
                         ."data-terrno='${row['terrno']}' "
                         ."data-minor='${row['minor']}' "
                         ."data-major='${row['major']}' "
                         ."data-terrtype='${row['terrtype']}' "
                         ."data-powername='${row['powername']}' "
                         ."data-nukes='${row['nukes']}' "
                         ."data-neutron='${row['neutron']}' "
                         ."data-ambushok='".(($retuserno==$row['userno'] or $retuserno==0)?'OK':'No')."' "
                         ."data-distance='0'>${row['terrname']}</option>";
        $result -> close(); ?>
        </select>
    </div>
    <div class="span3" id="ambushNukes"></div>
    <div class="span3" id="ambushNeutron"></div>
</div>
</div><!-- Ambush Row -->
<?php } ?>

<?php if ($RESOURCE['boomers_head']>0) { ?>
<div class="launchRow" style="display:none">
<div class="row-fluid">
  <div class="span6"><h4>Territory</h4></div>
    <div class="span3">Nukes</div>
    <div class="span3">Neutron</div>
</div>
<div class="row-fluid">
  <div class="span6 control-group">
        <select name="launchBoomer" id="launchBoomer" class="input-large">
            <option data-ambushok='OK' data-terrno='' data-minor='' data-major='' data-terrtype='' data-distance='' data-powername='' data-nukes='' data-neutron=''>-- Select --</option>
            <?php
        if (strpos($status['order_code'],'retaliation')>0) {
            $result = $mysqli -> query("Select order_code From sp_orders where gameno=$gameno and userno=$userno and ordername='MA_000_user'") or die ($mysqli->error);
            $row = $result -> fetch_row();
            $retuserno=$row[0];
            $result -> close();
        } else {
            $retuserno=0;
        }
        $result = $mysqli -> query("Select * From sp_boomers bm Left Join sv_map m On bm.gameno=m.gameno and bm.terrno=m.terrno Where info=1 and bm.gameno=$gameno and bm.userno=$userno and (bm.nukes>0 or bm.neutron>0) Order By m.terrname") or die ($mysqli->error);
        while ($row = $result -> fetch_assoc())
            echo "<option value='${row['boomerno']}' "
                         ."class='boomerOption' "
                         ."data-terrno='${row['terrno']}' "
                         ."data-minor='${row['minor']}' "
                         ."data-major='${row['major']}' "
                         ."data-terrtype='${row['terrtype']}' "
                         ."data-powername='${row['powername']}' "
                         ."data-nukes='${row['nukes']}' "
                         ."data-neutron='${row['neutron']}' "
                         ."data-ambushok='".(($retuserno==$row['userno'] or $retuserno==0)?'OK':'No')."' "
                         ."data-distance='0'>${row['terrname']}</option>";
        $result -> close(); ?>
        </select>
    </div>
    <div class="span3" id="launchNukes"></div>
    <div class="span3" id="launchNeutron"></div>
</div>
</div><!-- Launch Row -->
<?php } ?>

<div class="warheadRow" style="display:none">
<div class="row-fluid">
    <div class="span4"><h4>Territory</h4></div>
    <div class="span3">Nukes</div>
    <div class="span3">Neutron</div>
    <div class="span2">Owner</div>
</div>
<div class="row-fluid targetRow">
    <div class="span4 control-group">
        <select name="target1" id="target1" class="input-large targetTerr">
            <option powername=''>-- None --</option>
            <?php
        if (strpos($status['order_code'],'retaliation')>0) {
            $result = $mysqli -> query("Select order_code From sp_orders where gameno=$gameno and userno=$userno and ordername='MA_000_user'");
            $row = $result -> fetch_row();
            $result -> close();
            $result = $mysqli -> query("Select * From sv_map Where info=1 and gameno=$gameno and userno=${row[0]}");
        } else $result = $mysqli -> query("Select * From sv_map Where info=1 and gameno=$gameno and userno!=$userno and userno >= -1 and terrtype!='OCE' Order By terrname");
        while ($row = $result -> fetch_assoc()) echo "<option class='warheadOption' "
                                                            ."terrno='${row['terrno']}' "
                                                            ."minor='${row['minor']}' "
                                                            ."terrtype='${row['terrtype']}' "
                                                            ."powername='${row['powername']}' "
                                                            .">${row['terrname']}</option>";
        $result -> close(); ?>
        </select>
    </div>
    <div class="span3 control-group"><input type="number" class="input-mini nuke" min="0" max="<?php echo $RESOURCE['nukes']; ?>" name="target1_nukes" value="0"/></div>
    <div class="span3 control-group"><input type="number" class="input-mini neutron" min="0" max="<?php echo $RESOURCE['neutron']; ?>" name="target1_neutron" value="0"/></div>
    <div class="span2 target_powername"></div>
</div>
</div><!-- warheadRow -->

<div class="spaceblastRow" style="display:none">
<div class="row-fluid">
    <div class="span4"></div>
    <div class="span4"><h4>Nukes</h4></div>
    <div class="span4"></div>
</div>
<div class="row-fluid">
    <div class="span4"></div>
    <div class="span4 control-group">
        <input type="number" class="input-mini nuke" min="0" max="<?php echo $RESOURCE['nukes']; ?>" name="space_nukes" value="0" id="space_nukes"/>
    </div>
    <div class="span4"></div>
</div>
</div><!-- warheadRow -->

<div class="superpowerRow" style="display:none">
    <div class="row-fluid">
        <div class="span4">Superpower</div>
        <div class="span8 control-group">
            <select name="def_power" id="def_power" class="input-medium">
                <option>-- Select --</option>
                <?php
            $result = $mysqli -> query("Select powername From sp_resource Where gameno=$gameno and (lstars>0 or ksats>0) and powername!='$powername' and dead='N'");
            if ($result -> num_rows > 0) while ($row = $result -> fetch_assoc()) { echo "<option>${row['powername']}</option>"; }
            else echo "<option>-- None --</option>";
            $result -> close();
            ?>
            </select>
        </div>
    </div>
    <table id="currentBattleTable" class="table table-bordered table-condensed battleTable" align="center">
        <thead>
            <tr>
                <th rowspan=2 valign="bottom">Round</th>
                <th colspan=3 id="lstarAttackingPowername" align="center"><?php echo $powername; ?></th>
                <th colspan=3 id="lstarDefendingPowername" align="center"><?php echo isset($def_power)?$def_power:''; ?></th>
            </tr>
            <tr>
                <th>L-Stars</th>
                <th>K-Sats</th>
                <th>Hits</th>
                <th>L-Stars</th>
                <th>K-Sats</th>
                <th>Hits</th>
            </tr>
        </thead>
        <tbody id="battleBody">
            <tr>
                <td>Current</td>
                <td><?php echo $RESOURCE['lstars']; ?></td><td><?php echo $RESOURCE['ksats']; ?></td><td></td>
                <td>?</td><td>?</td><td></td>
            </tr>
        </tbody>
    </table>
    <div class="row-fluid">
        <div class="span12" align="center">
            <input type='button' id="battleAttack" value='Attack' class="btn btn-success" disabled/>
            <input type='button' id="battleStop" value='Stop Attacking' class="btn btn-warning" style="display:none"/>
            <input type='button' id="finished" onClick="parent.location.reload();return false" value='Finished' class="btn" style="display:none" style="display:none"/>
        </div>
    </div>
</div><!-- superPowerRow -->

<div class="row-fluid tanksRow" style="display:none">
    <div class="span4">Tanks</div>
    <div class="span8 control-group"><input type="number" value="0" min="0" max="0" class="input-mini troops" name="Tanks" id="Tanks" /></div>
</div>
<div class="row-fluid armiesRow" style="display:none">
    <div class="span4">Armies</div>
    <div class="span8 control-group"><input type="number" value="0" min="0" max="0" class="input-mini troops" name="Armies" id="Armies" /></div>
</div>
<div class="row-fluid visBoomersRow" style="display:none">
    <div class="span4">Boomers</div>
    <div class="span8 control-group"><input type="number" value="0" min="0" max="0" class="input-mini troops" name="Boomers" id="Boomers" /></div>
</div>
<div class="row-fluid naviesRow" style="display:none">
    <div class="span4">Navies</div>
    <div class="span8 control-group"><input type="number" value="0" min="0" max="0" class="input-mini troops" name="Navies" id="Navies" /></div>
</div>

<div class="row-fluid resultRow" style="display:none;padding-top:15px">
    <div class="span3"><h4>Owner</h4></div>
    <div class="span3" id="majorName">Major</div>
    <div class="span3" id="minorName">Minor</div>
    <div class="span3">Distance</div>
</div>
<div class="row-fluid resultRow" style="display:none">
    <div class="span3" id="powername"></div>
    <div class="span3" id="major"></div>
    <div class="span3" id="minor"></div>
    <div class="span3" id="distance"></div>
</div>

<?php
    // Get movement costs on land
    $result = $mysqli -> query ("Select * From sp_tech Where tech_level = ${RESOURCE['land_tech']}") or die ($mysqli -> error);
    $land_row = $result -> fetch_assoc();
    $result -> close();
    // Get movement costs on water
    $result = $mysqli -> query ("Select * From sp_tech Where tech_level = ${RESOURCE['water_tech']}") or die ($mysqli -> error);
    $water_row = $result -> fetch_assoc();
    $result -> close();
?>
<div class="row-fluid resultRow" style="display:none;padding-top:15px"><div class="span12"><h4>Cost</h4></div></div>
<div class="row-fluid resultRow" style="display:none">
    <table class="table table-bordered">
        <thead><tr>
            <th width="25%">Resource</th>
            <th width="25%">Available</th>
            <th width="25%">Spend</th>
            <th width="25%">Remaining</th>
        </tr></thead>
        <tbody>
            <tr class="costRow" march_n="<?php echo $land_row['march_nm']; ?>" march_j="<?php echo $land_row['march_jm']; ?>" fly_n="<?php echo $land_row['fly_nm']; ?>" fly_j="<?php echo $land_row['fly_jm']; ?>" sail_n="<?php echo $water_row['sail_nm']; ?>" sail_j="<?php echo $water_row['sail_jm']; ?>">
                <th>Minerals</th>
                <td id="mineralsAvailable" class="ral Available"><?php echo $RESOURCE['minerals']; ?></td>
                <td id="mineralsSpend" class="ral Spend" >0</td>
                <td id="mineralsRemaining" class="ral Remaining">&nbsp;</td>
            </tr>
            <tr class="costRow" march_n="<?php echo $land_row['march_no']; ?>" march_j="<?php echo $land_row['march_jo']; ?>" fly_n="<?php echo $land_row['fly_no']; ?>" fly_j="<?php echo $land_row['fly_jo']; ?>" sail_n="<?php echo $water_row['sail_no']; ?>" sail_j="<?php echo $water_row['sail_jo']; ?>">
                <th>Oil</th>
                <td id="oilAvailable" class="ral Available"><?php echo $RESOURCE['oil']; ?></td>
                <td id="oilSpend" class="ral Spend" >0</td>
                <td id="oilRemaining" class="ral Remaining">&nbsp;</td>
            </tr>
            <tr class="costRow" march_n="<?php echo $land_row['march_ng']; ?>" march_j="<?php echo $land_row['march_jg']; ?>" fly_n="<?php echo $land_row['fly_ng']; ?>" fly_j="<?php echo $land_row['fly_jg']; ?>" sail_n="<?php echo $water_row['sail_ng']; ?>" sail_j="<?php echo $water_row['sail_jg']; ?>">
                <th>Grain</th>
                <td id="grainAvailable" class="ral Available"><?php echo $RESOURCE['grain']; ?></td>
                <td id="grainSpend" class="ral Spend" >0</td>
                <td id="grainRemaining" class="ral Remaining">&nbsp;</td>
            </tr>
        </tbody>
    </table>
</div>

<div class="row-fluid">
    <div class="span12" align="center"><input type="submit" value="Pass" name="PROCESS" id="processOrders" class="btn btn-success"/></div>
</div>
<input type="hidden" id="terrtype_to" val="" />
</form>
