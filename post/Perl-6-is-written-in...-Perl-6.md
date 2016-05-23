%% title: Perl 6 is written in... Perl 6
%% date: 2016-01-22
%% desc: Discussion of Rakudo Perl 6 compiler's implementation.

Today, I've done something strange.

No, there weren't drugs involved, I merely sent a patch for Rakudo for a bug I reported a few weeks back. But the patch is... interesting.

First, about the "bug." Newest JSON spec lets you have anything as the top level thing. I spotted a few modules in the [Perl 6 ecosystem](http://modules.perl6.org/) that still expected an object or an array only, and the vendor-specific (possibly to be made hidden in the future) `to-json` subroutine provided by core Rakudo behaved the same as well.

One of the modules got fixed right away and today, seeing as there were no takers, I went in to fix the bug in Rakudo myself. Since I'm a lazy bum, I merely went in to that one fixed module and just copied the fix over!

But wait a second... ain't the Perl 6 module written in Perl 6? How did I manage to "just copy it over"? What sorcery is this! Surely you lie, good sir!

Here are the Rakudo and the module patches one above the other. Try to figure out which one is for Rakudo:

<img alt="source2.png" src="http://blogs.perl.org/users/zoffix_znet/source2.png" width="532" height="904" class="mt-image-none" style="" />

Give up yet? The code above the black bar is the [patch made in JSON::Tiny module](https://github.com/rakudo/rakudo/pull/687/files) and the code below it is the [patch I made for Rakudo](https://github.com/rakudo/rakudo/pull/687/files).

As surprising and amazing as it is, most of Perl 6 is actually written in Perl 6! The [NQP (Not Quite Perl)](https://github.com/perl6/nqp) provides the bricks and the mortar, but when it comes to the drywall, paint, and floorboards, you're full in the Perl 6 territory.

## So what does this all mean?

I'm not a genius programmer and I'm quite new to Perl 6 too, but I was able to send in a patch *for the Perl 6 compiler* that fixes something. And it's not even the first time [I sent some Perl 6 code](https://github.com/rakudo/rakudo/pull/635/files) to improve Rakudo. Each one of the **actual users of Perl 6** can fix bugs, add features, and do optimizations. For the most part, there's no need to learn some new arcane thing to hack on the innards of the compiler.

Imagine if to fix your car or to make it more fuel efficient, all you had to do was learn how to drive; if to rewire your house, all you had to do is learn how to turn on TV or a toaster; if to become a chef, all you had to do was enjoy a savory steak once in a while. And not only the users of Perl 6 are the potential guts hackers, they also have *direct interest* in making the compiler better.

So to the [speculations on the potential Perl 6 Killer App](http://blogs.perl.org/users/jt_smith/2016/01/perl-6s-killer-app---async.html), I'll add that one of the Perl 6's killer apps is Perl 6 itself. And for those wishing to add *"programming a compiler"* onto their résumés, simply clone [the Rakudo repo](https://github.com/rakudo/rakudo) and go to town on it... there are [plenty of bugs to squish](http://rt.perl.org).
