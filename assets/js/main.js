$(function(){
    setup_title_anchors();
    setup_glot_io();
});

function setup_title_anchors() {
    $('article').find('h1,h2,h3,h4,h5,h6').each(function(i, el){
        $(el).append(
            '<a href="#' + $(el).attr('id') + '" class="title-anchor">🔗</a>'
        );
    });
}

function setup_glot_io() {
    $('pre').each(function(i, el){
        var $el = $(el);
        CodeMirror(el, {
            lineNumbers:    true,
            lineWrapping:   true,
            mode:           'perl6',
            scrollbarStyle: 'null',
            value:          $el.find('code').text().trim(),
            viewportMargin: Infinity
        });

        $el.find('code').text('')
        $el.append('<div class="code-runner"><a>Run code</a><p></p></div>');
    });

    $('.code-runner').each(function(i, el){
        $(el).click(function(){
            var code = '';
            $(this).prev().find('.CodeMirror-code .CodeMirror-line').each(
                function(i, el){
                    code += $(el).text() + "\n";
                }
            );
            alert(code);
        })
    });
}