%% title: Perl 6: Sigils, Variables, and Containers
%% date: 2017-12-02
%% desc: which sigil to use and what are the containers?
%% draft: true

Having a rudimentary understanding of containers is vital for enjoyable programming in Perl 6. They're ubiquitous and not only do they affect the kind of variables you get, they also dictate how ``List``s and ``Map``s behave when iterated.

Today, we'll learn what containers are and how to work with them, but first, I'd like you to temporarily forget *everything* you might know or suspect about Perl 6's sigils and variables, especially if you're coming from Perl 5's background. **Everything.**

## Show Me The Money

In Perl 6, a variable is prefixed with a `$` sigil and is given a value with a binding operator (`:=`). Like so:

    my $foo := 42;
    say "The value is $foo"; # OUTPUT: «The value is 42␤»

If you've followed my suggestion to forget everything you know, it won't shock you to learn the same applies to ``List`` and ``Hash`` types:

    my $ordered-things := <foo bar ber>;
    my $named-things   := %(:42foo, :bar<ber>);

    say "$named-things<foo> bottles of $ordered-things[2] on the wall";
    # OUTPUT: «42 bottles of ber on the wall␤»

    .say for $ordered-things;  # OUTPUT: «foo␤bar␤ber␤»
    .say for $named-things;    # OUTPUT: «bar => ber␤foo => 42␤»

Knowing *just this*, you can write a great variety of programs, so if you ever start to feel like there's just too much to learn, remember you don't have to learn everything at once.

## We Wish You a Merry Listmas

Let's try doing more things with our variables. It's not uncommon to want to change a value in a list. How well do we fare with what we have so far?

    my $list := (1, 2, 3);
    $list[0] := 100;
    # OUTPUT: «Cannot use bind operator with this left-hand side […] »

Although we can bind to variables, if we attempt to bind to some value, we get an error, regardless of whether the value comes from a ``List`` or just, say, a literal:

    1 := 100;
    # OUTPUT: «Cannot use bind operator with this left-hand side […] »

This is how `List`s manage to be immutable. However, 'Tis The Season and  wishes do come true, so let's wish for a mutable ``List``!

What we need to get a hold of is a ``Scalar`` object because the binding operator can work with it. As the name suggests, a ``Scalar`` holds one thing. You can't instantiate a ``Scalar`` via the ``.new`` method, but we can get them by just declaring some lexical variables; don't need to bother giving them names:

    my $list := (my $, my $, my $);
    $list[0] := 100;
    say $list; # OUTPUT: «(100 (Any) (Any))␤»

The `(Any)` in the output are the default values of the containers (on that, a bit later). Above, it seems we managed to bind a value to a list's element after ``List``'s creation, did we not? Indeed we did, but…

    my $list := (my $, my $, my $);
    $list[0] := 100;
    $list[0] := 200;
    # OUTPUT: «Cannot use bind operator with this left-hand side […] »

The binding operation *replaces* the ``Scalar`` container with a new value (`100`), so if we try to bind again, we're back to square one, trying to bind to a value instead of a container again.

We need a better tool for the job.

## That's Your Assignment

The binding operator has a cousin: the assignment operator (``=``). Instead of replacing our ``Scalar`` containers with a binding operator, we'll use the assignment operator to assign, or "store", our values in the containers:

    my $list := (my $ = 1, my $ = 2, my $ = 3);
    $list[0] = 100;
    $list[0] = 200;
    say $list;
    # OUTPUT: «(200 2 3)␤»

Now, we can assign our original values right from the start, as well as replace them with other values whenever we want to. We can even get funky and put different type constraints on each of the containers:

    my $list := (my Int $ = 1, my Str $ = '2', my Rat $ = 3.0);
    $list[0] = 100; # OK!
    $list[1] = 42;  # Typecheck failure!

    # OUTPUT: «Type check failed in assignment;
    #    expected Str but got Int (42) […] »

That's somewhat indulgent, but there *is* one thing that *could* use a type constraint: the `$list` variable. We'll constrain it to the ``Positional`` role to ensure it can only hold ``Positional`` types, like ``List`` and ``Array``:

    my Positional $list := (my $ = 1, my $ = '2', my $ = 3.0);

