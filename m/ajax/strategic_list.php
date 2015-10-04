<?php

// $Id: strategic_list.php 70 2012-03-30 00:35:12Z paul $
// Mobile resource card feed

// Connect to database
session_start();
require("dbconnect.php");

// Set session
if (!isset($_SESSION['offset']) and isset($_COOKIE['offset'])) { $_SESSION['offset'] = $_COOKIE['offset']; }
if (!isset($_SESSION['dt_format']) and isset($_COOKIE['dt_format'])) { $_SESSION['dt_format'] = $_COOKIE['dt_format']; }

// Get resource card info
$query="
Select powername
       ,nuke_tech_level, nukes, nukes_left
       ,lstar_tech_level, lstars
       ,neutron_tech_level, neutron
       ,ksat_tech_level, ksats
From sp_resource r
Left Join sp_game g On g.gameno=r.gameno
Where userno=${_SESSION['sp_userno']} and r.gameno=${_SESSION['sp_gameno']}"
;
$result = $mysqli -> query($query);

// Output to window
if ($result->num_rows > 0) while ($row=$result->fetch_row()) {
?>
    <h3><?php echo $row[0]; ?></h3>
    <div class="ui-grid-a">
        <!-- Nukes -->
        <?php if ($row[1] < 6) { ?>
            <div class="ui-block-a"><div class="ui-bar ui-bar-a">Nukes</div></div>
            <div class="ui-block-b"><div class="ui-bar ui-bar-a"><?php echo $row[2]; ?></div></div>
            <div class="ui-block-a"><div class="ui-bar ui-bar-b">Tech required</div></div>
            <div class="ui-block-b"><div class="ui-bar ui-bar-b"><?php echo $row[1]; ?></div></div>
            <div class="ui-block-a"><div class="ui-bar ui-bar-b">Nukes Left</div></div>
            <div class="ui-block-b"><div class="ui-bar ui-bar-b"><?php echo $row[3]; ?></div></div>
        <?php }  else { ?>
            <div class="ui-block-a"><div class="ui-bar ui-bar-d">Nukes</div></div>
            <div class="ui-block-b"><div class="ui-bar ui-bar-d">Unavailable</div></div>
        <?php } ?>
        <!-- L-Stars -->
        <?php if ($row[4] < 6) { ?>
            <div class="ui-block-a"><div class="ui-bar ui-bar-a">L-Stars</div></div>
            <div class="ui-block-b"><div class="ui-bar ui-bar-a"><?php echo $row[5]; ?></div></div>
            <div class="ui-block-a"><div class="ui-bar ui-bar-b">Tech required</div></div>
            <div class="ui-block-b"><div class="ui-bar ui-bar-b"><?php echo $row[4]; ?></div></div>
            <?php if ($row[5] > -1) { ?>
                </div>
                <ul class="strategicList" data-theme="b" style="margin:0px">
                    <li><a href="lstars.php">L-Star Deployment</a></li>
                </ul>
                <div class="ui-grid-a">
            <?php }
    } else { ?>
            <div class="ui-block-a"><div class="ui-bar ui-bar-d">L-Stars</div></div>
            <div class="ui-block-b"><div class="ui-bar ui-bar-d">Unavailable</div></div>
        <?php } ?>
        <!-- Neutron Bombs -->
        <?php if ($row[6] < 6) { ?>
            <div class="ui-block-a"><div class="ui-bar ui-bar-a">Neutron Bombs</div></div>
            <div class="ui-block-b"><div class="ui-bar ui-bar-a"><?php echo $row[7]; ?></div></div>
            <div class="ui-block-a"><div class="ui-bar ui-bar-b">Tech required</div></div>
            <div class="ui-block-b"><div class="ui-bar ui-bar-b"><?php echo $row[6]; ?></div></div>
        <?php }  else { ?>
            <div class="ui-block-a"><div class="ui-bar ui-bar-d">Neutron Bombs</div></div>
            <div class="ui-block-b"><div class="ui-bar ui-bar-d">Unavailable</div></div>
        <?php } ?>
        <!-- K-Sats -->
        <?php if ($row[8] < 6) { ?>
            <div class="ui-block-a"><div class="ui-bar ui-bar-a">K-Sat</div></div>
            <div class="ui-block-b"><div class="ui-bar ui-bar-a"><?php echo $row[9]; ?></div></div>
            <div class="ui-block-a"><div class="ui-bar ui-bar-b">Tech required</div></div>
            <div class="ui-block-b"><div class="ui-bar ui-bar-b"><?php echo $row[8]; ?></div></div>
        <?php }  else { ?>
            <div class="ui-block-a"><div class="ui-bar ui-bar-d">K-Sats</div></div>
            <div class="ui-block-b"><div class="ui-bar ui-bar-d">Unavailable</div></div>
        <?php } ?>
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
