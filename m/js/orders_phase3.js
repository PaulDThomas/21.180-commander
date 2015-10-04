<script type="text/javascript"><!--
// $Id: orders_phase3.js 186 2014-01-20 20:06:54Z paul $
function ordersInit() {
    // Function to enable disable form entries on a change
    function resChange() {
        // Check numbers are being used
        $('input[type="number"]').each(function() {if (isNaN($(this).val())) $(this).val('0');});

        // Check maximum amount has not been exceeded for selling
        // Include minimum of zero to cover for negative Espionage levels
        var max = Math.max(0,$('#orderForm').find( '#'+$('#Resource').val() ).val());
        $('#Amount').attr('max', max );
        if (parseInt($('#Amount').val()) > max ) $('#Amount').val( max )
        $('#TotalValue').val( $('#Price').val() * $('#Amount').val() );

        // Check whether process button can be used
        if ($('#Amount').val() == '0' && $('#Resource').val() != 'pass' && $('#who').val() != 'Market') {
            $('#processOrders').attr('disabled','disabled');
        } else if ($('#Amount').val() == '0' && $('#who').val() == 'Market') {
            $('#processOrders').attr('disabled','disabled');
        } else {
            $('#processOrders').removeAttr('disabled');
        }
    };

    $('#Resource').change(function() {
        var r = ['minerals','oil','grain'];
        if ($(this).val()=='pass') {
            $('#theBlind').slideUp();
            $('#processOrders').val('Pass').removeAttr('disabled');
        } else if ($.inArray($(this).val(),r)>=0) {
            if ($('#who option[value=Market]').length==0 && $('#who').attr('siege')=='N') $('#who').prepend('<option value="Market">Market</option>');
            $('#who option').removeAttr('selected');
            $('#who option:first-child').attr('selected','selected');
            $('#Amount').val('0');
            $('#TotalValue').val('0');
            $('#Price').val($('#'+$(this).val()+'Price').val()).attr('readonly','readonly');
            $('#processOrders').val('Sell').attr('disabled','disabled');
            $('#theBlind').slideDown();
        } else {
            $('#who').removeAttr('readonly');
            $('#Price').val('0').removeAttr('readonly');
            $('#Amount').val('0');
            $('#TotalValue').val('0');
            $('#who option[value=Market]').remove();
            $('#who option').removeAttr('selected');
            $('#who option:first-child').attr('selected','selected');
            $('#processOrders').val('Offer').attr('disabled','disabled');
            $('#theBlind').slideDown();
        }
    });
    $('#who').change(function() {
        var r = ['minerals','oil','grain'];
        if ($(this).val()=='Market') {
            $('#Amount').val('0');
            $('#Price').val($('#'+$('#Resource').val()+'Price').val()).attr('readonly','readonly');
            $('#TotalValue').val('0');
            $('#processOrders').val('Sell').attr('disabled','disabled');
        } else {
            $('#Price').val('0').removeAttr('readonly');
            $('#Amount').val('0').removeAttr('readonly');
            $('#TotalValue').val('0');
            $('#processOrders').val('Offer').attr('disabled','disabled');
        }
    });
    $('input').change(function() {resChange();});
}
--></script>
