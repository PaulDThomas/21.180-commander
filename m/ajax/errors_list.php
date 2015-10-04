<?php

// $Id: errors_list.php 70 2012-03-30 00:35:12Z paul $
// Gamelist feed

// Connect to database
session_start();
require("dbconnect.php");

// Set session
if (!isset($_SESSION['offset']) and isset($_COOKIE['offset'])) { $_SESSION['offset'] = $_COOKIE['offset']; }
if (!isset($_SESSION['dt_format']) and isset($_COOKIE['dt_format'])) { $_SESSION['dt_format'] = $_COOKIE['dt_format']; }

// Get all games
$result = $mysqli -> query("Select gameno, deadline_uts
                            From sp_game
                            Where process is not null");

if ($result->num_rows > 0) while ($row=$result->fetch_row()) {
?>
    <div data-role="collapsible" data-content-theme="a" data-theme="a" data-collapsed="false">
            <h3>Game <?php echo $row[0]; ?></h3>
            <p>
                <div class="ui-grid-b">
                    <div class="ui-block-a"><img align="center" id="smap_<?php echo $row[0]; ?>" style="height: 80px; width: 80px; background-image: url(themes/images/ajax-loader.png); background-size: 80px 80px; border-bottom-left-radius: 40px; border-bottom-right-radius: 40px; border-top-left-radius: 40px; border-top-right-radius: 40px;" src="ajax/map.php?xsize=80&xgame=<?php echo $row[0]; ?>"/></div>
                    <div class="ui-block-b">Deadline : <?php echo gmdate($_SESSION['dt_format'], $row[1] - $_SESSION['offset']*60); ?></div>
                    <div class="ui-block-c"><a href="errorreset.php?gameselect=<?php echo $row[0]; ?>" data-role="button" data-icon="refresh" data-iconpos="top" data-inline="true" >Reset</a></div>
                </div>
            </p>
            <strong>Current Orders</strong>
            <div class="ui-grid-b">
                <div class="ui-block-a"><div class="ui-bar ui-bar-a">Superpower</div></div>
                <div class="ui-block-b"><div class="ui-bar ui-bar-a">Order</div></div>
                <div class="ui-block-c"><div class="ui-bar ui-bar-a">Order code</div></div>
                <?php
            $result2 = $mysqli -> query("Select powername, ordername, order_code
                                         From sp_game g, sp_resource r, sp_orders o
                                         Where g.gameno=$row[0]
                                          and g.gameno=r.gameno
                                          and r.userno=o.userno
                                          and o.gameno=g.gameno and o.phaseno=g.phaseno
                                          and o.turnno=g.turnno");
            if ($result2 -> num_rows > 0) while ($row2=$result2->fetch_row()) {
              ?>
                            <div class="ui-block-a"><div class="ui-bar ui-bar-d"><?php echo $row2[0]; ?></div></div>
                            <div class="ui-block-b"><div class="ui-bar ui-bar-d"><?php echo $row2[1]; ?></div></div>
                            <div class="ui-block-c"><div class="ui-bar ui-bar-d"><?php echo $row2[2]; ?></div></div>
                            <?php
            } else {
                ?><div class="ui-block-a">No orders</div><?php
            }
            $result2 -> close();
        ?>
        </div>
    </div><!-- Collapsiable game entry -->
<?php
} else {
?>
    <div data-role="collapsible" data-content-theme="a" data-theme="a" data-collapsed="true111">
            <h3>No games in error</h3>
            <p>None I tell you!</p>
    </div>
<?php
}

// Close result
$result -> close();
// Close connection
$mysqli -> close();
// Close session
session_write_close();

?>