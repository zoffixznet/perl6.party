$(function(){
    setup_title_anchors();
    setup_glot_io();
});

function setup_title_anchors() {
    $('article').find('h2:not(.blog-post-title),h3,h4,h5,h6').each(function(i, el){
        $(el).append(
            '<a href="#' + $(el).attr('id') + '" class="title-anchor">🔗</a>'
        );
    });
}

function setup_glot_io() {
    $('pre').each(function(i, el){
        var $el = $(el);
        var mirror = CodeMirror(el, {
            lineNumbers:    true,
            lineWrapping:   true,
            mode:           'perl6',
            scrollbarStyle: 'null',
            value:          $el.find('code').text().trim(),
            viewportMargin: Infinity
        });

        $el.find('code').text('')
        $el.append(
            '<div class="code-runner"><a class="btn btn-sm btn-primary">'
            + 'Run this code</a></div>'
        );

        mirror.on('focus',
            function (runner) {
                return function (mirror){
                    runner.find('a').slideDown();
                }
            }( $el.find('.code-runner') )
        );

        mirror.on('blur',
            function (runner) {
                return function (mirror){
                    runner.find('a').slideUp();
                }
            }( $el.find('.code-runner') )
        );
    });

    $('.code-runner').find('a').hide().end().each(function(i, el){
        $(el).click(function(){
            var code = '';
            $(this).prev().find('.CodeMirror-code .CodeMirror-line').each(
                function(i, el){
                    code += $(el).text() + "\n";
                }
            );

            console.log(code);

            jQuery.ajax('/run', {
                method: 'POST',
                success: function(data) {
                    $(el).find('p').remove();
                    $(el).append('<p>' + data + '</p>');
                },
                data: { code: code },
                error: function(req, error) {
                    $(el).find('p').remove();
                    $(el).append('<p> Error occured:' + error + '</p>');
                }
            });
        });
    });


}
