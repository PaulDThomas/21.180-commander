<?php

// Function to create (battle report/activity) table from XML input
// $Id: utl_xml_table.php 203 2014-03-23 07:55:38Z paul $

function utl_xml_table ($xmlstring,$id='',$footer='NO') {

libxml_use_internal_errors(true);
$xml = SimpleXML_Load_String($xmlstring);
if (!$xml) {
    if (stripos($xmlstring,'<table')===0) return $xmlstring;
    else if (stripos($xmlstring,'<strong')===0) {
        $return = "<DIV class='expander'><DIV class='collHead'><i class='icon-plus-sign'></i> ";
        $return .= substr($xmlstring,0,stripos($xmlstring,'<br>'));
        $return .= "</DIV><DIV class='collDetail' style='display:none'>";
        $return .= substr($xmlstring,stripos($xmlstring,'<br>'));
        $return .= "</DIV>";
        return $return;
    }
    else return htmlspecialchars($xmlstring);

//
// Battle report section
//
} else if ($xml->getName() == 'FIGHT') {
    $return = "<H6>Battle report for ".$xml->Terrname."</H6>";
    $return .= "<TABLE class='table table-condensed table-bordered battleTable'".(($id != '')?" ID='$id' ":"").">";

    // Get number of columns
    $att_cols=0;
    $def_cols=0;
    $att_head='';
    $def_head='';
    $att_base=1+("{$xml->LStarDice}"=="{$xml->AttPowername}"?1:0)+("{$xml->TechDice}"=="{$xml->AttPowername}"?1:0);
    $def_base=1+("{$xml->LStarDice}"=="{$xml->DefPowername}"?1:0)+("{$xml->TechDice}"=="{$xml->DefPowername}"?1:0)+("{$xml->DefAction}"=="Defend"?1:0);

                                  $att_cols++; $att_head.='<TH>Dice Roll</TH>';
    if (isset($xml->AttTanks))   {$att_cols++; $att_head.='<TH>Tanks</TH>';};
    if (isset($xml->AttArmies))  {$att_cols++; $att_head.='<TH>Armies</TH>';};
    if (isset($xml->AttBoomers)) {$att_cols++; $att_head.='<TH>Boomers</TH>';};
    if (isset($xml->AttNavies))  {$att_cols++; $att_head.='<TH>Navies</TH>';};
                                  $def_cols++; $def_head.='<TH>Dice Roll</TH>';
    if (isset($xml->DefTanks))   {$def_cols++; $def_head.='<TH>Tanks</TH>';};
    if (isset($xml->DefArmies))  {$def_cols++; $def_head.='<TH>Armies</TH>';};
    if (isset($xml->DefBoomers)) {$def_cols++; $def_head.='<TH>Boomers</TH>';};
    if (isset($xml->DefNavies))  {$def_cols++; $def_head.='<TH>Navies</TH>';};

    // Table header
    $return .= "<THEAD><TR><TH Rowspan='2' Valign'=Bottom'>Round</TH>";
    $return .= "<TH Colspan='$att_cols' Style='vertical-align:top'>".$xml->AttPowername.("{$xml->LStarDice}"=="{$xml->AttPowername}"?'<br/>+L-Star die':'').("{$xml->TechDice}"=="{$xml->AttPowername}"?'<br/>+Tech die':'')."</TH>";
    $return .= "<TH Colspan='$def_cols' Style='vertical-align:top'>".$xml->DefPowername.("{$xml->LStarDice}"=="{$xml->DefPowername}"?'<br/>+L-Star die':'').("{$xml->TechDice}"=="{$xml->DefPowername}"?'<br/>+Tech die':'')."<br/>".$xml->DefAction."</TH></TR>";
    $return .= "<TR>".$att_head.$def_head."</TR></THEAD>";

    // Table footer
    if ($footer == 'YES') {
        $return .= "<TFOOT><TR><TD Align='CENTER' Colspan='".($att_cols+$def_cols+1)."'>";
        $return .= "<INPUT Type='button' Id='battleAttack' Value='Attack again'/>";
        $return .= "<INPUT Type='button' Id='battleStop' Value='Stop attacking'/>";
        $return .= "<INPUT Type='button' Id='refresh' onClick='location.reload();return false' value='Finished'/>";
        $return .= "</TD></TR></TFOOT>";
    }

    // Table body - first row
    $return .= "<TBODY class='battleBody'><TR><TD>Initial</TD>";
    $return .= '<TD>&nbsp;</TD>';
    if (isset($xml->AttTanks)) $return .= '<TD>'.$xml->AttTanks.'</TD>';
    if (isset($xml->AttArmies)) $return .= '<TD>'.$xml->AttArmies.'</TD>';
    if (isset($xml->AttBoomers)) $return .= '<TD>'.$xml->AttBoomers.'</TD>';
    if (isset($xml->AttNavies)) $return .= '<TD>'.$xml->AttNavies.'</TD>';
    $return .= '<TD>&nbsp;</TD>';
    if (isset($xml->DefTanks)) $return .= '<TD>'.$xml->DefTanks.'</TD>';
    if (isset($xml->DefArmies)) $return .= '<TD>'.$xml->DefArmies.'</TD>';
    if (isset($xml->DefBoomers)) $return .= '<TD>'.$xml->DefBoomers.'</TD>';
    if (isset($xml->DefNavies)) $return .= '<TD>'.$xml->DefNavies.'</TD>';

    // Table body - remaining rows
    for ($ti = 1; $ti <= (int) $xml->Rounds; $ti++) {
        $return .= "<TR><TD>$ti</TD>";
        $r = $xml->xpath("/FIGHT/R[@Id='R$ti']"); $r = $r[0];
        if (isset($r->AttRoll)) $return .= '<TD '.($r->AttDice>$att_base?'class="battleHighlight" ':'').'title="'.$r->AttDice.' dice +'.$r->AttMod.'">'.$r->AttRoll.'</TD>';
        if (isset($r->AttTanks)) $return .= '<TD>'.$r->AttTanks.'</TD>';
        if (isset($r->AttArmies)) $return .= '<TD>'.$r->AttArmies.'</TD>';
        if (isset($r->AttBoomers)) $return .= '<TD>'.$r->AttBoomers.'</TD>';
        if (isset($r->AttNavies)) $return .= '<TD>'.$r->AttNavies.'</TD>';
        if (isset($r->DefRoll)) $return .= '<TD '.($r->DefDice>$def_base?'class="battleHighlight" ':'').'title="'.$r->DefDice.' dice +'.$r->DefMod.'">'.$r->DefRoll.'</TD>';
        if (isset($r->DefTanks)) $return .= '<TD>'.$r->DefTanks.'</TD>';
        if (isset($r->DefArmies)) $return .= '<TD>'.$r->DefArmies.'</TD>';
        if (isset($r->DefBoomers)) $return .= '<TD>'.$r->DefBoomers.'</TD>';
        if (isset($r->DefNavies)) $return .= '<TD>'.$r->DefNavies.'</TD>';
        $return .= "</TR>";
        }
    $return .= "</TBODY></TABLE>";
    return $return;

//
// Warhead attack report section, includes boomer shots
//
} else if ($xml->getName() == 'WARHEADS') {
    $return = "<H6>Warhead deployment report for Strategic attack by ".$xml->AttPowername.(isset($xml->FromTerrname)?(" from ".$xml->FromTerrname):"")."</H6>";
    $return .= "<TABLE class='table table-condensed table-bordered battleTable'><THEAD>";

	$return .= "<TR><TH rowspan='3'>Territory</TH><TH rowspan='3'>Owning Power</TH><TH rowspan='3'>Nukes</TH><TH rowspan='3'>Neutron Bombs</TH>";
	if (isset($xml->TARGET->BlanketSlots)) $return .= "<TH colspan='4'>L-Star</TH><TH rowspan='3'>Result</TH></TR><TR><TH colspan='2'>Blanket</TH><TH rowspan='2'>Slots</TH><TH rowspan='2'>Total hits</TH></TR><TR><TH>Slots</TH><TH>Hits</TH></TR></THEAD>";
	else $return .= "<TH colspan='2'>L-Star</TH><TH rowspan='3'>Result</TH></TR><TR><TH>Slots</TH><TH>Hits</TH></TR></THEAD>";

    // Table body
    $return .= "<TBODY>";
    foreach ($xml->xpath('//TARGET') as $target) {
        $return .= "<TR><TD>".$target->Terrname."</TD>";
        $return .= "<TD>".$target->Owner."</TD>";
        $return .= "<TD>".$target->Nukes."</TD>";
        $return .= "<TD>".$target->Neutron."</TD>";
		if (isset($target->BlanketSlots)) $return .= "<TD>".$target->BlanketSlots."</TD><TD>".$target->BlanketHits."</TD>";
		$return .= "<TD>".$target->TargettedSlots."</TD><TD>".$target->TargettedHits."</TD>";
		$return .= "<TD>".$target->Result."</TD>";
     }
     $return .= "</TBODY></TABLE>";
     return $return;


//
// Space blast report section
//
} else if ($xml->getName() == 'SPACEBLAST') {
    $return = "<H6>Space blast report for ".$xml->AttNukes." nuke attack by ".$xml->AttPowername."</H6>";
    $return .= "<TABLE class='table table-condensed table-bordered battleTable'><THEAD>";
    $return .= "<TR><TH>Superpower</TH><TH>L-Stars</TH><TH>K-Sats</TH><TH>Slots</TH><TH>Hits</TH></TR></THEAD>";
    $return .= "<TFOOT><TR><TH Colspan='5'>".$xml->Result."</TH></TR></TFOOT>";

    // Table body
    $return .= "<TBODY>";
    if (!isset($xml->Powername)) {
        $return .= "<TR><TD Colspan='5'>No Satellites</TD></TR>";
    } else foreach ($xml->xpath('//Powername') as $powername) {
        $return .= "<TR><TD>".$powername."</TD>";
        $return .= "<TD>".$powername->LStars."</TD>";
        $return .= "<TD>".$powername->KSats."</TD>";
        $return .= "<TD>".$powername->BlanketSlots."</TD>";
        $return .= "<TD>".$powername->Hits."</TD>";
    }
    $return .= "</TBODY></TABLE>";
    return $return;


//
// L-Star attack report section
//
} else if ($xml->getName() == 'LSTAR') {
    $return = "<h6>Satellite Offensive report</h6>";
    $return .= "<TABLE class='table table-condensed table-bordered battleTable'><THEAD>";
    $return .= "<TR><TH Rowspan='2' Valign='Bottom'>Round</TH><TH Colspan=3>".$xml->AttPowername."</TH>";
    $return .= "<TH Colspan=3>".$xml->DefPowername."</TH></TR>";
    $return .= "<TR><TH>L-Stars</TH><TH>K-Sats</TH><TH>Hits</TH><TH>L-Stars</TH><TH>K-Sats</TH><TH>Hits</TH></TR></THEAD>";

    // Table footer
    if ($footer == 'YES') {
        $return .= "<TFOOT><TR><TD Colspan=7 Align='Center'>";
        $return .= "<INPUT Type='button' class='btn btn-primary btn-medium' Id='battleAttack' Value='Attack again'/>";
        $return .= "<INPUT Type='button' class='btn btn-warning btn-medium' Id='battleStop' Value='Stop attacking'/>";
        $return .= "<INPUT Type='button' class='btn btn-medium' Id='refresh' onClick='location.reload();return false' value='Finished'/>";
        $return .= "</TD></TR></TFOOT>";
    }

    // Table body
    $return .= "<TBODY id='battleBody'>";
    for ($ti = 1; $ti <= (int) $xml->Rounds; $ti++) {
        $r = $xml->xpath("/LSTAR/R[@Id='R$ti']"); $r = $r[0];
        $return .= "<TR><TD>$ti</TD>";
        $return .= "<TD>".$r->att_lstars."</TD>";
        $return .= "<TD>".$r->att_ksats."</TD>";
        $return .= "<TD>".$r->att_hits."</TD>";
        $return .= "<TD>".$r->def_lstars."</TD>";
        $return .= "<TD>".$r->def_ksats."</TD>";
        $return .= "<TD>".$r->def_hits."</TD></TR>";
    }

    // Table body - last row
    $return .= "<TR><TD>Final</TD>";
    $return .= "<TD>".$xml->RESULT->ala."</TD>";
    $return .= "<TD>".$xml->RESULT->aka."</TD>";
    $return .= "<TD></TD>";
    $return .= "<TD>".$xml->RESULT->dla."</TD>";
    $return .= "<TD>".$xml->RESULT->dka."</TD>";
    $return .= "<TD></TD></TR></TBODY></TABLE>";

    return $return;

//
// Communication section
//
} else if ($xml->getName() == 'COMMS') {
    // Get message header information
    $realfrom = $xml->From->RealPowername;
    $from = $xml->From->Powername;
    if ($realfrom != '') {$from = $realfrom." seen as ".$from;}
    $to = '';
    if (isset($xml->To->Powername)) foreach ($xml->To->Powername as $to_powername) $to .= '*'.$to_powername;
    $messageno = $xml->messageno;
    $return = "<TABLE Class='table table-bordered table-condensed'>";
    //if ($messageno > 0) $return .= "<TFOOT><TR><TD Colspan=2 Align='center'><A HREF='messages.php?messageno=".$xml->messageno."'>Reply All</A></TD></TR></TFOOT>'";
    $return .= "<TBODY><TR><TH Width='30%'>From</TH><TD>$from</TD></TR>";
    $return .= "<TR><TH>To</TH><TD>".strtr(substr($to,1),array('*'=>', '))."</TD></TR>";
    $return .= "<TR><TD Colspan='2'>".html_entity_decode($xml->Text)."</TD></TR>";
    $return .= "</TBODY></TABLE>";

    return $return;

//
// Build report section
//
} else if ($xml->getName() == 'BUILDREPORT') {
    $return = '<h6>Build report</h6>';

    if (isset($xml->Research)?count($xml->Research->children())>0:0) {
        $return .= "<table class='table table-bordered table-compact'>";
        $return .= "<thead><tr><th>Research</th><th>Spend</th><th>Target</th><th>Success</th><th>Now</th></tr></thead><tbody>";
        foreach($xml->Research->children() as $xxml) $return .= "<tr><td>".$xxml->getName()."</td><td>".$xxml->Spend."</td><td>".$xxml->Levels."</td><td>".$xxml->Success."</td><td>".$xxml->NewLevel."</td></tr>";
        $return .= "</tbody></table>";
    }

    if (isset($xml->Storage)?Count($xml->Storage->children())>0:0) {
        $return .= "<table class='table table-bordered table-condensed'>";
        $return .= "<thead><tr><th>Storage</th><th>Built</th><th>Now</th></tr></thead><tbody>";
        foreach($xml->Storage->children() as $xxml) $return .= "<tr><td>".$xxml->getName()."</td><td>".$xxml->Built."</td><td>".$xxml->Now."</td></tr>";
        $return .= "</tbody></table>";
    }

    if (isset($xml->Strategic)?count($xml->Strategic->children())>0:0) {
        $return .= "<table class='table table-bordered table-condensed'>";
        $return .= "<thead><tr><th>Strategic Weapons</th><th>Built</th><th>Now</th><th>Left</th></tr></thead><tbody>";
        foreach($xml->Strategic->children() as $xxml) $return .= "<tr><td>".$xxml->getName()."</td><td>".$xxml->Built."</td><td>".$xxml->Now."</td><td>".$xxml->Left."</td></tr>";
        $return .= "</tbody></table>";
    }

    if (isset($xml->BuildTroops)?count($xml->BuildTroops->children())>0:0) {
        $return .= "<table class='table table-bordered table-condensed'>";
        $return .= "<thead><tr><th>Territory</th><th>Troops</th><th>Built</th><th>Now</th></tr></thead><tbody>";
        foreach($xml->BuildTroops->children() as $xxml) {
            $i=1;
            foreach($xxml as $txml) {
                $return .= "<tr>";
                if ( $i==1) $return .= "<td rowspan='".$xxml->count()."'>".$xxml."</td>";
                $return .= "<td>".$txml->getName()."</td><td>".$txml->Build."</td><td>".$txml->Now."</td></tr>";
                $i++;
            }
        }
        $return .= "</tbody></table>";
    }

    $return .= "<table class='table table-bordered table-condensed'><thead><tr><th>&nbsp;</th><th>Spend</th><th>Remaining</th></tr></thead><tbody>";
    $return .= "<tr><td>Cash</td><td>".$xml->Cash->Spend."</td><td>".$xml->Cash->Remaining."</td></tr>";
    $return .= "<tr><td>Minerals</td><td>".$xml->Minerals->Spend."</td><td>".$xml->Minerals->Remaining."</td></tr>";
    $return .= "<tr><td>Oil</td><td>".$xml->Oil->Spend."</td><td>".$xml->Oil->Remaining."</td></tr>";
    $return .= "<tr><td>Grain</td><td>".$xml->Grain->Spend."</td><td>".$xml->Grain->Remaining."</td></tr>";
    $return .= "</tbody></table>";

    return $return;

//
// Waiting message
//
} else if ($xml->getName() == 'WAIT') {
    $return = $xml;
    $return .= "<table width='100%' class='table table-bordered'>";
    $return .= "<tr><td width='33%'>Game</td><td><strong>".$xml -> Game."</strong></td></tr>";
    $return .= "<tr><td>Turn</td><td><strong>".$xml -> Turn."</strong></td></tr>";
    $return .= "<tr><td>Phase</td><td><strong>".$xml -> Phase."</strong></td></tr>";
    $return .= "<tr><td>Deadline</td><td><strong>";
    $return .= gmdate($xml -> dt_format, $xml -> UTS - ($xml -> offset*60))." (local)<br/>";
    $return .= gmdate($xml -> dt_format, (int) $xml -> UTS)." (GMT)";
    $return .= "</strong></td></tr></table>";

    return $return;

//
// Dead player message
//
} else if ($xml->getName() == 'DEADPOWER') {
    $return = '<h6>Superpower defeat salvage report</h6>';
    $return .= "<table width='100%' class='table table-bordered'>";
    $return .= "<tr><th>Powername</th><td>".$xml -> DeadPower."</td></tr>";
    $return .= "<tr><th>Territories</th><td>".($xml -> Territories - $xml -> NukedTerritories)."</td></tr>";

    foreach ($xml->xpath('//Powername') as $power) {
        $return .= "<tr><td><strong>$power</strong></td><td>";
        foreach ($power->children() as $bit) { if ($bit > 0)$return .= $bit->attributes()->Label." = ".$bit."<br/>"; }
        $return .= "</td></tr>";
    }
    $return .= "</table>";
    return $return;

//
//  UN Report
//
} else if ($xml->getName() == 'UNREPORT') {
    $return = '<h6>United Nations Resource Report</h6>';
    $return .= "<table width='100%' class='table table-bordered'>";
    $return .= "<tr>";
    foreach ($xml->Powername[0]->children() as $bit) {$return .="<th>".$bit->getName()."</th>";}
    $return .= "</tr>";

    foreach ($xml->Powername as $power) {
        $return .= '<tr>';
        foreach ($power->children() as $bit) {$return .="<td>$bit</td>";}
        $return .= '</tr>';
    }
    $return .= "</table>";
    return $return;

//
//  Corruption Report
//
} else if ($xml->getName() == 'BRIBES') {
    $return = '<h6>United Nations Report on Corruption spending</h6>';
    $return .= "<table width='100%' class='table table-bordered'>";
    $return .= "<tr><th>Superpower</th><th>Phase</th><th>Spend</th></tr>";
    foreach ($xml->Bribe as $bribe) {
        $return .= '<tr>';
        $return .= '<td>'.$bribe->Powername.'</td><td>'.$bribe->Phasedesc.'</td><td>'.$bribe->Amount.'</td>';
        $return .= '</tr>';
    }
    $return .= "</table>";
    return $return;

//
// Collapsible XML table
//
} else {
    $return = "<DIV class='expander'><DIV class='collHead'><i class='icon-plus-sign'></i> ".$xml->getName()."</DIV>";
    $return .= "<DIV class='collDetail' style='display:none'>";
    $return .= "<TABLE Width='100%' Class='table table-bordered'>";
    foreach ($xml -> children() as $bit) {
        $return .= "<TR Class='odd'><TD Width='120px'>".(isset($bit['Id'])?$bit['Id']:$bit->getName())."</TD><TD>";
        if ($bit!='') $return .= "<strong>$bit</strong><br/>";
        foreach ($bit -> children() as $bit2) {
            $return .= $bit2 -> getName()." = $bit2<BR>";
            foreach ($bit2 -> children() as $bit3) $return .= "->".$bit3 -> getName()." = $bit3<BR>";
        }
        $return .= "</TD></TR>";
    }
    $return .= "</TABLE></DIV><DIV>";

    return $return;
}

} ?>
