<h1>Acquire Companies</h1>
<div class="row-fluid" style='padding-top:10px'>
<?php
// $Id: orders_phase7.php 237 2014-07-10 07:28:53Z paul $

// Get list of companies from orders table (should always be one after Move Queue with 10 entries in it
$query = "
Select c.cardno, c.userno, rc.res_name, rc.res_type, rc.res_amount, p.terrname
 ,100*(Case When b.userno in (0,-1) Then 1 Else 0 End)*(10+b.minor+5*b.major)+200*rc.res_amount As cost
 ,Case When b.userno in (-1,0,$userno) Then 'Y' Else 'N' End As avail
From sp_cards c
Join sp_orders o On order_code like Concat('%<CardNo>',c.cardno,'</CardNo>%') and o.gameno=c.gameno and o.ordername='SR_ACOMP'
Join sp_res_cards rc On c.cardno=rc.cardno
Join sp_places p On rc.terrno=p.terrno
Join sp_board b On c.gameno=b.gameno and b.terrno=rc.terrno
Where c.gameno=$gameno
Order By Case
          When rc.res_type='Minerals' Then 1
          When rc.res_type='Oil' Then 2
          When rc.res_type='Grain' Then 3
          Else 9
        End, rc.res_amount, rc.res_name
;
";
$result = $mysqli -> query ($query) or die ($mysqli -> error);

?>
Cash : <?php echo $RESOURCE['cash']; ?>
<table class="table table-bordered table-nohover">
<thead>
        <tr>
            <th>Company</th>
            <th>Resource</th>
            <th>Units</th>
            <th>Territory</th>
            <th>Cost</th>
        </tr>
</thead>
<?php
while ($row = $result -> fetch_assoc()) { ?>
    <tr>
        <td><?php echo $row['res_name']; ?></td>
        <td><?php echo $row['res_type']; ?></td>
        <td><?php echo $row['res_amount']; ?></td>
        <td><?php echo $row['terrname']; ?></td>
        <td style="text-align:center">
            <?php if ($row['avail']=='N') echo "&nbsp;"; else echo "<input type='button' data-card='${row['cardno']}' value='${row['cost']}' class='btn btn-primary cardBtn'".($row['cost'] > $RESOURCE['cash']?' disabled':'')." />"; ?>
        </td>
    </tr>
<?php }
$result -> close();
?>
</table>
</div>
<div style="padding-top:10px" align="center">
    <form class="form-horizontal" method="post" id="orderForm">
        <input type="hidden" name="randgen" value="<?php echo $RESOURCE['randgen']; ?>" />
        <input type="hidden" name="PROCESS" value="Acquire" />
        <input type="hidden" id="CardNo" name="CardNo" value="-1" />
        <input type="submit" value="Pass" class="btn btn-primary"/>
    </form>
</div>