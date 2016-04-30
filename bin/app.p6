use lib </home/zoffix/CPANPRC/Mojo-Extended/lib  lib>;

use Text::MultiMarkdown:from<Perl5> <markdown>;

use Bailador;
use Bailador::Plugin::AssetPack::SASS;
use Bailador::Plugin::Static;

Bailador::Plugin::AssetPack::SASS.install;
Bailador::Plugin::Static.install;

app.location = '.';

get '/' => sub { template 'index.tt' }
get rx{ ^ '/post/' (<[a..zA..Z0..9_-]>+) $ } => sub (Str(Match:D) $name) {
    my $post =  "posts/$name.md".IO;
    return status 404 unless $post.f;
    return markdown slurp $post;
}


get rx{ '/foo/meow/' (.+) } => sub { "second foo $^a" }
get rx{ '/foo/'      (.+) } => sub ($arg) { "first foo $arg" }


baile;
