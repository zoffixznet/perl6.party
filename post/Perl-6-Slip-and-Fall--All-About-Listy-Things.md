%% title: Perl 6 Slip and Fall: All About Listy Things
%% date: 2016-04-25
%% desc: Learn to work with Slips, Arrays, and Lists
%% draft: True

Coming from Perl 5's marvelous
[Flatland](https://en.wikipedia.org/wiki/Flatland) where all listy things
auto-flatten, Perl 6's way of doing things always irked me. At times, it made
me want to smash my keyboard and call language designers idiots...

But language design is always a trade-off. Perl 5's chooses autoflattening
in exchange for the ability to "just pass" listy things, and Perl 6's
ability to do so means you have to explicitly slip things in when you do want
stuff to flatten.

However, my keyboard will remain unsmashed and I won't be namecalling either.
Today, I shall learn all about working with listy things in Perl 6,
and I'll tell you about it too, while I'm at it! Let's jump in.

## When Things Just Work™

A `List` in a `List` is a thing in Perl 6 and you don't need to think about it:

    my @foo = 1, 2, ('meow', moo'), 3, 4;
    dd @foo;

