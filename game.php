<?php

/*
** Description  : Main Game page
**
** Script name  : game.php
** Author       : Paul Thomas
** Date         : 16th December 2003
**
** $Id: game.php 274 2015-02-03 08:56:38Z paul $
**
*/

// Initialise
require_once("m/php/checklogin.php");

// Redirect if not ready
if ((isset($username)?$username:'') == '' or (isset($username)?$username:'') == 'FAIL') {
    header("Location:login.php");
    $mysqli -> close();
    exit;
} else if ($gameno == '0') {
    header("Location:index.php");
    $mysqli -> close();
    exit;
}

// Process orders if something is POSTed !!!!
if (isset($_POST['PROCESS'])) {
  require_once("m/php/process.php");
}

// Reset message number
$_SESSION['sp_messageno'] = '0';

?><!DOCTYPE html>
<html lang="en">
<head>
    <title>Game <?php echo $gameno." - ".$powername; ?></title>
    <?php require("m/php/header_base.php"); ?>
    <link href="m/themes/humanity.css" rel="stylesheet">
    <script type="text/javascript" src="m/js/message.js"></script>
    <?php if ($phaseno==0 or $phaseno==4 or $phaseno==5 or $phaseno==9) { ?>
        <script type="text/javascript" src="m/js/jquery.mousewheel.min.js"></script>
        <script type="text/javascript" src="m/js/map.js"></script>
        <script type="text/javascript" src="m/js/territory.js"></script>
        <script type="text/javascript" src="m/js/clean_storage.php"></script>
    <?php } else if ($phaseno==3 or $phaseno==6) { ?>
        <script type="text/javascript" src="m/js/resource.js"></script>
    <?php } ?>
</head>

<body>
<div class="container">

    <?php require_once("m/php/navbar.php"); ?>

    <ul class="breadcrumb">
        <li><a href="index.php">Home</a></li>
        <span class="divider">/</span>
        <li><a href="game.php">Game <?php echo $gameno." - ".$powername; ?></a></li>
        <span class="divider">/</span>
        <li>Orders</li>
    </ul><!-- Breadcrumbs -->

    <div class="row">
        <div class="span8" id="ordersPanel"><!-- Orders panel -->

<?php

// Get game information
$query2 = "Select order_code, phasedesc
           From sv_current_orders
           Where gameno=$gameno
            and turnno=$turnno
            and phaseno=$phaseno
            and userno=$userno
            and (ordername='ORDSTAT' or ordername='MA_000')
           Order By ordername
           Limit 1
           ;";
$result2 = $mysqli -> query("$query2");
$row2 = $result2 -> fetch_row();
$order_code = $row2[0];
$phasedesc = $row2[1];
$result2 -> close();

// Game finished - send messages
if ($phaseno == 9) { ?><div align="center"><strong>Game Over, chat...</strong></div><?php require_once("m/php/send_message_panel.php"); }

// Dead
else if ($RESOURCE['dead']!='N') { ?><div align="center"><strong>Game Over</strong></div><?php }

// In error
else if ($GAME['process']!='') { ?><div align="center"><strong>This is currently processing, or if this persists, is in a state of error.</strong></div><?php }

