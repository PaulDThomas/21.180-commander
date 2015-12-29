<h2>Status<?php echo ($turnno!='')?" <small>Turn $turnno</small>":""; ?></h2>
<table class="table table-bordered table-condensed">
<?php

// Status table
// $Id: status_panel.php 237 2014-07-10 07:28:53Z paul $

$last_phase='';
$showall = false; // If you want to make it as option or by espionage level
$firstdone = false;
$powerlist = array();
$query = "
Select powername, phasedesc
       ,Case
         When substring(ordername,8,3) = 'RET' Then 'In queue - Retaliation'
         When substring(ordername,8,4) = 'REDE' Then 'In queue - Redeploy'
         When substring(ordername,8,4) = 'REAT' Then 'In queue - Redeploy'
         Else order_code
        End, mia
From sv_current_orders
Where gameno=$gameno and (ordername='ORDSTAT' or substring(ordername,1,3)='MA_')
       and substring(ordername,1,7) != 'MA_000_'
";

$result = $mysqli -> query($query) or die ($mysqli -> error);
if ($result -> num_rows > 0) {
	while ($row = $result -> fetch_row()) {
		$tabpowername = $row[0];	
		$phasedesc = $row[1];
		$order_code = $row[2];
		$mia = $row[3];
		if (($last_phase != '') && ($last_phase != $phasedesc)) {
			$firstdone = true;
		}
		if ((($last_phase != $phasedesc) && (!$firstdone)) || (($last_phase != $phasedesc) && ($showall))) {
			echo "<thead><tr><th colspan='2'>$phasedesc</th></tr></thead>";
			$last_phase=$phasedesc;		
		}
		if ($showall || !$firstdone) {
			echo "<tr><td>";
			if ($mia >= 3) {
				echo "<em>$tabpowername (MIA)</em>";
			} else if($powername == $tabpowername) {
				echo "<strong>$tabpowername</strong>";
			} else {
				echo $tabpowername;
			}       
			echo "</td><td>$order_code</td></tr>";    
		}
		if (($powername == $tabpowername) && ($order_code != "Passed") && ($firstdone)) {
			if (!in_array($phasedesc, $powerlist)) {
				$powerlist[] = $phasedesc;
			}
		}
	}
	$result -> close();
	if (!$showall && (count($powerlist) > 0)) {
		echo "<thead><tr><th colspan='2'>The Next Phases You Selected</th></tr></thead>";
		foreach ($powerlist AS $desc) {
			echo "<tr><td colspan='2'>$desc</td></tr>";
		}
	}
}
?>
</table>
