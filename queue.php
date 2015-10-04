<?php

/*
** Description  : Available game queues and missing positions
**
** Script name  : queue2.php
** Author       : Paul Thomas
** Date         : 9th Feburary 2004
**
** $Id: queue.php 281 2015-04-20 05:14:50Z paul $
**
*/

// Start page
require_once("m/php/checklogin.php");

// Redirect if not ready
if ($username == '' or $username == 'FAIL') {
    header("Location:login.php");
}

// Get parameters
require_once("m/php/newq_x_params.php");

// End of header
?><!DOCTYPE html>
<html lang="en">
<head>
    <title>21.180 Game queues and Openings</title>
    <?php require_once("m/php/header_base.php"); ?>
    <script type="text/javascript" src="m/js/forum.js"></script>
    <script type="text/javascript" src="m/js/map.js"></script>
</head>
<body>
<div class="container">

    <?php require_once("m/php/navbar.php"); ?>
    <ul class="breadcrumb">
        <li><a href="index.php">Home</a></li>
        <span class="divider">/</span>
        <li>Queues</li>
    </ul><!-- Breadcrumbs -->

    <div class="page-header">
        <h1>Game queues and Openings</h1>
    </div>

    <div class="row">
    <div class="span8" id="ordersPanel">

    <h2>Queues</h2>
    <form id="queueForm" class="form-horizontal" method="post" action="queue_rdr.php">
    <input type="hidden" name="PROCESS" value="" id="PROCESS" />
    <table class="table table-bordered table-condensed table-nohover">
        <thead>
            <tr>
                <th>Players</th>
                <th>Deadline advances</th>
                <th>Number in queue</th>
                <th>Phase selection type</th>
                <th>Action</th>
                <th>&nbsp;</th>
            </tr>
        </thead>
        <tbody>
            <tr><!-- New queue -->
                <td>
                    <select name="players" id="players" class="input-mini">
                        <option>4</option><option>5</option><option selected>6</option><option>8</option><option>9</option>
                    </select>
                </td>
                <td>
                    <select name="advance_uts" id="advance_uts" class="input-small">
                        <option value='86400' selected>24 hours</option><option value='172800'>48 hours</option><option value='259200'>72 hours</option>
                    </select>
                </td>
                <td>&nbsp;</td>
                <td>
                    <select name="phase2_type" class="input-medium">
                        <option selected>Choose 3</option><option>Buy position</option><option>Choose 1</option><option>Choose 2</option>
                    </select>
                </td>
                <td><input type="button" class="btn btn-success btn-mini" value="Create" id="btnCreate"/></td>
                <td class="queueExpand" data-expand='newQueue'><i class="icon-plus-sign"></i>
            </tr>
            <tr><!-- New queue detail -->
                <td colspan='6'><div class="queueDetail" style="display:none" id='newQueue'>
                <table class="table table-condensed">
                    <tr><td class="span3">Description</td><td>
                        <input name="newq_description" class="input"/>
                    </td></tr>
<?php
// Read XML parameter file for available settings
foreach ($newq_xml->Parameter as $parameter) {?>
    <tr><td class="span3"><?php echo $parameter->Label; ?></td><td>
        <select name="<?php echo $parameter->Name;?>" class="input-<?php echo $parameter->Size; ?>">
            <?php foreach ($parameter->Options->Option as $option) {?>
                <option <?php echo isset($option->Default)?"Selected":""; ?> value="<?php echo $option->Value;?>"><?php echo isset($option->Label)?$option->Label:$option->Value; ?></option>
                <?php } ?>
            </select>
        </td></tr>
<?php } ?>

                </table>
            </div></td></tr>
<?php
// Get existing queue parameters
$query = "
Select n.players
       ,sf_format_hms(n.advance_uts) as advance
       ,in_queue
       ,phase2_type
       ,Case When in_queue=n.players Then 'Full' When status='' Then 'Join' Else status End As status
       ,n.advance_uts
       ,newq_description";
foreach ($newq_xml->Parameter As $parameter) $query .= ",".$parameter->Name;
$query .= "
From (Select Max(Case When userno=$userno Then 'In queue' Else '' End) as status, players, advance_uts, count(*) as in_queue From sp_newq Group By players, advance_uts) n
       ,sp_newq_params np
Where n.players=np.players
 and n.advance_uts=np.advance_uts
";

