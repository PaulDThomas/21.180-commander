<?php
/*
** Description  : View of companies for all Superpowers
**
** Script name  : companies.php
** Author       : Paul Thomas
** Date         : 4th November 2003
**
** $Id: companies.php 274 2015-02-03 08:56:38Z paul $
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

// Set MIA to zero, print the rest of the page
?><!DOCTYPE html>
<html lang="en">
<head>
    <title>Game <?php echo $gameno." - ".$powername; ?></title>
    <?php require("m/php/header_base.php"); ?>
    <script type="text/javascript" src="m/js/companies.js"></script>
</head>

<body>
<div class="container">

    <?php require_once("m/php/navbar.php"); ?>

    <ul class="breadcrumb">
        <li><a href="index.php">Home</a></li>
        <span class="divider">/</span>
        <li><a href="game.php">Game <?php echo "$gameno - $powername"; ?></a></li>
        <span class="divider">/</span>
        <li>Companies</li>
    </ul><!-- Breadcrumbs -->

    <div class="row" style="padding-top:10px">
        <div class="span8" id="ordersPanel">
            <?php require_once("m/php/companies_panel.php"); ?>
        </div><!-- Main span -->

        <div class="span4" id="rightPanel">
            <?php require_once("m/php/company_summary_panel.php"); ?>
        </div><!-- Right span -->

    </div>

    <?php require_once("m/php/footer_base.php"); ?>
</div><!-- Container -->

<script type="text/javascript"><!--
function onError(data, status) {
    // handle an error
}
$(document).ready(function() {
    companiesInit();
});
-->
</script>
</body>
</html>
<?php $mysqli -> close(); ?>
