<?php
/*
** Description  : Resignation page
**
** Script name  : resign.php
** Author       : Paul Thomas
** Date         : 17th April 2004
**
** $Id: resign.php 274 2015-02-03 08:56:38Z paul $
**
*/

// Set up page and connect to the database
require_once("m/php/checklogin.php");

// Redirect if not ready
if ($username == '' or $username == 'FAIL') {
    header("Location:login.php");
    $mysqli -> close();
    exit;
} else if ($gameno == '') {
    header("Location:index.php");
    $mysqli -> close();
    exit;
} else if ($RESOURCE['dead']!='N') {
    header("Location:game.php");
    $mysqli -> close();
    exit;
}

?><!DOCTYPE html>
<html lang="en">
<head>
    <title>Game <?php echo $gameno." - ".$powername; ?></title>
    <?php require("m/php/header_base.php"); ?>
</head>

<body>
<div class="container">

    <?php require_once("m/php/navbar.php"); ?>

    <ul class="breadcrumb">
        <li><a href="index.php">Home</a></li>
        <span class="divider">/</span>
        <li><a href="game.php">Game <?php echo $gameno." - ".$powername; ?></a></li>
        <span class="divider">/</span>
        <li>Resign</li>
    </ul><!-- Breadcrumbs -->

<h1>Resign</h1>
<div align="center">
<p>
    Click below to resign.  This will re-direct you to the main menu.<br/>
    Logging back into this game at any time will re-activate you.<br/>
    You will not score any points from a game where you have resigned.<br/>
</p>
    <form action="game.php" method="post">
        <input type="hidden" name="Resign" value="yes" />
        <input type="hidden" name="randgen" value="<?php echo $RESOURCE['randgen']; ?>" />
        <input type="submit" value="Resign" id="resignBtn" name="PROCESS" Class="btn btn-danger"/>
    </form>
</div>
</div>
</body>
</html>
