// $Id: message.js 204 2014-03-24 19:46:09Z paul $
function messageInit() {
    $("#messageOlder").click(function(){
        $("#messageN").text("...");
        $.ajax({
            type: "POST",
            url: "m/ajax/message_list.php",
            cache: false,
            data: "message_older=yes&messageSearch="+$('#messageSearch').val()+"&messageDropValue="+$('#messageDropValue').val(),
            success: function(data,Status) {
                $("#messageList").empty().append(data);
                $('.collHead').click(function() {$(this).closest('.expander').find('.collDetail').slideToggle();$(this).find('i').toggleClass('icon-plus-sign icon-minus-sign');});
                $("#messageN").text($("#messageList li").size());
            },
            error: onError
        });
        return false;
    });

    $("#messageNewer").click(function(){
        $("#messageN").text("...");
        $.ajax({
            type: "POST",
            url: "m/ajax/message_list.php",
            cache: false,
            data: "message_newer=yes&messageSearch="+$('#messageSearch').val()+"&messageDropValue="+$('#messageDropValue').val(),
            success: function(data,Status) {
                $("#messageList").empty().append(data);
                $('.collHead').click(function() {$(this).closest('.expander').find('.collDetail').slideToggle();$(this).find('i').toggleClass('icon-plus-sign icon-minus-sign');});
                $("#messageN").text($("#messageList li").size());
            },
            error: onError
        });
        return false;
    });

    $("#messageFewer").click(function(){
        $("#messageN").text("...");
        $.ajax({
            type: "POST",
            url: "m/ajax/message_list.php",
            cache: false,
            data: "message_fewer=yes&messageSearch="+$('#messageSearch').val()+"&messageDropValue="+$('#messageDropValue').val(),
            success: function(data,Status) {
                $("#messageList").empty().append(data);
                $('.collHead').click(function() {$(this).closest('.expander').find('.collDetail').slideToggle();$(this).find('i').toggleClass('icon-plus-sign icon-minus-sign');});
                $("#messageN").text($("#messageList li").size());
            },
            error: onError
        });
        return false;
    });

    $("#messageMore").click(function(){
        $("#messageN").text("...");
        $.ajax({
            type: "POST",
            url: "m/ajax/message_list.php",
            cache: false,
            data: "message_more=yes&messageSearch="+$('#messageSearch').val()+"&messageDropValue="+$('#messageDropValue').val(),
            success: function(data,Status) {
                $("#messageList").empty().append(data);
                $('.collHead').click(function() {$(this).closest('.expander').find('.collDetail').slideToggle();$(this).find('i').toggleClass('icon-plus-sign icon-minus-sign');});
                $("#messageN").text($("#messageList li").size());
            },
            error: onError
        });
        return false;
    });

    $("#messageRefresh").click(function(){
        $.ajax({
            type: "POST",
            url: "m/ajax/message_list.php",
            cache: false,
            data: "message_first=yes&messageSearch="+$('#messageSearch').val()+"&messageDropValue="+$('#messageDropValue').val(),
            success: function(data,Status) {
                $("#messageList").empty().append(data);
                $('.collHead').click(function() {$(this).closest('.expander').find('.collDetail').slideToggle();$(this).find('i').toggleClass('icon-plus-sign icon-minus-sign');});
                $("#messageN").text($("#messageList li").size());
            },
            error: onError
        });
        return false;
    });


    $("#messageRead").click(function(){
        $.ajax({
            type: "POST",
            url: "m/ajax/message_list.php",
            cache: false,
            data: "message_first=yes&messageRead=yes&messageDropValue="+$('#messageDropValue').val(),
            success: function(data,Status) {
                $("#messageList").empty().append(data);
                $('.collHead').click(function() {$(this).closest('.expander').find('.collDetail').slideToggle();$(this).find('i').toggleClass('icon-plus-sign icon-minus-sign');});
                $("#messageN").text($("#messageList li").size());
            },
            error: onError
        });
        return false;
    });


    $(".messageDropItem").click(function(){
        $("#messageN").text("...");
        $('#messageDropValue').val($(this).text());
        $.ajax({
            type: "POST",
            url: "m/ajax/message_list.php",
            cache: false,
            data: "message_first=yes&messageSearch="+$('#messageSearch').val()+"&messageDropValue="+$('#messageDropValue').val(),
            success: function(data,Status) {
                $("#messageList").empty().append(data);
                $('.collHead').click(function() {$(this).closest('.expander').find('.collDetail').slideToggle();$(this).find('i').toggleClass('icon-plus-sign icon-minus-sign');});
                $("#messageN").text($("#messageList li").size());
            },
            error: onError
        });
    });


    // Get current message list
    $.ajax({
        type: "POST",
        url: "m/ajax/message_list.php",
        cache: false,
        success: function(data,Status) {
            $("#messageList").empty().append(data);
            $('.collHead').click(function() {$(this).closest('.expander').find('.collDetail').slideToggle();$(this).find('i').toggleClass('icon-plus-sign icon-minus-sign');});
            $("#messageN").text($("#messageList li").size());
        },
        error: onError
    });
    return false;
};

function sndMessageInit() {
    $("#sndOK").click(function() {
        var formData = $("#sendForm").serialize();
        $.ajax({
            type: "POST",
            url: "m/ajax/message_list.php",
            cache: false,
            data: formData,
            success: function(data,Status) {
                $("#messageSearch").val("");
                $("#messageList").empty().append(data);
                $('.powerChk').removeAttr('checked');
                $('#sndText').val('');
                $('#sndOK').attr('disabled','disabled');
                // Comfort message
                $('#comfortHead').text('Communication');
                $('#comfortText').text('Message sent successfully')
                $('#comfort').modal('show');
            },
            error: onError
        });
        return false;
    });

    $(".powerChk").change(function() {
        $('#sndOK').attr('disabled','disabled');
        $(".powerChk").each(function() {if ($(this).is(':checked')) $('#sndOK').removeAttr('disabled');});
    });

    $('#sndOK').attr('disabled','disabled');

    return false;
};
