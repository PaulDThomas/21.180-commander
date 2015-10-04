// Forum Javascript Functions
// $Id: forum.js 88 2012-06-11 22:57:51Z paul $

function forumInit() {
    function reloadForum() {
        // Get current forum messages
        $.ajax({
            type: "POST",
            url: "m/ajax/forum_list.php",
            cache: false,
            success: function(data,Status) {
                $("#forumList").empty().append(data);
            },
            error: onError
        });
        return false;
    }

    $('#forumPost').click( function () {
        var formData = $("#forumForm").serialize();
        $.ajax({
            type: "POST",
            url: "m/ajax/forum_list.php",
            cache: false,
            data: formData,
            error: onError,
            success: function(data,Status) {
                $('#forumList').empty().append(data);
                $('#forumMessage').val('');
            },
        });
        return false;
    });

    $("#forumOlder").click(function(){
        $.ajax({
            type: "POST",
            url: "m/ajax/forum_list.php",
            cache: false,
            data: 'forum_older=yes',
            success: function(data,Status) {
                $("#forumList").empty().append(data);
            },
            error: onError
        });
        return false;
    });

    $("#forumNewer").click(function(){
        $.ajax({
            type: "POST",
            url: "m/ajax/forum_list.php",
            cache: false,
            data: "forum_newer=yes",
            success: function(data,Status) {
                $("#forumList").empty().append(data);
            },
            error: onError
        });
        return false;
    });

    reloadForum();
};
