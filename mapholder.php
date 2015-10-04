<?php
/*
** Description  : Holder page for Map
**
** Script name  : mapholder.php
** Author       : Paul Thomas
** Date         : 8th Janurary 2004
**
** $Id: mapholder.php 274 2015-02-03 08:56:38Z paul $
**
*/

// Set up page and connect to the database
require_once("m/php/checklogin.php");
require_once("m/php/utl_territory_form.php");

// Redirect if not ready
if ($username == '' or $username == 'FAIL') {
    header("Location:login.php");
    $mysqli -> close();
    exit;
} else if ($gameno == '0') {
    header("Location:index.php");
    $mysqli -> close();
    exit;
}

?><!DOCTYPE html>
<html lang="en">
<head>
    <title>Game <?php echo $gameno." - ".$powername; ?></title>
    <?php require("m/php/header_base.php"); ?>
    <script type="text/javascript" src="m/js/bootstrap-modal.js"></script>
    <script type="text/javascript" src="m/js/jquery.mousewheel.min.js"></script>
    <script type="text/javascript" src="m/js/map.js"></script>
    <script type="text/javascript" src="m/js/territory.js"></script>
    <script type="text/javascript" src="m/js/clean_storage.php"></script>
</head>

<body>
<div class="container">

    <?php require_once("m/php/navbar.php"); ?>

    <ul class="breadcrumb">
        <li><a href="index.php">Home</a></li>
        <span class="divider">/</span>
        <li><a href="game.php">Game <?php echo $gameno." - ".$powername; ?></a></li>
        <span class="divider">/</span>
        <li>Map</li>
    </ul><!-- Breadcrumbs -->

    <div id="refreshMapWarning" style='display:none' class="alert alert-info"><h4>Warning</h4>Changes to the map require a <a href='#' onclick='javascript:mapLoad()'>refresh</a></div>

    <div class="row">
        <div class="span12" id="ordersPanel">
            <?php require_once ("m/php/map_panel.php"); ?>
        </div>
    </div><!-- Row -->
    <div class="row">
        <div class="span12" id="ordersPanel">
            <button id='mapRefresh' class='btn btn-small'>Refresh map</button>
        </div>
    </div><!-- Row -->

    <?php require_once("m/php/footer_base.php"); ?>

</div><!-- Container -->

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
<SCRIPT><!--

function onError(data, status) {
    // handle an error
    <?php
if ($USER['admin']=='Y') {
    echo 'alert("ERROR, see console");';
    echo 'console.log(data);';
    echo 'console.log(status);';
} ?>
}

$(document).ready(function () {
    mapInit();
    terrInit();
});
--></SCRIPT>
</body>
</html>
<?php $mysqli -> close(); ?>
