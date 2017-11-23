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
available in `does` only on bleeding edge Rakudo, version 2017.11-1-g47ebc4a and up)</i></small>:

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

That override will work even if we stick it into a module. We can also kick it up a notch
and mess with enums and cached constants, which likely won't be able to cross the module
boundary and other implementation-specific cache invalidation:

    True does False;
    say 42 ?? "tis true" !! "tis false";
    # OUTPUT: «tis true␤»

So far, that didn't quite have the wanted impact, but let's try coercing our number
to a `Bool`:

    True does False;
    say 42.Bool ?? "tis true" !! "tis false";
    # OUTPUT: «tis false␤»

There we go! And now, for the final Grinch-worthy touch, we'll mess with numerical
results of computations on numbers. Rakudo caches `Int` constants. Infix `+` operator
also uses the `.Bridge` method when computing with numerics of different types. So,
let's override the `.Bridge` on our constant to return something funky:

    BEGIN 42 does role { method Bridge { 12e0 } }
    say 42 + 15;   # OUTPUT: «57␤»
    say 42 + 15e0; # OUTPUT: «27␤»

That's proper evil, sure to ruin any Christmas, but we're only getting started…

## Wrapping It Up

What kind of Christmas would it be without wrapped presents?! Oh, for presents we shall have and Perl 6's `.wrap` method provided by `Routine` type will let us wrap 'em up.

    use soft;
    sub foo { say 'in foo' }
    &foo.wrap: -> | {
        say 'in the wrap';
        callsame;
        say 'back in the wrap';
    }
    foo;

    # OUTPUT:
    # in the wrap
    # in foo
    # back in the wrap

We enable `use soft` pragma to prevent unwanted inlining of routines that would interefere with out wrap. Then, we use a routine we want to wrap as a noun by using it with its `&` sigil and call the `.wrap` method that takes a `Callable`.

The given `Callable`'s signature must be compatible with the one on the wrapped routine (or its `proto` if it's a multi); otherwise we'd not be able to both dispatch to the routine correctly and call the wrapper with the args. In the example above, we simply use an anonymous `Capture` (`|`) to accept all possible arguments.

