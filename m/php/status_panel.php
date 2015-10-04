<h2>Status<?php echo ($turnno!='')?" <small>Turn $turnno</small>":""; ?></h2>
<table class="table table-bordered table-condensed">
<?php

// Status table
// $Id: status_panel.php 237 2014-07-10 07:28:53Z paul $

$last_phase='';
$query = "
Select powername, phasedesc
       ,Case
         When substring(ordername,8,3) = 'RET' Then 'In queue - Retaliation'
         When substring(ordername,8,4) = 'REDE' Then 'In queue - Redeploy'
         When substring(ordername,8,4) = 'REAT' Then 'In queue - Redeploy'
         Else order_code
        End, mia
From sv_current_orders
Where gameno=$gameno and (ordername='ORDSTAT' or substring(ordername,1,3)='MA_')
       and substring(ordername,1,7) != 'MA_000_'
";

$result = $mysqli -> query($query) or die ($mysqli -> error);
if ($result -> num_rows > 0) { while ($row = $result -> fetch_row()) {
    $tabpowername = $row[0];
    $phasedesc = $row[1];
    $order_code = $row[2];
    $mia = $row[3];

    if ($last_phase != $phasedesc) {?><thead><tr><th colspan="2"><?php echo $phasedesc; ?></th></tr></thead><?php }
    $last_phase=$phasedesc;
    ?><tr>
        <td><?php
            if ($mia >= 3) echo "<em>$tabpowername (MIA)</em>";
            else if($powername == $tabpowername) echo "<strong>$tabpowername</strong>";
            else echo $tabpowername;
        ?>
        </td>
        <td><?php echo $order_code; ?></td>
    </tr><?php } $result -> close(); } ?>
</table>
