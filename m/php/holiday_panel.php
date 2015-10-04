<?php
// Panel for holidays
// $Id: holiday_panel.php 237 2014-07-10 07:28:53Z paul $

$result = $mysqli -> query("Select g.gameno, powername, holiday, deadline_uts From sp_resource r Left Join sp_game g on r.gameno=g.gameno Where userno=$userno and dead='N' and phaseno < 9");
if (($result -> num_rows) > 0) { ?>
<form id="holidayForm" class="form-horizontal" method="post" action="holidays.php">

<div class="control-group">
    <label class="control-label" for="holidayDate">Return on</label>
    <div class="controls">
        <input type="text" id="holidayDate" name="holidayDate" value="" class="input-medium"/>
    </div>
</div>

<table class="table table-compressed table-bordered">
    <thead>
        <tr>
            <th width="10%">Game</th>
            <th width="30%">Current deadline</th>
            <th width="15%">Available holiday</th>
            <th width="15%">Take holiday</th>
            <th width="30%">New deadline</th>
        </tr>
    </thead>
    <tbody><?php
while ($row = $result -> fetch_row()) {
    $gameno = $row[0];
    $powername = $row[1];
    $holiday = $row[2];
    $deadline_uts = $row[3];
    $deadline = gmdate($USER['dt_format'],$deadline_uts-$_SESSION['offset']*60);
    ?>
    <tr>
        <td><?php echo $gameno; ?></td>
        <td><span class="cur_dl" data-dt="<?php echo $deadline_uts; ?>"><?php echo $deadline; ?></span></td>
        <td><span class="avl_dl"><?php echo $holiday; ?></span></td>
        <td><input class="input-mini days_dl" type="number" value="0" name="days_<?php echo $gameno; ?>"/></td>
        <td><span class="new_dl"><?php echo $deadline; ?></span></td>
    </tr>
<?php } ?></tbody>
</table>

<div class="control-group" align="center">
<input type="submit" id="takeHoliday" name="takeHoliday" value="Submit" class="btn btn-success btn-medium"/>
</div>

</form>
<script><!--
var dt_format = "<?php echo $_SESSION['dt_format']; ?>";

// Work out new deadlines
function calcDLs() {
    $('.days_dl').each(function() {
        var tr = $(this).parent().parent();
        var cur_dl = Math.max( parseInt(tr.find('.cur_dl').attr("data-dt")), new Date().getTime()/1000 );
        var max_hol = parseInt(tr.find('.avl_dl').text());
        var val = $(this).val();
        if (isNaN(val) | val == '' ) { val=0; }
        else if (val > max_hol) { val = max_hol;}
        else if (val < 0) { val = 0;}
        $(this).val(val);
        if (val > 0) {
            var new_dl = cur_dl + (val * 86400);
            tr.find('.new_dl').text( date(dt_format, new_dl) );
        } else if (val == 0) {
            tr.find('.new_dl').text( tr.find('.cur_dl').text() );
        }
    });
}

function holidayInit() {

    $('.days_dl').change(function(){calcDLs();});

    // Set up holiday button
    $("#holidayDate").datepicker({
        minDate:'0'
        , maxDate:'1m'
        , defaultDate:'0'
        , dateFormat:'d M yy'
        , onSelect: function(dateText, inst) {
            var epoch = $.datepicker.formatDate('@', $(this).datepicker('getDate'))/1000;
            $('.days_dl').each(function() {
                var tr = $(this).parent().parent();
                var cur_dl = tr.find('.cur_dl').attr("data-dt");
                $(this).val(Math.ceil( (epoch - cur_dl) / 86400));
            });
            calcDLs();
          }
    });
}
--></script>
<?php } else { ?>
<div align="center">No active games</div>

<script><!--
function holidayInit() {
    // Nothing to do
}
--></script>
<?php } ?>
