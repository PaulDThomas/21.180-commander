<?php

// $Id: ma.php 274 2015-02-03 08:56:38Z paul $
// Move attack query

// Initialise
require_once("m/php/checklogin.php");

// Redirect if not ready
if ($username == '' or $username == 'FAIL') {
    header("Location:login.php");
    $mysqli -> close();
    exit;
} else if ($gameno == 0) {
    header("Location:index.php");
    $mysqli -> close();
    exit;
}

// Reset message number
$_SESSION['sp_messageno'] = '0';

?><!DOCTYPE html>
<html lang="en">
<head>
    <title>Game <?php echo $gameno." - ".$powername; ?></title>
    <?php require("m/php/header_base.php"); ?>
    <link href="m/themes/humanity.css" rel="stylesheet">
    <script type="text/javascript" src="m/js/jquery.mousewheel.min.js"></script>
    <script type="text/javascript" src="m/js/map.js"></script>
    <script type="text/javascript" src="m/js/territory.js"></script>
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

    <div><!-- Add in extra div to ensure footer works ok --><div class="row">
        <div class="span8" id="ordersPanel"><!-- Orders panel -->
            <?php
            if ($RESOURCE['dead']!='N') {
                // No screen if dead
                ?><div align="center"><strong>Game Over</strong></div><?php
            } else {
                // Show movements
                require_once("m/php/orders_phase4.php");
                require_once("m/js/orders_phase4.js");
            }  ?>
        </div><!-- Orders panel -->

    <div class="span4" id="rightPanel"><!-- Map panel -->
        <div>
            <i class="icon-circle-arrow-left visible-desktop rightResize"></i>
            <?php include("m/php/map_panel.php"); ?>
            <i class="icon-circle-arrow-left visible-desktop rightResize"></i>
        </div>
    </div>

    </div></div><!-- Main row -->
    <?php require_once("m/php/footer_base.php"); ?>

</div><!-- container -->

<script><!--

function onError(data, status) {
    // handle an error
}

function numberDrop() {
    // Put wrappers around all available number inputs
    $('input[type="number"]:not([readonly])').each( function() {
        if ($(this).attr('min')!=undefined && $(this).attr('max')!=undefined) {
            $(this).wrap('<div class="input-append nDWrap dropdown"/>');
            $(this).parent().append('<span class="add-on"><a href="#" class="dropdown-toggle nDDrop" data-toggle="dropdown"><b class="caret"></b></a></span>');
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
        // Change click behaviour or items
        $('.nDItem').click( function() {
            $(this).closest('.nDWrap').find('input[type="number"]').val( $(this).text() ).change();
       });
        // Call the dropdown
        $(this).dropdown();
    });

}

$(document).ready(function () {
    mapInit();

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
        mapHeight();
    });

    if ($.isFunction(window.ordersInit)) { ordersInit(); }
    $('#processOrders').hide();
    $('#Action').find('option[value="Warhead"]').remove();
    $('#Action').find('option[value="Satellite"]').remove();

    numberDrop();

});
--></script>

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

</body>
</html>
<?php $mysqli -> close(); ?>
