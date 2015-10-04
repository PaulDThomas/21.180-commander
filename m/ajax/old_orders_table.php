<!-- $Id: old_orders_table.php 233 2014-07-08 20:11:00Z paul $  -->
<table width='100%' class="table table-nohover table-bordered table-condensed">
    <thead>
        <tr>
            <th width="5%" align='center'>Game</th>
            <th width="5%" align='center' class='hidden-phone'>Turn</th>
            <th width="5%" align='center' class='hidden-phone'>Phase</th>
            <th width="5%" align='center' class='hidden-phone'>User</th>
            <th width="12%" align='center'>Order</th>
            <th width="15%" align='center'>Timestamp</th>
            <th align='center'>Returned</th>
        </tr>
    </thead>
<tbody>
<?php

// Get database connection
ob_start();
require("../php/dbconnect.php");
ob_end_clean();
require("../php/utl_xml_table.php");

$s = $_POST['s']."/1000 and (".$_POST['e']."/1000+86359)";
if ($_POST['g'] != 'All') $s .= "and gameno=".$_POST['g'];
$result = $mysqli->query("Select gameno, turnno, phaseno, userno, ordername, from_unixtime(order_uts) as uts, order_code From sp_old_orders Where order_uts between $s  Order By order_uts Desc, old_order_pk Desc");

if ($result->num_rows > 0) while ($row = $result->fetch_assoc()) { 
?>
    <tr <?php if (strstr($row['order_code'],'FAIL')) echo "style='background-color:#ff4444'"; ?>>
        <td valign='top'><?php echo $row['gameno'] ?></td>
        <td valign='top' class='hidden-phone'><?php echo $row['turnno'] ?></td>
        <td valign='top' class='hidden-phone'><?php echo $row['phaseno'] ?></td>
        <td valign='top' class='hidden-phone'><?php echo $row['userno'] ?></td>
        <td valign='top'><?php echo $row['ordername'] ?></td>
        <td valign='top'><?php echo $row['uts'] ?></td>
        <td><?php echo utl_xml_table($row['order_code']); ?></td>
    </tr>
<?php } else { ?><tr><td colspan='4'>No data from <pre><?php print_r($_POST) ?></pre></td></tr><?php }

if ($result) $result -> close();
$mysqli -> close();
?>
</tr>
</tbody>
</table>
