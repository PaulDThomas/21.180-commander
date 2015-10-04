<h2>Company Summary</h2>
<table class="table table-bordered table-condensed" id="companiesTable">
    <thead>
        <tr>
            <td width="40%">Output (Companies)</td>
            <th width="20%">Minerals</th>
            <th width="20%">Oil</th>
            <th width="20%">Grain</th>
        </tr>
    </thead>
    <tbody>
<?php

// Table of resource output for a game
// $Id: company_summary_panel.php 268 2014-12-02 07:31:43Z paul $

// Check siege status
$query = "select powername, siege_status From sv_siege where gameno=$gameno";
$siegeList = array();
$result = $mysqli -> query($query);
if ($result -> num_rows > 0) while ($row = $result -> fetch_row()) $siegeList = array_merge($siegeList, array($row[0] => $row[1]));
$result -> close();

// Get company summary
$query = "Select powername
                  ,Count(Case When res_type='Minerals' Then res_amount Else null End) as n_Minerals
                  ,Count(Case When res_type='Oil' Then res_amount Else null End) as n_Oil
                  ,Count(Case When res_type='Grain' Then res_amount Else null End) as n_Grain
                  ,Sum(Case When res_type='Minerals' and trading='Trading' Then res_amount Else 0 End) as sum_Minerals
                  ,Sum(Case When res_type='Oil' and trading='Trading' Then res_amount Else 0 End) as sum_Oil
                  ,Sum(Case When res_type='Grain' and trading='Trading' Then res_amount Else 0 End) as sum_Grain
           From   sv_companies
           Where gameno=$gameno
           Group By powername
           ";
$result = $mysqli -> query($query);
while ($row = $result -> fetch_assoc()) { ?>
        <tr>
            <th class="tabHead"><?php echo $row['powername']; ?> <?php if ((isset($siegeList[$row['powername']])?$siegeList[$row['powername']]:'') == 'Siege') {?> <span class='badge badge-important'>Siege</span><?php } ?></th>
            <td class="ral"><?php echo "${row['sum_Minerals']} (${row['n_Minerals']})"; ?></td>
            <td class="ral"><?php echo "${row['sum_Oil']} (${row['n_Oil']})"; ?></td>
            <td class="ral"><?php echo "${row['sum_Grain']} (${row['n_Grain']})"; ?></td>
        </tr>
<?php } ?>
    </tbody>
</table>
