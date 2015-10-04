<h2>Market Prices</h2>
<?php 
// Table of market prices for a game
// $Id: market_panel.php 86 2012-06-07 23:24:07Z paul $

// Get prices
$query = "
Select m.price as minerals, o.price as oil, g.price as grain
From sp_market a Left Join sp_prices m On m.market_level=minerals_level
Left Join sp_prices o on o.market_level=oil_level
Left Join sp_prices g on g.market_level=grain_level
Where gameno=$gameno
";
$result = $mysqli -> query($query);
$row = $result -> fetch_assoc();
$result -> close();
?>
<table class="table table-bordered table-condensed">
    <tr><th width="40%">Minerals</th><td class="ral"><?php echo $row['minerals']; ?></td></tr>
    <tr><th width="40%">Oil</th><td class="ral"><?php echo $row['oil']; ?></td></tr>
    <tr><th width="40%">Grain</th><td class="ral"><?php echo $row['grain']; ?></td></tr>
</table>
