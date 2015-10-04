<?php
/*
** Description  : Index page
**
** Script name  : index.php
** Author       : Paul Thomas
** Date         : 21st December 2003
**
** $Id: index.php 274 2015-02-03 08:56:38Z paul $
**
*/

// Set up page
require_once("m/php/checklogin.php");

// Redirect if not ready
if ((isset($username)?$username:'') == '' or (isset($username)?$username:'') == 'FAIL') {
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
    <title>21.180 Main Page</title>
    <?php require_once("m/php/header_base.php"); ?>
    <script type="text/javascript" src="m/js/forum.js"></script>
    <script type="text/javascript" src="m/js/news.js"></script>
    <script type="text/javascript" src="m/js/map.js"></script>
    <script type="text/javascript" src="m/js/clean_storage.php"></script>
</head>
<body>
<div class="container">
    <?php require_once("m/php/navbar.php"); ?>
    <ul class="breadcrumb">
        <li><a href="index.php">Home</a></li>
    </ul><!-- Breadcrumbs -->

    <div class="page-header">
        <h1>Welcome <?php echo $_SESSION['sp_username']; ?><small> to 21.180 Commander</small></h1>
    </div>

    <div class="row">
        <div class="span8" id="ordersPanel">
            <h2>Games...</h2>
            <div style="float:right">
                <label class="checkbox"><input id="all-games" type="checkbox"/>Show inactive games</label>
            </div>
            <ul id="gamesList" class="commanderList"></ul>
            <h2>News...</h2>
            <?php if ($USER['admin'] == 'Y') {?>
                <form id="newsForm" class="form-inline">
                    <div class="controls" align="center">
                        <input type='text' id="newsMessage" name="newsMessage" class="input-large" value=''/>
                        <input id="newsPost" type='button' name='newsPost' value='Post' class="btn"/>
                    </div>
                </form>
            <?php } ?>
            <ul class="pager">
                <li class="previous"><a href="#" id="newsOlder">&larr; Older</a></li>
                <li class="next"><a href="#" id="newsNewer">Newer &rarr;</a></li>
            </ul>
            <ul id="newsList" class="commanderList"></ul>
        </div><!-- Left hand slide -->

        <div class="span4" id="rightPanel">
            <?php require_once("m/php/forum_panel.php"); ?>
        </div><!-- Right hand slide -->
    </div><!-- Row -->

    <?php require_once("m/php/footer_base.php"); ?>

</div><!-- Container -->
<script type="text/javascript"><!--
function loadGames() {
    // Get current Games list
    $.ajax({
        type: "POST",
        url: "m/ajax/game_list.php",
        cache: false,
        success: function(data,Status) {
            $("#gamesList").empty().append(data);
            // Trigger initial map load
            mapLoad();
        },
        error: onError
    });

    $('#all-games').change(function() {
        if ($(this).is(':checked')) $('.game-over').slideDown();
        else $('.game-over').slideUp();
    });
    return false;
}

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
    // Set up offset
    $.ajax({
        type: "POST"
        ,url: "m/ajax/session_offset.php"
        ,cache: false
        ,data: "offset="+(new Date().getTimezoneOffset())
        ,success: function(data, Status) {}
    });

    // Set up page
    newsInit();
    forumInit();
    loadGames();

});
-->
</script>
</body>
</html>
<?php

// Close page
$mysqli -> close();
session_write_close();

?>
