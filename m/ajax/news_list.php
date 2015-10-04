<?php

// $Id: news_list.php 78 2012-05-21 23:24:11Z paul $
// News list feed

// Connect to database
session_start();
ob_start();
require("../php/dbconnect.php");
ob_end_clean();

// Set session news pointer
if (!isset($_SESSION['news_first'])) { $_SESSION['news_first'] = 0; }
if (!isset($_SESSION['offset']) and isset($_COOKIE['offset'])) { $_SESSION['offset'] = $_COOKIE['offset']; }
if (!isset($_SESSION['dt_format']) and isset($_COOKIE['dt_format'])) { $_SESSION['dt_format'] = $_COOKIE['dt_format']; }
if (!isset($_SESSION['news_limit'])) {
    // Highest news row
    $result = $mysqli -> query ("Select Count(*) From sp_news;");
    $row = $result -> fetch_row();
    $_SESSION['news_limit'] = $row[0];
    $result -> close();
}

// Process posts
if (isset($_POST['newsMessage'])?strlen($_POST['newsMessage']):0 > 0) {
    $mysqli -> query ("Insert Into sp_news (news, news_uts) Values ('".strip_tags($_POST['newsMessage'])."', unix_timestamp());");
    $_SESSION['news_first'] = 0;
}

// Process forwards and backwards arrows
if (isset($_POST['news_older'])) {
    $_SESSION['news_first'] = min($_SESSION['news_first']+5, floor($_SESSION['news_limit']/5)*5);
} elseif (isset($_POST['news_newer'])) {
    $_SESSION['news_first'] = max($_SESSION['news_first']-5, 0);
}

// Run news query for 5 entries
$result = $mysqli -> query("Select news_uts, news From sp_news Order By news_uts desc Limit ".$_SESSION['news_first'].",5");

if ($result->num_rows > 0) while ($row=$result->fetch_row()) {
?>
    <LI>
        <div class="newsDate"><?php echo gmdate($_SESSION['dt_format'], $row[0] - $_SESSION['offset']*60); ?></div>
        <div class="newsText"><?php echo $row[1]; ?></div>
    </LI>
<?php
}

// Close result
$result -> close();
// Close connection
$mysqli -> close();
// Close session
session_write_close();

?>
