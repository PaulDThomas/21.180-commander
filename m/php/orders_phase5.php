<h1>Build and research</h1>
<form id="orderForm" class="form-horizontal" method="post">
<input type="hidden" name="randgen" value="<?php echo $RESOURCE['randgen']; ?>" />
<?php
// Build orders
// $Id: orders_phase5.php 237 2014-07-10 07:28:53Z paul $

// Exisiting info will be in the SR_ORDERXML order
$result = $mysqli -> query ("select order_code From sp_orders Where gameno=$gameno and userno=$userno and ordername='SR_ORDERXML'") or die ($mysqli -> error);;
$row = $result -> fetch_row();
$result -> close();

libxml_use_internal_errors(true);
$orderxml = SimpleXML_Load_String($row[0]);

//echo "<PRE>"; print_r($orderxml); echo "</PRE>";
//echo "*-". $orderxml -> Research -> {"Strategic"} -> Val. "-*";

?>
<div id="researchTable">
    <div class="row-fluid" style="padding-top:20px">
        <div class="span9 collHead"><h3><i id='troops' class="icon-plus-sign"></i> Research Budget</h3></div>
        <div class="span3 control-group" align="right"><div class="input-prepend"><span class="add-on">-</span><input id="researchTotal" class="input-mini subTotal" type="text" align="right" readonly value="0" /></div></div>
    </div>
    <div class='collDetail' style='display:none'>
        <div class='row-fluid'>
            <div class='span3'><strong>Budget</strong></div>
            <div class='span3'><strong>Level</strong></div>
            <div class='span3'><strong>Spend</strong></div>
            <div class='span3'><strong>% Chance</strong></div>
        </div>
        <?php
        // Print rows for research
        $rT = array("strategic"=>"Strategic", "land"=>"Army", "water"=>"Naval", "resource"=>"Resource", "espionage"=>"Espionage");
        $rTm = array("strategic"=>4000, "land"=>"3000", "water"=>"3000", "resource"=>"2500", "espionage"=>"2500");
        foreach ($rT as $key=>$val) {
            $Value = $orderxml -> Research -> $key -> Val;
            $Amt = $orderxml -> Research -> $key -> Amt;
            ?><div class='row-fluid control-group'>
                <div class='span3'><?php echo $val; ?></div>
                <div class='span3'><?php echo $RESOURCE["${key}_tech"]; ?> + <input type="number" min="0" max="<?php echo (($key=='espionage')?20:5)-$RESOURCE[$key.'_tech']; ?>" class="researchAmt input input-mini" name="RA_<?php echo $key;?>" value="<?php echo $Amt; ?>" /></div>
                <div class='span3'><input type="number" min="0" max="<?php echo $RESOURCE['cash']; ?>" step="100" class="researchVal input-mini" name="RV_<?php echo $key;?>" value="<?php echo $Value; ?>" /></div>
                <div class='span3'><input readonly class="pct input-mini" align="right" data-pctmod="<?php echo $rTm[$key]; ?>" /></div>
            </div>
        <?php } ?>
    </div><!-- collDetail -->
</div><!-- researchTable -->

<div id="storageTable">
<div class="row-fluid" style="padding-top:20px">
  <div class="span9 collHead"><h3><i class="icon-plus-sign"></i> Build storage</h3></div>
  <div class="span3 control-group" align="right"><div class="input-prepend"><span class="add-on">-</span><input id="resourceTotal" class="input-mini subTotal" type="text" align="right" readonly value="0" /></div></div>
</div>
<div class='collDetail' style='display:none'>
    <div class="row-fluid">
        <div class="span5"><strong>Storage</strong></div>
        <div class="span4"><strong>Amount</strong></div>
        <div class="span3"><strong>Cost</strong></div>
    </div>
    <?php
    $storage = array ("Minerals","Oil","Grain");
    foreach($storage as $val) {
        $value = $orderxml -> Storage -> {"max_$val"};
        $lval = strtolower($val);
        ?><div class="row-fluid control-group">
                <div class="span5"><?php echo $val; ?></div>
                <div class="span4"><?php echo $RESOURCE["max_$lval"]; ?> + <input type="number" class="storeAmt input-mini" id="Max_<?php echo $val; ?>" name="max_<?php echo $val; ?>" value="<?php echo $value; ?>" max="<?php echo $RESOURCE['resource_tech']; ?>" min="0" <?php if ($RESOURCE['resource_tech']==0) echo "readonly";?>/></div>
                <div class="span3"><input readonly value="0" align="right" class="storeVal input-mini" /></div>
            </div>
        <?php } ?>
