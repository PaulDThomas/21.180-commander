<?php

// $Id: game_list.php 196 2014-02-08 15:33:18Z paul $
// Gamelist feed

// Connect to database
require_once("../php/checklogin.php");

// Get all games
$result = $mysqli -> query("Select r1.gameno, r1.powername, g.deadline_uts, g.turnno, g.phaseno, r1.mia, r1.dead, Case When o2.userno is not null Then 'Offer pending' Else '' End as offer, beta, mapHash
                            From sp_resource r1
                            Left Join sv_map_hash g On r1.gameno=g.gameno
                            Left Join sp_orders o2 On o2.gameno=r1.gameno
                                                      and o2.ordername='SR_ORDERXML'
                                                      and (extractValue(o2.order_code,'//Buyer')=r1.powername
                                                           or extractValue(o2.order_code,'//Seller')=r1.powername
                                                           )
                            Where r1.userno=$userno") or die ($mysqli -> error);

if ($result->num_rows > 0) while ($row=$result->fetch_assoc()) {
    $gameinfo = ($row['phaseno']==9)?"Game over":"Turn ${row['turnno']}, Phase ${row['phaseno']}";
?>   <li><?php if ($row['dead']!='N' or $row['phaseno']==9) echo "<div class='game-over' style='display:none'>"?>
        <div class="commanderThumb">
            <a href="<?php if ($row['beta']==0) echo "game.php?gameselect=${row['gameno']}";
                     else if ($row['beta']==-1) echo "legacy/next.php?gameselect=${row['gameno']}";
                     else if ($row['beta']==1) echo "beta/game.php?gameselect=${row['gameno']}";
               ?>">
                <img class="commanderMapThumb supremMap" id="mapImage<?php echo $row['gameno']; ?>" data-width="210" data-gameno="<?php echo $row['gameno']; ?>" data-mapHash="<?php echo "S".$row['gameno']."T".$row['turnno']."P".$row['phaseno'].'H'.$row['mapHash']; ?>" src='m/themes/img/ajax-loader.gif'/>
            </a>
        </div>
        <div class="newsText">
            <h3>Game <?php echo $row['gameno'].' - '.$row['powername']; ?> <small><?php echo $gameinfo; ?></small></h3>
            <p><?php
                $result2 = $mysqli -> query("Select Distinct powername From sp_orders o Left Join sp_resource r On o.userno=r.userno and r.gameno=o.gameno Where o.gameno=".$row['gameno']." and (o.order_code like 'Waiting%' or o.order_code like 'Extra%') Order by powername");
                if ($result2->num_rows > 0) {
                    echo "Waiting for "; $i=1;
                    while ($row2=$result2->fetch_row()) {echo (($i==1)?'':',')." ".(($row2[0]==$row['powername'])?'<strong>':'').$row2[0].(($row2[0]==$row['powername'])?'</strong>':''); $i++;}
                }
            ?></p>
            <p <?php if (isset($row['deadline_uts'])?($row['deadline_uts'] < time()):0) echo "style='font-style:italic'"; ?>>
                <?php if (isset($row['deadline_uts'])) echo "Deadline: ".gmdate($_SESSION['dt_format'], $row['deadline_uts'] - $_SESSION['offset']*60); ?>
           </p>
            <?php if ($row['mia']>=3) { ?><p><span class='badge badge-important'>MIA</span></p><?php } ?>
            <?php if ($row['dead']!='N') { ?><p><span class='badge badge-important'>Defeated</span></p><?php } ?>
            <?php if ($row['offer']!='') { ?><p><span class='badge badge-info'>Offer pending</span></p><?php } ?>
        </div>
    <?php if ($row['dead']!='N' or $row['phaseno']==9) echo "</div>"?></li>
<?php
} else {
?>
    <li>
        <p>No games active</p>
        <p>The game queue is available on the Game menu</p>
    </li>
<?php
}

// Close result
$result -> close();
// Close connection
$mysqli -> close();
// Close session
session_write_close();

?>
