<div id="terrTable"><?php
// Get total forces on board
$result = $mysqli -> query ("Select Sum(Case When Length(terrtype)=4 Then major Else 0 End) as tanks
                                    ,Sum(Case When Length(terrtype)=3 Then major Else 0 End) as boomers
                                    ,Sum(minor) as minor
                            From sp_board b Left Join sp_places p on b.terrno=p.terrno Where gameno=$gameno and userno=$userno");
$sumrow = $result -> fetch_assoc();
$result -> close();
// Get hidden boomers
$result = $mysqli -> query ("Select Count(*) From sp_boomers Where gameno=$gameno and userno=$userno and visible='N'");
$row = $result -> fetch_row();
$sumrow['hidden_boomers'] = $row[0];
$result -> close();
?>
<div class="row-fluid" style="padding-top:20px">
  <div class="span9 collHead"><h3><i id='troops' class="icon-plus-sign"></i> <?php echo $terrs_table_type; ?> Troops</h3></div>
  <div class="span3 control-group" align="right"><div class="input-prepend"><span class="add-on">-</span><input id="troopTotal" class="input-mini subTotal" type="text" align="right" readonly value="0" /></div></div>
</div><!-- row -->
<div id='troopsDetail' class='collDetail' style='display:none'>

<?php
// Land territories
$query = "Select *
          From sv_map_build
          Where gameno=$gameno
           and build_userno=$userno
           and Length(terrtype)=4
          Order By terrname
          ;";
?><div class="row-fluid">
    <div class="span3"></div>
    <div class="span3"><strong>Tanks</strong></div>
    <div class="span3"><strong>Armies</strong></div>
    <div class="span3"><strong>Cost</strong></div>
</div><?php
$result = $mysqli -> query($query) or die ($mysqli -> error);
while ($row = $result -> fetch_assoc()) {?>
  <div class="row-fluid terrRow">
    <div class="span3"><?php echo $row['terrname']; ?></div>
    <div class="span3 control-group">
      <?php
          if ($terrs_table_type=="Pay") {
            $order = $orderxml -> xpath("/PAYSALARIES/PayTroops[text()='".$row['terrno']."']/Major");
            $val = isset($order[0][0])?$order[0][0]:'0';
            $default = $row['major'];
            $max = $row['major'];
          } else if ($terrs_table_type=="Build") {
            echo "${row['major']} + ";
            $order = $orderxml -> xpath("/BUILD/BuildTroops[Terrno/text()='".$row['terrno']."']/Major");
            $val = isset($order[0][0])?$order[0][0]:'0';
            $default = '0';
            $max = max(0,5 - $sumrow['tanks']);
          } else if ($terrs_table_type=="Initial") {
            echo "${row['major']} + ";
            $order = $orderxml -> xpath("/INITIAL/BuildTroops[Terrno/text()='".$row['terrno']."']/Major");
            $val = isset($order[0][0])?$order[0][0]:'0';
            $default = '0';
            $max = '1';
          }
        echo "<input type='number' id='T-${row['terrno']}' name='T-${row['terrno']}' value=$val min='0' max='$max' class='input-mini tanks' data-default='$default' ".(($RESOURCE['land_tech']<$GAME['tank_tech_level'])?'readonly':'')."/>";
      ?>
    </div>
    <div class="span3 control-group">
      <?php
          if ($terrs_table_type=="Pay") {
            $order = $orderxml -> xpath("/PAYSALARIES/PayTroops[Terrno/text()='".$row['terrno']."']/Minor");
            $val = isset($order[0][0])?$order[0][0]:'0';
            $default = $row['minor'];
            $max = $row['minor'];
          } else if ($terrs_table_type=="Build") {
            echo "${row['minor']} + ";
            $order = $orderxml -> xpath("/BUILD/BuildTroops[Terrno/text()='".$row['terrno']."']/Minor");
            $val = isset($order[0][0])?$order[0][0]:'0';
            $default = '0';
            if ($row['terrtype']=='OCE') $max = 0;
            else $max = max(0,$RESOURCE['max_grain']*3 - $sumrow['minor']);
          } else if ($terrs_table_type=="Initial") {
            echo "${row['minor']} + ";
            $order = $orderxml -> xpath("/INITIAL/BuildTroops[Terrno/text()='".$row['terrno']."']/Minor");
            $val = isset($order[0][0])?$order[0][0]:'0';
            $default = '0';
            $max = '9';
          }
        echo "<input type='number' id='M-${row['terrno']}' name='M-${row['terrno']}' value=$val min='0' max='$max' class='input-mini troops' data-default='$default' />";
      ?>
    </div>
    <div class="span2 control-group" align="right">
      <input id="t1Value" class="input-mini troopSum" type="text" align="right" readonly value="0" />
    </div>
  </div><!-- territory row --><?php
}
$result -> close();

// Sea territories - Check Oceans are present for paying, not for building
$query = "Select *
          From sv_map_build b
          Where gameno=$gameno
           and build_userno=$userno
           and Length(terrtype)=3
          Order By terrname
          ;";
?><div class="row-fluid">
    <div class="span3"></div>
    <div class="span3"><strong>Boomers<?php if ($sumrow['hidden_boomers']>0) echo " <em>(".$sumrow['hidden_boomers']." hidden)</em>"; ?></strong></div>
    <div class="span3"><strong>Navies</strong></div>
    <div class="span3"><strong>Cost</strong></div>
</div><?php
$result = $mysqli -> query($query) or die ($mysqli -> error);
while ($row = $result -> fetch_assoc()) { if ($row['minor']>0 or $row['major']>0 or $GAME['phaseno']==5) {?>
  <div class="row-fluid terrRow">
    <div class="span3"><?php echo $row['terrname']; ?></div>
    <div class="span3 control-group">
      <?php
          if ($terrs_table_type=="Pay") {
            $order = $orderxml -> xpath("/PAYSALARIES/PayTroops[text()='".$row['terrno']."']/Major");
            $val = isset($order[0][0])?$order[0][0]:'0';
            $default = $row['major'];
            $max = $row['major'];
          } else if ($terrs_table_type=="Build") {
            echo "${row['major']} + ";
            $order = $orderxml -> xpath("/BUILD/BuildTroops[Terrno/text()='".$row['terrno']."']/Major");
            $val = isset($order[0][0])?$order[0][0]:'0';
            $default = '0';
            $max = max(0,5 - $sumrow['boomers'] - $sumrow['hidden_boomers']);
          } else if ($terrs_table_type=="Initial") {
            echo "${row['major']} + ";
            $order = $orderxml -> xpath("/INITIAL/BuildTroops[Terrno/text()='".$row['terrno']."']/Major");
            $val = isset($order[0][0])?$order[0][0]:'0';
            $default = '0';
            $max = '0';
          }
        echo "<input type='number' id='B-${row['terrno']}' name='B-${row['terrno']}' value=$val min='0' max='$max' class='input-mini boomers' data-default='$default' ".(($RESOURCE['water_tech']<$GAME['boomer_tech_level'])?'readonly':'')."/>";
      ?>
    </div>
    <div class="span3 control-group">
      <?php
          if ($terrs_table_type=="Pay") {
            $order = $orderxml -> xpath("/PAYSALARIES/PayTroops[Terrno/text()='".$row['terrno']."']/Minor");
            $val = isset($order[0][0])?$order[0][0]:'0';
            $default = $row['minor'];
            $max = $row['minor'];
          } else if ($terrs_table_type=="Build") {
            echo "${row['minor']} + ";
            $order = $orderxml -> xpath("/BUILD/BuildTroops[Terrno/text()='".$row['terrno']."']/Minor");
            $val = isset($order[0][0])?$order[0][0]:'0';
            $default = '0';
            if ($row['terrtype']=='OCE') $max = 0;
            else $max = max(0,$RESOURCE['max_grain']*3 - $sumrow['minor']);
          } else if ($terrs_table_type=="Initial") {
            echo "${row['minor']} + ";
            $order = $orderxml -> xpath("/INITIAL/BuildTroops[Terrno/text()='".$row['terrno']."']/Minor");
            $val = isset($order[0][0])?$order[0][0]:'0';
            $default = '0';
            $max = '9';
          }
        echo "<input type='number' id='M-${row['terrno']}' name='M-${row['terrno']}' value=$val min='0' max='$max' class='input-mini troops' data-default='$default' />";
      ?>
    </div>
    <div class="span2 control-group" align="right">
      <input id="t2Value" class="input-mini troopSum" type="text" align="right" readonly value="0" />
    </div>
  </div><!-- territory row --><?php
}}
$result -> close(); ?>
</div><!-- collDetail -->
<div class="row-fluid" style="padding-top:20px">
    <div class="span3"></div>
    <div class="span3">Initial</div>
    <div class="span3">Build</div>
    <div class="span3"></div>
</div>
<?php if ($terrs_table_type!="Pay") { ?>
<div class="row-fluid">
  <div class="span3"><h3>Tanks</h3></div>
  <div class="span3 initials"><?php echo $sumrow['tanks']; ?></div>
  <div class="span3"><input readonly id="tankAmt" class="input-mini totals" align="right" value='0'/></div>
  <div class="span3 control-group" align="right"><input id="tankFinal" align="right" class="input-mini finalbuild" readonly data-max="<?php echo ($terrs_table_type=='Build')?(max(5,$sumrow['tanks'])):1; ?>" value="0"/></div>
</div><!-- row -->
<div class="row-fluid">
  <div class="span3"><h3>Boomers</h3></div>
  <div class="span3 initials"><?php echo $sumrow['boomers']; ?></div>
  <div class="span3"><input readonly id="boomerAmt" class="input-mini totals" align="right" value='0'/></div>
  <div class="span3 control-group" align="right"><input id="boomerFinal" align="right" class="input-mini finalbuild" readonly data-max="<?php echo ($terrs_table_type=='Build')?(max(5,$sumrow['boomers'])):1; ?>" value="0"/></div>
</div><!-- row -->
<div class="row-fluid">
  <div class="span3"><h3>Armies &amp; Navies</h3></div>
  <div class="span3 initials"><?php echo $sumrow['minor']; ?></div>
  <div class="span3"><input readonly id="troopAmt" class="input-mini totals" align="right" value='0'/></div>
  <div class="span3 control-group" align="right"><input id="troopFinal" align="right" class="input-mini finalbuild" readonly data-max="<?php echo ($terrs_table_type=='Build')?(max($RESOURCE['max_grain']*3,$sumrow['minor'])):(9+$sumrow['minor']); ?>" value="0"/></div>
</div><!-- row -->
<?php } ?>
</div><!-- terrTable -->