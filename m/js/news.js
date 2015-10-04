// News Javascript Functions
// $Id: news.js 101 2012-07-09 22:14:57Z paul $

function newsInit() {
    function reloadNews() {
        // Get current news messages
        $.ajax({
            type: "POST",
            url: "m/ajax/news_list.php",
            cache: false,
            success: function(data,Status) {
                $("#newsList").empty().append(data);
            },
            error: onError
        });
        return false;
    }

    $('#newsPost').click( function () {
        var formData = $("#newsForm").serialize();
        $.ajax({
            type: "POST",
            url: "m/ajax/news_list.php",
            cache: false,
            data: formData,
            error: onError,
            success: function(data,Status) {
                $('#newsList').empty().append(data);
                $('#newsMessage').val('');
            },
        });
        return false;
    });

    $("#newsOlder").click(function(){
        $.ajax({
            type: "POST",
            url: "m/ajax/news_list.php",
            cache: false,
            data: 'news_older=yes',
            success: function(data,Status) {
                $("#newsList").empty().append(data);
            },
            error: onError
        });
        return false;
    });

    $("#newsNewer").click(function(){
        $.ajax({
            type: "POST",
            url: "m/ajax/news_list.php",
            cache: false,
            data: "news_newer=yes",
            success: function(data,Status) {
                $("#newsList").empty().append(data);
            },
            error: onError
        });
        return false;
    });

    reloadNews();
};
