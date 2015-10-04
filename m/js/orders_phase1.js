<script type="text/javascript"><!--
// $Id: orders_phase1.js 203 2014-03-23 07:55:38Z paul $
function recalc () {

  // Bank Statement specific bits
  $('#tbond').val( $('#takeBond').prop('checked')?'Y':'N' );
  $('#bondTaken').val( $('#takeBond').prop('checked')*$('#bondValue').val() );
  if (parseInt($('#interestValue').val()) < parseInt($('#interestOutstanding').val())) {$('#interestWarning').slideDown();$('#interestCont').addClass("warning");}
  else {$('#interestWarning').slideUp();$('#interestCont').removeClass("warning");}
  if ($('#interestCont').hasClass("warning")) {$('#bankTotal').parent().addClass("warning");} else {$('#bankTotal').parent().removeClass("warning");}
  // Add up bank total
  $('#bankTotal').val('0');
  $('.incoming').each(function () {$('#bankTotal').val(parseInt($('#bankTotal').val())+parseInt($(this).val()));});
  $('.outgoing').each(function () {$('#bankTotal').val(parseInt($('#bankTotal').val())-parseInt($(this).val()));});

  // Troop specific bits
  $('#troopTotal').val('0');
  $('.terrRow').each(function () {
    var troopSum=$(this).find('.troopSum');
    troopSum.val('0');
    $(this).find('.troops').each(function () {
      troopSum.val( parseInt(troopSum.val()) + 10*parseInt($(this).val()) );
      if (parseInt($(this).val()) < Math.max.apply(Math,$(this).children().map(function() {return parseInt($(this).val())}).get())) {$(this).parent().addClass("warning");}
      else {$(this).parent().removeClass("warning");}
    });
    if ($(this).find('.troops').parent().hasClass("warning")) {troopSum.parent().addClass("warning");} else {troopSum.parent().removeClass("warning");}
    $('#troopTotal').val(parseInt($('#troopTotal').val()) + parseInt(troopSum.val()));
  });
  if ($('.troopSum').parent().hasClass("warning")) {
      $('#troopTotal').parent().parent().addClass("warning");
      $('#troopWarn').show();
  } else {
    $('#troopTotal').parent().parent().removeClass("warning");
    $('#troopWarn').hide();
  }

  // Company specific bits
  $('#companiesTotal').val('0');
  $('#mineralsTotal').val('0');
  $('#oilTotal').val('0');
  $('#grainTotal').val('0');
  $('.companyRow').each(function () {
    var b = $(this).find('.companyButton');
    var s = $(this).find('.companySum');
    var r = $(this).find('.resourceValue');
    var n = $(this).find('.companyRunning');
    if (b.val()=='Running' ) {b.addClass("btn-success");s.val('50');s.parent().removeClass("warning");if (!r.hasClass("resourceBlockaded")) {r.text(r.text().substring(2,3)+'/'+r.text().substring(2,3))};}
    else if (b.val()=='Re-open' ) {b.addClass("btn-success");s.val($('#resourceReopen').val());s.parent().removeClass("warning");if (!r.hasClass("resourceBlockaded")) {r.text(r.text().substring(2,3)+'/'+r.text().substring(2,3))};}
    else {
        b.removeClass("btn-success");
        s.val('0');
        s.parent().addClass("warning");
        r.text('0/'+r.text().substring(2,3));
        if (b.val()=='Close') b.addClass("btn-warning");
    }
    $('#companiesTotal').val( parseInt($('#companiesTotal').val()) + parseInt(s.val()) );
  });
  if ($('.companySum').parent().hasClass("warning")) {$('#companiesTotal').parent().parent().addClass("warning");} else {$('#companiesTotal').parent().parent().removeClass("warning");}
  // Add up resources
  $('.resourceMinerals').each(function() {$('#mineralsTotal').val(parseInt($('#mineralsTotal').val())+parseInt($(this).text().substring(0,1)));});
  $('.resourceOil').each(function() {$('#oilTotal').val(parseInt($('#oilTotal').val())+parseInt($(this).text().substring(0,1)));});
  $('.resourceGrain').each(function() {$('#grainTotal').val(parseInt($('#grainTotal').val())+parseInt($(this).text().substring(0,1)));});
  // Add on bonus resources
  if ($('#mineralsTotal').val() > 0) {$('#mineralsBonus').val( $('#bonusResource').val() );} else {$('#mineralsBonus').val('0');}
  if ($('#oilTotal').val() > 0) {$('#oilBonus').val( $('#bonusResource').val() );} else {$('#oilBonus').val('0');}
  if ($('#grainTotal').val() > 0) {$('#grainBonus').val( $('#bonusResource').val() );} else {$('#grainBonus').val('0');}
  $('#mineralsFinal').val( Math.min(parseInt($('#mineralsMax').val()), parseInt($('#mineralsTotal').val()) + parseInt($('#mineralsStart').val()) + parseInt($('#mineralsBonus').val())) );
  $('#oilFinal').val( Math.min(parseInt($('#oilMax').val()), parseInt($('#oilTotal').val()) + parseInt($('#oilStart').val()) + parseInt($('#oilBonus').val())) );
  $('#grainFinal').val( Math.min(parseInt($('#grainMax').val()), parseInt($('#grainTotal').val()) + parseInt($('#grainStart').val()) + parseInt($('#grainBonus').val())) );

  // Grand Total
  $('#grandTotal').val($('#bankTotal').val());
  $('.subTotal').each(function() {$('#grandTotal').val(parseInt($('#grandTotal').val())-parseInt($(this).val()));});
  if ($('#grandTotal').val() < 0) {
    $('#grandTotal').parent().addClass("error");
    $('#grandTotal').parent().removeClass("success");
  } else {
    $('#grandTotal').parent().removeClass("error");
    $('#grandTotal').parent().addClass("success");
  }

  // Boomer specific bits
  $('.boomerNuke').change(function(){
      if (isNaN($(this).val())) {$(this).val(0);}
      var nukesAdd=parseInt($(this).val())
          ,nukesMax=parseInt($(this).attr('max'))
          ,nukesAvail=parseInt($(this).attr('data-avail'))
          ,nukesThere=parseInt($(this).attr('data-there'))
          ,nukes=parseInt($(this).closest('.boomerRow').find('.boomerNukeHidden').val())
          ,neutron=parseInt($(this).closest('.boomerRow').find('.boomerNeutronHidden').val())
          ,neutronAdd=parseInt($(this).closest('.boomerRow').find('.boomerNeutron').val())
          ,neutronThere=parseInt($(this).closest('.boomerRow').find('.boomerNeutron').attr('data-there'))
          ;
      nukesAdd = Math.min(nukesAdd,nukesAvail);
      nukes = Math.min(2,nukesThere+nukesAdd);
      neutron = Math.min(2-nukes,neutron);
      neutronAdd = neutron-neutronThere;
      $(this).val(nukesAdd);
      $(this).closest('.boomerRow').find('.boomerNukeHidden').val(nukes);
      $(this).closest('.boomerRow').find('.boomerNeutron').val(neutronAdd);
      $(this).closest('.boomerRow').find('.boomerNeutronHidden').val(neutron);
  });
  $('.boomerNeutron').change(function(){
      if (isNaN($(this).val())) {$(this).val(0);}
      var neutronAdd=parseInt($(this).val())
          ,neutronMax=parseInt($(this).attr('max'))
          ,neutronAvail=parseInt($(this).attr('data-avail'))
          ,neutronThere=parseInt($(this).attr('data-there'))
          ,nukes=parseInt($(this).closest('.boomerRow').find('.boomerNukeHidden').val())
          ,neutron=parseInt($(this).closest('.boomerRow').find('.boomerNeutronHidden').val())
          ,nukesAdd=parseInt($(this).closest('.boomerRow').find('.boomerNuke').val())
          ,nukesThere=parseInt($(this).closest('.boomerRow').find('.boomerNuke').attr('data-there'))
          ;
      neutronAdd = Math.min(neutronAdd,neutronAvail);
      neutron = Math.min(2,neutronThere+neutronAdd);
      nukes = Math.min(2-neutron,nukes);
      nukesAdd = nukes-nukesThere;
      $(this).val(neutronAdd);
      $(this).closest('.boomerRow').find('.boomerNeutronHidden').val(neutron);
      $(this).closest('.boomerRow').find('.boomerNuke').val(nukesAdd);
      $(this).closest('.boomerRow').find('.boomerNukeHidden').val(nukes);
  });
  $('.boomerTerrname').change(function(){
      var o=$(this).find('option:selected');
      $(this).closest('.boomerRow').find('.boomerTerrnoHidden').val(o.attr('data-terrno'));
      if (o.attr('data-visok')=='OK') {
        // Allow select
        $(this).closest('.boomerRow').find('.boomerVisibleText').hide();
        $(this).closest('.boomerRow').find('.boomerVisibleSelect').show();
      } else {
        // Set to no and hide select
        $(this).closest('.boomerRow').find('.boomerVisibleSelect option:last-child').attr('selected','selected');
        $(this).closest('.boomerRow').find('.boomerVisibleSelect').hide();
        $(this).closest('.boomerRow').find('.boomerVisibleText').show();
      }
      $(this).closest('.boomerRow').find('.boomerVisibleText').text($(this).closest('.boomerRow').find('.boomerVisibleSelect option:selected').text());
  });
  // Initial call to set the visible box correctly on open
  //$('.boomerTerrname').change();

  // Check phases are not the same
  if ( $('#P_A').val() == $('#P_B').val()
       | $('#P_A').val() == $('#P_C').val()
       | ($('#P_B').val() == $('#P_C').val())
       ) $('#phaseAlert').slideDown();
  else $('#phaseAlert').slideUp();
  // Update pay salaries values
  if ($('#P_A_fl')) { if (isNaN($('#P_A_ival').val())) {$('#P_A_ival').val('0')}; if ($('#P_A_fl').val()=='Last') $('#P_A_val').val(-1*$('#P_A_ival').val()); else $('#P_A_val').val($('#P_A_ival').val());}
  if ($('#P_B_fl')) { if (isNaN($('#P_B_ival').val())) {$('#P_B_ival').val('0')}; if ($('#P_B_fl').val()=='Last') $('#P_B_val').val(-1*$('#P_B_ival').val()); else $('#P_B_val').val($('#P_B_ival').val());}
  if ($('#P_C_fl')) { if (isNaN($('#P_C_ival').val())) {$('#P_C_ival').val('0')}; if ($('#P_C_fl').val()=='Last') $('#P_C_val').val(-1*$('#P_C_ival').val()); else $('#P_C_val').val($('#P_C_ival').val());}

  enableProcess();

};

