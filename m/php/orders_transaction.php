<h1 id="orderLabel"><?php echo $transaction; ?></h1>
<form class="form-horizontal" method="post" id="orderForm">
<input type="hidden" name="randgen" value="<?php echo $RESOURCE['randgen']; ?>" />
<input type="hidden" name="transaction" value="<?php echo $transaction; ?>" />
<?php

// Called from Sell, Buy or Accept panels
// $Id: orders_transaction.php 244 2014-07-13 16:44:49Z paul $

// Get current orders
$result = $mysqli -> query("Select order_code From sp_orders Where gameno=$gameno and phaseno=$phaseno and ordername='SR_ORDERXML'");
if ($result -> num_rows > 0) {
    $row = $result -> fetch_row();
    libxml_use_internal_errors(true);
    $orderxml = SimpleXML_Load_String($row[0]);
    $Resource = $orderxml -> Resource;
    $Price = $orderxml -> Price;
    $Amount = $orderxml -> Amount;
    $Buyer = $orderxml -> Buyer;
    $Seller = $orderxml -> Seller;
    $Accepted = 'N';
} else {
    $Resource = '';
    $Price = '0';
    $Amount = '0';
    $Buyer = '';
    $Seller = '';
    $Accepted = 'N';
}
$result -> close();
$TotalValue = $Price * $Amount;

?>
<div class="row-fluid">
    <div class="span4" align="right" id="resourceLab"></div>
    <div class="span8 control-group" align="left">
        <select name="Resource" class="input-large" id="Resource">
            <?php
            $resList = array("pass"=>"Pass","minerals"=>"Minerals","oil"=>"Oil","grain"=>"Grain"
                            ,"land_tech"=>"Armies technology","water_tech"=>"Naval technology","strategic_tech"=>"Strategic technology"
                            ,"resource_tech"=>"Resource technology","espionage_tech"=>"Espionage technology"
                            ,"nukes"=>"Nukes","lstars"=>"L-Stars","ksats"=>"K-Sats","neutron"=>"Neutron Bombs"
                            ,"max_minerals"=>"Minerals storage","max_oil"=>"Oil storage","max_grain"=>"Grain storage"
                            );
            foreach ($resList as $key=>$value) {
                echo "<option ".(($Resource==$key)?"selected":"")." value='$key'>$value</option>";
                }
            ?>
        </select>
    </div>
</div>

<div id="theBlind" style="<?php if ($Resource=='') echo "display:none;"; ?>padding:0;<?php if ($Resource=='pass') {echo "display:none";}; ?>">
<div class="row-fluid">
    <div class="span4" align="right" id="actionLabel"><?php echo $transaction_label; ?></div>
    <div class="span8 control-group" align="left">
        <input type='hidden' name='<?php echo ($transaction_var=='Seller')?'Buyer':'Seller'; ?>' value='<?php echo $powername; ?>' />
        <?php
        // No Siege, just the list
        if ($GAME['siege'] != "Y") {
            $byrList = array("Market");
            $query = "Select powername From sp_resource Where gameno=$gameno and dead='N' and powername!='$powername' order by powername";
            $result = $mysqli -> query($query) or die($mysqli -> error);
            while ($row = $result -> fetch_row() ) $byrList[] = $row[0];
            $result -> close();
            $siege_status='N';
        } else {
            // Get trading partners
            $byrList = array();
            $result = $mysqli -> query("Select * From sv_trading_partners Where gameno=$gameno and powername='$powername' Order By Case When trading_partner='Market' Then 0 Else 1 End, trading_partner") or die($mysqli->error);
            while ($row = $result -> fetch_assoc()) array_push($byrList,$row['trading_partner']);
            $result -> close();
            if (in_array("Market",$byrList)) $siege_status='N'; else $siege_status='Y';
        }
        ?><select id="who" name="<?php echo $transaction_var; ?>" class="input-large" siege="<?php echo $siege_status; ?>" ><?php
        foreach ($byrList as $value) {
            echo "<option ".(($$transaction_var==$value)?"selected ":"")."value='$value'>$value</option>";
        }
    ?>
        </select>
    </div>
</div>

<div class="row-fluid">
    <div class="span4" align="right">Price each</div>
    <div class="span8 control-group" align="left">
        <input <?php if ($Resource=='') echo "readonly ";?>type="number" min="0" value="<?php echo $Price; ?>" id="Price" name="Price" class="input-medium"/>
    </div>
</div>

<div class="row-fluid">
    <div class="span4" align="right">Amount</div>
    <div class="span8 control-group" align="left">
        <input type="number" min="0" value="<?php echo $Amount; ?>" id="Amount" name="Amount" class="input-medium"/>
    </div>
</div>

<div class="row-fluid">
    <div class="span4" align="right">Total Value</div>
    <div class="span8 control-group" align="left">
        <input readonly type="number" min="0" value="<?php echo $TotalValue; ?>" id="TotalValue" name="TotalValue" class="input-medium"/>
    </div>
</div>
</div><!-- theBlind -->
<!-- Process orders button -->
<div class="row-fluid" style="padding-top:20px">
    <div class="span12" align="center">
        <input type="button" id="rejectOffer" class="btn btn-danger" value="Reject" style="display:none" />
        <input type="submit" id="processOrders" value="Process" name="PROCESS" class="btn btn-success"/>
    </div>
</div>

<!-- Current resources -->
<?php foreach ($RESOURCE as $key=>$val) if (array_key_exists($key, $resList)) echo "<input type='hidden' id='$key' value='$val'/>"; ?>
<input type='hidden' id='cash' value='<?php echo $RESOURCE['cash']; ?>'/>
<!-- Market prices -->
<?php
$result = $mysqli -> query("Select lower(resource) as resource, price From sv_market_prices Where gameno=$gameno");
while ($row = $result -> fetch_assoc()) echo "<input type='hidden' id='${row['resource']}Price' value='${row['price']}' />";
$result -> close();
?>
<input type='hidden' name='Accepted' id='Accepted' value='<?php echo $Accepted; ?>' />
</form>