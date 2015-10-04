<?php
/* $Id: banking.php 274 2015-02-03 08:56:38Z paul $ */

// Initialise
require_once("m/php/checklogin.php");

// Redirect if not ready
if ($username == '' or $username == 'FAIL') {
    header("Location:login.php");
    $mysqli -> close();
    exit;
} else if ($gameno == '0') {
    header("Location:index.php");
    $mysqli -> close();
    exit;
} else if ($RESOURCE['dead']!='N') {
    header("Location:game.php");
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
    <script type="text/javascript" src="m/js/message.js"></script>
    <script type="text/javascript" src="m/js/banking.js"></script>
</head>

<body>
<div class="container">

    <?php require_once("m/php/navbar.php"); ?>

    <ul class="breadcrumb">
        <li><a href="index.php">Home</a></li>
        <span class="divider">/</span>
        <li><a href="game.php">Game <?php echo $gameno." - ".$powername; ?></a></li>
        <span class="divider">/</span>
        <li>Banking</li>
    </ul><!-- Breadcrumbs -->

    <div class="row">
        <div class="span8" id="ordersPanel"><!-- Orders panel -->
            <?php require_once("m/php/transfer_panel.php"); ?>
            <br/>
            <?php require_once("m/php/loan_panel.php"); ?>
        </div><!-- Orders panel -->

    <div class="span4" id="rightPanel"><!-- Message panel -->
        <?php include("m/php/message_panel.php"); ?>
    </div>

    </div><!-- Main row -->
    <?php require_once("m/php/footer_base.php"); ?>

</div><!-- container -->

<div class="modal fade hide" id="resultModal">
    <div class="modal-header">
        <button class="close" data-dismiss="modal">&times;</button>
        <h3 id="resultTitle" class="resourceVal"></h3>
    </div>
    <div class="modal-body resourceVal" id="resultText"></div>
    <div class="modal-footer"><a href="#" class="btn btn-primary" data-dismiss="modal">Close</a></div>
</div><!-- Modal -->

<script><!--

function onError(data, status) {
    // handle an error
    alert("ERROR:" + data);
}

$(document).ready(function () {
    bankingInit();
    messageInit();
});
--></script>

</body>
</html>
<?php $mysqli -> close(); ?>
