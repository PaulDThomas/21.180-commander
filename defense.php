<?php
/**
**
** Description  : Update territory defense status page
**
** Script name  : defense.php
** Author       : Paul Thomas
** Date         : 10th December 2003
**
** $Id: defense.php 274 2015-02-03 08:56:38Z paul $
**
*/

// Start page
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
} else if ($RESOURCE['dead']!='N') {
    header("Location:game.php");
    $mysqli -> close();
    exit;
}

// Reset message number
$_SESSION['sp_messageno'] = '0';

// Set MIA to zero, print the rest of the page
?><!DOCTYPE html>
<html lang="en">
<head>
    <title>Game <?php echo $gameno." - ".$powername; ?></title>
    <?php require("m/php/header_base.php"); ?>
    <script type="text/javascript" src="m/js/defense.js"></script>
    <script type="text/javascript" src="m/js/territory.js"></script>
</head>

<body>
<div class="container">

    <?php require_once("m/php/navbar.php"); ?>

    <ul class="breadcrumb">
        <li><a href="index.php">Home</a></li>
        <span class="divider">/</span>
        <li><a href="game.php">Game <?php echo "$gameno - $powername"; ?></a></li>
        <span class="divider">/</span>
        <li>Territory Defense</li>
    </ul><!-- Breadcrumbs -->

    <div class="row" style="padding-top:10px">
        <div class="span12">
            <?php require_once("m/php/defense_panel.php"); ?>
        </div><!-- Main span -->

    </div>

    <?php require_once("m/php/footer_base.php"); ?>
</div><!-- Container -->

<script type="text/javascript"><!--
function onError(data, status) {
    // handle an error
    alert("ERROR:"+data);
}
$(document).ready(function() {
    defenseInit();
    terrInit();
});
-->
</script>
</body>
</html>
<?php $mysqli -> close(); ?>
