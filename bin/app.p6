use lib <lib>;

use Bailador;
use Bailador::Template::Mojo::Extended;
use Bailador::Plugin::AssetPack::SASS;
use Bailador::Plugin::Static;
use Perl6::Party::Posts;

Bailador::Plugin::AssetPack::SASS.install;
Bailador::Plugin::Static.install;

app.location = '.';
renderer Bailador::Template::Mojo::Extended.new;

use experimental :cached;
sub _ctemplate (|C) is cached { template |C }

my Perl6::Party::Posts $posts .= new;
get '/' => sub {
    _ctemplate 'index.tt', :posts($posts.all), :active-page<home>;
}

get '/about' => sub {
    _ctemplate 'about.tt', :posts($posts.all), :active-page<about>;
}

get rx{ ^ '/post/' (<[a..zA..Z0..9_-]>+) $ } => sub (Str(Match:D) $name) {
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

baile;
