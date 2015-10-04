<h2>Companies</h2>
<?php

// Table of companies for a game
// $Id: companies_panel.php 268 2014-12-02 07:31:43Z paul $

// Check siege status
$query = "select powername, siege_status From sv_siege where gameno=$gameno";
$siegeList = array();
$result = $mysqli -> query($query);
if ($result -> num_rows > 0) while ($row = $result -> fetch_row()) $siegeList = array_merge($siegeList, array($row[0] => $row[1]));
$result -> close();

// Get companies
$query = "Select * From sv_companies Where gameno=$gameno Order By powername, Case When res_type='Minerals' Then 1 When res_type='Oil' Then 2 Else 3 End, res_amount desc, res_name, terrname";
$result = $mysqli -> query($query) or die($mysqli -> error);
$last_power = '';
$last_resource = '';
while ($row = $result -> fetch_assoc()) {
    if ($row['powername'] != $last_power) {
        $query2 = "Select Count(Case When res_type='Minerals' Then res_amount Else null End) as n_Minerals
                          ,Count(Case When res_type='Oil' Then res_amount Else null End) as n_Oil
                          ,Count(Case When res_type='Grain' Then res_amount Else null End) as n_Grain
                   From   sv_companies
                   Where gameno=$gameno
                    and powername='${row['powername']}'
                   ";
        $result2 = $mysqli -> query($query2);
        $row2 = $result2 -> fetch_assoc();
        if ($last_power != "") { ?></tbody></table></div></div><?php }
?><div>
<div class="collHead">
    <i class="icon-<?php echo ($powername==$row['powername'])?'minus':'plus'; ?>-sign"></i>
    <?php echo $row['powername']; ?>
    <?php if ((isset($siegeList[$row['powername']])?$siegeList[$row['powername']]:'') == 'Siege') {?> <span class='badge badge-important'>Siege</span><?php } ?>
</div>
<div class="collDetail" style="display:<?php echo ($powername==$row['powername'])?'inherit':'none'; ?>">
<table class="table table-bordered table-condensed" id="companiesTable">
    <thead>
        <tr>
            <th width="15%">Resource</th>
            <th width="26%">Company</th>
            <th width="25%">Territory</th>
            <th width="10%">Production</th>
            <th width="24%">Status</th>
        </tr>
    </thead>
    <tbody><?php
    } ?>
        <tr>
            <?php if ($row['res_type'] != $last_resource) { ?><td rowspan="<?php echo $row2['n_'.$row['res_type']]; ?>"><?php echo $row['res_type']; ?></td><?php } ?>
            <td><?php echo $row['res_name']; ?></td>
            <td><?php echo $row['terrname']; ?></td>
            <td class="ral"><?php echo $row['res_amount']; ?></td>
            <td><?php echo $row['running']; if ($row['trading']=="Blockaded") echo " <span class='badge badge-important'>Blockaded</span>"; ?></td>
        </tr>
    <?php
    $last_power = $row['powername'];
    $last_resource = $row['res_type'];
} ?></tbody></table></div></div>