</div><!-- collDetail -->
</div><!-- storageTable -->

<div id="strategicTable">
<div class="row-fluid" style="padding-top:20px">
  <div class="span9 collHead"><h3><i class="icon-plus-sign"></i> Strategic Budget</h3></div>
  <div class="span3 control-group" align="right"><div class="input-prepend"><span class="add-on">-</span><input id="strategicTotal" class="input-mini subTotal" type="text" align="right" readonly value="0" /></div></div>
</div>
<div class='collDetail' style='display:none'>
    <div class="row-fluid">
        <div class="span5"></div>
        <div class="span4"><strong>Amount</strong></div>
        <div class="span3"><strong>Cost</strong></div>
    </div>
    <?php
    $sT = array("nukes"=>"Nukes","lstars"=>"L-Stars","ksats"=>"K-Sats","neutron"=>"Neutron Bombs");
    $sTm = array("nukes"=>"500","lstars"=>"1000","ksats"=>"1000","neutron"=>"500");
    $sTx = array("nukes"=>"nuke_tech_level","lstars"=>"lstar_tech_level","ksats"=>"ksat_tech_level","neutron"=>"neutron_tech_level");
    foreach ($sT as $key=>$val) {
        $value = $orderxml -> Strategic -> $key;
        ?><div class="row-fluid control-group">
                <div class="span5"><strong><?php echo $val; ?></strong></div>
                <div class="span4"><?php echo $RESOURCE[$key]; ?> + <input type='number' min='0' max='<?php if ($key=='nukes') echo min($RESOURCE['nukes_left'],$RESOURCE['minerals']); else if ($key=='neutron') echo $RESOURCE['minerals']; else echo floor($RESOURCE['minerals']/2); ?>' id="<?php echo $key;?>" name="S-<?php echo $key;?>" class="strategicAmt input-mini" value="<?php echo $value; ?>" <?php if ($RESOURCE['strategic_tech']<$GAME[$sTx[$key]]) echo "readonly";?>/></div>
                <div class="span3"><input readonly class="strategicVal input-mini" align="right" data-cost="<?php echo $sTm[$key]; ?>" value='0'/></div>
            </div>
        <?php } ?>
</div><!-- collDetail -->
</div><!-- strategicTable -->

<?php
$terrs_table_type = "Build";
require_once("utl_terrs_table.php");
?>

<div class="row-fluid" style="padding-top:20px">
    <div class="span3"></div>
    <div class="span3">Initial</div>
    <div class="span3">Spend</div>
    <div class="span3"></div>
</div>
<div class="row-fluid">
  <div class="span3"><h3>Cash</h3></div>
  <div class="span3 initials"><?php echo $RESOURCE['cash']; ?></div>
  <div class="span3"><input readonly id="grandTotal" class="input-mini totals" align="right" value='0'/></div>
  <div class="span3 control-group" align="right"><input id="cashFinal" align="right" class="input-mini final" readonly value="0"/></div>
</div><!-- row -->
<div class="row-fluid">
  <div class="span3"><h3>Minerals</h3></div>
  <div class="span3 initials"><?php echo $RESOURCE['minerals']; ?></div>
  <div class="span3"><input readonly id="mineralsSpend" class="input-mini totals resSpend" align="right" value='0'/></div>
  <div class="span3 control-group" align="right"><input id="mineralsFinal" align="right" class="input-mini final" readonly value="0"/></div>
</div><!-- row -->
<div class="row-fluid">
  <div class="span3"><h3>Oil</h3></div>
  <div class="span3 initials"><?php echo $RESOURCE['oil']; ?></div>
  <div class="span3"><input readonly id="oilSpend" class="input-mini totals resSpend" align="right" value='0'/></div>
  <div class="span3 control-group" align="right"><input id="oilFinal" align="right" class="input-mini final" readonly value="0"/></div>
</div><!-- row -->
<div class="row-fluid">
  <div class="span3"><h3>Grain</h3></div>
  <div class="span3 initials"><?php echo $RESOURCE['grain']; ?></div>
  <div class="span3"><input readonly id="grainSpend" class="input-mini totals resSpend" align="right" value='0'/></div>
  <div class="span3 control-group" align="right"><input id="grainFinal" align="right" class="input-mini final" readonly value="0"/></div>
</div><!-- row -->

<div class="row-fluid" style="padding-top:20px">
    <div class="span12" align="center">
        <input type="submit" id="processOrders" value="Process Orders" name="PROCESS" class="btn btn-success"/>
    </div>
</div>
</form>
