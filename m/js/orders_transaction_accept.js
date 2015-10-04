// $Id: orders_transaction_accept.js 190 2014-02-03 18:14:41Z paul $
function ordersInit() {
    // Function to enable disable form entries on a change
    function resChange() {
        // Check numbers are being used
        $('input[type="number"]').attr('readonly','readonly');
        $('select').attr('readonly','readonly');

        // Check accept is possible
        $('#processOrders').val('Accept');
        if ($('#actionLabel').text() == 'Sell to'
            && parseInt($('#Amount').val()) > $('#orderForm').find( '#'+$('#Resource').val() ).val()) {
            $('#processOrders').attr('disabled','disabled');
        } else if ($('#actionLabel').text() == 'Buy from'
            && parseInt($('#TotalValue').val()) > $('#cash').val() ) {
            $('#processOrders').attr('disabled','disabled');
        } else
            $('#processOrders').removeAttr('disabled');
        // Show reject button
        $('#rejectOffer').show();
    };
    resChange();

    // Change accept before submit
    $('#processOrders').click(function() {
        $('#Accepted').val('Y');
    });

    // Change reject button
    $('#rejectOffer').click(function() {
        $('#Accepted').val('R');
        $('<input>').attr({type:'hidden',name:'PROCESS',value:'Hello'}).appendTo('#orderForm');
        $('#orderForm').submit();
    });

}
