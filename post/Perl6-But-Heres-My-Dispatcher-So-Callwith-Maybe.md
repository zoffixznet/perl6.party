%% title: But Here's My Dispatch, So callwith Maybe
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
`nextwith`, `nextsame`, `samewith`, `callwith`, `callsame`, `nextcallee`, and
`lastcall`.

## Setup The Lab

Multies get sorted from narrowest to widest candidate and when a multi is called, the binder tries to find a match and calls the first matching
candidate. Sometimes, you may wish to call or simply move to the next matching candidate in the chain, optionally using different arguments. To observe these effects, we'll use the following setup:


```
    class Wide             { }
    class Middle is Wide   { }
    class Narrow is Middle { }

    multi foo (Narrow $v) { say 'Narrow ', $v; 'from Narrow' }
    multi foo (Middle $v) { say 'Middle ', $v; 'from Middle' }
    multi foo (Wide   $v) { say 'Wide   ', $v; 'from Wide'   }

    foo Narrow; # OUTPUT: Narrow (Narrow)
    foo Middle; # OUTPUT: Middle (Middle)
    foo Wide;   # OUTPUT: Wide   (Wide)
```

We have three classes, each inheriting from the previous one, so that way
our `Narrow` class can fit into both `Middle` and `Wide` candidates; `Middle`
can also fit into `Wide`, but not `Narrow`; and `Wide` fits neither
into `Middle` nor into `Narrow`. Remember that all three of these classes
are of type `Any` as well, and so will fit into any candidate that accepts an
`Any`.

For our Callables, we use three multi candidates for routine `foo`:
one for each of the classes.
In their bodies, we print what type of multi we called, along with the
value that was passed as the argument. For the return value, we just use
a string that tells us which multi the return value came from; we'll use these
a bit later.

Finally, we make three calls to routine `foo`, using three type objects with
our custom classes. From the output, we can see each of the three candidates
got called as expected.

This is all plain and boring. However, we can spice it up! While inside of these routines we can call `nextwith`, `nextsame`, `samewith`,
`callwith`, or `callsame` to call another candidate with either the same or different arguments. But first, let's figure out which one does what...

## The Subject

The naming of the five routines follows this convention:

- `call____` — **call** next matching candidate in the chain
    (and return back here)