Don't know about you, but that looks awfully verbose to me. Luckily, Perl 6 has syntax to simplify it!

## Position@lly

First, let's get rid of the explicit type constraint on the variable. In Perl 6, you can use `@` instead of `$` as a sigil to say that you want the variable to be type-constrained with role ``Positional``:

    my @list := 42;
    # OUTPUT: «Type check failed in binding;
    #   expected Positional but got Int (42) […] »

Second, instead of parentheses to hold our ``List``, we'll use square brackets. This tells the compiler to create an ``Array`` instead of a ``List``. ``Array``s are mutable and they stick each of their elements into a ``Scalar`` container automatically, just like we did manually in the previous section:

    my @list := [1, '2', 3.0];
    @list[0] = 100;
    @list[0] = 200;
    say @list;
    # OUTPUT: «[200 2 3]␤»

Our code became a lot shorter, but we can toss out a couple more characters. Just like assigning, instead of binding, to a `$`-sigiled variable gives you a ``Scalar`` container for free, you can *assign* to `@`-sigiled variable to get a free ``Array``. If we switch to assignment, we can get rid of the square brackets altogether:

    my @list = 1, '2', 3.0;

Nice and concise.

Similar ideas are behind `%`- and `&`-sigiled variables. The `%` sigil implies  a type-constraint on ``Associative`` role and offers the same shortcuts for assignment (giving you a ``Hash``) and creates ``Scalar`` containers for the values. The `&`-sigiled variables type-constrain on role ``Callable`` and assignment behaves similar to `$` sigils, giving a free ``Scalar`` container whose value you can modify:

    my  %hash = :42foo, :bar<ber>;
    say %hash;  # OUTPUT: «{bar => ber, foo => 42}␤»

    my &reversay = sub { $^text.flip.say }
    reversay '6 lreP ♥ I'; # OUTPUT: «I ♥ Perl 6␤»

    # store a different Callable in the same variable
    &reversay = *.uc.say;  # a WhateverCode object
    reversay 'I ♥ Perl 6'; # OUTPUT: «I ♥ PERL 6␤»

## The One and Only

Earlier we learned that *assignment* to `$`-sigiled variables gives you a free ``Scalar`` container. Since scalars, as the name suggests, contain just one thing… what exactly happens if you put a ``List`` into a ``Scalar``? After all, the Universe remains unimploded  when you try to do that:

    my  $listish = (1, 2, 3);
    say $listish; # OUTPUT: «(1 2 3)␤»

Such behaviour may make it seem that ``Scalar`` is a misnomer, but it *does* actually treat the *entire* list as a single thing. We can observe the difference in a couple of ways. Let's compare a ``List`` **bound** to a `$`-sigiled variable (so no ``Scalar`` is involved) with one that is **assigned** into a `$`-sigiled variable (automatic ``Scalar`` container):

    # Binding:
    my  $list := (1, 2, 3);
    say $list.perl;
    say "Item: $_" for $list;

    # OUTPUT:
    # (1, 2, 3)
    # Item: 1
    # Item: 2
    # Item: 3


    # Assignment:
    my $listish = (1, 2, 3);
    say $listish.perl;
    say "Item: $_" for $listish;

    # OUTPUT:
    # $(1, 2, 3)
    # Item: 1 2 3

The ``.perl`` method gave us an extra insight and showed the second ``List`` with a `$` before it, to indicate it's containerized in a ``Scalar``. More importantly, when we iterated over our ``List``s with the `for` loop, the second ``List`` resulted in just a single iteration: the entire ``List`` as **one item!** The ``Scalar`` lives up to its name.

This behaviour isn't merely of academic interest. Recall that ``Array``s (and ``Hash``es) create ``Scalar`` containers for their values. This means that if we nest things, even if we select an individual list or hash stored inside the ``Array`` (or ``Hash``) and try to iterate over it, it'd be treated as just a single item:

    my @stuff = (1, 2, 3), %(:42foo, :70bar);
    say "List Item: $_" for @stuff[0];
    say "Hash Item: $_" for @stuff[1];

    # OUTPUT:
    # List Item: 1 2 3
    # Hash Item: bar  70
    # foo 42

