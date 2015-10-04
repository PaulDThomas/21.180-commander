<H2>Loan Application Form</H2>
<!-- $Id: loan_panel.php 131 2013-05-13 22:22:33Z paul $ -->
<form method="post" class="form-horizontal" id="loanForm">
<input type="hidden" name="randgen" id="randgen" class="resourceVal" value="<?php echo $RESOURCE['randgen']; ?>" />
<div class="row-fluid"><div class="span5">Current Loan</div><div class="span7 resourceVal" id="loan"><?php echo $RESOURCE['loan']; ?></div></div>
<div class="row-fluid">
    <div class="span5">Companies Held</div>
    <div class="span7">
        <?php
    $result = $mysqli -> query ("Select Count(*) From sp_cards Where gameno=$gameno and userno=$userno");
    $row = $result -> fetch_row();
    $result -> close();
    $companies_held = $row[0];
    echo $companies_held;
    ?>
    </div>
</div>
<div class="row-fluid"><div class="span5">Maximum loan available</div><div class="span7" id="maxLoanAmt"><?php echo (min(floor($companies_held/2),12))*1000 ?></div></div>
<div class="row-fluid">
    <div class="span5">Amount to borrow</div>
    <div class="span7 control-group">
        <select id="loanAmt" name="loanAmt" class="input-medium">
            <?php for ($i=0; $i <= (min(floor($companies_held/2),12))*1000 - $RESOURCE['loan']; $i=$i+1000) echo "<option>" . $i . "</option>"; ?>
        </select>
    </div>
</div>
<div class="row-fluid">
    <div class="span12 control-group" align="center">
        <input type="button" value="Apply" id="loanButton" class="btn btn-primary"/>
    </div>
</div>
</form>