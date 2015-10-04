<?php

// $Id: lstar_update.php 101 2012-07-09 22:14:57Z paul $
// L-Star update ajax

// Initialise
require("../php/checklogin.php");

// Stop if not ready
if ($username == '' or $username == 'FAIL' or $gameno == '0') exit;

// Set up XML element
$lstarXML = new SimpleXMLElement('<?xml version="1.0"?><LSTAR></LSTAR>');
$LSTAR = array();
$OWNER = array();

foreach ($_POST as $id=>$terrname) {
    // Get slot and lstar number
    $z = explode('_',$id);
    $lstar = $z[1];
    $slot = $z[2];
    // Set update query
    if ($terrname=='Blanket coverage') $query = "Update sp_lstars Set terrno = 0";
    else $query = "Update sp_lstars Set terrno = (Select terrno From sp_places Where terrname='$terrname')";
    $query .= " Where gameno=$gameno and userno=$userno and lstarno=$lstar and seqno=$slot";
    $result = $mysqli -> query($query) or die ($mysqli -> error);
    $LSTAR[$id] = "$terrname";
    // Get territory owner
    $result = $mysqli -> query("Select powername From sv_map Where gameno=$gameno and terrname='$terrname'");
    $row = $result -> fetch_row();
    $result -> close();
    $OWNER["O_${lstar}_$slot"] = $row[0];
}

// Send $LSTAR to XML
foreach ($LSTAR as $var => $val) $lstarXML -> addChild($var,$val);
foreach ($OWNER as $var => $val) $lstarXML -> addChild($var,$val);
echo $lstarXML->asXML();

// Close page
$mysqli -> close();

/*

$result = $mysqli -> query("Select powername, lstars, strategic_tech From sp_resource Where gameno=$gameno and userno=$userno");
if ($result -> num_rows > 0) {
    $row = $result -> fetch_row();
    $powername = $row[0];
    $lstar_slots = $row[1]*($row[2]+3);
    $result -> close();
}

$allocated = array_sum($_POST);

echo "$allocated / $lstar_slots L-Star slots submitted<br>";

// Fail on over-allocation
if ($allocated > $lstar_slots) {
    echo "L-Star slots over allocated, no changed made<br>";
} else {

    // Set first lstar and slot
    $lstarno = 1;
    $seqno = 1;
    $last_terr = '';

    // Allocate L-Stars in order
    echo "<p>";
    foreach ($_POST as $key => $val) {
        $terrno = substr($key,5);
        // Cycle through required slots
        for ($i = 1; $i <= $val; $i++) {
            // Check for existing slot
            $result = $mysqli -> query("Select * From sp_lstars Where gameno=$gameno and userno=$userno and lstarno=$lstarno and seqno=$seqno");
            $n = $result -> num_rows;
            $result -> close();

            if ($n == 0) {
                // Insert new value
                $mysqli -> query("Insert into sp_lstars (gameno, userno, lstarno, seqno, terrno) Values ($gameno ,$userno, $lstarno, $seqno, $terrno)");
            } else {
                // Update existing value
                $mysqli -> query("Update sp_lstars Set terrno=$terrno Where gameno=$gameno and userno=$userno and lstarno=$lstarno and seqno=$seqno;");
            }

            // Show territory name
            $terrres = $mysqli -> query("Select terrname From sp_places Where terrno=$terrno");
            $terrname = $terrres -> fetch_row();
            if ($terrname != $last_terr) {
                echo "${terrname[0]}<br>";
                $last_terr = $terrname;
                }
            $terrres -> close();

            // Move to next slot
            if ($seqno < $row[2]+3) {
                $seqno++;
            } else {
                $lstarno++;
                $seqno = 1;
            }
        }
    }
    echo "<p>";

    // Set remaining slots to zero
    while ($lstarno <= $row[1] and $seqno <= $row[2]+3) {
        // Check for existing slot
        $result = $mysqli -> query("Select * From sp_lstars Where gameno=$gameno and userno=$userno and lstarno=$lstarno and seqno=$seqno");
        $n = $result -> num_rows;
        $result -> close();

        if ($n == 0) {
            // Insert new value
            $mysqli -> query("Insert into sp_lstars (gameno, userno, lstarno, seqno, terrno) Values ($gameno ,$userno, $lstarno, $seqno, 0)");
        } else {
            // Update existing value
            $mysqli -> query("Update sp_lstars Set terrno=0 Where gameno=$gameno and userno=$userno and lstarno=$lstarno and seqno=$seqno;");
        }

        // Move to next slot
        if ($seqno < $row[2]+3) {
            $seqno++;
        } else {
            $lstarno++;
            $seqno = 1;
        }
    }

}
*/
?>