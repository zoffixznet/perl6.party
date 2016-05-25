#!/usr/bin/env perl

use lib qw<lib>;
use Mojolicious::Lite;
use Mojo::UserAgent;
use Mojo::Util qw/slurp  trim/;
use Time::Moment;
use Perl5::Party::Posts;

use constant GLOT_KEY => '02fb41ba-78cd-44d8-9f30-2a28350000a8';
my $posts = Perl5::Party::Posts->new;
my $ua = Mojo::UserAgent->new;

app->config({ hypnotoad => { listen => ['http://*:3000'], proxy => 1 } });

plugin 'AssetPack' => { pipes => [qw/Sass JavaScript Combine/] };
app->asset->process( 'app.css' => 'sass/main.scss' );
app->asset->process( 'app.js' => qw{
        js/ie10-viewport-bug-workaround.js
        js/codemirror/codemirror.min.js
        js/codemirror/perl6-mode.js
        js/main.js
    }
);

### Routes

get '/about';

get '/' => sub {
    my $c = shift;
    $c->stash( posts => $posts->all );
} => 'index';

get '/post/#post' => sub {
    my $c = shift;
    my ($meta, $post) = $posts->load( $c->param('post') );
    $post or return $c->reply->not_found;
    $c->stash( %$meta, post => $post, title => $meta->{title} );
} => 'post';

post '/run' => sub {
    my $c = shift;
    my $code = $c->param('code')
        or return $c->reply->not_found;
    $code =~ s/\N{ZERO WIDTH SPACE}//g;

    $ua->post(
        'https://run.glot.io/languages/perl6/latest' => {
            'Content-type'  => 'application/json',
            'Authorization' => 'Token ' . GLOT_KEY,
        } => json => { files => [{ name => 'main.p6', content => $code }] }
        => sub {
            my ($ua, $tx) = @_;
            my $out = $tx->res->json;
            $out = trim join "\n", $out->{stdout} // (),
                $out->{stderr} ? "STDERR:\n$out->{stderr}" : ();
            $c->render( text => $out );
        },
    );

    $c->render_later;
};

any $_ => sub {
    my $c = shift;
    my $posts = [ map +{ %$_ }, @{ $posts->all } ];
    $_->{date} = blog_date_to_feed_date($_->{date}) for @$posts;

    my $blog_last_updated_date = $posts->[0]{date};
    $c->stash(
        posts       => $posts,
        last_update => $blog_last_updated_date,
        template    => 'feed',
        format      => 'xml',
    );
} for '/feed', '/feed/', '/feed/index', '/atom', '/atom/', '/atom/index';

get '/pull/*password' => sub {
    my $c = shift;

    return $c->reply->not_found
        unless $c->param('password') eq trim slurp 'pull-password';

    $c->render(
        text   => "Pulled!\n" . `git pull`,
        format => 'txt',
    );
};

app->start;

sub blog_date_to_feed_date {
    my $date = shift;
    return Time::Moment->from_string("${date}T00:00:00Z")
        ->strftime("%a, %d %b %Y %H:%M:%S %z");
}