// New Queue header
$result = $mysqli -> query($query) or die($mysqli -> error . " For query : $query");
$qn = 0; while ($row = $result -> fetch_assoc()) { $qn++ ?>
    <tr>
        <td class="pV"><?php echo $row['players']; ?></td>
        <td class="aV" data-advance="<?php echo $row['advance_uts']; ?>"><?php echo $row['advance']; ?></td>
        <td><?php echo $row['in_queue']; ?></td>
        <td><?php echo $row['phase2_type']; ?></td>
        <td><input class="joinButton btn btn-mini btn-primary" type="button" name="join" value="<?php echo $row['status']; ?>" data-players="<?php echo $row['players']; ?>" data-advance="<?php echo $row['advance_uts']; ?>" /></td>
        <td class="queueExpand" data-expand="queueDetail<?php echo $qn; ?>"><i class="icon-plus-sign"></i></td>
    </tr>
    <?php if ($row['newq_description'] != '') {?><tr>
        <td colspan='6' style='padding-top:2px;padding-bottom:2px'><em><?php echo $row['newq_description']; ?></em></td>
    </tr><?php } ?>

    <?php // New queue detail ?>
    <tr><td colspan='6' style='padding-top:0px;padding-bottom:12px'><div id="queueDetail<?php echo $qn; ?>" style="display:none">
        <table class="table table-condensed">
            <?php foreach ($newq_xml->Parameter As $parameter) { ?>
                <tr>
                    <td width="40%"><?php echo $parameter->Label; ?></td>
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
    </div></td></tr>

<?php }
$result -> close();
        ?>
    </tbody>
    </table>
    </form>

    <h2>Openings</h2>
    <ul class="commanderList"><?php
// Get open positions
$query2 = "
Select g.gameno, r.powername, g.turnno, g.phaseno, g.deadline_uts, g.mapHash, r.powername
From sp_resource r
Left Join sv_map_hash g On r.gameno=g.gameno
Left Join sp_resource r2 On r2.userno=$userno and r2.gameno=g.gameno
Where g.phaseno < 9
 and r2.userno is null
 and r.dead != 'Y'
 and g.worldcup = 0
 and (   (r.mia >= 3
          and g.turnno <= 3)
      or (unix_timestamp()-deadline_uts >= 86400*14)
      )
Order By g.gameno, r.powername
";

$result = $mysqli -> query($query2) or die($mysqli->error);

if ($result->num_rows > 0) while ($row=$result->fetch_assoc()) { ?>
    <li>
        <div class="commanderThumb">
            <a class="revolutionLink" data-power="<?php echo $row['powername']; ?>" data-game="<?php echo $row['gameno']; ?>">
                <img class="commanderMapThumb supremMap" id="mapImage<?php echo $row['gameno'].$row['powername']; ?>" data-width="210" data-gameno="<?php echo $row['gameno']; ?>" data-mapHash="<?php echo "S".$row['gameno']."T".$row['turnno']."P".$row['phaseno'].'H'.$row['mapHash']; ?>" src='m/themes/img/ajax-loader.gif'/>
            </a>
        </div>
        <div class="newsText">
            <h3>Game <?php echo $row['gameno'].' - '.$row['powername']; ?> <small>Turn <?php echo $row['turnno']; ?>, Phase <?php echo $row['phaseno']; ?></small></h3>
            <p><?php
                $result2 = $mysqli -> query("Select Distinct powername From sp_orders o Left Join sp_resource r On o.userno=r.userno and r.gameno=o.gameno Where o.gameno=".$row['gameno']." and (o.order_code like 'Waiting%' or o.order_code like 'Extra%');");
                if ($result2->num_rows > 0) {
                    echo "Waiting for ";
                    while ($row2=$result2->fetch_row()) {
                        echo " ".$row2[0];
                    }
                }
                $result2 -> close();
            ?></p>
            <p <?php if (isset($row['deadline_uts'])?($row['deadline_uts'] < time()):0) echo "style='font-style:italic'"; ?>>
                <?php if (isset($row['deadline_uts'])) echo "Deadline: ".gmdate($_SESSION['dt_format'], $row['deadline_uts'] - $_SESSION['offset']*60); ?>
            </p>
        </div>
    </li>
<?php } else {?>
    <li>
        No game openings
    </li>
<?php }
$result -> close(); ?>
    </div><!-- Left panel -->

    <div class="span4" id="rightPanel">
        <?php require("m/php/forum_panel.php"); ?>
    </div><!-- Right panel -->

    </div><!-- Row -->

    <?php require_once("m/php/footer_base.php"); ?>

</div><!-- Container -->

<div class="modal fade hide" id="revolutionModal">
    <div class="modal-header">
        <button class="close" data-dismiss="modal">&times;</button>
        <h3><div id="revolutionTitle">Revolution</div></h3>
    </div>
    <div class="modal-body">
        <div id="revolutionBody">View game or take over?</div>
    </div>
    <div class="modal-footer">
        <a href="#" class="btn btn-primary" id="revolutionView">View</a>
        <a href="#" class="btn btn-success" id="revolutionTake">Revolution</a>
        <a href="#" class="btn btn-warning" id="revolutionClose" data-dismiss="modal">Close</a>
    </div>
</div><!-- Territory modal -->

<script type="text/javascript"><!--
function onError(data, status) {
    // handle an error
}

$(document).ready(function() {
    // Set up expanding sections
    $('.queueExpand').click(function() {
        $("#"+$(this).attr("data-expand")).slideToggle( function() {
//            $(this).find('i').toggleClass('icon-plus-sign icon-minus-sign');
        });
    });

    // Set up Join buttons
    $('.joinButton').click(function() {
        $('#players').val( $(this).attr('data-players') );
        $('#advance_uts').val( $(this).attr('data-advance') );
        $('#PROCESS').val( $(this).val() );
        $('#queueForm').submit();
    });

    // Set up Create button
    $('#btnCreate').click(function() {
        $('#PROCESS').val( $(this).val() );
        $('#queueForm').submit();
    });

    // Deal with player number changes
    function chkCreate() {
        $('#btnCreate').removeAttr('disabled');
        var pV = $(document).find('table .pV');
        pV.each(function() {
            if ( $('#players').val()==$(this).text() && $('#advance_uts').val()==$(this).parent().find('.aV').attr('data-advance') ) $('#btnCreate').attr("disabled","disabled");
        });
    };
    $('#players').change(function(){chkCreate()});
    $('#advance_uts').change(function(){chkCreate()});
    chkCreate();

    // Function for clicking on a map
    $(".revolutionLink").click(function(e) {
        // Update modal information
        $('#revolutionTitle').text( "Take over "+$(this).attr('data-power') );
        // Update buttons
        $('#revolutionView').attr('href','guest.php?gameselect='+$(this).attr('data-game'));
        $('#revolutionTake').attr('href','queue_rdr.php?gamerevolution='+$(this).attr('data-game')+"&powername="+$(this).attr('data-power'));
        // Show modal
        $('#revolutionModal').modal('show');
    });

    // Load forum messages
    forumInit();
    mapLoad();
});

-->
</script>
</body>
</html>
<?php

// Close page
$mysqli -> close();
?>
