%% title: But Here's My Dispatcher, So callwith Maybe
%% date: 2017-03-28
%% desc: All about nextwith, nextsame, samewith, callwith, and callsame
%% draft: True

One of the great features of Perl 6 is multi-dispatch. It lets you use the
same name for your functions, methods, or Grammar tokens and let the type of
data they're called with or asked to match to determine which version gets
executed:

```
    multi fact (0) { 1 }
    multi fact (UInt \n) { n × samewith n − 1 }

    say fact 5

    # OUTPUT: 120
```

While the subject is broad and [there are some docs on it](https://docs.perl6.org/language/functions#Multi-dispatch), there are five special routines I'd
like to talk about that let you navigate the dispatch-inal maze. They're
`nextwith`, `nextsame`, `samewith`, `callwith`, and `callsame`.

## Setup The Lab

The candidates in multi-dispatch are tried from narrowest to widest, but
sometimes you may wish to retry with a different value, or use another
candidate from that dispatch chain. To observe that effect, we'use a group
of three multi candidates starting from the narrowest, an `Int`, going wider
to `Cool`, and widest still the candidate that takes values of `Any` type. We
use a [`.flip`ped](https://docs.perl6.org/routine/flip) value of `$x` as the
last statement of the routines so its value gets returned from them; but we
won't use it just yet:

```
    multi foo (Int  $x) { say "Int  [$x]"; $x.flip }
    multi foo (Cool $x) { say "Cool [$x]"; $x.flip }
    multi foo (Any  $x) { say "Any  [$x]"; $x.flip }

    foo 42;         # OUTPUT: Int  [42]
    foo "Blah";     # OUTPUT: Cool [Blah]
    foo Date.today; # OUTPUT: Any  [2017-03-28]
```

While inside of these routines we can call `nextwith`, `nextsame`, `samewith`,
`callwith`, or `callsame` to call another candidate with either the same
arguments or another set of arguments. Let's first figure out which one does
what...

## The Subject

The naming of the five routines follows this convention:

|  **Name**  |                       **Explanation**                                                                |
| `call____` | **call** next matching candidate in the chain (and return back here)                                 |
| `next____` | just go to **next** matching candidate in the chain (don't return)                                   |
| `____same` | use the **same** arguments as used for current candidate                                             |
| `____with` | make the operation **with** these new arguments I'm giving                                           |
| `samewith` | make the **same** call from scratch, from the start of dispatch chain, **with** these new arguments. |

The `samesame` is not a thing, as that case is best replaced by a regular loop.
The main takeaway is "call" means you call the candidate and come back and
use its return value or do more things; "next" means to just proceed to the next
candidate and not return. And `same` and `with` at the end simply control whether
you want to use the same args or provide a new set.

Let's play with these!

## It's all called the same...

The first to try out is `callsame`. It **call**s the next matching with the
**same** arguments used for the current candidate and returns that candidate's
return value:

```
    multi foo (Int  $x) { say "Int  [$x]"; $x.flip }
    multi foo (Cool $x) {
        say "Cool [$x]";
        my $v = callsame;
        say "We're back! The return value is $v";
        $x.flip
    }
    multi foo (Any  $x) { say "Any  [$x]"; $x.flip }

    foo 42;         # OUTPUT: Int  [42]
    foo Date.today; # OUTPUT: Any  [2017-03-28]
```

So far the output looks just like before. That's because `42` hits our `Int`
candidate and the `Date` object hits the `Any` candidate. Let's try calling
the `Cool` candidate now:

```
    multi foo (Int  $x) { say "Int  [$x]"; $x.flip }
    multi foo (Cool $x) {
        say "Cool [$x]";
        my $v = callsame;
        say "We're back! The return value is $v";
        $x.flip
    }
    multi foo (Any  $x) { say "Any  [$x]"; $x.flip }

    foo "I ♥ Perl 6!";

    # OUTPUT:
    # Cool [I ♥ Perl 6!]
    # Any  [I ♥ Perl 6!]
    # We're back! The return value is !6 lreP ♥ I
```

Now something's happening! From the output, we can see we entered the `Cool`
candidate, then, thanks to `callsame`, we entered the `Any` candidate giving
it the same arguments as the `Cool` candidate was given. And finally, we
print out the returned value from `callsame`, which is the return value
from the `Any` candidate that just flipped our argument.

So far so clear, let's try modifying the arguments!

## These don't look that good, instead try calling with...

As we've learned, the `__with` variants let us use different args. They can
be anything you want, so if it's perfectly OK to call a candidate that takes
3 arguments from a candidate that takes just 1. Let's try `callwith` with our
familiar setup:

```
    multi foo (Int  $x) { say "Int  [$x]"; $x.flip }
    multi foo (Cool $x) {
        say "Cool [$x]";
        my $v = callwith 42;
        say "We're back! The return value is $v";
        $x.flip
    }
    multi foo (Any  $x) { say "Any  [$x]"; $x.flip }

    foo "I ♥ Perl 6!";

    # OUTPUT:
    # Cool [I ♥ Perl 6!]
    # Any  [42]
    # We're back! The return value is 24
```

We've used `callwith 42` to use `42` as the argument, instead of the orginal
string we received. However, the output doesn't quite check out, does it? We
*do* have an `Int` candidate, so how come the output shows our `callwith`
called the `Any` candidate instead?

This has to do with the dispatchee chain. When our original
`foo "I ♥ Perl 6!"` was dispatched, it looked at the `Int` candidate and it
wasn't good enough, so it went further up the chain to the next wider candidate,
which is our `Cool` candidate with the `callwith` routine in it. Since it doesn't
start the dispatch from scratch and instead uses the next matching candidate,
it gets to the wider-still `Any` and *not* the `Int` candidate.

The output shows the `Any` candiate was called with the `42` we gave to
`callwith` and not the original `"I ♥ Perl 6!"` string. The rest of the output
follows a similar pattern: we got the flipped return value back and printed it
out.
