use lib
    # '/home/zoffix/CPANPRC/Bailador-Plugin-Static/lib',
    # '/home/zoffix/CPANPRC/AssetPack',
    'lib';

use experimental :cached;
use Bailador::App;
use Bailador::Template::Mojo::Extended;
use Bailador::Plugin::AssetPack::SASS;
use Bailador::Plugin::Static;
use Perl6::Party::Posts;
use GlotIO;
use HTTP::Easy::PSGI;

my GlotIO $glot .= new: :key<02fb41ba-78cd-44d8-9f30-2a28350000a8>;
my Perl6::Party::Posts $posts .= new;

class Party is Bailador::App {
    submethod BUILD(|) {
        self.location = '.';
        self.renderer = Bailador::Template::Mojo::Extended.new;

        Bailador::Plugin::AssetPack::SASS .install: self;
        Bailador::Plugin::Static          .install: self;

        self.get: '/' => sub {
            _ctemplate self, 'index.tt', :posts($posts.all), :active-page<home>;
        }

        self.get: '/about' => sub {
            _ctemplate self, 'about.tt', :posts($posts.all), :active-page<about>;
        }

        self.get: rx{ ^ '/post/' (<[a..zA..Z0..9_.-]>+) $ } => sub (Str(Match:D) $name) {
            return self.response.code: 404 unless .f and .r given "post/$name.md".IO;
            my ($meta, $post) = $posts.serve: "post/$name.md";
            _ctemplate self, 'post.tt',
                :posts($posts.all),
                :post($post),
                :post-title($meta<title>),
                :meta($meta),
                :title($meta<title>),
                :active-page('post');
        }

        self.post: '/run' => sub {
            my $code = self.request.params<code> or return self.response.code: 404;
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
    }

    sub _ctemplate ($self, |c) { $self.template: |c }
}

given HTTP::Easy::PSGI.new(:host<0.0.0.0>, :3000port) {
    .app(Party.new.get-psgi-app);
    say "Entering the development dance floor: http://0.0.0.0:3000";
    .run;
}
