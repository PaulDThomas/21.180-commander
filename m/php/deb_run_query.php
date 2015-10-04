<?php

// Code to run and print a query, use for debugging
// $Id: deb_run_query.php 115 2012-09-17 21:16:26Z paul $

function deb_run_query($query,$echo='N',$csv='N') {
    global $mysqli;

    if ($echo=='Y') {echo "<div><div class='collHead'><i class='icon-minus-sign'></i> Query</div><div class='collDetail'><PRE>\r\n$query\r\n</PRE><br/>";}

    if ($mysqli->multi_query($query)) {
        do {
            // store first or next result set
            if ($result = $mysqli->store_result()) {

                // Print header
                echo '<TABLE class="table table-bordered table-condensed" width="100%"><THEAD><TR>';
                while ($finfo = $result -> fetch_field()) {
                    printf ("<TH>%s</TH>",$finfo -> name);
                }
                echo "</TR></THEAD><TBODY>";

                // Print body
                if ($csv=='Y') echo "<TD COLSPAN='$numcols'>";
                while ($row = $result->fetch_row()) {
                    if ($csv!='Y') echo "<TR>";
                    for ($j = 0; $j < $result -> field_count; $j++) {
                        if ($csv=='Y') printf("%s,",htmlspecialchars($row[$j]));
                        else { ?><td><?php echo utl_xml_table($row[$j]); ?></TD><?php }
                    }
                    if ($csv!='Y') echo "</TR>";
                    if ($csv=='Y') echo "<br/>";
                    }

                $result->free();
                echo "</TBODY></TABLE>";
            }

            // print divider
            if ($mysqli->more_results()) {
                 echo "<br/>";
                 $more = 1;
                 $mysqli -> next_result();
            } else $more = 0;
        } while ($more > 0);
    } else die("Bad query - try again <BR/> ".mysqli_error($mysqli));

    if ($echo=='Y') { echo "</div></div>"; }
}
?>
