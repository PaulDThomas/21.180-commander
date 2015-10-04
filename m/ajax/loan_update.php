<?php

// $Id: loan_update.php 71 2012-04-09 22:09:48Z paul $
// Loan update ajax

// Connect to database
session_start();
require("dbconnect.php");

// Get game and user information
$gameno = isset($_SESSION['sp_gameno']) ? $_SESSION['sp_gameno']:'';
$userno = isset($_SESSION['sp_userno']) ? $_SESSION['sp_userno']:'';
$result = $mysqli -> query("Select powername From sp_resource Where gameno=$gameno and userno=$userno");
if ($result -> num_rows > 0) {
    $row = $result -> fetch_row();
    $powername = $row[0];
    $result -> close();
}

// Check value has been posted
$loanAmount = isset($_POST['loanAmount'])?$_POST['loanAmount']:0;

$mysqli -> query("Call sr_change_loan($gameno, '$powername', $loanAmount)");
$result = $mysqli -> query("Select cash, loan From sp_resource Where gameno=$gameno and userno=$userno");
if ($result -> num_rows > 0) {
    $row = $result -> fetch_row();
}

// Close connection
$result -> close();
$mysqli -> close();

// Close session
session_write_close();

?>
<div id='newCash'><?php echo $row[0] ?></div>
<div id='newLoan'><?php echo $row[1] ?></div>
