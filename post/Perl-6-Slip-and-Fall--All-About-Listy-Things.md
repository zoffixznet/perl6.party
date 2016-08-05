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
and I'll tell you about it too, while I'm at it!

## Before We Begin

Perl 6 has multiple listy types. There are
[`Seq`](https://docs.perl6.org/type/Seq),
[`Range`](https://docs.perl6.org/type/Range),
[`List`](https://docs.perl6.org/type/List),
[`Array`](https://docs.perl6.org/type/Array),
[`Slip`](https://docs.perl6.org/type/Slip), as well as their subclasses
or things that do [`Positional`](https://docs.perl6.org/type/Positional)
and [`Iterable`](https://docs.perl6.org/type/Iterable).

You get the idea, there's lots of stuff. To keep the eye on the ball, I won't
bother trying to differentiate between them at all times and will use word
'list' as a catch-all sort of thing. When difference is important, I'll
use the proper type name, such as `List`. Let's jump in!

## When Things Just Work™

A list in a list is a thing in Perl 6 and you don't need to think about it:

    dd my @foo = 1, 2, ('meow', 'moo'), 3, 4;

    # OUTPUT:
    # Array @foo = [1, 2, ("meow", "moo"), 3, 4]

And so is a list in a list in a list in a list in a list in a list...

    dd my @foo = 1, (2, (3, (4, (5, (6,)))));
    say @foo[1][1][1][1][1].WHAT;

    # OUTPUT:
    # Array @foo = [1, (2, (3, (4, (5, (6,)))))]
    # (List)

I did not typo that comma after the `6`, it's making that last list with
`6` in it a list. And so comes the first rule: commas make lists, not
parentheses. The parentheses are there just for grouping. If you need a list
with just one item in it, pop a comma after it.

It's a bit hard to see the effect with the `@`-sigiled variables, so let's see
an alternative.

## That's a Tight Fit

    dd my $foo = (1, 2, ('meow', 'moo'), 3, 4);

    # OUTPUT:
    # List $foo = $(1, 2, ("meow", "moo"), 3, 4)

The `$` sigil doesn't mean you can store just "one" thing in it, as
can be the case in some other sigiled languages. Or rather,
we *are* storing just one thing in it: the `List` object. And now we can
observe the comma effect more closely:

    dd my $foo1 =  1;
    dd my $foo2 = (1);
    dd my $foo3 = (1,);

    # OUTPUT:
    # Int $foo1 = 1
    # Int $foo2 = 1
    # List $foo3 = $(1,)


The comma is on the third line and it's the third line of output that
gives us a `List` instead of an `Int`. So, naturally the question then
becomes... what the hell is `@` for anyway?



# Rules

1. Commas make lists, not parentheses