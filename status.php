<?php
/*
** Description  : Status page
**
** Script name  : status.php
** Author       : Paul Thomas
** Date         : 16th March 2004
**
** $Id: status.php 274 2015-02-03 08:56:38Z paul $
**
*/

// Start page
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
}

// Reset message number
$_SESSION['sp_messageno'] = '0';

?><!DOCTYPE html>
<html lang="en">
<head>
    <title>Game <?php echo $gameno." - ".$powername; ?></title>
    <?php require("m/php/header_base.php"); ?>
    <script type="text/javascript" src="m/js/message.js"></script>
</head>

<body>
<div class="container">

    <?php require_once("m/php/navbar.php"); ?>

    <ul class="breadcrumb">
        <li><a href="index.php">Home</a></li>
        <span class="divider">/</span>
        <li><a href="game.php">Game <?php echo $gameno." - ".$powername; ?></a></li>
        <span class="divider">/</span>
        <li>Status</li>
    </ul><!-- Breadcrumbs -->

    <div class="row" style="padding-top:10px">
        <div class="span4" id="leftPanel">
            <?php require_once("m/php/status_panel.php"); ?>
        </div><!-- Status span -->

        <div class="span4" id="centrePanel">
            <?php require_once("m/php/parameters_panel.php"); ?>
        </div><!-- Parameters span -->

        <div class="span4" id="rightPanel">
            <?php require_once("m/php/message_panel.php"); ?>
        </div><!-- Messages -->

    </div>

    <?php require_once("m/php/footer_base.php"); ?>
</div><!-- Container -->

<script type="text/javascript"><!--
function onError(data, status) {
    // handle an error
}
$(document).ready(function() {
    messageInit();
});
-->
</script>
</body>
</html>
<?php session_write_close(); ?>