// Waiting
else if ($order_code == 'Passed' or $order_code == 'Orders processed' or substr($order_code, 0, 8) == 'In queue') {
    // Check for pending transaction
    if ($mysqli -> query("Select order_code
                          From sp_orders
                          Where gameno=$gameno
                           and phaseno in (3,6)
                           and ordername='SR_ORDERXML'
                           and (extractValue(order_code,'//Buyer')='$powername'
                                or extractValue(order_code,'//Seller')='$powername'
                                )") -> num_rows > 0) {
        $transaction = "Accept";
        $transaction_label = ($phaseno==3)?"Buy from":"Sell to";
        $transaction_var = ($phaseno==3)?"Seller":"Buyer";
        // Load panel
        echo "<script type='text/javascript' src='m/js/orders_transaction_accept.js'></script>";
        require_once("m/php/orders_transaction.php");
    } else { ?>
        <h1><?php echo $phasedesc; ?></h1>
        <div align="center" style="padding-top:20px">Waiting for other players orders</div>
        <div align="center" style="padding-top:20px">
            <?php
            if (substr($order_code, 0, 8) == 'In queue') { ?>
                <form method='post' id='passForm'>
                    <input type="hidden" name="randgen" value="<?php echo $RESOURCE['randgen']; ?>"/>
                    <input type="hidden" name="Prepass" value="Pass"/>
                    <input type="hidden" name="PROCESS" value="Prepass"/>
                    <input type="button" value="Withdraw from this phase" id="withdrawButton" class="btn btn-warning"/>
                </form>
            <?php }
            if ($GAME['deadline_uts'] < time()) { ?>
                <form method='post' id='forceForm'>
                    <input type="hidden" name="randgen" value="<?php echo $RESOURCE['randgen']; ?>"/>
                    <input type="hidden" name="Force" value="Force"/>
                    <input type="submit" value="Force Pass" name="PROCESS" class="btn btn-danger"/>
                </form>
            <?php } ?>
        </div><?php include("m/php/status_panel.php"); }
} else {
    // Orders required
    require_once("m/php/orders_phase${phaseno}.php");
    // Get appropriate script for phase (if it exists)
    require_once("m/js/orders_phase${phaseno}.js");
} ?></div><!-- Orders panel -->

    <div class="span4" id="rightPanel"><!-- Message panel -->
        <?php
        if ($phaseno == 3 or $phaseno == 6) {include("m/php/market_panel.php"); include("m/php/resource_panel.php");}
        if ($phaseno == 0 or $phaseno == 7) include ("m/php/company_summary_panel.php");
        if ($phaseno == 0 or $phaseno == 4 or $phaseno == 5 or $phaseno==9) {
            echo '<i class="icon-circle-arrow-left visible-desktop rightResize"></i>';
            include("m/php/map_panel.php");
            echo '<i class="icon-circle-arrow-left visible-desktop rightResize"></i>';
            }
            include("m/php/message_panel.php");
 ?>
    </div>

    </div><!-- Main row -->
    <?php require_once("m/php/footer_base.php"); ?>

</div><!-- container -->

<?php if ($phaseno==0 or $phaseno==4 or $phaseno==5 or $phaseno==9) { ?>
<div class="modal fade hide" id="terrModal">
    <div class="modal-header">
        <button class="close" data-dismiss="modal">&times;</button>
        <h3><div id="terrTitle"></div></h3>
    </div>
    <div class="modal-body">
        <div id="terrBody"></div>
    </div>
    <div class="modal-footer" id>
        <a href="#" class="btn btn-primary" id="terrOK">Update</a>
        <a href="#" class="btn btn-warning" id="terrClose" data-dismiss="modal">Close</a>
    </div>
</div><!-- Territory modal -->
<?php } ?>
<script><!--
function onError(data, status) {
    // handle an error
    <?php
if ($USER['admin']=='Y') {
    echo 'alert("ERROR, see console");';
    echo 'console.log(data);';
    echo 'console.log(status);';
} ?>
}

function numberDrop() {
    // Put wrappers around all available number inputs
    $('input[type="number"]:not([readonly])').each( function() {
        if ($(this).attr('min')!=undefined && $(this).attr('max')!=undefined) {
            $(this).wrap('<div class="input-append nDWrap dropdown"/>');
            $(this).parent().append('<a href="#" class="dropdown-toggle nDDrop" data-toggle="dropdown"><span class="add-on"><b class="caret"></b></span></a>');
        }
    });

    // Add a span into each nDWrap
    $('.nDDrop').click( function() {
        // Remove any existing dropdown menu
        $(this).find(".dropdown-menu").remove();
        // Built list of available values
        var inp = $(this).closest('.nDWrap').find('input[type="number"]');
        var min = parseFloat((inp.attr('min')!=undefined)?inp.attr('min'):0);
        var max = parseFloat((inp.attr('max')!=undefined)?inp.attr('max'):10);
        var step = parseFloat((inp.attr('step')!=undefined)?inp.attr('step'):1);
        var list = '<ul class="dropdown-menu">';
        for (i=min;i<=max;i=i+step) {
            list += '<li><a class="nDItem" href="#">'+i+'</a></li>';
        }
        list += '</ul>';
        $(this).append(list);
        // Change click behaviour for items
        $('.nDItem').click( function() {
            $(this).closest('.nDWrap').find('input[type="number"]').val( $(this).text() ).change();
        });
        // Call the dropdown
        $(this).dropdown();
    });

}

$(document).ready(function () {
    if ($.isFunction(window.ordersInit)) { ordersInit(); }
    if ($.isFunction(window.sndMessageInit)) { sndMessageInit(); }
    messageInit();

    <?php
    if ($phaseno == 0 or $phaseno == 4 or $phaseno == 5 or $phaseno == 9) echo "mapInit(); terrInit();";
    if ($phaseno == 3 or $phaseno == 6) echo "resourceInit();";
    if (isset($processMessage)) { ?>
        // Comfort message
        $('#comfortHead').text('Processing');
        $('#comfortText').text('<?php echo $processMessage; ?>')
        $('#comfort').modal('show');
    <?php } ?>

    // Set up expanders
    $('.rightResize').click(function() {
        if ($(this).hasClass('icon-circle-arrow-left')) {
            $('#ordersPanel').switchClass('span8','span4',1000);
            $('#rightPanel').switchClass('span4','span8',1000, mapHeight);
        } else {
            $('#rightPanel').switchClass('span8','span4',1000);
            $('#ordersPanel').switchClass('span4','span8',1000, mapHeight);
        }
        $('.rightResize').toggleClass('icon-circle-arrow-left icon-circle-arrow-right');
        if ($.isFunction(window.mapHeight())) { mapHeight(); }
    });

    // Set up withdraw button check
    $('#withdrawButton').click (function() {
        $('#comfortHead').text('Leave Phase');
        $('#comfortText').text('Do you want to leave this phase?');
        if ($('#comfort .modal-footer a').size() == 1) {
            $('#comfort .modal-footer a').text('No');
            $('#comfort .modal-footer').prepend('<a href="#" class="btn btn-warning" onclick="' + "{$('#passForm').submit();return false;}" + '" data-dismiss="modal">Yes</a>');
        }
        $('#comfort').modal('show');

    });

    numberDrop();
});
--></script>

</body>
</html>
<?php $mysqli -> close(); ?>
