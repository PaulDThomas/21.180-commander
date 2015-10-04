<!-- $Id: currentstats.php 69 2012-03-19 05:47:53Z paul $ -->
<!-- Current user statistics -->
<table>
    <th><td><h3>Current Statistics:</h3></td></th>
    <?php

        // Connect to database
        require("dbconnect.php");

        $result1 = $mysqli -> query ("Select Count(Distinct t.userno), Count(Distinct t.gameno)
                                  From sp_board t, sp_resource r, sp_game g, sp_users u
                                  Where lower(username) not like binary '%test%' and t.userno > 0 and r.gameno > 0 and r.gameno=t.gameno
                                        and g.gameno=t.gameno and r.userno=u.userno and g.phaseno < 9;
                                  ");
        $result2 = $mysqli -> query ("Select Count(*) From sp_newq;");
        $result3 = $mysqli -> query ("Select Count(*)
                                      From sp_users
                                      Where username not like binary '%test%' and last_login_uts is not null
                                     ");
        $result4 = $mysqli -> query ("Select Count(Distinct r.userno) From sp_resource r, sp_game g Where worldcup!=0 and dead!='Y' and g.gameno=r.gameno");

        $row1 = $result1 -> fetch_row();
        $row2 = $result2 -> fetch_row();
        $row3 = $result3 -> fetch_row();
        $row4 = $result4 -> fetch_row();

    ?>
    <tr><td><?php  echo $row3[0] ?> people signed up</td></tr>
    <tr><td><?php  echo $row1[1] ?> active games</td></tr>
    <tr><td><?php  echo $row1[0] ?> active players</td></tr>
    <tr><td><?php  echo $row2[0] ?> players in the game queues</td></tr>
    <?php
    if ($row4[0] > 0) { echo "<tr><td>".$row4[0]." players left in the World Cup</td></tr>"; }
    $result1 -> close(); $result2 -> close(); $result3 -> close(); $result4 -> close();
    $mysqli -> close();
    ?>
</table>