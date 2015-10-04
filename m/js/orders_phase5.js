<script type="text/javascript"><!--
// $Id: orders_phase5.js 199 2014-02-28 20:24:04Z paul $
function ordersInit() {

    // Set up expanders
    $('.collHead').click(function() {
        $(this).parent().parent().find('.collDetail').slideToggle();
        $(this).find('i').toggleClass('icon-plus-sign icon-minus-sign');
    });

    // Work out calculated inputs
    function recalc() {
        $('.totals').val('0');
        $('input[type="number"]').each(function() {if (isNaN($(this).val())) $(this).val('0');});

        // Research
        $('#researchTotal').val('0');
        $('.pct').each(function () {
            var amt = $(this).parent().parent().find('.researchAmt').val();
            var val = $(this).parent().parent().find('.researchVal').val();
            if (amt==0 | val==0) $(this).val('0');
            else $(this).val(Math.floor(Math.min(100,100*Math.sqrt(val/($(this).attr('data-pctmod')*amt*amt)))));
            $('#researchTotal').val(parseInt($('#researchTotal').val())+parseInt(val));
        });

        // Storage
        $('#resourceTotal').val('0');
        $('.storeVal').each(function() {
            $(this).val($(this).parent().parent().find('.storeAmt').val()*150);
            $('#resourceTotal').val(parseInt($('#resourceTotal').val()) + parseInt($(this).val()));
        });

        // Strategic
        $('#strategicTotal').val('0');
        $('.strategicVal').each(function() {
            $(this).val($(this).parent().parent().find('.strategicAmt').val()*$(this).attr('data-cost'));
            $('#strategicTotal').val(parseInt($('#strategicTotal').val()) + parseInt($(this).val()));
        });

        // Territories
        $('#troopTotal').val('0');
        $('#troopAmt').val('0');
        $('#tankAmt').val('0');
        $('#boomerAmt').val('0');
        $('.terrRow').each(function() {
            var troopSum=$(this).find('.troopSum');
            //alert ($(this).find('.troops').val() +":"+ $(this).find('.tanks').val());
            if ($(this).find('.tanks')[0]) {
                troopSum.val($(this).find('.troops').val()*100 + $(this).find('.tanks').val()*500);
                $('#troopAmt').val(parseInt($('#troopAmt').val()) + parseInt($(this).find('.troops').val()));
                $('#tankAmt').val(parseInt($('#tankAmt').val()) + parseInt($(this).find('.tanks').val()));
            } else {
                troopSum.val($(this).find('.troops').val()*100 + $(this).find('.boomers').val()*1000);
                $('#troopAmt').val(parseInt($('#troopAmt').val()) + parseInt($(this).find('.troops').val()));
                $('#boomerAmt').val(parseInt($('#boomerAmt').val()) + parseInt($(this).find('.boomers').val()));
            }
            $('#troopTotal').val(parseInt($('#troopTotal').val()) + parseInt(troopSum.val()));
        });
        $('.finalbuild').each(function() { $(this).val( parseInt($(this).parent().parent().find('.initials').text()) + parseInt($(this).parent().parent().find('.totals').val()) );});

        // Totals
        $('.subTotal').each(function() { $('#grandTotal').val(parseInt($('#grandTotal').val()) + parseInt($(this).val())); });
        $('.resSpend').val( Math.ceil($('#troopAmt').val()/3) + parseInt($('#tankAmt').val()) + parseInt($('#boomerAmt').val()) );
        $('#mineralsSpend').val( parseInt($('#mineralsSpend').val()) + parseInt($('#nukes').val()) + parseInt($('#lstars').val())*2 + parseInt($('#ksats').val())*2 + parseInt($('#neutron').val()) );
        $('.final').each(function() { $(this).val( parseInt($(this).parent().parent().find('.initials').text()) - parseInt($(this).parent().parent().find('.totals').val()) );});

        // Process button and warnings
        $('#processOrders').removeAttr('disabled');
        $('.final').each(function() {
            if (parseInt($(this).val()) < 0) {
                $('#processOrders').attr('disabled','disabled');
                $(this).parent().addClass('error');
            } else $(this).parent().removeClass('error');
        });
        $('.finalbuild').each(function() {
            if (parseInt($(this).val()) > parseInt($(this).attr('data-max'))) {
                $('#processOrders').attr('disabled','disabled');
                $(this).parent().addClass('error');
            } else $(this).parent().removeClass('error');
        });

    };

    // Set up recalculation points
    $('.researchVal').change(function() {recalc();});
    $('.researchAmt').change(function() {recalc();});
    $('.troops').change(function() {recalc();});
    $('.tanks').change(function() {recalc();});
    $('.boomers').change(function() {recalc();});
    $('.storeAmt').change(function() {recalc();});
    $('.strategicAmt').change(function() {recalc();});

    // Perform initial calculation
    recalc();

};
--></script>
