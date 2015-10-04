<?php

// Debug query page - Admin only
// $Id: old_orders.php 274 2015-02-03 08:56:38Z paul $

// Initialise
require_once("m/php/checklogin.php");

// Redirect if not admin
if ($USER['admin'] != 'Y') {
    header("Location:index.php");
    $mysqli -> close();
    exit;
}

?><!DOCTYPE HTML>
<HTML lang="en">
<head>
    <title>Old Orders</title>
    <?php require_once("m/php/header_base.php"); ?>
    <link href="m/themes/humanity.css" rel="stylesheet">

    <script>
$(document).ready(function() {
    $("#start_date").datepicker({
        minDate:'-1m'
        , maxDate:'0'
        , defaultDate:'-1'
        , dateFormat:'d M yy'
        , onClose: function(dateText,inst) {
            if ($("#start_date").datepicker("getDate") >= $("#end_date").datepicker("getDate")) {
                $("#end_date").datepicker("setDate",$("#start_date").datepicker("getDate"));
            }
            //getOldOrders();
        }
    });
    $("#end_date").datepicker({
        minDate:'-1m+1'
        , maxDate:'+1'
        , defaultDate:'+1'
        , dateFormat:'d M yy'
        , onClose: function(dateText,inst) {
            if ($("#end_date").datepicker("getDate") <= $("#start_date").datepicker("getDate")) {
                $("#start_date").datepicker("setDate",$("#end_date").datepicker("getDate"));
            }
            //getOldOrders();
        }
    });
    //getOldOrders();

});

function onError(data, status) {
    // handle an error
}

function getOldOrders () {
    var formData="s="+$('#start_date').datepicker('getDate').getTime()
                +"&e="+$('#end_date').datepicker('getDate').getTime()
                +"&g="+$('#gameno option:selected').text()
                ;
    $.ajax({
        type: "POST",
        url: "m/ajax/old_orders_table.php",
        cache: false,
        data: formData,
        success: function(data,Status) {
            $("#date_results").empty().append(data);
            $('.collHead').click(function() {
                $(this).parent().find('.collDetail').slideToggle();
                $(this).find('i').toggleClass('icon-plus-sign icon-minus-sign');
                return false;
            });
        },
        error: onError
    });
    return false;
}

</script>
</head>

<body>
<div class="container">

    <?php require_once("m/php/navbar.php"); ?>
    <ul class="breadcrumb">
        <li><a href="index.php">Home</a></li>
        <span class="divider">/</span>
        <li>Old Orders</li>
    </ul><!-- Breadcrumbs -->

    <div class="page-header">
        <h1>Old Orders Table</h1>
    </div>

    <div class="container">
        <div class="row">
            <div class="span4">From</div>
            <div class="span8"><INPUT Type=text id="start_date" Value="Yesterday" Align=Top Class="input-medium"/></div>
        </div>
        <div class="row">
            <div class="span4">to</div>
            <div class="span8"><INPUT Type=text id="end_date" Value="Tomorrow" Align=Top Class="input-medium"/></div>
        </div>
        <div class="row">
            <div class="span4">Game</div>
            <div class="span8">
                <SELECT id="gameno" Value="All" Align=Top class="input-medium">
                    <option>All</option>
                    <?php
                        $result = $mysqli->query("Select gameno From sp_game Order By gameno");
                        if ($result->num_rows > 0) while ($row=$result->fetch_row()) {
                            echo "<OPTION>$row[0]</OPTION>";
                            }
                        $result -> close();
                        $mysqli -> close();
                    ?>
                </SELECT>
            </div>
        </div>
        <div class="controls" align="center" style="padding-bottom:10px">
            <input type="button" id="update" value="Update" class="btn btn-primary" onClick="javascript:getOldOrders()" />
        </div>
    </div>
    <DIV Id="date_results"></DIV>
    <?php require_once("m/php/footer_base.php"); ?>
</div><!-- Container -->
</body>
</html>
