The Grinch of Perl 6: A Practical Guide to Ruining Christmas

*Look at them! All smiling and happy. Coworkers, friends, and close family members. All enjoying programming in Perl 6 version 6.c "Christmas". Great concurrency primitives, core grammars, and a fantastic object model. It sickens me!*

*But wait a second... wait just a second. I got an idea. An awful idea. I got a wonderful, *awful* idea! We can ruin their "Christmas". All we need is a few tricks up our sleeves. Muahuahahaha!!*

-------

Welcome to the 2017th Perl 6 Advent Calendar! Each day, from today until Christmas, we'll have an awesome blog post about Perl 6 lined up for you.

Today, we'll show our naughty side and purposefully do naughty things. Sure, these have good uses, but being naughty is a lot more fun. Let's begin!

## But True does False

Have you heard of the `but` operator? A fun little thing:

    say True but False ?? 'Tis true' !! 'Tis false';
    # OUTPUT: «Tis false␤»

    my  $n = 42 but 'forty two';
    say $n;     # OUTPUT: «forty two␤»
    say $n + 7; # OUTPUT: «49␤»

It's an infix operator that first clones the object on the left hand side
and then mixes in a role provided on the right hand side into the clone:

    my $n = 42 but role Evener {
        method is-even { self %% 2 }
    }
    say $n.is-even; # OUTPUT: «True␤»
    say $n.^name;   # OUTPUT: «Int+{Evener}␤»

Those aren't roles in the first two examples above. The `but` operator has a handy shortcut: if the thing on the right isn't a role, it creates one for you! The role will have a single method, named after the `.^name` of the object on the right hand side, and the method will simply return the given object. Thus, this…

    put True but 'some boolean'; # OUTPUT: «some boolean␤»

…is equivalent to:

    put True but role {
        method ::(BEGIN 'some boolean'.^name) {
            'some boolean'
        }
    } # OUTPUT: «some boolean␤»

The `.^name` of on our string returns `Str`, since it's a `Str` object:

    say 'some boolean'.^name; # OUTPUT: «Str␤»

And so the role provides method named `Str`, which `put` calls to obtain
a stringy value to output, causing our boolean to have an altered stringy representation.

As an example string `'0'` is `True` in Perl 6 but is `False` in Perl 5. Using the `but` operator, we can alter a string to behave like Perl 5's version:

    role Perl5Str {
        method Bool {
            nextsame unless self eq '0';
            False
        }
    }
    sub perlify { $^v but Perl5Str };

    say so perlify 'meows'; # OUTPUT: «True␤»
    say so perlify '0';     # OUTPUT: «False␤»
    say so perlify '';      # OUTPUT: «False␤»

The role provides the `Bool` method that the `so` routine calls. Inside the method,
we re-dispatch to the original `Bool` method using
[`nextsame` routine](https://rakudo.party/post/Perl6-But-Heres-My-Dispatch-So-Callwith-Maybe)
unless the string is a '0', in which case we simply return `False`.


The `but` operator has a brother: an infix `does` operator. It behaves very similarly, except
it does *not* clone <small><i>(N.B.: the shortcut for automatically making roles from non-roles is
available only on bleeding edge Rakudo, version 2017.11-1-g47ebc4a and up)</i></small>:

    my $o = class { method stuff { 'original' } }.new;
    say $o.stuff; # OUTPUT: «original␤»

    $o does role { method stuff { 'modded' } };
    say $o.stuff; # OUTPUT: «modded␤»

Some of the things in a program are globally accessible and in some implementations (e.g. Rakudo),
certain constants are cached. This means we can get quite naughty in a separate part of a program
and those Christmas celebrators won't eve know what hit 'em! How about, we override what the
`prompt` routine reads? They like Christmas? We'll give them some Christmas trees:

    $*IN does role { method get { "🎄 {callsame} 🎄" } }

    say "You entered your name as: {prompt "Enter your name: "}";
    
    # OUTPUT (first occurance of "Zoffix Znet" is input typed by the user"):
    # Enter your name: Zoffix Znet
    # You entered your name as: 🎄 Zoffix Znet 🎄

We can stick our override into a separate module. It doesn't have to be in the same lexical
scope. 
