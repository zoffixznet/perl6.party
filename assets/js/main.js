$(function(){
    setup_glot_io();
});

function setup_glot_io() {
    var codes = $('.glot-code');
    if ( ! codes.length ) { return; }

    codes.each(function(i, el){
        $(el).find('button').click(function() {
            var code  = $(el).parent('.glot-code').find('textarea').val();
            $.post('http://localhost:3000/run',
                'code=say%20print(42)',
                function(data){alert("wtf?" + data)}
            );
            return false;
        })
    });
}