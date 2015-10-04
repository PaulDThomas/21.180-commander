function commsInit() {
    // $Id: communication.js 282 2015-04-20 09:05:21Z paul $
    function commsRefresh(formData) {
        $("#commsN").text("Updating...");
        $.ajax({
            type: "POST",
            url: "m/ajax/communications_list.php",
            cache: false,
            data: formData,
            dataType: "xml",
            success: function(xml) {
                if ($(xml).find('sndOK').size()>0) {
                    // Unmark all powernames
                    $('.powerChk').removeAttr('checked');
                    // Remark any sent powernames
                    $('.powerChk').each(function(){
                        var pC=$(this);
                        var name=$(this).prop('name');
                        $(xml).find('sndOK Powername').each(function(){
                            var sent=$(this).text();
                            if (name==sent) {pC.attr('checked',true);}
                        });
                    });
                    $('#sndText').val('');
                    $('.sndBtn').attr('disabled','disabled');
                    // Comfort comms
                    $('#comfortHead').text('Communication');
                    $('#comfortText').text('Message sent successfully')
                    $('#comfort').modal('show');
                }
                $("#commsList").empty();
                $(xml).find('message').each(
                    function(){
                        var mD = $(this).find('messageDate').text();
                        var mT = $(this).find('messageText').text();
                        var item = $('<li><div class="messageDate">'+mD+'</div><div class="messageText"></div></li>');
                        $(item).find('.messageText').append(mT);
                        $("#commsList").append(item);
                    });
                if ($(xml).find('total').text() == 0) {
                    $('#commsN').text('None');
                } else {
                    $('#commsN').text((parseInt($(xml).find('first').text())+1)+' to ' + (parseInt($(xml).find('first').text())+$('#commsList li').size()) + ' of ' + $(xml).find('total').text());
                }
            },
            error: onError
        });
        return false;
    }

    $("#commsOlder").click(function(){commsRefresh("comms_older=yes&"+$("#sendForm").serialize());});
    $("#commsNewer").click(function(){commsRefresh("comms_newer=yes&"+$("#sendForm").serialize());});
    $("#commsFewer").click(function(){commsRefresh("comms_fewer=yes&"+$("#sendForm").serialize());});
    $("#commsMore").click(function(){commsRefresh("comms_more=yes&"+$("#sendForm").serialize());});
    $("#sndOK").click(function(){commsRefresh("comms_send=ok&"+$("#sendForm").serialize());});
    $("#sndAnon").click(function(){commsRefresh("comms_send=anon&"+$("#sendForm").serialize());});
    $("#sndAs").click(function(){commsRefresh("comms_send=as&"+$("#sendForm").serialize());});
    
    var w = $('#sendForm').data('white');
    var g = $('#sendForm').data('grey');
    var b = $('#sendForm').data('black');
    
    $(".powerChk").change(function() {
        $('.sndBtn').attr('disabled','disabled');
        $(".powerChk").each(function() {
            if ($(this).is(':checked')) {
                if (w=='Y') {$('#sndOK').removeAttr('disabled');}
                if (b=='Y') {$('#sndAnon').removeAttr('disabled');}
            }
        });
        commsRefresh($("#sendForm").serialize());
    });
    $("#global").change(function() {
        alert(g);
        if ($(this).is(':checked')) {
            if ($(this).is(':checked')) {
                if (g=='Y') {$('#sndOK').removeAttr('disabled');}
                if (b=='Y') {$('#sndAnon').removeAttr('disabled');}
            }
            $('.powerChk').prop('checked',1);
            $('.powerChk').attr('disabled','disabled');
        } else {
            $('.sndBtn').attr('disabled','disabled');
            $('.powerChk').prop('checked',0);
            $('.powerChk').removeAttr('disabled');
        }
        commsRefresh($("#sendForm").serialize());
    });
    $('.sndBtn').attr('disabled','disabled');
    commsRefresh();
};
