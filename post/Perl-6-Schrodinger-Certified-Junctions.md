%% title: Perl 6's Schrödinger-Certified Junctions
%% date: 2016-09-05
%% desc: Using Junction types in Perl 6
%% draft: True

[Erwin Schrödinger](https://en.wikipedia.org/wiki/Erwin_Schr%C3%B6dinger) would
have loved Perl 6, because the famous [cat
gedanken](https://en.wikipedia.org/wiki/Schr%C3%B6dinger%27s_cat) can be
expressed in a Perl 6 [Junction](https://docs.perl6.org/type/Junction):

    my $cat = 'dead' | 'alive';
    say "cat is dead"  if $cat eq 'dead';
    say "cat is alive" if $cat eq 'alive';

    # OUTPUT:
    # cat is dead
    # cat is alive

What's happening here? I'll tell ya all about it!

## 
