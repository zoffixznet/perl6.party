package Perl5::Party::Posts;

use base 'Mojo::Base';

use Text::MultiMarkdown qw/markdown/;
use File::Glob qw/bsd_glob/;
use Mojo::File qw/path/;
use Mojo::Util qw/decode  encode  xml_escape/;

sub all {
    my @posts = bsd_glob 'post/*.md';
    s/\.md$// for @posts;
    my @return;
    for ( @posts ) {
        my $post = decode 'UTF-8', path("$_.md")->slurp;
        my ($meta) = process($post);
        next if $meta->{draft};
        push @return, {
            name    => $_,
            date    => $meta->{date},
            title   => $meta->{title},
            desc    => $meta->{desc},
            words   => $meta->{words},
            link    => "/$_",
       };
    }
    return [ sort { $b->{date} cmp $a->{date} } @return ];
}

sub load {
    my ($self, $post) = @_;
    return unless -e "post/$post.md";
    my ($meta, $content) = process( decode 'UTF-8', path("post/$post.md")->slurp );
    $content =
                process_sub_links(
                    process_type_links(
                        process_module_links(
                            process_irc($content))));

    $content =~ s/^```$//gm;
    my $prefix = '<a href="https://rakudo.party/post/' . $post
        . '" style="display: block; background: #ccc; border-radius: 3px; '
        . 'font-size: 110%; border: 1px dotted #666; text-align: center; '
        . 'padding: 10px 5px;">Read this article on Rakudo.Party</a>'
        . "\n\n<!-- no-perly-bot -->\n\n";
    return $meta, "$prefix$content", markdown $content;
}

sub process {
    my $post = shift;
    my %meta;
    $meta{ $1 } = $2 while $post =~ s/^%%\s*(\w+)\s*:\s*([^\n]+)\n//;
    $meta{words} = () = $post =~ /\s+/g;
    return \%meta, $post;
}

sub process_sub_links {
    my $content = shift;
    $content =~ s{``((?:\.|[a-z])[^`|]+)(?:\|([^`]+))?``}{
        my $text = $1;
        my $optional = $2 // "";
        (my $routine = $1) =~ s/^\.//;
        "[`$text`$optional](https://docs.perl6.org/routine/$routine)"
    }ger;
}
sub process_type_links {
    my $content = shift;
    $content =~ s{``([A-Z][^`|]+)(?:\|([^`]+))?``}{
        my $type = $1;
        my $optional = $2 // "";
        "[`$type`$optional](https://docs.perl6.org/type/$type)"
    }ger;
}

sub process_module_links {
    my $content = shift;

    return $content =~ s{
        ``
        P   (?<lang> [65]):
        (?: (?<optional_text> .+?) `` )??
            (?<module_name> [^` ]+ )
        ``
    }{
        my $text = $+{optional_text} // '`' . $+{module_name} . '`';
        my $url  = $+{lang} eq '6' ? 'https://modules.perl6.org/dist/'
                                   : 'https://metacpan.org/pod/';

        "[$text]($url" . $+{module_name} . ")";
    }gexr;
}

sub process_irc {
    my $content = shift;
    my $in_irc = 0;
    my @new_content;
    for ( split /\n/, $content ) {
        unless ( $in_irc or /^```irc/ ) {
            push @new_content, $_;
            next;
        }

        if ( /^```irc/ ) { $in_irc = 1; next; }
        if ( /^```/    ) { $in_irc = 0; next; }

        if ( # IRC actions
            s{^ \* \s+ (\S+)  (.+) }{"<b>* $1</b>"        . xml_escape $2}xe
        ) {}
        elsif ( # alt IRC nick
            s{^  <\|([^>]+)> \s (.+) }{
                "<b class='irc-alt'>&lt;$1&gt;</b> " . xml_escape $2
            }xe
        ) {}
        elsif ( # IRC nick
            s{^  <([^>]+)> \s (.+) }{"<b>&lt;$1&gt;</b> " . xml_escape $2}xe
        ) {}
        else  { $_ = ('&nbsp;' x 4) . xml_escape $_ }

        s/^/> /;
        s/$/<br>/;

        push @new_content, $_;
    }
    return join "\n", @new_content;
}

1;