`next____` — just go to **next** matching candidate in the chain (don't return)
`____same` — use the **same** arguments as used for current candidate
`____with` — make the operation **with** these new arguments I'm giving
`samewith` — make the **same** call from scratch, from the start of dispatch
    chain, **with** these new arguments.

The `samesame` is not a thing, as that case is best replaced by a regular loop.
The main takeaway is "call" means you call the candidate and come back and
use its return value or do more things; "next" means to just proceed to the
next candidate and not return. And `same` and `with` at the end simply control
whether you want to use the same args or provide a new set.

Let's play with these!

## It's all called the same...

The first to try out is `callsame`. It **call**s the next matching with the
**same** arguments used for the current candidate and returns that candidate's
return value.

Let's modify our `Middle` candidate to call `callsame` and then print out
its return value:

```
    class Wide             { }
    class Middle is Wide   { }
    class Narrow is Middle { }

    multi foo (Narrow $v) { say 'Narrow ', $v; 'from Narrow' }
    multi foo (Middle $v) {
        say 'Middle ', $v;
        my $result = callsame;
        say "We're back! The return value is $result";
        'from Middle'
    }
    multi foo (Wide   $v) { say 'Wide   ', $v; 'from Wide'   }

    foo Middle;

    # OUTPUT:
    # Middle (Middle)
    # Wide   (Middle)
    # We're back! The return value is from Wide
```

We can now see that our single `foo` invocation resulted in two calls. First
to `Middle`, since it's the type object we gave to our `foo` call. Then, to
`Wide`, as that is the next candidate that can take a `Middle` type; in the
output we can see that `Wide` was still called with our original `Middle`
type object. Lastly, we returned back to our `Middle` candidate, with the
`$result` variable set to `Wide` candidate's return value.

So far so clear, let's try modifying the arguments!

## Have you tried to call them with...

As we've learned, the `__with` variants let us use different args. We'll use
the same code as in the previous example, except now we'll execute `callwith`,
using the `Narrow` type object as the new argument:

```
    class Wide             { }
    class Middle is Wide   { }
    class Narrow is Middle { }

    multi foo (Narrow $v) { say 'Narrow ', $v; 'from Narrow' }
    multi foo (Middle $v) {
        say 'Middle ', $v;
        my $result = callwith Narrow;
        say "We're back! The return value is $result";
        'from Middle'
    }
    multi foo (Wide   $v) { say 'Wide   ', $v; 'from Wide'   }

    foo Middle;

    # OUTPUT:
    # Middle (Middle)
    # Wide   (Narrow)
    # We're back! The return value is from Wide
```

The first portion of the output is clear: we still call `foo` with `Middle`
and hit the `Middle` candidate first. However, something's odd with the next
line. We've used `Narrow` in `callwith`, so how come the `Wide` candidate
gets called with it and not the `Narrow` candidate?

The reason is that `call____` and `next____` routines use *the same dispatch
chain* the original call followed. Since the `Narrow` candidate is narrower
than `Middle` candidate and was rejected for the original call with `Middle`,
it will no longer be considered in `callwith`. The next candidate `callwith`
will call will be the next candidate that matches **`Middle`**—and that's not
a typo: `Middle` is the argument we used to initiate the dispatch and so the
next candidate will be the one that can still take the original arguments. Once
it is found, the **new** arguments that were given to `callwith` will be bound
to it, and it's your job to ensure they can be.

Let's see that in action with a bit more elaborate example.

## Kicking It Up a Notch

We'll expand our original base example with a few more multies and types:

```
    class Wide             { }
    class Middle is Wide   { }
    class Narrow is Middle { }

    subset    Prime where     .?is-prime;
    subset NotPrime where not .?is-prime;

    multi foo (Narrow   $v) { say 'Narrow    ', $v; 'from Narrow'   }
    multi foo (Middle   $v) { say 'Middle    ', $v; 'from Middle'   }
    multi foo (Wide     $v) { say 'Wide      ', $v; 'from Wide'     }
    multi foo (Prime    $v) { say 'Prime     ', $v; 'from Prime'    }
    multi foo (NotPrime $v) { say 'Non-Prime ', $v; 'from NotPrime' }

    foo Narrow; # OUTPUT: Narrow    (Narrow)
    foo Middle; # OUTPUT: Middle    (Middle)
    foo Wide;   # OUTPUT: Wide      (Wide)
    foo 42;     # OUTPUT: Non-Prime 42
    foo 31337;  # OUTPUT: Prime     31337
```

All three of our classes are of type `Any` and we also created two `subset`s
of `Any`: `Prime` and `NotPrime`. The `Prime` type-matches with numbers that
are prime and `NotPrime` type-matches with numbers that are not prime or with
types that don't have an `.is-prime` method. Since our three custom classes
don't have it, they all type-match with `NotPrime`.

If we recreate the previous example in this new setup, we'll get the same
output as before:

```
    class Wide             { }
    class Middle is Wide   { }
    class Narrow is Middle { }

    subset    Prime where     .?is-prime;
    subset NotPrime where not .?is-prime;

    multi foo (Narrow   $v) { say 'Narrow    ', $v; 'from Narrow'   }
    multi foo (Middle   $v) {
        say 'Middle    ', $v;
        my $result = callwith Narrow;
        say "We're back! The return value is $result";
        'from Middle'
    }
    multi foo (Wide     $v) { say 'Wide      ', $v; 'from Wide'     }
    multi foo (Prime    $v) { say 'Prime     ', $v; 'from Prime'    }
    multi foo (NotPrime $v) { say 'Non-Prime ', $v; 'from NotPrime' }

    foo Middle;

    # OUTPUT:
    # Middle    (Middle)
    # Wide      (Narrow)
    # We're back! The return value is from Wide
```

Original call goes to `Middle` candidate, it `callwith` into `Wide`
candidate with the `Narrow` type object.

Now, let's mix it up a bit and `callwith` with `42` instead of `Narrow`. We
*do* have a `NotPrime` candidate. Both `42` and the original `Middle` can
fit into that candidate. And it's wider than the original `Middle` candidate,
and so is still up in the dispatch chain. What could possibly go wrong!

```
    class Wide             { }
    class Middle is Wide   { }
    class Narrow is Middle { }

    subset    Prime where     .?is-prime;
    subset NotPrime where not .?is-prime;

    multi foo (Narrow   $v) { say 'Narrow    ', $v; 'from Narrow'   }
    multi foo (Middle   $v) {
        say 'Middle    ', $v;
        my $result = callwith 42;
        say "We're back! The return value is $result";
        'from Middle'
    }
    multi foo (Wide     $v) { say 'Wide      ', $v; 'from Wide'     }
    multi foo (Prime    $v) { say 'Prime     ', $v; 'from Prime'    }
    multi foo (NotPrime $v) { say 'Non-Prime ', $v; 'from NotPrime' }

    foo Middle;

    # OUTPUT:
    # Middle    (Middle)
    # Type check failed in binding to $v; expected Wide but got Int (42)
    #   in sub foo at z2.p6 line 15
    #   in sub foo at z2.p6 line 11
    #   in block <unit> at z2.p6 line 19
```

Oh, right, that! The new arguments we gave to `callwith` do not affect the
dispatch, so despite there being a candidate that can handle our new arg
further up the chain, it's not the **next** candidate that can handle
**the original args** that `callwith` calls. The result is throwage due to
failed binding of our new args to the... next callee...

## Who's Next?

The handy little routine that lets us grab the next matching
candidate up the dispatch chain is `nextcallee`. Not only it returns the
`Callable` for that candidate, it shifts it off the chain, so that the next
`next____`, `call____`, and even the next `nextcallee` calls will go the
next-next candidate. So... let's go back to our previous example and cheat a
bit!

```
    class Wide             { }
    class Middle is Wide   { }
    class Narrow is Middle { }

    subset    Prime where     .?is-prime;
    subset NotPrime where not .?is-prime;

    multi foo (Narrow   $v) { say 'Narrow    ', $v; 'from Narrow'   }
    multi foo (Middle   $v) {
        say 'Middle    ', $v;
        nextcallee;
        my $result = callwith 42;
        say "We're back! The return value is $result";
        'from Middle'
    }
    multi foo (Wide     $v) { say 'Wide      ', $v; 'from Wide'     }
    multi foo (Prime    $v) { say 'Prime     ', $v; 'from Prime'    }
    multi foo (NotPrime $v) { say 'Non-Prime ', $v; 'from NotPrime' }

    foo Middle;

    # OUTPUT:
    # Middle    (Middle)
    # Non-Prime 42
    # We're back! The return value is from NotPrime
```

Aha! It works! The code is almost entirely the same. The only change is we
popped `nextcallee` call right before our `callwith` call. It shifted off
the `Wide` candidate that couldn't handle the new `42` arg, and so, as can
be seen from the output, our call went into `NotPrime` candidate.

The `nexcallee` is finicky and so looping with it is a challenge, since it'd
use the loop's or thunk's dispatcher to look for callees in. So the most
common and saner way to use it is to just get the... next callee. You'd
primarily need to do if you need to pass the next callee around, e.g. in:

    multi pick-winner (Int \s) {
        my &nextone = nextcallee;
        Promise.in(rand × 2).then: { nextone s }
    }
    multi pick-winner { say "Woot! $^w won" }

    with pick-winner ^5 .pick -> \result {
        say "And the winner is...";
        await result;
    }

    # OUTPUT:
    # And the winner is...
    # Woot! 3 won

With my reaching the summit of convoluted examples, I can hear cries in the
audience. What's this stuff's good for, anyway? Just make more subs instead
of messing with multies! So, let's take a look at more real-worldish examples
as well as meet the `nextsame` and `nextwith`!

## Who's Next?

Let's make a class! A class that does Things!

```
    role Things {
        multi method do-it ($place) {
            say "I am {<eating  sleeping  coding  weeping>.pick} at $place"
        }
    }

    class Doin'It does Things { }

    Doin'It.new.do-it: 'home' # OUTPUT: I am coding at home
```

We can't touch the `role`, since someone else made it for us and they like it
the way it is. However, we want our class to do more! For some `$place`s, we
want it to tell us something more specific. In addition, if the place is
`'my new place'` we want to tell which of our places we consider new. Here's
the code:

```
    role Things {
        multi method do-it ($place) {
            say "I am {<eating  sleeping  coding  weeping>.pick} at $place"
        }
    }

    class Doin'It does Things {
        multi method do-it (\place where .contains: 'home' ) {
            nextsame if place.contains: 'large';
            nextwith "house with $<color> roof"
                if place ~~ /$<color>=[red | green | blue]/;
            samewith 'my new place';
        }
        multi method do-it ('my new place') {
            nextwith 'red home'
        }
    }

    Doin'It.new.do-it: 'the bus';
    Doin'It.new.do-it: 'home';
    Doin'It.new.do-it: 'large home';
    Doin'It.new.do-it: 'red home';
    Doin'It.new.do-it: 'some new home';
    Doin'It.new.do-it: 'my new place';

I am eating at the bus
I am sleeping at red home
I am sleeping at large home
I am eating at house with red roof
I am eating at red home
I am coding at red home
```