The same reasoning—that lists and hashes in ``Scalar`` containers are a single item—applies when you try to ``flat``ten an ``Array``'s elements or pass them as an argument to a [slurpy parameter](https://docs.perl6.org/type/Signature#index-entry-parameter_%2A%40-parameter_%2A%2525_slurpy_argument_%28Signature%29-Slurpy_%28A.K.A._Variadic%29_Parameters):

    my @stuff = (1, 2, 3), %(:42foo, :70bar);
    say flat @stuff;
    # OUTPUT: «((1 2 3) {bar => 70, foo => 42})␤»

    -> *@args { @args.say }(@stuff)
    # OUTPUT: «[(1 2 3) {bar => 70, foo => 42}]␤»

It's *this* behaviour that can drive Perl 6 beginners up the wall, especially those who come from auto-flattening languages, such as Perl 5. However, now that we know *why* this behaviour is observed, we can change it!

## Decont

If the ``Scalar`` container is the culprit, all we need to do is remove it. We need to de-containerize our list and hash, or "decont" for short. In your Perl 6 travels, you'll find several ways to accomplish that, but one way that's designed precisely for that is the decont methodop (`<>`):

    my @stuff = (1, 2, 3), %(:42foo, :70bar);
    say "Item: $_" for @stuff[0]<>;
    say "Item: $_" for @stuff[1]<>;

    # OUTPUT:
    # Item: 1
    # Item: 2
    # Item: 3
    # Item: bar   70
    # Item: foo   42

It's easy to remember: it looks like a squished box (a trampled container). After retrieving our containerized items by indexing into the ``Array``, we appended the decont and removed the contents from their ``Scalar`` containers, causing our loop to iterate over each item in them individually.

If you wish to decont every element of an ``Array`` in one go, simply use the hyper operator (`»`, or `>>` if you prefer ASCII) along with the decont:

    my @stuff = (1, 2, 3), %(:42foo, :70bar);
    say flat @stuff»<>;
    # OUTPUT: «(1 2 3 bar => 70 foo => 42)␤»

    -> *@args { @args.say }(@stuff»<>)
    # OUTPUT: «[1 2 3 bar => 70 foo => 42]␤»

With the containers removed, our list and hash flattened just like we wanted. And of course, we could have avoided the ``Array`` and *bound* our original ``List`` to the variable instead. Since ``List``s don't put their elements into containers, there's nothing to decont:

    my @stuff := (1, 2, 3), %(:42foo, :70bar);
    say flat @stuff;
    # OUTPUT: «(1 2 3 bar => 70 foo => 42)␤»

    -> *@args { @args.say }(@stuff)
    # OUTPUT: «[1 2 3 bar => 70 foo => 42]␤»

## Don't Let It Slip Away

