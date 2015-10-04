<?php

// $Id: resource_list.php 69 2012-03-19 05:47:53Z paul $
// Mobile resource card feed

// Connect to database
session_start();
require("dbconnect.php");

// Set session
if (!isset($_SESSION['offset']) and isset($_COOKIE['offset'])) { $_SESSION['offset'] = $_COOKIE['offset']; }
if (!isset($_SESSION['dt_format']) and isset($_COOKIE['dt_format'])) { $_SESSION['dt_format'] = $_COOKIE['dt_format']; }

// Get resource card info
$query="
Select powername, cash, loan, interest
       ,minerals, max_minerals, oil, max_oil, grain, max_grain
       ,land_tech, water_tech, strategic_tech, resource_tech, espionage_tech
From sp_resource r
Where userno=${_SESSION['sp_userno']} and r.gameno=${_SESSION['sp_gameno']}"
;
$result = $mysqli -> query($query);

// Output to window
if ($result->num_rows > 0) while ($row=$result->fetch_row()) {
?>
    <h3><?php echo $row[0]; ?></h3>
    <div class="ui-grid-a">
        <div class="ui-block-a"><div class="ui-bar ui-bar-a">Cash</div></div>
        <div class="ui-block-b"><div class="ui-bar ui-bar-a"><?php echo $row[1]; ?></div></div>
        <div class="ui-block-a"><div class="ui-bar ui-bar-b">Loan</div></div>
        <div class="ui-block-b"><div class="ui-bar ui-bar-b"><?php echo $row[2]; ?></div></div>
        <div class="ui-block-a"><div class="ui-bar ui-bar-b">Interest</div></div>
        <div class="ui-block-b"><div class="ui-bar ui-bar-b"><?php echo $row[3]; ?></div></div>
    </div>
    <ul class="resourceList" data-theme="b" style="margin:0px">
        <li><a href="loan.php">Take loan</a></li>
    </ul>

    <h4>Resources</h4>
    <div class="ui-grid-a">
        <div class="ui-block-a"><div class="ui-bar ui-bar-a">Minerals</div></div>
        <div class="ui-block-b"><div class="ui-bar ui-bar-a"><?php echo $row[4]; ?> (<?php echo $row[5]; ?>)</div></div>
        <div class="ui-block-a"><div class="ui-bar ui-bar-a">Oil</div></div>
        <div class="ui-block-b"><div class="ui-bar ui-bar-a"><?php echo $row[6]; ?> (<?php echo $row[7]; ?>)</div></div>
        <div class="ui-block-a"><div class="ui-bar ui-bar-a">Grain</div></div>
        <div class="ui-block-b"><div class="ui-bar ui-bar-a"><?php echo $row[8]; ?> (<?php echo $row[9]; ?>)</div></div>
    </div>
    <ul class="resourceList" data-theme="b" style="margin:0px">
        <li><a href="companies.php">Company details</a></li>
    </ul>

<h4>Technologies</h4>
    <div class="ui-grid-a">
        <div class="ui-block-a"><div class="ui-bar ui-bar-a">Army</div></div>
        <div class="ui-block-b"><div class="ui-bar ui-bar-a"><?php echo $row[10]; ?></div></div>
        <div class="ui-block-a"><div class="ui-bar ui-bar-a">Naval</div></div>
        <div class="ui-block-b"><div class="ui-bar ui-bar-a"><?php echo $row[11]; ?></div></div>
        <div class="ui-block-a"><div class="ui-bar ui-bar-a">Strategic</div></div>
        <div class="ui-block-b"><div class="ui-bar ui-bar-a"><?php echo $row[12]; ?></div></div>
        <div class="ui-block-a"><div class="ui-bar ui-bar-a">Resource</div></div>
        <div class="ui-block-b"><div class="ui-bar ui-bar-a"><?php echo $row[13]; ?></div></div>
        <div class="ui-block-a"><div class="ui-bar ui-bar-a">Espionage</div></div>
        <div class="ui-block-b"><div class="ui-bar ui-bar-a"><?php echo $row[14]; ?></div></div>
    </div>
<?php
} else {
?>No resources found<?php
}

// Close result
$result -> close();
// Close connection
$mysqli -> close();
// Close session
session_write_close();

?>
