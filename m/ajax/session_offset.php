<?php

// Copy offset from ajax call
 // $Id: session_offset.php 252 2014-08-24 21:18:23Z paul $

session_start();
 $_SESSION['offset'] = $_POST['offset'];
 require_once "../php/dbconnect.php";
 if (isset($_SESSION['sp_userno'])) {
     $mysqli -> query("update sp_users set timezone=${_POST['offset']} Where userno=${_SESSION['sp_userno']}") or die($mysqli -> error);
 }
 session_write_close();

?>
