<?php

// Guest view page
// $Id: guest.php 274 2015-02-03 08:56:38Z paul $

// Initialise
require_once("m/php/checklogin.php");

// Reset message list
$_SESSION['message_first'] = 0;
?><!DOCTYPE html>
<html lang="en">
<head>
    <title>Browse Games</title>
    <?php require_once("m/php/header_base.php"); ?>
    <script type="text/javascript" src="m/js/message.js"></script>
    <script type="text/javascript" src="m/js/bootstrap-modal.js"></script>
    <script type="text/javascript" src="m/js/jquery.mousewheel.min.js"></script>
    <script type="text/javascript" src="m/js/map.js"></script>
</head>
<body>
<div class="container">

    <?php require_once("m/php/navbar.php"); ?>
    <ul class="breadcrumb">
        <li><a href="index.php">Home</a></li>
        <span class="divider">/</span>
        <li><a href="guest.php">Browse Games</a></li>
        <?php if ($gameno > 0) { ?>
            <span class="divider">/</span>
            <li>Game <?php echo $gameno; ?></li>
        <?php } ?>
    </ul><!-- Breadcrumbs -->

    <div class="page-header">
        <h1>Browse Game
            <form class="form-inline" method="GET">
                <select class="input-medium" onChange='$(this).closest("form").submit();' name="gameselect">
                        <?php
            if ($gameno == 0) ?><option value='0'>Select</option><?php ;
            $result = $mysqli -> query("select gameno, phaseno from sp_game");
            while ($row = $result -> fetch_row()) {?><option<?php if ($row[0]==$gameno) echo " selected "; ?> value='<?php echo $row[0]; ?>'><?php echo $row[0]; if ($row[1]==9) echo " - Finished"; ?></option><?php }
            $result -> close();
            ?>
                </select>
            </form>
        </h1>
    </div>

    <div class="row">
        <div class="span12" id="ordersPanel">
            <?php require_once("m/php/map_panel.php"); ?>
        </div>
    </div>

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


</div><!-- Container -->

<script type="text/javascript"><!--
function onError(data, status) {
    // handle an error
}
$(document).ready(function() {
    messageInit();
    mapInit();
    $('area').attr('data-owned','guest');
    $('#terrOK').hide();
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
