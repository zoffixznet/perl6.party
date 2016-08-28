package Perl5::Party::Posts;

use base 'Mojo::Base';

use Text::MultiMarkdown qw/markdown/;
use File::Glob qw/bsd_glob/;
use Mojo::Util qw/slurp  decode  encode  xml_escape/;

sub all {
    my @posts = bsd_glob 'post/*.md';
    s/\.md$// for @posts;
    my @return;
    for ( @posts ) {
        my $post = decode 'UTF-8', slurp "$_.md";
        my ($meta) = process($post);
        next if $meta->{draft};
        push @return, {
            name    => $_,
            date    => $meta->{date},
            title   => $meta->{title},
            desc    => $meta->{desc},
            link    => "/$_",
       };
    }
    return [ sort { $b->{date} cmp $a->{date} } @return ];
}

sub load {
    my ($self, $post) = @_;
    return unless -e "post/$post.md";
    my ($meta, $content) = process( decode 'UTF-8', slurp "post/$post.md" );
    $content = process_module_links(process_irc($content));
    return $meta, markdown $content =~ s/^```$//gmr;
}

sub process {
    my $post = shift;
    my %meta;
    $meta{ $1 } = $2 while $post =~ s/^%%\s*(\w+)\s*:\s*([^\n]+)\n//;
    return \%meta, $post;
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
