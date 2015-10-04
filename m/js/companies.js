function companiesInit() {
    // $Id: companies.js 100 2012-07-02 06:49:16Z paul $
    $('.collHead').click(function() {$(this).parent().find('.collDetail').slideToggle();$(this).find('i').toggleClass('icon-plus-sign icon-minus-sign');});
    $('.tabHead').click(function() {
        var det = $(document).find(".collHead:contains('"+$(this).text()+"')");
        det.parent().find(".collDetail").slideToggle();
        det.find('i').toggleClass('icon-plus-sign icon-minus-sign');
    });
};
