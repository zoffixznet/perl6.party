%% title: The Hot New Language Named Rakudo
%% date: 2017-07-07
%% desc: A rose by any other name...
%% draft: true

*This article represents my own thoughts on the matter alone and is not an
official statement on behalf of the Rakudo team or, perhaps, is not even
representative of the majority opinion.*

----

When I came to Perl 6 around its first stable Christmas 2015 release,
"The Name Issue" was in hot debate. From what I understand, the debate raged on
for years prior to my arrival, so the topic always felt taboo to talk about,
because it always ended up in a heated discussion, without a solution at end.
However, we do need a solution.

At that time, the major argument I heard (and often peddled myself) for why
Perl 6 had 'Perl' in the name was because of brand recognition. The hypothesis
was that fewer people would bother to use an unknown language "Foo" than a
recognizable language "Perl". Now, two years later, we can examine whether that
hypothesis was true and act accordingly.

## Fo6.d for Thought

The Perl 6 language—to which I shall refer to as Rakudo language, for the
rest of the article—is versioned separately from its implementations and is
defined by [the specification](https://github.com/perl6/roast). The current
version is 6.c "Christmas" and the upcoming version is 6.d "Diwali"

As some know, despite slinging a lot of code in my spare time, I earn my
bread under the banner of *Multi-Media Designer*, and while one of the "media"
I care for is Web and so I do get to write some code once in a while, my office
for the past 8-ish years has been squarely in the *Marketing* Department, not
<abbr title="Information Technology">I.T</abbr>.

As the core team was recently penning down the dates for 6.d release, I got
excited to have the opportunity to do some design and marketing for something
different than products at my job. However, I very quickly hit a roadblock. The
name "Perl 6" isn't marketable.

Even ignoring trolls and people whose knowledge of Perl ends with the
line-noise quips, Perl is the Grandfather of Web, the Queen of Stability, and
Gluest language of all the Glues. Perl is installed by default on many systems,
and if you're worthy enough to wield its magic, it's quite damn performant.

Rakudo language, on the other hand, is *none* of those things. It's a young
and hip teenager who doesn't mind breaking long held status quo. Rakudo is the
King of Unicode and Queen of Concurrency. It's a "4th generation" language,
and if you take the time to learn its many features, it's quite damn concise.

Trying to market Rakudo language as a "Perl 6" language is like trying to win
in [Blackjack](https://en.wikipedia.org/wiki/Blackjack) while holding a great
[Poker](https://en.wikipedia.org/wiki/Poker) hand. The truly distinguishing
features don't get any attention, while at the same time people get
disappointed when a "Perl" language [no longer does](https://irclog.perlgeek.de/perl6/2017-06-29#i_14804470) things Perl used to do.

So did the hypothesis about Perl brand name recognition hold true? Yes, but
Rakudo language has very different strengths than those that brand represents.
Which leads to a lot of [confusion](https://www.reddit.com/r/programming/comments/6jzpyd/perl_6_seqs_drugs_and_rocknroll_part_2/dji747p/),
[disappointment](https://www.reddit.com/r/perl6/comments/6hagwm/performance_concern_with_respect_to_gnu_yes/), and
[annoyance](https://irclog.perlgeek.de/mojo/2017-06-04#i_14684821).

As the 6.d language release nears, I think it would behoove us to reflect on
the issues of the past two years and make a change for the better.

## "Just Rename It"

Even if the entire Rakudo community would decide the name change is good,
there's teenie-tiny problem of existing infrastructure. Need documentation?
You go to [perl6.org](https://perl6.org), not [rakudo.org](http://rakudo.org).
Need live squishy human help? You go to
[#perl6](https://webchat.freenode.net/?channels=#perl6) IRC channel, not
[#rakudo](https://webchat.freenode.net/?channels=#rakudo).
Need a Rakudo book? Why, then go to [perl6book.com](https://perl6book.com/)
and pick any of the books with "Perl 6" in their titles.

This is one of the major things that derailed my thinking on the subject
in the past: people saying "just rename it," when clearly it's no easy task.
Domain names, email addresses, bug trackers, Reddit subreddits, Facebook
groups, Twitter feeds, GitHub orgs, IRC channels, presentations, books, blog
posts, videos, hell, even names of some variables (`$*PERL`) and env
vars (`PERL6_TEST_DIE_ON_FAIL`) would all need to change for a thorough rename
job.

Not only would all those things need a rename, the old versions in many cases
would need to be able to redirect to the new name. Even "just renaming"
[perl6.party](https://perl6.party) website and its contents took me some effort
and incurred a monetary expense. The effort required to do the same everywhere
would be monumental.

I think the ship for "just renaming" it has sailed a few years before first
stable language release. However, we don't have to be at the mercy of
all-or-nothing tacticts, when there are clear benefits to reap from a name
tweak.

## Rakudo Perl 6

Rakudo is the name of a mature—and to date, the only one that's
usable—implementation of the language. If [Wikipedia](https://en.wikipedia.org/wiki/Rakudo_Perl_6) is to be believed, the name means
"The Way of The Camel" or "Paradise." It's a compiler. It's like
the [`gcc`](https://en.wikipedia.org/wiki/GNU_Compiler_Collection) in the world
of the `C` language.








