<h2>Satellite status</h2>
<?php
// L-Star defense panel
// $Id: lstar_panel.php 190 2014-02-03 18:14:41Z paul $
$lstars = $RESOURCE['lstars'];
$slots = $RESOURCE['strategic_tech'] + 3;

// Create places array
$PLACES = array();
$PLACES[0] = "Blanket coverage";
$OWNERS[0] = "";
$result = $mysqli -> query("call sr_check_lstar_slots($gameno,'$powername')");
$result = $mysqli -> query("Select terrno, terrname, powername From sv_map Where gameno=$gameno Order By terrname");
while ($row = $result -> fetch_row()) {
    $PLACES[$row[0]] = $row[1];
    $OWNERS[$row[0]] = $row[2];
}
$result -> close();

if ($lstars == 0) { ?><div align="center">No L-Stars Active</div><?php }
else {
?><form id="lstarForm" class="form-horizontal">
<table class="table table-bordered table-condensed">
    <thead>
        <tr>
            <th width="13%">L-Star</th>
            <th width="47%">Protected Territory</th>
            <th width="30%">Owner</th>
        </tr>
    </thead>
    <tbody>
        <?php
        for ($i=0;$i<$lstars;$i++) for ($j=0;$j<$slots;$j++) { ?>
                    <tr>
                        <?php if ($j==0) { ?><td style="text-align:center" rowspan="<?php echo $slots;?>"><?php echo $i+1?></td><?php } ?>
                        <td><?php $v = lsterr($i,$j); ?></td>
                        <td><div id="O_<?php echo $i.'_'.$j; ?>" class="slotVal" data-start="<?php echo $OWNERS[$v]; ?>"><?php echo $OWNERS[$v]; ?></div></td>
                <?php } ?>
    </tbody>
</table>
</form>
<div align="center">
    <input type="button" id="lstarOK" value="Update" class="btn btn-primary" />
</div>
<?php }

// Function to print territory selections
function lsterr($lstar,$slot) {
    global $mysqli, $gameno, $userno, $PLACES;
    $query = "Select terrno From sp_lstars Where gameno=$gameno and userno=$userno and lstarno=$lstar and seqno=$slot";
    $result = $mysqli -> query($query);
    if ($result -> num_rows > 0) {
        $row = $result -> fetch_row();
        $result -> close();
    } else {
        $row[0] = '0';
    }
    ?><select class="slotVal" id='LS_<?php echo $lstar.'_'.$slot; ?>' name='LS_<?php echo $lstar.'_'.$slot; ?>' class="input-large" data-start="<?php echo $PLACES[$row[0]]; ?>">
    <?php foreach($PLACES as $n=>$d) { echo "<option".(($row[0]==$n)?' selected':'').">$d</option>"; } ?>
    </select><?php
    return $row[0];
}
?>