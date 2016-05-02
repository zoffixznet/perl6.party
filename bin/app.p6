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

my Perl6::Party::Posts $posts .= new;
get '/' => sub {
    template 'index.tt', :posts($posts.all)
}

get rx{ ^ '/post/' (<[a..zA..Z0..9_-]>+) $ } => sub (Str(Match:D) $name) {
    return status 404 unless .f and .r given "post/$name.md".IO;
    return $posts.serve: $name;
}

baile;
