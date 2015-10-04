// $Id: banking.js 186 2014-01-20 20:06:54Z paul $

function bankingButtons() {
    if ($('#loanAmt').val()>0) $('#loanButton').removeAttr("disabled");
    else $('#loanButton').attr("disabled", "disabled");

    if ($('#transferAmt').val()>0) $('#transferButton').removeAttr("disabled");
    else $('#transferButton').attr("disabled", "disabled");
};

function refreshBanking(xml){
    // Update form elements

    $('input.resourceVal').each (function() {
        $(this).val( $(xml).find( $(this).attr('id') ).text() );
    });
    $('div.resourceVal').each (function() {
        $(this).text( $(xml).find( $(this).attr('id') ).text() );
    });
    $('h3.resourceVal').each (function() {
        $(this).text( $(xml).find( $(this).attr('id') ).text() );
    });
    $('#transferAmt').attr('max', $('#cash_avail').text());

    // Check amount to borrow select
    $('#loanAmt option').each (function() {
        if (parseInt($(this).val()) > parseInt($('#maxLoanAmt').text()) - parseInt($('#loan').text())) {
            $(this).remove();
        }
    });

    // Show modal
    $('#resultModal').modal('show');
    $('#transferAmt').val('0');
    $('#loanAmt').val('0');
    bankingButtons();

    // Refresh messages
    $.ajax({
        type: "POST",
        url: "m/ajax/message_list.php",
        cache: false,
        data: "message_first=yes",
        success: function(data,Status) {
            $("#messageList").empty().append(data);
        },
        error: onError
    });

};

function bankingInit() {
    $("#transferButton").click(function(){
        if ( (parseInt($("#transferAmt").val()) < parseInt($("#transferAmt").attr('min')))
           | (parseInt($("#transferAmt").val()) > parseInt($("#transferAmt").attr('max')))
           | (parseInt($("#transferAmt").val()) == 0)
           ) {
            $("#transferAmt").val(0);
        } else {
            var transferData = $("#transferForm").serialize();
            $.ajax({
                type: "POST",
                url: "m/ajax/process_banking.php",
                cache: false,
                data: transferData,
                success: function(xml) { refreshBanking(xml) },
                error: onError
            });
        }
        return false;
    });

    $("#transferAmt").change(function() {bankingButtons();});

    $("#loanButton").click(function(){
        var loanData = $("#loanForm").serialize();
        if (parseInt($("#loanAmt").val()) > 0) {$.ajax({
            type: "POST",
            url: "m/ajax/process_banking.php",
            cache: false,
            data: loanData,
            /*dataType: "xml",*/
            success: function(xml) { refreshBanking(xml) },
            error: onError
        })};
        return false;
    });

    $("#loanAmt").change(function() {bankingButtons();});

    bankingButtons();

};
