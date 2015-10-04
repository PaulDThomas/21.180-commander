<?php

// Process orders from phase 3
// $Id: process_phase3.php 101 2012-07-09 22:14:57Z paul $

// Process non-market zero sales
if ($_POST['Buyer']!='Market' and $_POST['Amount'] > 0 and $_POST['Price']=='0') {
    $_POST['Accepted']='Y';
}

// Continue transaction as normal
require_once("process_phase6.php");

?>