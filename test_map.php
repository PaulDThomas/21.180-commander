<!DOCTYPE html>
<html lang="en">
<!-- $Id: test_map.php 274 2015-02-03 08:56:38Z paul $ -->
<head>
    <title>Test map loading</title>
    <?php require("m/php/header_base.php"); ?>
    <?php require("m/php/dbconnect.php"); ?>
</head>

<body>
<div class="container">

    <?php require_once("m/php/navbar.php"); ?>

    <ul class="breadcrumb">
        <li><a href="index.php">Home</a></li>
        <span class="divider">/</span>
        <li>Test map loading</li>
    </ul><!-- Breadcrumbs -->

<?php
$result = $mysqli->query("select * from sv_map_hash where gameno=192") or die("MYSQL error 1");;
$row = $result -> fetch_assoc() or die ("MYSQL error 2");
$result -> close();
?>
<img id="mapImage192" class="commanderMapThumb supremMap" data-maphash="<?php echo "S".$row['gameno']."T".$row['turnno']."P".$row['phaseno'].'H'.$row['mapHash']; ?>" data-gameno="192" data-width="210" src='m/themes/img/ajax-loader.gif'></img>

<div id='log'>Loaded page</div>

<?php
$result2 = $mysqli->query("select * from sv_map_hash where gameno=196") or die("MYSQL error 3");;
$row = $result2 -> fetch_assoc() or die ("MYSQL error 4");
$result2 -> close();
?>
<img id="mapImage196" class="commanderMapThumb supremMap" data-maphash="<?php echo "G".$row['gameno']."T".$row['turnno']."P".$row['phaseno'].'H'.$row['mapHash'];; ?>" data-gameno="196" data-width="1489" src='m/themes/img/ajax-loader.gif'></img>



<?php require_once("m/php/footer_base.php"); ?>
</div><!-- Container -->
<script><!--

function mapLoad() {
    $('#log').append("<br/>Loading maps...");
    $(".supremMap").each(function() {
        $('#log').append("<br/>Found map: "+$(this).attr("data-mapHash"));
        var e=$(this).attr("id")
            ,l="map_"+$(this).attr("data-mapHash")
            ,g=$(this).attr("data-gameno")
            ,x=$(this).attr("data-width")
            ;
        var mapStored = localStorage.getItem(l);
        var map = document.getElementById(e);
        $('#log').append("<br/>looking for map : "+l);

        if (!window.FileReader || !window.XMLHttpRequest) {
            $('#log').append("<br/>No FileReader, setting source: "+e);
            map.setAttribute("src","m/ajax/map.php?xgame="+g+"&xsize="+x);
        } else if (mapStored) {
            $('#log').append("<br/>Map retrieved: " + l);
            map.setAttribute("src",mapStored);
            $('#log').append("<br/>Map placed: " + e);
        } else {
            var xhr = new XMLHttpRequest()
                ,blob
                ,fileReader = new FileReader()
                ,url
                ;
            url = "m/ajax/map.php?xgame="+g+"&xsize="+x;
            $('#log').append("<br/>Getting map: " + url);
            xhr.open("GET", url, true);
            xhr.responseType = "arraybuffer";

            xhr.addEventListener("load", function () {
                $('#log').append("<br/>loading..."+xhr.status);
                if (xhr.status === 200) {
                    blob = new Blob([xhr.response], {type: "image/png"});
                    fileReader.onload = function (evt) {
                        $('#log').append("<br/>FileReader loading");
                        var result = evt.target.result;
                        map.setAttribute("src", result);
                        $('#log').append("<br/>Map set");
                        try {
                            localStorage.setItem(l,result);
                            $('#log').append("<br/>Stored");

                        } catch (e) {
                            $('#log').append("<br/>Storage fail: "+l);
                        }
                    }
                    // Load BLOB as URL
                    fileReader.readAsDataURL(blob);
                }
            },false);
            // Send XHR
            xhr.send();
        }
    });
};


function storageClean () {
    $('#log').append('<br/>Cleaning storage');
    var validMaps = ['dummy'];
    try {
        Object.keys(localStorage).forEach(function(key) {
            if ((key.substring(0,4) == 'map_') && ($.inArray(key,validMaps)==-1)) {
                $('#log').append('<br/>Removing item: ' + key + '**' + $.inArray(key,validMaps) + '**'+ ($.inArray(key,validMaps)==-1));
                localStorage.removeItem(key);
            } else {
                $('#log').append('<br/>Keeping item: ' + key + '**' + $.inArray(key,validMaps));
            }
        });
    } catch(e) {
        $('#log').append('<br/>No keys');
    }
}

if (!window.FileReader) {$('#log').append('<br/>No fileReader');}
if (!window.XMLHttpRequest) {$('#log').append('<br/>No XMLHttpRequest');}
storageClean();mapLoad();
--></script>
</BODY>
</HTML>

