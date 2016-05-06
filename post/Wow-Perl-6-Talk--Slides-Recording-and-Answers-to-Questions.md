%% title: "Wow, Perl 6!" Talk: Slides, Recording, and Answers to Questions
%% date: 2016-03-31

Last night I gave a "Wow, Perl 6!" talk at the Toronto Perl Mongers, whom I thank for letting me speak, even after I got lost for 15 minutes in the building the event was hosted at and was subsequently late.

The talk is an overview of some of the cool features Perl 6 offers. If you didn't get a chance to be at the talk or to watch it via a Google Hangout, you can still get a recording of it.

You can view the slides at [http://tpm2016.zoffix.com/](http://tpm2016.zoffix.com/) and [the recording of the talk is on YouTube](https://www.youtube.com/watch?v=paa3niF72Nw):

<iframe width="560" height="315" src="https://www.youtube.com/embed/paa3niF72Nw" frameborder="0" allowfullscreen></iframe>

## Synopsis

**Couch Potato:**

* Lazy lists and their uses

**Molding Your Own:**

* Subsets
* Custom operators
* Muti-dispatch

**Hyperspace: Multi-core processing at a touch of a button**

* Hyper operators
* Hyper sequence methods
* Autothreaded junctions
* Promises, Supplies, and Channels

**How's Your Spellin'?**

* Grammars: Parsing made easy

**Whatever, man!:**

* Whatever Code
* Meta operators
* Model6 Object Model (very brief "teaser" overview)
* MOP: Meta Object Protocol
* Sets, bags, and mixes

**Polyglot:**

* NativeCall
* Inline::Perl5

**Not Really Advanced Things:**

* Hacking on the Perl 6 Compiler

**Bonus Slides:**

* Backtraces for failures in concurrent code
* Peculiarities with Rats
* Proc::Async
* `say` is for humans `put` is for computers
* More useful objects
* Built in profiler

## Answers to Questions

During the talk a couple of questions were asked and I didn't know the answer at the time. I do now:

### Is there a way to have better error messages when a subset doesn't match a value given?

The code in the `where` can be anything you want, so you can `warn` or `fail` inside the check to get a better error message. Once caveat: the argument given to `callframe` might be different depending on where you're performing the check. Try adjusting it:


    subset Foo of Int where {
        $_ > 10_000
            or fail "You need a number more than 10,000 on "
                ~ "line {(callframe 4).line}, but you passed $_";
    };

    my Foo $x = 1000;

    # OUTPUT:
    #  You need a number more than 10,000 on line 7, but you passed 1000
    #  in block <unit> at test.p6 line 2

### Can you check whether or not a value fits the subset?

Yes, just smartmatch against the type/subset:

    subset Even where * %% 2;
    say 3 ~~ Even;
    say 42 ~~ Even

    # OUTPUT:
    # False
    # True

### Can you have an infinite <code>Set</code>?

No, it tries to actually create one. Makes sense, since a Set cares about the elements in it. Sure, it's possible to special-case some forms of sequences to figure out whether an element is part of the sequence or not, but it's probably not worth it. In a more general case, you are faced with the Halting Problem. Speaking of which, here is a gotcha with the sequence operator and the upper limit:

    my @seq = 0, 2 ... * == 1001;

Here, I'm using the sequence operator to create a sequence of even numbers, and I'm limiting the upper bound by when it'd be equal to 1001. But it won't ever be equal to that. To human brain, it might seem obvious that once you're over 1001, you should stop here, but to a computer it's a Halting Problem and it'll keep trying to find the end point (so it'll never complete here).

### Can you kill a running Promise?

Not possible. If you need that kind of thing, you'll have to use processes, or you'll have to build the code inside the Promise so that it exposes some kind of a "should I continue working?" flag.

### Links for Learning Materials and Ecosystem

Along with [http://perl6intro.com/](http://perl6intro.com/) that I mentioned during the talk, there's also [Learn X in Y Minues Perl 6 page](https://learnxinyminutes.com/docs/perl6/), which I personally found very useful when just starting out with Perl 6.

The Ecosystem is at [http://modules.perl6.org/](http://modules.perl6.org/)  you should have `panda` program installed, and you can install modules from the Ecosystem by typing `panda install Foo::Bar`
