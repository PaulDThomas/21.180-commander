<H2>Transfer Cash</H2>
<!-- $Id -->
<form method="post" class="form-horizontal" id="transferForm">
<input type="hidden" name="randgen" id="randgen" class="resourceVal" value="<?php echo $RESOURCE['randgen']; ?>" />
<div class="row-fluid"><div class="span5">Total funds</div><div class="span7 resourceVal" id="cash"><?php echo $RESOURCE['cash']; ?></div></div>
<div class="row-fluid"><div class="span5">Liquid Asset %</div><div class="span7"><?php echo $GAME['liquid_asset_percent']; ?></div></div>
<div class="row-fluid"><div class="span5">Cash available</div><div class="span7 resourceVal" id="cash_avail"><?php $avail = floor(($RESOURCE['cash']-$RESOURCE['cash_transferred_in']+$RESOURCE['cash_transferred_out'])*$GAME['liquid_asset_percent']/100) + $RESOURCE['cash_transferred_in'] - $RESOURCE['cash_transferred_out']; echo $avail; ?></div></div>
<div class="row-fluid">
    <div class="span5">Superpower</div>
    <div class="span7 control-group">
        <select id="transferTo" name="transferTo" class="input-medium">
            <?php
        $result = $mysqli -> query ("Select powername From sp_resource Where gameno=$gameno and powername != '$powername' and dead = 'N'");
        while ($row = $result -> fetch_row()) echo "<option>" . $row[0] . "</option>";
        $result -> close();
        ?>
        </select>
    </div>
</div>
<div class="row-fluid">
    <div class="span5">Amount</div>
    <div class="span7 control-group">
        <input name="transferAmt" id="transferAmt" value="0" type="number" min="0" max="<?php echo $avail; ?>" class="input-medium"/>
    </div>
</div>
<div class="row-fluid">
    <div class="span12 control-group" align="center">
        <input type="button" value="Transfer" id="transferButton" class="btn btn-primary"/>
    </div>
</div>
</form>