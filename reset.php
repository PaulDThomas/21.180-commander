<?php

// Reset game page - Admin only
// $Id: reset.php 274 2015-02-03 08:56:38Z paul $

// Initialise
require_once("m/php/checklogin.php");

// Redirect if not admin
if ($USER['admin'] != 'Y') {
    header("Location:index.php");
}

?><!DOCTYPE html>
<html lang="en">
<head>
    <title>Game reset</title>
    <?php require_once("m/php/header_base.php"); ?>
    <script type="text/javascript" src="m/js/forum.js"></script>
    <script type="text/javascript" src="m/js/bootstrap-modal.js"></script>
</head>
<body>
<div class="container">

    <?php require_once("m/php/navbar.php"); ?>
    <ul class="breadcrumb">
        <li><a href="index.php">Home</a></li>
        <span class="divider">/</span>
        <li>Reset</li>
    </ul><!-- Breadcrumbs -->

    <div class="page-header">
        <h1>Reset Games</h1>
    </div>

    <div class="row">
        <div class="span6" id="leftPanel">
            <h2>In Error</h2>
            <ul id="errorList" class="commanderList">

<?php
// Get all games in error
$result = $mysqli -> query("Select gameno, deadline_uts, turnno, phaseno From sp_game Where process is not null");
if ($result->num_rows > 0) while ($row=$result->fetch_row()) {
    $gameno = $row[0];
    $deadline_uts = $row[1];
    $turnno = $row[2];
    $phaseno = $row[3];
?>   <li>
        <div class="commanderThumb">
            <a href='#' class="errorLink" data-gameno="<?php echo $gameno; ?>">
                <img class="commanderMapThumb" src="m/ajax/map.php?xsize=210&xgame=<?php echo $gameno; ?>"/>
            </a>
        </div>
        <div class="newsText">
            <h3>Game <?php echo $gameno; ?> <small>Turn <?php echo $turnno; ?>, Phase <?php echo $phaseno; ?></small></h3>
            <p><?php
                $result2 = $mysqli -> query("Select Distinct powername From sp_orders o Left Join sp_resource r On o.userno=r.userno and r.gameno=o.gameno Where o.gameno=".$row[0]." and (o.order_code like 'Waiting%' or o.order_code like 'Extra%');");
                if ($result2->num_rows > 0) {
                    echo "Waiting for ";
                    while ($row2=$result2->fetch_row()) {
                        echo " ".$row2[0];
                    }
                }
                $result2 -> close();
            ?></p>
            <p <?php if (isset($deadline_uts)?($deadline_uts < time()):0) echo "style='font-style:italic'"; ?>>
                <?php if (isset($deadline_uts)) echo "Deadline: ".gmdate($_SESSION['dt_format'], $deadline_uts - $_SESSION['offset']*60); ?>
            </p>
            <!-- Orders table -->
            <table class="table table-condensed">
                <thead><tr>
                    <th>Superpower</th>
                    <th>Order name</th>
                    <th>Order code</th>
                </tr></thead>
                <tbody><?php
                $result2 = $mysqli -> query("Select powername, ordername, order_code
                                             From sp_game g, sp_resource r, sp_orders o
                                             Where g.gameno=${row[0]}
                                              and g.gameno=r.gameno
                                              and r.userno=o.userno
                                              and o.gameno=g.gameno and o.phaseno=g.phaseno
                                              and o.turnno=g.turnno");
                if ($result2 -> num_rows > 0) while ($row2=$result2->fetch_row()) { ?>
                    <tr>
                        <td><?php echo $row2[0]; ?></td>
                        <td><?php echo $row2[1]; ?></td>
                        <td><?php echo $row2[2]; ?></td>
                    </tr>
                <?php } else { ?>
                    <tr><td colspan="3">No orders</td></tr>
                <?php }
                $result2 -> close();
                ?></tbody>
            </table>
        </div>
    </li>
<?php } ?>

            </ul>
        </div><!-- Left hand slide -->

        <div class="span6" id="rightPanel">
            <h2>Run cron job</h2>
            <pre><?php require_once("m/php/cron.php"); ?></pre>
        </div><!-- Right hand slide -->
    </div><!-- Row -->

    <?php require_once("m/php/footer_base.php"); ?>

</div><!-- Container -->

<div class="modal fade hide" id="reset">
    <div class="modal-header">
        <button class="close" data-dismiss="modal">&times;</button>
        <h3>Reset</h3>
    </div>
    <div class="modal-body">
        <div id="resetF">
            <p>Reset game <span id="resetGameno"></span>?</p>
        </div>
        <div id="resetP"></div>
    </div>
    <div class="modal-footer">
        <a href="#" class="btn btn-primary" id="resetOK">Reset</a>
        <a href="#" class="btn btn-warning" id="resetC" data-dismiss="modal">Cancel</a>
    </div>
</div><!-- Reset modal -->

<script type="text/javascript"><!--
function onError(data, status) {
    // handle an error
}

$(document).ready(function() {
    // Set up forum
    forumInit();

    // Set up reset button
    $("#resetOK").click(function(){
        $.ajax({
            type: "POST",
            url: "m/ajax/reset_game.php",
            cache: false,
            data: 'gameselect='+$('#resetGameno').text(),
            success: function(data,Status) {
                $("#resetF").empty();
                $("#resetP").empty().append(data);
                $("#resetOK").hide();
                $("#resetC").text('OK');
            },
            error: onError
        });
        return false;
    });

    // Refresh form on modal close
    $("#reset").on('hidden', function() {
        location.reload();
    });


    $(".errorLink").click(function() {
        $('#resetGameno').text($(this).attr("data-gameno"));
        $('#reset').modal('show');
    });

});
-->
</script>
</body>
</html>
<?php

// Close page
$mysqli -> close();
session_write_close();

?>
