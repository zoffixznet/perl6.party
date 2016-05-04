unit class Perl6::Party::Posts;

use Text::MultiMarkdown:from<Perl5> <markdown>;
use File::Find;

method all {
    my @posts = find :dir<post>, :name(/ '.md' $/);
    s/'.md' $// for @posts;
    my @return;
    for @posts {
        my $post = "$_.md".IO.slurp;
        my ($meta, $content) = process $post;
        next if $meta<draft>;
        @return.push: %(
            name    => $_,
            date    => $meta<date>,
            title   => $meta<title>,
            link    => "/$_",
            content => markdown( abridge-content $content ),
       );
    }
    return @return.sort: *<date>;
}

method serve ($post) {
    my ($meta, $content) = process $post.IO.slurp;
    return ($meta, markdown $content);
}

sub abridge-content ($text) {
    my $out = '';
    for $text.lines {
        last if $out.chars > 1000;
        $out ~= "\n$_";
    }
    return markdown $out;
}

sub process ($post is copy) {
    my %meta;
    %meta{ $0 } = ~$1 while $post ~~ s/^ '%%' \s* (\w+)\s* ':' \s* (\N+) \n//;
    return (%meta, $post);
}
