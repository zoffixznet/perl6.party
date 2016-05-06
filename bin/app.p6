use lib <lib>;

use experimental :cached;
use Bailador;
use Bailador::Template::Mojo::Extended;
use Bailador::Plugin::AssetPack::SASS;
use Bailador::Plugin::Static;
use Perl6::Party::Posts;
use GlotIO;

Bailador::Plugin::AssetPack::SASS.install;
Bailador::Plugin::Static.install;

app.location = '.';
renderer Bailador::Template::Mojo::Extended.new;

my GlotIO $glot .= new: :key<02fb41ba-78cd-44d8-9f30-2a28350000a8>;
my Perl6::Party::Posts $posts .= new;

get '/' => sub {
    _ctemplate 'index.tt', :posts($posts.all), :active-page<home>;
}

get '/about' => sub {
    _ctemplate 'about.tt', :posts($posts.all), :active-page<about>;
}

get rx{ ^ '/post/' (<[a..zA..Z0..9_.-]>+) $ } => sub (Str(Match:D) $name) {
    return status 404 unless .f and .r given "post/$name.md".IO;
    my ($meta, $post) = $posts.serve: "post/$name.md";
    _ctemplate 'post.tt',
        :posts($posts.all),
        :post($post),
        :post-title($meta<title>),
        :meta($meta),
        :title($meta<title>),
        :active-page('post');
}

post '/run' => sub {
    my $code = request.params<code> or return status 404;
    $code ~~ s:g/\c[ZERO WIDTH SPACE]//;
    say '----';
    say $code;
    my $ret = $glot.run: 'perl6', $code ~ "\n";
    say '----';
    my $out = trim join "\n", $ret<stdout> // Empty, $ret<stderr> // Empty;
    say $out;
    say '----';
    return $out;
}

baile;


sub _ctemplate (|c) is cached { template |c }
