<!-- $Id: orders_phase2.php 237 2014-07-10 07:28:53Z paul $ -->
<div class="row-fluid" style="padding-top:20px">
  <div class="span4">
    <h3>Phase selection</h3>
  </div>
  <div class="span8">
    <div class="alert alert-error" id="phaseAlert" style="display:none">
      <strong>Warning!</strong> Two or more phases are the same
    </div>
  </div>
</div><!-- Row -->

<?php
// Add Phase Selection
$result = $mysqli -> query("Select phase2_type From sp_game Where gameno=$gameno");
$row = $result -> fetch_row();
$result -> close();
$phase2_type = $row[0];

if ($phase2_type == 'Choose 1') {$psel = array("P_A"); $nsel = array("P_B","P_C");}
else if ($phase2_type == 'Choose 2') {$psel = array("P_A","P_B"); $nsel = array("P_C");}
else {$psel = array("P_A","P_B","P_C"); $nsel = array();};
$phases = array("3"=>"Sell", "4"=>"Move/Attack", "5"=>"Build", "6"=>"Buy", "7"=>"Acquire");

if ($phase2_type == 'Buy position') {
    foreach ($psel as $value) {
        $selected = $orderxml -> $value -> Phase;
        $cost = $orderxml -> $value -> Cost;
        $selected2 = ($cost<0)?"Last":"First";
        $selected3 = abs($cost); ?>
            <div class="row-fluid"><div class="control-group">
                <div class="span4" align="center">
                    <select id="<?php echo $value; ?>" name="<?php echo $value; ?>" class="input-medium">
                        <?php foreach ($phases as $no=>$name) echo "<option ".($selected==$no?"selected ":"")."value='$no'>$name</option>"; ?>
                    </select>
                </div>
                <div class="span4" align="center">
                    <select id="<?php echo $value; ?>_fl" name="<?php echo $value; ?>_fl" class="input-small">
                        <option <?php if ($selected2=='First') echo "selected ";?>>First</option>
                        <option <?php if ($selected2=='Last') echo "selected ";?>>Last</option>
                    </select>
                </div>
                <div class="span4" align="center">
                    <input id="<?php echo $value; ?>_ival" name="<?php echo $value; ?>_ival" class="input-small subTotal" ty align="right" value="<?php echo $selected3; ?>" onchange="recalc(); return false;" type="number" min="0"/>
                    <input id="<?php echo $value; ?>_val" name="<?php echo $value; ?>_val" type="hidden"/>
                </div>
            </div></div><!-- Phase selection row -->
        <?php
    }
} else {
    foreach ($psel as $value) {
        $selected = $orderxml -> $value -> Phase;
    ?><div class="row-fluid">
      <div class="span12 control-group" align="center">
        <select id="<?php echo $value; ?>" name="<?php echo $value; ?>" class="input-medium">
            <?php foreach ($phases as $no=>$name) {
            echo "<option ".($selected==$no?"selected ":"")."value='$no'>$name</option>";
            } ?>
        </select>
        <input type='hidden' name='<?php echo $value; ?>_val' value='0'/>
      </div>
    </div><!-- Phase selection row -->
    <?php }
    foreach ($nsel as $value) { ?>
    <input type='hidden' name='<?php echo $value; ?>' id='<?php echo $value; ?>' value='<?php echo $value; ?>'/>
    <input type='hidden' name='<?php echo $value; ?>_val' value='0'/>
    <?php }
} ?>