While we're here, it's worth noting that many people use the *slip operator* (``|``), when they want to **do the decont** (we're *not* talking about using it when passing arguments to ``Callable``s):

    my @stuff = (1, 2, 3), (4, 5);
    say "Item: $_" for |@stuff[0];

    # OUTPUT:
    # Item: 1
    # Item: 2
    # Item: 3

Although it gets the job done as far as deconting goes, it can introduce subtle bugs that could be very difficult to track down. Try to spot one here, in a program that iterates over an infinite list of non-negative integers and prints those that are prime:

    my $primes = ^∞ .grep: *.is-prime;
    say "$_ is a prime number" for |$primes;

Give up? This program leaks memory… very slowly. Even though, we're iterating over an infinite list of items, that's not an issue because ``.grep`` method returns a ``Seq`` object that doesn't keep already-iterated items around and so memory usage never grows there.

The problematic part is our ``|`` slip operator. It converts our ``Seq`` into a ``Slip``, which is a type of a ``List`` and keeps around all of the values we already consumed. Here's a modified version of the program that grows faster, if you wanted to see that growth in [`htop`](http://hisham.hm/htop/):

    # CAREFUL! Don't consume all of your resources!
    my $primes = ^∞ .map: *.self;
    Nil for |$primes;

Let's try it again, but this time using the decont method op:

    my $primes = ^∞ .map: *.self;
    Nil for $primes<>;

The memory usage is stable now and the program can sit there and iterate until the end of times. Of course, since we know it's the ``Scalar`` container that causes containerization and we wish to avoid it here, we can simply *bind* the ``Seq`` to the variable instead:

    my $primes := ^∞ .map: *.self;
    Nil for $primes;


## I Want Less

If you detest sigils, Perl 6 got something you can smile about: sigil-less variables. Just prefix the name with a backslash during declaration, to indicate you don't want no stinkin' sigils:

    my \Δ = 42;
    say Δ²; # OUTPUT: «1764␤»

You don't get any free ``Scalar``s with such variables and so, during declaration, it makes no difference between binding or assignment to them. They behave similar to how binding a value to a `$`-sigiled variable behaves, including the ability to bind ``Scalar``s and make the variable mutable:

    my \Δ = my $ = 42;
    Δ = 11;
    say Δ²; # OUTPUT: «121␤»

A more common place where you might see such variables is as parameters of routines, here, these mean you want [`is raw`](https://docs.perl6.org/type/Signature#index-entry-trait__is_raw) trait applied to the parameter. The meaning exists for the [`+` positional slurpy](https://docs.perl6.org/type/Signature#index-entry-%2B_%28Single_Argument_Rule_Slurpy%29) parameter as well (no backslash is needed), where having it `is raw` means you won't get unwanted ``Scalar`` containers due to the slurpy being an ``Array`` as it has the `@` the sigil:

    sub sigiled ($x is raw, +@y) {
        $x = 100;
        say flat @y
    }

    sub sigil-less (\x, +y) {
        x = 200;
        say flat y
    }

    my $x = 42;
    sigiled    $x, (1, 2), (3, 4); # OUTPUT: «((1 2) (3 4))␤»
    say $x;                        # OUTPUT: «100␤»

    sigil-less $x, (1, 2), (3, 4); # OUTPUT: «(1 2 3 4)␤»
    say $x;                        # OUTPUT: «200␤»

## Defaulting on Default Defaults

One awesome feature offered by containers is default values. You may have heard that in Perl 6 `Nil` signals the *absence* of a value and not a value in itself. Container defaults is where it comes into play:

    my $x is default(42);
    say $x;   # OUTPUT: «42␤»

    $x = 10;
    say $x;   # OUTPUT: «10␤»

    $x = Nil;
    say $x;   # OUTPUT: «42␤»

A container's default value is given to it using the [`is default` trait](https://docs.perl6.org/type/Variable#index-entry-trait_is_default_%28Variable%29-trait_is_default). Its argument is evaluated at compile time and the resultant value is used whenever the container lacks a value. Since `Nil`'s job is to signal just that, assigning a `Nil` into a container will result in the container containing its default value, not a `Nil`.

Defaults can be given to ``Array`` and ``Hash`` containers just the same and if you wish your containers to contain a `Nil` literally, when no value is present, just specify `Nil` as a default:

    my @a is default<meow> = 1, 2, 3;
    say @a[0, 2, 42]; # OUTPUT: «(1 3 meow)␤»

    @a[0]:delete;
    say @a[0];        # OUTPUT: «meow␤»

    my %h is default(Nil) = :bar<ber>;
    say %h<bar foos>; # OUTPUT: «(ber Nil)␤»

    %h<bar>:delete;
    say %h<bar>       # OUTPUT: «Nil␤»

The container's default has a default default: the explicit type constraint that's present on the container:

    say my Int $y; # OUTPUT: «(Int)␤»
    say my Mu  $z; # OUTPUT: «(Mu)␤»

    say my Int $i where *.is-prime; # OUTPUT: «(<anon>)␤»
    $i.new; # OUTPUT: (exception) «You cannot create […]»

If no explicit type constraint is present, the default default is an ``Any`` type object:

    say my $x;    # OUTPUT: «(Any)␤»
    say $x = Nil; # OUTPUT: «(Any)␤»

Note that the [default values you may use in routine signatures for optional parameters](https://docs.perl6.org/type/Signature#index-entry-optional_argument_%28Signature%29) are *not* the container defaults and assigning `Nil` to subroutine arguments or into parameters will *not* utilize the defaults from the signature.

## Customizing

If the standard behaviour of containers doesn't suit your needs, you can make your own container, using the ``Proxy`` type:

    my $collector := do {
        my @stuff;
        Proxy.new: :STORE{ @stuff.push: @_[1] },
                   :FETCH{ @stuff.join: "|"   }
    }

    $collector = 42;
    $collector = 'meows';
    say $collector; # OUTPUT: «42|meows␤»

    $collector = 'foos';
    say $collector; # OUTPUT: «42|meows|foos␤»

The interface is somewhat clunky, but it gets the job done. We create the ``Proxy`` object using method ``.new`` that takes two required named arguments: `STORE` and `FETCH`, each taking a ``Callable``.

The `FETCH` ``Callable`` gets called whenever a value is read from the container, which can happen more times than is immediately apparent: in the code above, the `FETCH` ``Callable`` is called 10 times as the container percolates through dispatch and routines of the two ``say`` calls. The ``Callable`` is called with a single positional argument: the ``Proxy`` object itself.

The `STORE` ``Callable`` gets called whenever a value is stored into our container, for example, with an assignment operator (``=``). The first positional argument to the ``Callable`` is the ``Proxy`` object itself, and the second argument is the value that was given to be stored.

We'd like `STORE` and `FETCH` ``Callable``s to share the `@stuff` variable, so we use the [`do` statement prefix](https://docs.perl6.org/syntax/do) with a code block to contain it all nicely inside.

We *bind* our ``Proxy`` to a variable and the rest is just normal variable usage. The output shows the altered behaviour our custom container provides.

Proxies are also handy as a return value from methods to provide extra behaviour with mutable attributes. For example, here's an attribute that from the outside appears to be just a normal mutable attribute, but actually coerces its value from an ``Any`` type to an ``Int``

    class Foo {
        has $!foo;
        method foo {
            Proxy.new: :STORE(-> $, Int() $!foo { $!foo }),
                       :FETCH{ $!foo }
        }
    }

    my $o = Foo.new;
    $o.foo = ' 42.1e0 ';
    say $o.foo; # OUTPUT: «42␤»

Quite sweet! And if you want a ``Proxy`` with a better interface with a few more features under its belt, check out the [`Proxee` module](http://modules.perl6.org/dist/Proxee).

## That's All, Folks

That about covers it all. The remaining beasts you'll see in the land of Perl 6 are "twigils": variables with TWO symbols before the name, but as far as containers go, they behave the same as the variables we've covered. The second symbol simply indicates *additional* information, such as whether the variable is an implied positional or named parameter…

    sub test { say "$^implied @:parameters[]" }
    test 'meow', :parameters<says the cat>;
    # OUTPUT: «meow says the cat␤»

…or whether the variable is a private or public attribute:

    with class Foo {
        has $!foo = 42;
        has @.bar = 100;
        method what's-foo { $!foo }
    }.new {
        say .bar;       # OUTPUT: «[100]␤»
        say .what's-foo # OUTPUT: «42␤»
    }

That's a journey for another day, however.

## Conclusion

Perl 6 has a rich system of variables and containers that differs vastly from Perl 5. It's important to understand the way it works, as it affects the way iteration and flattening of lists and hashes behaves.

Assignment to variables offers valuable shortcuts, such as providing ``Scalar``, ``Array``, or ``Hash`` containers, depending on the sigil. Binding to variables allows you to bypass such shortcuts, if you so require.

Sigil-less variables exist in Perl 6 and they have similar behaviour to how `$`-sigiled variables with binding work. When used as parameters, these variables behave like `is raw` trait was applied to them.

Lastly, containers can have default values and it's possible to create your own custom containers that can either be bound to a variable or returned from a routine.

Happy Holidays!
