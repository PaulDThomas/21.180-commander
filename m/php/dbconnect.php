<?php
// $Id: dbconnect.php 242 2014-07-13 13:48:48Z paul $
// Start new database connection

$mysqli = new mysqli("localhost","db_name","db_password","db_schema");

/* check connection */
if (mysqli_connect_errno()) {
    printf("Connect failed: %s", mysqli_connect_error());
    exit();
}

$mysqli -> query("Set @debug='N'");
$mysqli -> query("SET character_set_client  = latin1; SET character_set_results = latin1; SET collation_connection  = latin1_swedish_ci;");

?>