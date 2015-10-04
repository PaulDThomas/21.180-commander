<?php

// $Id: companies_list.php 237 2014-07-10 07:28:53Z paul $
// Mobile resource card feed

// Connect to database
session_start();
require("dbconnect.php");

// Set session
if (!isset($_SESSION['offset']) and isset($_COOKIE['offset'])) { $_SESSION['offset'] = $_COOKIE['offset']; }
if (!isset($_SESSION['dt_format']) and isset($_COOKIE['dt_format'])) { $_SESSION['dt_format'] = $_COOKIE['dt_format']; }

// Resolve log in details
$username = isset($_SESSION['sp_username']) ? $_SESSION['sp_username'] : '';
$userno = isset($_SESSION['sp_userno']) ? $_SESSION['sp_userno'] : '';

// Resolve game details
$gameno = isset($_SESSION['sp_gameno']) ? $_SESSION['sp_gameno'] : '';

// Check is siege and blockade are enabled
$result = $mysqli -> query("Select siege, blockade From sp_game Where gameno=$gameno");
$sb = $result -> fetch_row();
$result -> close();

// Check if under siege
$query1 = "
Select *
From sp_resource r1
Inner Join sp_powers pw1 On r1.powername=pw1.powername
Inner Join sp_board b1 On b1.gameno=r1.gameno and r1.userno=b1.userno
Inner Join sp_places pl1 On pl1.terrno=b1.terrno and pw1.terrtype=pl1.terrtype
Inner Join sp_border br1 On b1.terrno=br1.terrno_to
Inner Join sp_board b2 On b2.terrno=br1.terrno_from  and b2.gameno=r1.gameno
Inner Join sp_places pl2 On pl2.terrno=b2.terrno and length(pl2.terrtype)=3
Where r1.gameno=$gameno
 and r1.userno=$userno
 and (b2.userno in (0,b1.userno) or b1.userno=b2.passuser or b2.minor=0)
;";
$result = $mysqli -> query($query1);
if ($result->num_rows == 0 and $sb[0]=='Y') {?><I><B>Siege Status: Under siege</B></I><?php
elseif ($sb[0] == 'Y') {?><I>Siege Status: Trading normally</I><?php}
$result -> close();

// Set up companies query
$query = "
Select rc.res_type
       ,p1.terrname
       ,rc.res_amount
       ,Case When count(b2.terrno)>0 or p1.terrtype=p.terrtype Then 'Trading'
             Else 'Blockaded'
             End As status
       ,Case When c.running='Y' Then 'Active' Else 'Closed' End
From sp_board b
Inner Join sp_cards c On b.gameno=c.gameno
                         and b.userno=c.userno
Inner Join sp_res_cards rc On c.cardno=rc.cardno
                              and rc.terrno=b.terrno
Left Join sp_resource r On r.gameno=b.gameno
                           and r.userno=b.userno
Left Join sp_powers p On p.powername=r.powername
Left Join sp_places p1 On p1.terrno=b.terrno
Left Join sp_border bd On b.terrno=bd.terrno_from
Left Join sp_places p2 On p2.terrno=bd.terrno_to
Left Join sp_board b2 On p2.terrno=b2.terrno
                         and b.gameno=b2.gameno
                         and (b2.userno in (0,b.userno) or b.userno=b2.passuser or (char_length(p2.terrtype)=3 and b2.minor=0))
Where char_length(p2.terrtype)!=char_length(p1.terrtype)
        and b.gameno=$gameno
        and b.userno=$userno
Group By b.gameno
       ,b.userno
       ,r.powername
       ,b.terrno
       ,p1.terrname
       ,p.terrtype
       ,p1.terrtype
       ,c.cardno
       ,c.running
       ,rc.res_name
       ,rc.res_type
       ,rc.res_amount
Order by b.gameno
       ,Case When rc.res_type='Minerals' Then 1
             When rc.res_type='Oil' Then 2
             Else 3 End
       ,p1.terrname
       ,rc.res_amount desc
;";
$result = $mysqli -> query($query);

// Output to window
$last_resource = '';
$row_num = 0;
if ($result->num_rows > 0) while ($row=$result->fetch_row()) {
?>
    <?php
    $row_num++;
    if ($row[0] != $last_resource) {
        if ($last_resource != '') {?></div><?php}
        ?>
        <h3><?php echo $row[0]; $last_resource = $row[0]?></h3>
        <div class="ui-grid-c">
        <?php } ?>
            <div class="ui-block-a"><div class="ui-bar ui-bar-b"><?php echo $row[1]; ?></div></div>
            <div class="ui-block-b"><div class="ui-bar ui-bar-b"><?php echo $row[2]; ?></div></div>
            <div class="ui-block-c"><div class="ui-bar ui-bar-b"><?php echo $row[3].' - '.$row[4]; ?></div></div>
            <?php
    if ($row_num == $result -> num_rows) {?></div><?php }
} else {
?>No companies found<?php
}

// Close result
$result -> close();
// Close connection
$mysqli -> close();
// Close session
session_write_close();

?>
