<?php

// $Id: status_list.php 69 2012-03-19 05:47:53Z paul $
// Mobile resource card feed

// Connect to database
session_start();
require("dbconnect.php");

// Set session
if (!isset($_SESSION['offset']) and isset($_COOKIE['offset'])) { $_SESSION['offset'] = $_COOKIE['offset']; }
if (!isset($_SESSION['dt_format']) and isset($_COOKIE['dt_format'])) { $_SESSION['dt_format'] = $_COOKIE['dt_format']; }

// Get resource card info
$query="
Select Distinct Case When a.mia < 3 Then a.powername Else Concat(a.powername,' (MIA)') End
       ,b.turnno
       ,b.phaseno
       ,Case When substring(b.ordername,8,3) = 'RET' Then 'In queue - Retaliation'
             When substring(b.ordername,8,4) = 'REDE' Then 'In queue - Redeploy'
             When substring(b.ordername,8,4) = 'REAT' Then 'In queue - Redeploy'
             Else b.order_code
             End
       ,g.deadline_uts
       ,a.mia
From sp_resource a
    ,sp_orders b
    ,sp_game g
Where a.userno=b.userno
 and a.gameno=${_SESSION['sp_gameno']}
and g.gameno=a.gameno
and b.gameno=a.gameno
and b.turnno = g.turnno
and b.phaseno >= g.phaseno
and (b.ordername='ORDSTAT' or substring(b.ordername,1,3)='MA_')
and substring(b.ordername,1,7) != 'MA_000_'
Order By 2,3,1,Case When ordername='ORDSTAT' Then 'A' else ordername end
";
$result = $mysqli -> query($query);
// Output to window
$last_phase = '';
$last_power = '';
if ($result->num_rows > 0) while ($row=$result->fetch_row()) {
    if ($last_phase == '') {
        ?>
        <div class="ui-bar ui-bar-a">Deadline : <?php echo gmdate($_SESSION['dt_format'], $row[4] - $_SESSION['offset']*60); ?>, Turn : <?php echo $row[1]; ?></div>
        <?php
    }
    if ($last_phase != $row[2]) {
        ?>
        </div>
        <h4>Phase <?php echo $row[2]; ?></h4>
        <div class="ui-grid-a">
        <?php
        $last_phase = $row[2];
    }
    if ($row[5] >= 3) {
        ?>
                    <em>
                    <div class="ui-block-a"><div class="ui-bar ui-bar-d"><?php if ($row[0]!=$last_power) echo $row[0]; else echo "&nbsp"; $last_power=$row[0]; ?></div></div>
                    <div class="ui-block-b"><div class="ui-bar ui-bar-d"><?php echo $row[3]; ?></div></div>
                    </em>
                <?php
    } else {
        ?>
                    <div class="ui-block-a"><div class="ui-bar ui-bar-c"><?php if ($row[0]!=$last_power) echo $row[0]; else echo "&nbsp"; $last_power=$row[0]; ?></div></div>
                    <div class="ui-block-b"><div class="ui-bar ui-bar-c"><?php echo $row[3]; ?></div></div>
                <?php
    }
}
?></div><?php

// Close result
$result -> close();
// Close connection
$mysqli -> close();
// Close session
session_write_close();

?>
