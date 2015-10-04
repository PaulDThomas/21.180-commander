<?php
// Code to process holiday form
// $Id: process_holidays.php 128 2013-01-26 07:01:08Z paul $

$holiday_message = "*";

foreach($_POST as $key => $hol_days) {

    // Check game has been passed
    if (substr($key,0,4)=="days") $hol_game = substr($key, 5);
    else continue;

$holiday_message .= $hol_game . '/' . $hol_days . '*';

    // Check get holiday
    $result = $mysqli -> query("Select holiday From sp_resource Where gameno=$hol_game and userno=$userno");
    if ($result -> num_rows == 0) continue;
    else $row = $result -> fetch_row();

    // Process if ok
    if ($hol_days > 0 and $hol_days <= $row[0]) {
        // Update game
        $mysqli -> query("Update sp_game Set deadline_uts = Greatest(unix_timestamp(), deadline_uts) + 86400*$hol_days Where gameno = $hol_game");
        // Update resource
        $mysqli -> query("Update sp_resource Set holiday = holiday - $hol_days Where gameno = $hol_game and userno=$userno");
        // Add message
        $mysqli -> query("Insert into sp_messages (gameno, userno, message) Values ($hol_game, 0, Concat($hol_days, Case When $hol_days>1 Then ' days' Else ' day' End, ' holiday taken by a Superpower.'))");
        // Add to log
        $mysqli -> query("Insert into sp_old_orders (gameno, userno, ordername, order_code) Select $hol_game, $userno, 'HOLIDAY', Concat('$hol_days taken by ',powername) From sp_resource Where gameno=$hol_game and userno=$userno");
    }
}
?>