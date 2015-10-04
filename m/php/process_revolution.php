<?php

// Code to process game revolution
// $Id: process_revolution.php 183 2014-01-13 20:44:15Z paul $

// See who is being changed
$gameno = $_GET['gamerevolution'];
$powername = $_GET['powername'];

// Update
$mysqli -> query("Call sr_revolution($gameno, '$powername', $userno)");

?>