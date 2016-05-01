unit class Perl6::Party::Posts;

use Text::MultiMarkdown:from<Perl5> <markdown>;
use File::Find;

method all {
    my @posts = find :dir<post>, :name(/ '.md' $/);
    s/'.md' $// for @posts;
    return @posts.map: {%(
            name => $_,
            title => meta-for($_)<title>,
            link => "/$_",
            content => markdown( abridge-content(content($_)) ),
        )};
}

method serve ($post) {
    return markdown content "post/$post";
}

sub abridge-content ($text) {
    my $out = '';
    for $text.lines {
        last if $out.chars > 1000;
        $out ~= "\n$_";
    }
    return $out;
}

sub meta-for ($post) {
    my $post-content = "$post.md".IO.slurp;
    my %meta;
    %meta{ $0 } = ~$1 while $post-content ~~ s/^ '%%' \s* (\w+)\s* ':' \s* (\N+) \n//;
    return %meta;
}

sub content ($post) {
    my $post-content = "$post.md".IO.slurp;
    my %meta;
    %meta{ $0 } = ~$1 while $post-content ~~ s/^ '%%' \s* (\w+)\s* ':' \s* (\N+) \n//;
    return $post-content;
}

