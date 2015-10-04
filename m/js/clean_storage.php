<?php
// Clean up any local storage Javascript Functions
// $Id: clean_storage.php 218 2014-04-13 14:23:58Z paul $
require_once("../php/checklogin.php");
Header("content-type: text/javascript");
?>
function storageClean (f) {
    <?php if ($USER['admin']=='Y') echo 'console.log("Cleaning storage");';?>
    var validMaps = ['dummy'<?php
// List all valid mapHash values
$result = $mysqli -> query("Select gameno, turnno, phaseno, mapHash From sv_map_hash") or die($mysqli->error);
if ($result -> num_rows > 0) {
    while ($row = $result -> fetch_assoc()) {
        echo ",'map_G".$row['gameno']."T".$row['turnno']."P".$row['phaseno'].'H'.$row['mapHash']."'";
        echo ",'map_S".$row['gameno']."T".$row['turnno']."P".$row['phaseno'].'H'.$row['mapHash']."'";
    }
}
$result -> close();
    ?>];
    try {
       Object.keys(localStorage).forEach(function(key) {
            if ((key.substring(0,4) == 'map_') && (f != '' || ($.inArray(key,validMaps)==-1))) {
                <?php if ($USER['admin']=='Y') echo 'console.log("Removing item: " + key + "**" + $.inArray(key,validMaps) + "**"+ ($.inArray(key,validMaps)==-1));'; ?>
                localStorage.removeItem(key);
            } else {
                <?php if ($USER['admin']=='Y') echo 'console.log("Keeping item: " + key + "**" + $.inArray(key,validMaps));'; ?>
            }
        });
    } catch(e) {
        <?php if ($USER['admin']=='Y') echo 'console.log("No keys");';?>
        localStorage.clear();
    }
}
if (window.localStorage) {storageClean();}
else {
    <?php if ($USER['admin']=='Y') echo 'console.log("No storage clean");';?>
}
