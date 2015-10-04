<?php
/*
** Description  : Rankings
**
** Script name  : finished.php
** Author       : Paul Thomas
** Date         : 4th April 2006
**
** $Id: finished.php 274 2015-02-03 08:56:38Z paul $
**
*/

// Start page
require_once("m/php/checklogin.php");

// Load table script
require_once("m/php/deb_run_query.php");
require_once("m/php/utl_xml_table.php");

?><!DOCTYPE html>
<html lang="en">
<head>
    <title>21.180 Rankings</title>
    <?php require_once("m/php/header_base.php"); ?>
</head>
<body>
<div class="container">
    <?php require_once("m/php/navbar.php"); ?>
    <ul class="breadcrumb">
        <li><a href="index.php">Home</a></li>
        <span class="divider">/</span>
        <li>Rankings</li>
    </ul><!-- Breadcrumbs -->

    <div class="page-header">
        <h1>Player Rankings</h1>
    </div>

        <div class="row">
            <div class="span7" id="ordersPanel">
                <div id="ladder">
                    <h2>Ladder <small>Top players from the last 300 days</small></h2>
                    <?php
                        $query = "Select username as Username
                                   ,count(score) as Games
                                   ,avg(score) as Average
                                  From sp_score s
                                  Left Join sp_users u On s.userno=u.userno
                                  Left Join sp_game g On s.xgameno=g.gameno
                                  Where xgameno >= 0
                                   and finish_uts >= unix_timestamp()-86400*300
                                  Group By s.userno
                                  Having count(score) >= 3
                                  Order By 3 desc
                                  Limit 25
                                  ";
                        deb_run_query($query);
                    ?>
                </div>

                <?php if (isset($_SESSION['sp_userno'])) { ?>
                    <div id="yourResults">
                        <h2>Your Results</h2>
                        <?php
                            $query = "Select xgameno as Game
                                       ,players as Players
                                       ,powername as Superpower
                                       ,score as Score
                                       ,from_unixtime(finish_uts, '%D %M %Y') as Date
                                      From sp_score s
                                      Left Join sp_users u On s.userno=u.userno
                                      Left Join sp_game g On s.xgameno=g.gameno
                                      Where xgameno >= 0
                                       and  finish_uts >= unix_timestamp()-86400*300
                                       and  s.userno=$userno
                                      ";
                        deb_run_query($query);
                    ?>
                    </div>
                <?php } ?>
                <div id="winningPowers">
                    <h2>Results of all games so far</h2>
                    <?php
                        $query = "select powername as Superpower
                                   ,max(case when players=2 Then concat(victories,'/',n) Else null End) as Two
                                   ,max(case when players=4 Then concat(victories,'/',n) Else null End) as Four
                                   ,max(case when players=5 Then concat(victories,'/',n) Else null End) as Five
                                   ,max(case when players=6 Then concat(victories,'/',n) Else null End) as Six
                                   ,max(case when players=8 Then concat(victories,'/',n) Else null End) as Eight
                                   ,max(case when players=9 Then concat(victories,'/',n) Else null End) as Nine
                                  from (
                                        select players
                                               ,Case
                                                  When powername='North America' Then 'USA'
                                                  When powername='Russia' Then 'USSR'
                                                  Else powername
                                                 End as powername
                                               ,count(*) as n
                                               ,sum(score=players+4) as victories
                                        from sp_score
                                        where powername != 'Neutron'
                                        group by 1, 2
                                        ) core
                                  group by powername
                                  ";
                        deb_run_query($query);
                    ?>
                </div>
            </div>
            <div class="span5" id="rightPanel"><!-- Right hand pane -->
                <div id="recentResults">
                    <h2>Recent Results</h2>
                    Filter:
                    <select id="recSel">
                        <option>All</option>
                        <option>Winners</option>
                        <?php
                            $result = $mysqli -> query("Select distinct xgameno From sp_score Inner Join sp_game On gameno=xgameno Order by xgameno");
                            while ($row = $result -> fetch_row()) echo "<option>${row[0]}</option>";
                        ?>
                    </select>
                    <?php
                        $query = "Select xgameno as Game
                                   ,players as Players
                                   ,powername as Superpower
                                   ,username as Username
                                   ,score as Score
                                  From sp_score s
                                      ,sp_game g
                                      ,sp_users u
                                  Where u.userno=s.userno
                                      and gameno=xgameno
                                  Order By xgameno, score desc
                                  ";
                        deb_run_query($query);
                    ?>
                </div>
            </div><!-- Right hand pane -->
        </div><!-- Outer row -->

    <?php require_once("m/php/footer_base.php"); ?>

</div><!-- Container -->
    <script type="text/javascript"><!--
$(document).ready(function() {
    $('#recSel').change( function () {
        // Get rows in the right table
        var rows = $(this).parent().find('table tbody tr');
        // Cycle through each row

        rows.each(function() {
            //alert (4+parseInt($(this).find('td:nth-child(5)').text()));
            if ( $('#recSel').val() == $(this).find('td:first-child').text()
               | $('#recSel').val() == 'All' ) {
                $(this).show();
            } else if ($('#recSel').val() == 'Winners'
               && $(this).find('td:nth-child(2)').text() == parseInt($(this).find('td:nth-child(5)').text())-4 ) {
                $(this).show();
            } else {
                $(this).hide();
            }
        });
    });
});
    --></script>
</body>
</html>
<?php

// Close page
$mysqli -> close();
session_write_close();

?>