function enableProcess() {

  // Decide whether to allow processing or not
  if ( $('#grandTotal').val() < 0
       | $('#phaseAlert').is(':visible')
       ) {
    $('#processOrders').attr("disabled", "disabled");
  } else {
    $('#processOrders').removeAttr("disabled");
  }

}


function ordersInit() {
  // Set up expanding sections
  $('#statement').click(function() {$('#statementDetail').slideToggle(); $('#statement').toggleClass('icon-plus-sign icon-minus-sign');});
  $('#troops').click(function() {$('#troopsDetail').slideToggle(); $('#troops').toggleClass('icon-plus-sign icon-minus-sign');});
  $('#companies').click(function() {$('#companiesDetail').slideToggle(); $('#companies').toggleClass('icon-plus-sign icon-minus-sign');});

  // Set up text change on buttons
  $('.companyButton').click(function() {
    if ($(this).val()=='Running') {
      $(this).val('Close');
    } else if ($(this).val()=='Close') {
      $(this).val('Running');
    } else if ($(this).val()=='Re-open') {
      $(this).val('Closed');
    } else if ($(this).val()=='Closed') {
      $(this).val('Re-open');
    }
  });

  // Add on recalcs
  $('input').click(function() {recalc();});
  $('select').change(function() {recalc();});

  // Initial calculation
  recalc();
};

--></script>
