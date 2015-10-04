<?php

// Forum list feed
// $Id: forum_list.php 90 2012-06-13 07:54:30Z paul $

// Initialise
require("../php/checklogin.php");

// Set session forum pointer
if (!isset($_SESSION['forum_first'])) { $_SESSION['forum_first'] = 0; }
if (!isset($_SESSION['offset']) and isset($_COOKIE['offset'])) { $_SESSION['offset'] = $_COOKIE['offset']; }
if (!isset($_SESSION['dt_format']) and isset($_COOKIE['dt_format'])) { $_SESSION['dt_format'] = $_COOKIE['dt_format']; }

// Highest forum row
$result = $mysqli -> query ("Select Count(*) From sp_messages Where gameno=-99;") or die ($mysqli->error);
$row = $result -> fetch_row();
$_SESSION['forum_limit'] = $row[0];
$result -> close();

// Process forwards and backwards arrows
if (isset($_POST['forum_older'])) {
    $_SESSION['forum_first'] = min($_SESSION['forum_first']+10, floor($_SESSION['forum_limit']/10)*10);
} elseif (isset($_POST['forum_newer'])) {
    $_SESSION['forum_first'] = max($_SESSION['forum_first']-10, 0);
}

// Process posts
elseif (isset($_POST['forumMessage'])?strlen($_POST['forumMessage']):0 > 0 and isset($_SESSION['sp_userno'])) {
    $mysqli -> query ("Insert Into sp_messages (message, userno, gameno) Values ('".addslashes(strip_tags($_POST['forumMessage']))."', ".$_SESSION['sp_userno'].", -99);");
    $_SESSION['forum_first'] = 0;
}

// Run forum query for 10 entries
$result = $mysqli -> query("Select message_uts, message, username From sp_messages m Left Join sp_users u On m.userno=u.userno Where gameno=-99 Order By message_uts desc Limit ".$_SESSION['forum_first'].",10") or die ($mysqli->error);

if ($result->num_rows > 0) while ($row=$result->fetch_row()) {
?>
    <li>
        <div class="forumName"><?php echo $row[2]; ?></div>
        <div class="forumDate"><?php echo gmdate($_SESSION['dt_format'], $row[0] - $_SESSION['offset']*60); ?></div>
        <div class="forumText"><?php echo $row[1]; ?></div>
    </li>
<?php
}

// Close result
$result -> close();
// Close connection
$mysqli -> close();

?>
