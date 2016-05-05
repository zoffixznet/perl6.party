%% title: Comb It!
%% date: 2016-04-25

In Perl 5, I always appreciated the convenience of constructs like these two:

    my @things = $text =~ /thing/g;
    my %things = $text =~ /(key)...(value)/g;

You take some nice, predictable text, pop a regex next to it, and BOOM! You get
a nice list of things or a pretty hash. Magical!

There are some similarities to this construct in Perl 6, but if you're a new
programmer, with Perl 5 background, there might be some confusion. First,
using several captures doesn't result in nice hashes right off the bat. Second,
you don't get strings, you get [`Match` objects](http://docs.perl6.org/type/Match).

While Matches are fine, let's look at a tool more suited for the job:
[The `comb`](http://docs.perl6.org/routine/comb)

<img src="/assets/stock/20160425-Perl6-Comb-It.jpg" height=400>

## Plain 'Ol Characters

You can use `comb` as a subroutine or as a method. In its basic form, `comb`
simply breaks up strings into characters:

    'foobar moobar 駱駝道bar'.comb.join('|').say;
    'foobar moobar 駱駝道bar'.comb(6).join('|').say;

    # OUTPUT:
    # f|o|o|b|a|r| |m|o|o|b|a|r| |駱|駝|道|b|a|r
    # foobar| mooba|r 駱駝道b|ar

Without arguments, you get individual characters. Supply an integer and you'll
get a list of strings at most that many characters long, receiving a
shorter string when there are not enough characters left. This method is
also about 30x faster than using a regex for the job.

## Limits

You can also provide a second integer, the limit, to indicate that you want
at most that many items in the final list:

    'foobar moobar 駱駝道bar'.comb(1, 5).join('|').say;
    'foobar moobar 駱駝道bar'.comb(6, 2).join('|').say;

    # OUTPUT:
    # f|o|o|b|a
    # foobar| mooba

This applies to all forms of using `comb`, not just the one shown above.

## Counting Things

The `comb` also takes a regular [`Str`](http://docs.perl6.org/type/Str) as an
argument, returning a list of matches
containing... that string. So this is useful to get the total number the
substring appears inside a string:

    'The 🐈 ran after a 🐁, but the 🐁 ran away'.comb('🐈').Int.say;
    'The 🐈 ran after a 🐁, but the 🐁 ran away'.comb('ran').Int.say;

    # OUTPUT:
    # 1
    # 2

## Simple Matching

Moving onto the realm of [regexes](http://docs.perl6.org/language/regexes),
there are several ways to obtain what you want using `comb`. The simplest
way is to just match what you want. The entire match will be returned as an
item by the comb:

    'foobar moobar 駱駝道bar'.comb(/<[a..z]>+ 'bar'/).join('|').say;

    # OUTPUT:
    # foobar|moobar

The `bar` with [Rakuda-dō Japaneese characters](https://en.wikipedia.org/wiki/Rakudo_Perl_6#Name) did not match our `a` through
`z` character class and so was excluded from the list.

The wildcard match can be useful, but sometimes you don't want to include
the wildcard in the resulting strings... Well, good news!

## Limit What's Captured

You could use [look-around assertions](http://docs.perl6.org/language/regexes#Look-around_assertions) but an even simpler way is to
use `<(` and `)>` regex capture markers (`<(` is similar to `\K` in Perl 5):

    'moo=meow ping=pong'.comb(/\w+    '=' <( \w**4/).join('|').say; # values
    'moo=meow ping=pong'.comb(/\w+ )> '='    \w**4/).join('|').say; # keys

    # OUTPUT:
    # meow|pong
    # moo|ping

You can use one or the other or both of them.`<(` will exclude from the match
anything described before it and `)>` anything that follows it. That is,
`/'foo' <('bar')> 'ber'/`, will match things containing `foobarber`, but
the returned string from `comb` would only be string `bar`.

## Multi Captures

As powerful as `comb` has been so far, we still haven't seen the compliment
to Perl 5's way of fishing out key/value pairs out of text using regex. We
won't be able to achieve the same clarity and elegance, but we can still
use `comb`... we'll just ask it to give us [`Match` objects](http://docs.perl6.org/type/Match):

    my %things = 'moo=meow ping=pong'.comb(/(\w+) '=' (\w+)/, :match)».Slip».Str;
    say %things;

    # OUTPUT:
    # moo => meow, ping => pong

Let's break that code down:
it uses the same old `.comb` to look for a sequence of word characters, followed by
the `=` character, followed by another sequence of word characters. We use
`()` parentheses to capture both of those sequences in separate captures. Also,
notice we added `:match` argument to `.comb`, this causes it to return a list
of `Match` objects instead of strings. Next, we use two hyper operators (») to
first convert the `Matches` to [`Slips`](http://docs.perl6.org/type/Slip), which gives us a list of captures, but they're still `Match` objects, which is
why we convert them to [`Str`](http://docs.perl6.org/type/Str) as well.

An even more verbose, but much clearer, method is to use named captures instead
and then `.map` them into [`Pairs`](http://docs.perl6.org/type/Pair):

    my %things = 'moo=meow ping=pong'
        .comb(/$<key>=\w+ '=' $<value>=\w+/, :match)
        .map({ .<key> => .<value>.Str });
    say %things;

    # OUTPUT:
    # moo => meow, ping => pong

Lastly, an astute reader will rember I mentioned at the beginning that
simply using Perl 5's method
will result in a list of `Match` objects... the same `Match` objects we're
asking `.comb` to give us above. Thus, you can also write the above code like
this, without `.comb`:

    my %things = ('moo=meow ping=pong' ~~ m:g/(\w+) '=' (\w+)/)».Slip».Str;
    say %things;

    # OUTPUT:
    # moo => meow, ping => pong

## Conclusion

We've learned how break up a string into bits any way we want to. Be it one or more characters. Be it simple strings or regex matches. Be it partial captures
or multiple ones. You can use `comb` for all. Combined with [`.rotor`](http://blogs.perl.org/users/zoffix_znet/2016/01/perl-6-rotor-the-king-of-list-manipulation.html), the power is limitless.

The other thing we also are certain of: nothing beats Perl 5's concise
`my %things = $text =~ /(key)...(value)/g;`
