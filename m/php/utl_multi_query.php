<?php
// $Id: utl_multi_query.php 107 2012-08-23 00:06:26Z paul $

function utl_multi_query($query) {
    global $mysqli;
    $out = "<strong>Execute</strong>:$query<br>";
    if ($mysqli->multi_query($query)) {
        do {
            $out .= '<table class="table table-bordered table-condensed" width="auto">';

            // store first or next result set
            if ($result = $mysqli->store_result()) {

                // Print header
                $out .= '<thead><tr>';
                while ($finfo = $result -> fetch_field()) {
                    $out .= "<th>".$finfo -> name."</th>";
                }
                $out .= "</tr></thead><tbody>";

                // Print body
                while ($row = $result->fetch_row()) {
                    $out .= "<tr>";
                    for ($j = 0; $j < $result -> field_count; $j++) $out .= "<td>${row[$j]}</td>";
                    $out .= "</tr>";
                    }

                $result->free();
            }
            $out .= "</tbody></table>";

            // print divider
            if (!$mysqli->more_results()) {
              break;
            }
            if (!$mysqli->next_result()) {
              // report error
              $out .= "<br>".$mysqli->error;
              break;
            }
        } while (true);
    }
    return $out;
};

?>