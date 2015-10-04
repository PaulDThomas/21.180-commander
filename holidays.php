<?php

/*
** Description  : Holiday page, for multiple games at once
**
** Script name  : holidays.php
** Author       : Paul Thomas
** Date         : 29th May 2012
**
** $Id: holidays.php 274 2015-02-03 08:56:38Z paul $
**
*/
// Set up page
ignore_user_abort(true);

// Set up page
require_once("m/php/checklogin.php");

// Redirect if not ready
if ($username == '' or $username == 'FAIL') {
    header("Location:login.php");
    exit;
}

// Process hoilday if the form has been submitted
if (isset($_POST['takeHoliday'])) {require("m/php/process_holidays.php");}

// Reset forum number
$_SESSION['forum_first'] = '0';

?><!DOCTYPE html>
<html lang="en">
<head>
    <title>Holiday</title>
    <?php require("m/php/header_base.php"); ?>
    <script type="text/javascript" src="m/js/forum.js"></script>
    <script type="text/javascript" src="m/js/date.js"></script>
    <link href="m/themes/humanity.css" rel="stylesheet">
</head>

<body>
<div class="container">

<!-- <?php echo $holiday_message; ?> -->

    <?php require_once("m/php/navbar.php"); ?>
    <ul class="breadcrumb">
        <li><a href="index.php">Home</a></li>
        <span class="divider">/</span>
        <li>Holidays</li>
    </ul><!-- Breadcrumbs -->

    <div class="page-header">
        <h1>Take holiday</h1>
    </div>

    <div class="row" id="ordersPanel">
        <div class="span8"><!-- Holiday panel -->
            <?php require_once("m/php/holiday_panel.php"); ?>
        </div><!-- Holiday panel -->

        <div class="span4" id="rightPanel"><!-- Forum panel -->
            <?php require_once("m/php/forum_panel.php"); ?>
        </div>

    </div><!-- Main row -->
    <?php require_once("m/php/footer_base.php"); ?>

</div><!-- container -->

<script><!--

function onError(data, status) {
    // handle an error
}

$(document).ready(function () {
    holidayInit();
    forumInit();
});
--></script>

</body>
</html>
<?php $mysqli -> close(); ?>
