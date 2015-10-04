<h2>Loan Rates</h2>
<table class="table table-bordered table-condensed">
    <thead><tr><th width="50%">Loan</th><th>Interest/turn</th></tr></thead>
    <tbody>
<?php 
// Table of loan rates
// $Id: loanrates_panel.php 237 2014-07-10 07:28:53Z paul $

// Get rates
$query = "
Select loan_level, price
From sp_loan
";
$result = $mysqli -> query($query);
while ($row = $result -> fetch_assoc()) { ?>
    <tr><td class="ral"><?php echo $row['loan_level']?></td><td class="ral"><?php echo $row['price']; ?></td></tr>
<?php }
$result -> close();
?>
    </tbody>
</table>