Inside the `Callable` we have two print statements and make use of [`callsame` routine](https://rakudo.party/post/Perl6-But-Heres-My-Dispatch-So-Callwith-Maybe) to call the next available dispatch candidate, which happens to be our original routine. This comes in handy, since attempting to call `foo` by its name inside the wrapper, we'd start the dispatch over from scratch, resulting in an infinite dispatch loop.

Since methods are `Routine`s, we can wrap them as well. We can get a hold of the `Method` object using `.^lookup` meta method:

    IO::Handle.^lookup('print').wrap: my method (|c) {
        my &wrapee = nextcallee;
        wrapee self, "🎄 Ho-ho-ho! 🎄\n";
        wrapee self, |c
    };

    print "Hello, World!\n";

    # OUTPUT:
    # 🎄 Ho-ho-ho! 🎄
    # Hello, World!

Here, we grab the `.print` method from `IO::Handle` type and `.wrap` it. We wish to make use of `self` inside the method, so we're wrapping using a standalone method (`my method …`) instead of a block or a subroutine. The reason we want to have `self` is to be able to call the very method we're wrapping to print our Christmas-y message. Because our method is detached, the [`callwith` and related routines](https://rakudo.party/post/Perl6-But-Heres-My-Dispatch-So-Callwith-Maybe) will need `self` fed to them along with the rest of the args, to ensure we continue dispatch to the right object. Incidentally, the `nextcallee` is the `proto` of the method (if it's a `multi`), not a specific candidate that best matches the original arguments, so [the next candidate ordering](https://rakudo.party/post/Perl6-But-Heres-My-Dispatch-So-Callwith-Maybe#haveyoutriedtocallthemwith...) is slightly different inside the wrap.

Thanks to the `.wrap`, we can alter or even completely redefine behaviour of subroutines and methods, which is sure to be jolly fun when your friends try to use them. Ho-ho-ho!


## Invisibility Cloak

The tricks we've played so far are wonderfully terrible, but they're just too obvious too… visible. Since Perl 6 has superb Unicode support, I think we can should search the Unicode characters for some fun mischief. In particular, we're looking for *invisible* characters that are NOT whitespace. Just one is sufficient for our purpose, but these four are fairly invisible on my computer:

    [⁠] U+2060 WORD JOINER [Cf]
    [⁡] U+2061 FUNCTION APPLICATION [Cf]
    [⁢] U+2062 INVISIBLE TIMES [Cf]
    [⁣] U+2063 INVISIBLE SEPARATOR [Cf]

Perl 6 supports custom terms and operators that can consist of any characters, except whitespace. Here's my patented Shrug Operator:

    sub infix:<¯\(°_o)/¯> {
        ($^a, $^b).pick
    }

    say 'Coke' ¯\(°_o)/¯ 'Pepsi';
    # OUTPUT: «Pepsi␤»

And here's a term, made out of non-identifier characters (we could've used the actual characters in the definition as well):

    sub term:«"\c[family: woman woman boy boy]"» {
        'All you need is loooove!'
    }

    say 👩‍👩‍👦‍👦; # OUTPUT: «All you need is loooove!␤»

With our invisible non-whitespace characters in hand, we can make *invisible operators and terms!*

    sub infix:«"\c[INVISIBLE TIMES]"» { $^a × $^b }
    my \r = 42;

    say "Area of the circle is " ~ π⁢r²;
    # OUTPUT: «Area of the circle is 5541.76944093239␤»

Let's make a `Jolly` module that will export some invisible terms and operators. We'll then sprinkle them into our Christmas-y friends' code:

    unit module Jolly;

    sub   term:«"\c[INVISIBLE TIMES]"» is export { 42 }
    sub  infix:«"\c[INVISIBLE TIMES]"» is export {
        $^a × $^b
    }
    sub prefix:«"\c[INVISIBLE SEPARATOR]"» (|) is looser(&[,]) is export {
        say "Ho-ho-ho!";
    }

We've used the same character for the term and the infix operator. That's fine, as Perl 6 has fairly strict expectation of terms being followed by operators and vice versa, so it'll know when we meant to use the term or when to use the infix operator. Here's the resultant Grinch code, along with the output it produces:

    ⁣say 42⁢⁢;

    # OUTPUT:
    # 1764
    # Ho-ho-ho!


That'll sure be fun to debug! Here's a list of characters in that line of code, for you to see where we've used our invisible goodies:

    .say for '⁣say 42⁢⁢;'.uninames;

    # OUTPUT:
    # INVISIBLE SEPARATOR
    # LATIN SMALL LETTER S
    # LATIN SMALL LETTER A
    # LATIN SMALL LETTER Y
    # SPACE
    # DIGIT FOUR
    # DIGIT TWO
    # INVISIBLE TIMES
    # INVISIBLE TIMES
    # SEMICOLON

## Ho-Ho-Ho

Productivity at Christmas time drops to a standstill. People have the holidays and the New Year on their minds. Wouldn't surprise me to see a whole bunch of `TODO` comments in all the codes. But what if we were able to detect and complain about them? There's nothing more Grinch-like than aborting program compilation whenever someone is feeling lazy!

Perl 6 has Slangs. It's an experimental feature that currently does not have an officially supported interface, however, for our purpose, it'll do just fine.

Using Slangs, it's possible to *lexically* mutate Perl 6's grammar and introduce language features and behaviour, just like a Perl 6 core developer would.

    BEGIN $*LANG.refine_slang: 'MAIN',
        role SomeExtraGrammar {
            token term:sym<meow> { 'This is not a syntax error' }
        },
        role SomeExtraActions {
            method EXPR (Mu $/) {
                say "Parsed expression: " ~ $/;
                nextsame
            }
        }

    This is not a syntax error;
    say 'hehe'

    # OUTPUT:
    # Parsed expression: This is not a syntax error
    # Parsed expression: 'hehe'
    # Parsed expression: say 'hehe'
    # hehe

The "experimental" part of the feature largely lies in having to rely on the structure of [core Grammar](https://github.com/rakudo/rakudo/blob/master/src/Perl6/Grammar.nqp) and [core Actions](https://github.com/rakudo/rakudo/blob/master/src/Perl6/Actions.nqp) and currently there's no guarantee that will remain unchanged.

For our naughty, Grinchy trick, we'll be modifying behaviour of comments and if we trace what calls [the comment token](https://github.com/rakudo/rakudo/blob/79390147ac6b874f7c01c5818520cc5b31bde042/src/Perl6/Grammar.nqp#L700-L702), we'll find it's actually part of [the `ws` token](https://github.com/rakudo/rakudo/blob/79390147ac6b874f7c01c5818520cc5b31bde042/src/Perl6/Grammar.nqp#L652-L666).

This complicates the matter slightly, as `ws` is such a base token that, along with `comp_unit`, `statementlist`, and `statement`, it can't be modified in the mainline (code outside routines and blocks). The reason is the Slang is loaded *after* the mainline is already being parsed using the stock version of these tokens. The tokens inside `statement` token can be changed even in the mainline, because `statement` token reblesses the grammar, but `ws` does not get such luxury.

But enough talk! Let's code:

    BEGIN $*LANG.refine_slang: 'MAIN', role {
        token comment:sym<todo> {
            '#' \s* 'TODO' ':'? \s+ <( \N*
            { die "Ho-ho-ho! I think you were meant to finish " ~ $/ }
        }
    }

    sub business-stuff {
        # TODO: business stuff
    }

    # OUTPUT:
    # ===SORRY!===
    # Ho-ho-ho! I think you were meant to finish business stuff

We use the `BEGIN` phaser to make the Slang modification happen at compile time, since we're trying to affect how further compilation is performed.

We added a new proto token `comment:sym<todo>` to core Perl 6 grammar that matches what a regular comment would match, except it also looks for the `TODO` our Christmas-y friends decided to leave around. The `\N*` atom captures whatever string the user typed after the TODO and the `<(` match capture marker tells the compiler to exclude the previously matched stuff in the token from the captured text inside the `Match` object stored in the `$/`.

At the end of the token, we simply use a codeblock to `die` with a message
that tells the user to finish up their TODO. Quite crafty!

Since we'd rather the user not notice our jolly tricks, let's stick the Slang into a module that's to be loaded by the module. We'll just make a slight tweak to the original code:

    # File: ./Jolly.pm6
    sub EXPORT {
        $*LANG.refine_slang: 'MAIN', role {
            token comment:sym<todo> {
                '#' \s* 'TODO' ':'? \s+ <( \N*
                { die "Ho-ho-ho! I think you were meant to finish " ~ $/ }
            }
        }

        Map.new
    }

    # File: ./script.p6
    use lib <.>;
    use Jolly;

    sub business-stuff {
        # TODO: business stuff
    }

    # OUTPUT:
    # ===SORRY!===
    # Ho-ho-ho! I think you were meant to finish business stuff

We want the slang to run at the compilation time of the script, not the module, so we removed the `BEGIN` phaser and instead stuck the code to be inside `sub EXPORT`, which will run when the module is `use`d. In our script, we now merely have to `use` the module and the Slang gets activated. Awesome!

## Conclusion

Today, we started off the 2017 Perl 6 Advent Calendar by being naughty Grinches and messing with users' programs. We mutated objects using `but` and `does` operators. Wrapped methods and subroutines with our custom routines that implemented extra features. Made invisible terms and operators. And even mutated the language itself to do our bidding.

Over the next 23 days, we'll see more Perl 6 Advent articles, so be sure to check back. And maybe, by the end of it all, our Grinchy hearts will grow three sizes…

-Ofun