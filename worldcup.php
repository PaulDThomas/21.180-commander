<?php
/*
** Description  :  World Cup signup page
**
** Script name  : worldcup.php
** Author       : Paul Thomas
** Date         : 1st February 2004
**
** $Id: worldcup.php 274 2015-02-03 08:56:38Z paul $
**
*/

// Set up page
require_once("m/php/checklogin.php");

// Redirect if not ready
if ($username == '' or $username == 'FAIL') {
    header("Location:login.php");
}

// Remove any existing game related session variables
unset($_SESSION['sp_gameno'],$_SESSION['sp_turnno'],$_SESSION['sp_phaseno'],$_SESSION['sp_powername']);

// Reset message numbers
$_SESSION['forum_first'] = '0';
$_SESSION['news_first'] = '0';
?><!DOCTYPE html>
<html lang="en">
<head>
    <title>21.180 World Cup Sign Up</title>
    <?php require_once("m/php/header_base.php"); ?>
    <script type="text/javascript" src="m/js/forum.js"></script>
</head>
<body>
<div class="container">
    <?php require_once("m/php/navbar.php"); ?>
    <ul class="breadcrumb">
        <li><a href="index.php">Home</a></li>
    </ul><!-- Breadcrumbs -->


    <div class="row">
        <div class="span8" id="ordersPanel">
            <?php require_once("m/php/worldcup_panel.php"); ?>
        </div><!-- Left hand slide -->

        <div class="span4" id="rightPanel">
            <?php require_once("m/php/forum_panel.php"); ?>
        </div><!-- Right hand slide -->
    </div><!-- Row -->

    <?php require_once("m/php/footer_base.php"); ?>

</div><!-- Container -->
<script type="text/javascript"><!--
function onError(data, status) {
    // handle an error
    alert("ERROR:" + data);
}

$(document).ready(function() {
    // Set up page
    forumInit();
});
-->
</script>
</body>
</html>
<?php

// Close page
$mysqli -> close();

?>