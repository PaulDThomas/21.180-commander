<h2>Parameters</h2>
<?php

// Game parameters table
// $Id: parameters_panel.php 201 2014-03-03 19:19:03Z paul $

require_once("m/php/newq_x_params.php");

$gameno = isset($gameno)?$gameno:0;
$query = "Select deadline_uts ,sf_format_hms(advance_uts) as advance ,phase2_type";
foreach ($newq_xml->Parameter As $parameter) $query .= ",".$parameter->Name;
$query .= " From sp_game Where gameno=$gameno;";
$result = $mysqli -> query($query) or die("Failed on query: $query");
if ($row = $result -> fetch_assoc()) {
    if ($row['deadline_uts']==null) {
        $deadline = 'Game over';
    } else {
        $deadline = gmdate((isset($_SESSION['dt_format'])?$_SESSION['dt_format']:'jS F Y h:i:s a'), $row['deadline_uts'] - (isset($_SESSION['offset'])?$_SESSION['offset']:0)*60);
    }
    ?>
    <table class="table table-bordered">
        <tr><th>Deadline</th><td><?php echo $deadline; ?></td></tr>
        <tr><th>Deadline advances</th><td><?php echo $row['advance']; ?></td></tr>
        <tr><th>Phase selection type</th><td><?php echo $row['phase2_type']; ?></td></tr>
        <?php foreach ($newq_xml->Parameter As $parameter) { ?>
            <tr>
                <th><?php echo $parameter->Label; ?></th>
                <td>
                    <?php
            $xpath = "Options/Option[Value='".$row["$parameter->Name"]."']";
            $value = $parameter->xpath($xpath);
            echo isset($value[0]->Label)?$value[0]->Label:$value[0]->Value;
        ?>
                </td>
            </tr>
        <?php } ?>
    </table>
<?php } ?>
