<?php

// $Id: map.php 203 2014-03-23 07:55:38Z paul $

// Start page
ob_start();
require("../php/dbconnect.php");
ob_end_clean();
session_start();
ignore_user_abort(false);

// Get working parameters
$userno = isset($_SESSION['sp_userno'])?$userno=$_SESSION['sp_userno']:$userno = -5;
$gameno = isset($_GET['xgame'])?$_GET['xgame']:(isset($_SESSION['sp_gameno'])?$_SESSION['sp_gameno']:0);

// Create the image
$font = RealPath('../themes/img/verdanab.ttf');
$map = ImageCreateFromPNG('../themes/img/supremacy map.png');

// Find out what size map is required
$xsize = isset($_GET['xsize'])?$_GET['xsize']:ImagesX($map);
if ($xsize <= 200) { $ysize = $xsize; }
else $ysize = ImagesY($map)*$xsize/ImagesX($map);

// Set colours up
$white = ImageColorExact($map, 255, 255, 255);
$black = ImageColorExact($map, 0, 0, 0);
$blue = ImageColorExact($map, 0, 200, 235);
$minerals = ImageColorExact($map, 233,238,18);
$oil = ImageColorExact($map, 254, 0, 254);
$grain = ImageColorExact($map, 41, 215, 78);

if ($xsize > 200) {
    $result = $mysqli -> query("Select red, green, blue From sp_resource r Left Join sp_powers pw On r.powername=pw.powername Where userno=$userno");
    $row = $result -> fetch_assoc();
    $result -> close();
    $powerc = ImageColorExact($map,$row["red"],$row["green"],$row["blue"]);
}

// Decide how much information is needed for the map
if ($xsize > 200) {
    $query = "Select Distinct b.x,b.y,b.powername,b.terrtype,b.red,b.green,b.blue,b.terrno,b.userno,b.info,b.minor,b.major
                     ,Case When l.terrno is not null Then 'Prot' Else 'Vuln' End As colour,b.minerals,b.oil,b.grain
                 	 ,Coalesce(boomers,0) As boomers
              From   sv_map b
              Left Join sp_lstars l On l.terrno=b.terrno and l.userno=$userno and l.gameno=b.gameno
              Left Join (Select terrno, count(*) as boomers From sp_boomers Where gameno=$gameno and userno=$userno and visible!='Y' Group By 1) bm On bm.terrno=b.terrno
              Where b.gameno=$gameno
              Order By b.terrno";
} else {
    $query = "Select Distinct x, y, powername, terrtype, red, green, blue
              From    sv_map
              Where b.gameno=$gameno
              ";
}

// Run query
$result = $mysqli -> query ($query);

// Colour territories
if ($result->num_rows > 0) while ($row=$result->fetch_assoc()) {

    // Allocate fill colour for un-occupied territories
    if (in_array($row["powername"],array("Locals","Neutral","Warlords","Pirates"))) {
        if ($row["terrtype"] == "SEA") $bg = ImageColorExact($map,0,102,255);
        else if ($row["terrtype"] == "OCE") $bg = ImageColorExact($map,0,0,255);
        else $bg = ImageColorExact($map,153,153,153);
        }
    // Allocate fill colour for occupied territories
    else $bg = ImageColorExact($map,$row["red"],$row["green"],$row["blue"]);

    // Fill territory
    ImageFill($map,$row["x"],$row["y"],$bg);

    // Print only for Information Map points on large maps
    if ($xsize > 500 and isset($row["info"])?$row["info"]:0 == 1) {
        // Draw outer circle
        ImageFilledEllipse($map, $row["x"], $row["y"], 30, 24, $white);

        // Draw resources
        if ($row["minerals"] > 0) ImageFilledArc($map, $row["x"], $row["y"], 30, 24, 210-(12*$row["minerals"]), 210+(12*$row["minerals"]), $minerals, IMG_ARC_PIE);
        if ($row["oil"] > 0) ImageFilledArc($map, $row["x"], $row["y"], 30, 24, 330-(12*$row["oil"]), 330+(12*$row["oil"]), $oil,      IMG_ARC_PIE);
        if ($row["grain"] > 0) ImageFilledArc($map, $row["x"], $row["y"], 30, 24,  90-(12*$row["grain"]),  90+(12*$row["grain"]), $grain,    IMG_ARC_PIE);

        // Draw hidden boomer lines
        for ($i = 1; $i <= $row["boomers"]; $i++) {
            ImageEllipse($map, $row["x"], $row["y"], 25+($i*4), 19+($i*4), $powerc);
        }

        // Draw tank or visible boomer lines
        for ($i = 1; $i <= $row["major"]; $i++) {
            ImageEllipse($map, $row["x"], $row["y"], 25+(($row['boomers']+$i)*4), 19+(($row['boomers']+$i)*4), $black);
        }

        // Draw inner ellipse
        if ($row["colour"] == 'Vuln') ImageFilledEllipse($map, $row["x"], $row["y"], 19, 13, $white);
        else ImageFilledEllipse($map, $row["x"], $row["y"], 19, 13, $blue);

        // Draw minor units
        if ($row["minor"] > 9) $row["minor"]='*';
        ImageTTFText($map, 10, 0, $row["x"]-4, $row["y"]+5, $black, $font, $row["minor"]);
    }

} // Finish colouring in

// Add Game number
if ($xsize >= 500) {
    // Get turn and phase
    $result = $mysqli -> query("Select Distinct turnno, phaseno From sp_game Where gameno=$gameno");
    if ($result->num_rows > 0) {
        $row = $result -> fetch_assoc();
        $turnno = $row["turnno"];
        $phaseno = $row["phaseno"];
        ImageTTFText($map, 15, 0, 50, 75, $black, $font, "Game $gameno Turn $turnno Phase $phaseno");
        ImageTTFText($map, 20, 0, 50, 50, $black, $font, '21.180 Commander');
    }
}

// Create the output the right size
$mapout = ImageCreateTrueColor($xsize, $ysize);
ImageCopyResampled($mapout, $map, 0, 0, 0, 0, $xsize, $ysize, 1489, 1060);

// Send the image
Header("content-type: image/png");
ImagePNG($mapout);

// Close page
$result -> close();
$mysqli -> close();
ImageDestroy($mapout);
ImageDestroy($map);

?>
