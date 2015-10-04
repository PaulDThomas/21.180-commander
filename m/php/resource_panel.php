<h2>Resource Card</h2>
<?php

// Resource table
// $Id: resource_panel.php 237 2014-07-10 07:28:53Z paul $
// Mainly populated by AJAX

?>
<table class="table table-bordered table-condensed">
    <tr><td colspan="2"><h4><div class="dropdown">
        <div data-toggle="dropdown" class="dropdown-toggle"><span class="resourceVal" id="powername"><?php echo $powername; ?></span> <b class="caret"></b></div>
        <ul class="dropdown-menu">
            <li><a class="powerLink" href="#"><?php echo $powername; ?></a></li>
            <?php
            // Get available Superpowers list
            $query = "Select powername From sp_resource Where gameno = $gameno and powername != '$powername' and dead='N' and espionage_tech < ${RESOURCE['espionage_tech']} Order By powername";
            $result = $mysqli -> query($query);
            // No rows
            if ($result -> num_rows == 0) { ?><li>No Superpowers available</li><?php }
            // Some rows
            else while ($row = $result -> fetch_row()) { ?><li><a class="powerLink" href="#"><?php echo $row[0]; ?></a></li> <?php }

            $result -> close();
            ?>
        </ul>
    </div></h4></td></tr>
    <tr>
        <th width='50%'>Total funds</th>
        <td width='50%' id="cash" class="resourceVal"></td>
    </tr>
    <tr>
        <th>Loan</th>
        <td id="loan" class="resourceVal"></td>
    </tr>
    <tr>
        <th>Outstanding Interest</th>
        <td id="interest" class="resourceVal"></td>
    </tr>
</table>
<table class="table table-bordered table-condensed">
    <thead>
        <tr>
            <td width='40%'>&nbsp;</td>
            <th width='30%'>Available</th>
            <th width='30%'>Capacity</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <th>Minerals</th>
            <td id="minerals" class="resourceVal"></td>
            <td id="max_minerals" class="resourceVal"></td>
        </tr>
        <tr>
            <th>Oil</th>
            <td id="oil" class="resourceVal"></td>
            <td id="max_oil" class="resourceVal"></td>
        </tr>
        <tr>
            <th>Grain</th>
            <td id="grain" class="resourceVal"></td>
            <td id="max_grain" class="resourceVal"></td>
        </tr>
    </tbody>
</table>
<table class="table table-bordered table-condensed">
<?php
$resList = array("nukes"=>"Nukes","nukes_left"=>"Nuclear material","lstars"=>"L-Stars","ksats"=>"K-Sats","neutron"=>"Neutron Bombs"
                );
foreach ($resList as $name => $label) echo "<tr><th width='40%'>$label</th><td class='resourceVal' id='$name'></td></tr>";
?></table>
<table class="table table-bordered table-condensed">
<?php
$resList = array("strategic_tech"=>"Strategic technology","land_tech"=>"Armies technology","water_tech"=>"Naval technology"
                ,"resource_tech"=>"Resource technology","espionage_tech"=>"Espionage technology"
                );
foreach ($resList as $name => $label) echo "<tr><th width='40%'>$label</th><td class='resourceVal' id='$name'></td></tr>";
?></table>
