<?php

/*
** Description  : Administer Boomers
**
** Script name  : boomer_admin.php
** Author       : Paul Thomas
** Date         : 5th March 2014
**
** $Id: boomer_admin.php 274 2015-02-03 08:56:38Z paul $
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
    <script type="text/javascript" src="m/js/boomer.js"></script>
</head>

<body>
<div class="container">

    <?php require_once("m/php/navbar.php"); ?>

    <ul class="breadcrumb">
        <li><a href="index.php">Home</a></li>
        <span class="divider">/</span>
        <li><a href="game.php">Game <?php echo "$gameno - $powername"; ?></a></li>
        <span class="divider">/</span>
        <li>Boomer status</li>
    </ul><!-- Breadcrumbs -->

    <div class="row" style="padding-top:10px">
        <div class="span8" id="ordersPanel">
            <?php require_once("m/php/boomer_panel.php"); ?>
        </div><!-- Send orders panel -->

        <div class="span4" id="rightPanel">
            <?php require_once("m/php/message_panel.php"); ?>
        </div><!-- Messages -->

    </div>

    <?php require_once("m/php/footer_base.php"); ?>
</div><!-- Container -->

<script type="text/javascript"><!--
function onError(data, status) {
    // handle an error
    <?php
if ($USER['admin']=='Y') {
    echo 'alert("ERROR, see console");';
    echo 'console.log(data);';
    echo 'console.log(status);';
} ?>
}

$(document).ready(function() {
    messageInit();
    boomerInit();
});
-->
</script>
</body>
</html>
<?php $mysqli -> close(); ?>
