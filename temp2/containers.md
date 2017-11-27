Perl 6: Sigils, Variables, and Containers

Having a rudimentary understanding of containers is vital for enjoyable programming in Perl 6. They're ubiquitous and not only do they affect the kind of variables you get, they also dictate how ``List``s and ``Map``s behave when
iterated.

Today, we'll learn what containers are and how to work with them, but first, I'd like you to temporarily forget *everything* you might know or suspect about Perl 6's sigils and variables, especially if you're coming from Perl 5's background. **Everything.**

## Show Me The Money

In Perl 6, a variable is prefixed with a `$` sigil and is given a value with
a binding operator (`:=`). Like so:

    my $foo := 42;
    say "The value is $foo"; # OUTPUT: «The value is 42␤»

If you've followed my suggestion to forget everything you know, it won't shock
you to learn the same applies to ``List`` and ``Hash`` types:

    my $ordered-things := <foo bar ber>;
    my $named-things   := %(:42foo, :bar<ber>);

    say "$named-things<foo> bottles of $ordered-things[2] on the wall";
    # OUTPUT: «42 bottles of ber on the wall␤»

    .say for $ordered-things;  # OUTPUT: «foo␤bar␤ber␤»
    .say for $named-things;    # OUTPUT: «bar => ber␤foo => 42␤»

Knowing just this, you can write a great variety of programs, so if you ever
start to feel like there's just too much to learn, remember you don't have to
learn everything at once.

## We Wish You a Merry Listmas

Let's try doing more things with our variables. It's not uncommon to want
to change a value in a list. How well do we fare?

    my $list := (1, 2, 3);
    $list[0] := 100;
    # OUTPUT: «Cannot use bind operator with this left-hand side […] »

Although we can bind to variables, if we attempt to bind to some value, we
get an error, regardless of whether it comes from a ``List`` or just, say, a
literal:

    1 := 100;
    # OUTPUT: «Cannot use bind operator with this left-hand side […] »

This is how `List`s manage to be immutable. However, 'Tis The Season and wishes do come true, so let's wish for a mutable ``List``!

What we need to get a hold of is a ``Scalar`` object because the binding operator can work with it. As the name suggests, a ``Scalar`` holds one thing.
You can't instantiate a ``Scalar`` via ``.new`` method,
but we can get some of them by just declaring some lexical variables; don't
need to bother giving them names:

    my $list := (my $, my $, my $);
    $list[0] := 100;
    say $list; # OUTPUT: «(100 (Any) (Any))␤»

The `(Any)` in the output are the default values of the containers (on that, a bit later). It seems we managed to bind a value to a list's element after
``List``'s creation, did we not? Indeed we did, but…

    my $list := (my $, my $, my $);
    $list[0] := 100;
    $list[0] := 200;
    # OUTPUT: «Cannot use bind operator with this left-hand side […] »

The binding operation *replaced* the ``Scalar`` container with a new value
(`100`), so if we try to bind again, we're back to square one, trying to bind
to a value instead of a container again.

We need a better tool for the job.

## That's Your Assignment

The binding operator has a cousin: the assignment operator (`=`). Instead of
replacing our ``Scalar`` containers with a binding operator, we'll use the
assignment operator to assign (or "store") our values in the containers:

    my $list := (my $ = 1, my $ = 2, my $ = 3);
    $list[0] = 100;
    $list[0] = 200;
    say $list;
    # OUTPUT: «(200 2 3)␤»

Now, we can assign our original values, as well as replace them with other
values whenever we want to. We can even get funky and put different types on each of the containers:

    my $list := (my Int $ = 1, my Str $ = '2', my Rat $ = 3.0);
    $list[0] = 100; # OK!
    $list[1] = 42;  # Typecheck failure!

    # OUTPUT: «Type check failed in assignment;
    #    expected Str but got Int (42) […] »

That's somewhat indulgent, but there *is* one thing that *could* use a type-constaint: the `$list` variable. We'll constain it to the ``Positional`` role to ensure it can only hold ``Positional`` types, like ``List`` and ``Array``:

    my Positional $list := (my $ = 1, my $ = '2', my $ = 3.0);

Don't know about you, but that looks awfully verbose to me. Luckily, Perl 6
has syntax to simplify it!

## Position@lly

First, let's get rid of the type constraint on the variable. In Perl 6, you
can use `@` instead of `$` as a sigil to say that you want the variable
be type-constrained with role ``Positional``:

    my @list := 42;
    # OUTPUT: «Type check failed in binding;
    #   expected Positional but got Int (42) […] »

Second, instead of parentheses to hold our ``List``, we'll use square brackets.
This tells the compiler to create an ``Array`` instead of a ``List``.
``Array``s are mutable and they stick each item into a ``Scalar`` container automatically, just like we did manually in the previous section:

    my @list := [1, '2', 3.0];
    @list[0] = 100;
    @list[0] = 200;
    say @list;
    # OUTPUT: «[200 2 3]␤»

Our code became a lot shorter, but we can toss a couple more characters. Just
like assigning instead of binding to a `$`-sigiled variable gives you a
``Scalar`` container for free, you can assign to `@`-sigiled variable to get
a free ``Array``, so we can get rid of the square brackets altogether:

    my @list = 1, '2', 3.0;

Nice and concise.

Similar ideas are behind `%`- and `&`-sigiled variables. The `%` sigil implies
 a type-constraint on ``Associative`` role and offers the same shortcuts for assignment (giving you a ``Hash``) and creates ``Scalar`` containers for the values. The `&`-sigiled variables type-constrain on role ``Callable`` (I'm not avare of any significant differences between assignment and binding to `&` variables that regular users would care about).

    my %hash = :42foo, :bar<ber>;
    say %hash;  # OUTPUT: «{bar => ber, foo => 42}␤»

    my &reversay = sub { $^text.flip.say };
    reversay '6 lreP ♥ I'; # OUTPUT: «I ♥ Perl 6␤»


## The One and Only

Above I mentioned that assigment to `$`-sigiled variables gives you a free
``Scalar`` container and scalars contain just one thing… So what exactly
happens if you put a ``List`` into a ``Scalar``? After all, it seems to not implode the Universe when you try to do that:

    my  $listish = (1, 2, 3);
    say $listish; # OUTPUT: «(1 2 3)␤»

Such behaviour may make it seem that ``Scalar`` is a misnomer, but it *does*
actually treat the *entire* list as a single thing. We can observe the
difference in a couple of ways. Let's compare it to a ``List`` **bound** to
a `$`-sigiled variable (so no ``Scalar`` is involved):

    my $list := (1, 2, 3);
    say $list.perl;
    say "Item: $_" for $list;

    # OUTPUT:
    # (1, 2, 3)
    # Item: 1
    # Item: 2
    # Item: 3


    my $listish = (1, 2, 3);
    say $listish.perl;
    say "Item: $_" for $listish;

    # OUTPUT:
    # $(1, 2, 3)
    # Item: 1 2 3

The ``.perl`` method gave us an extra insight and showed the second ``List`` with a `$` before it, to indicate it's containerized in a ``Scalar``. More importantly, when we iterated over our ``List``s with the `for` loop, the second ``List`` resulted in just a single iteration: the entire ``List`` as **one item!**

This behaviour isn't merely of academic interest. Recall that ``Array``s (and ``Hash``es) create ``Scalar`` containers for their stuff. This means that even if we select an individual list stored inside the ``Array`` and try to iterate over it, it'd be treated as just a single item:

    my @stuff = (1, 2, 3), (4, 5);
    say "Item: $_" for @stuff[0];
    # OUTPUT: «Item: 1 2 3␤»

The same reasoning—that lists in ``Scalar`` containers are a single item—applies when you try to ``flat``ten an ``Array``'s elements or use them for a slurpy routine argument:

    my @stuff = (1, 2, 3), (4, 5);
    say flat @stuff; # OUTPUT: «((1 2 3) (4 5))␤»

    -> *@args {
        @args.say;   # OUTPUT: «[(1 2 3) (4 5)]␤»
    }(@stuff)

It's *this* behaviour that can drive Perl 6 beginners up the wall, especially those who come from auto-flattening languages, such as Perl 5. However, now that we know *why* this behaviour is observed, we can change it!

## Decont

If the ``Scalar`` container is the culprit, all we need to do is remove it. We need to de-containerize our lists, or "decont" for short. In your Perl 6 travels, you'll find several ways to accomplish that, but one way that's designed precisely for that is the decont methodop (`<>`):

    my @stuff = (1, 2, 3), (4, 5);
    say "Item: $_" for @stuff[0]<>;
    # OUTPUT: «Item: 1␤Item: 2␤Item: 3␤»

It's easy to remember: it looks like a squished box (a trampled container). After retrieving our containerized list by indexing into the `Array`, we appended the decont, and removed the list from the `Scalar` container, causing our loop to iterate over each item in the list individually.

If you wish to decont every element of an `Array`, simply use the hyper operator (`»` or `>>` if you prefer ASCII) along with the decont:

    my @stuff = (1, 2, 3), (4, 5);
    say flat @stuff»<>; # OUTPUT: «(1 2 3 4 5)␤»

    -> *@args {
        @args.say;      # OUTPUT: «[1 2 3 4 5]␤»
    }(@stuff»<>)

With the containers removed, our lists flattened just like we wanted.

## Don't Let It Slip Away

While we're here, it's worth noting that many people use the slip operator (`|`) to do the decont:

    my @stuff = (1, 2, 3), (4, 5);
    say "Item: $_" for |@stuff[0];

Although it gets the job done as far as deconting goes, it can introduce subtle bugs that could be very difficult to track down. Try to spot one here:

    my $primes = ^Inf .grep: *.is-prime;
    say "$_ is a prime number" for |$primes;

Give up? This program leaks memory… very slowly. Although we're iterating over an infinite list of items, that's not an issue because `.grep` method returns a `Seq` object that doesn't keep already-iterated items around and so memory usage never grows there.

The problematic part is our `|` slip operator. It converts our `Seq` into a `Slip`, which is a type of a `List` and keeps around all of the values we already consumed. Here's a modified version of the program that grows faster, if you wanted to see that growth in `htop`:

    # CAREFUL! Don't consume all of your resources!
    my $primes = ^Inf .map: *.self;
    $ = $ for |$primes;

Let's try it again, but this time using the decont method op:

    my $primes = ^Inf .map: *.self;
    $ = $ for $primes<>;

The memory usage is stable now and the program can sit there and iterate until the end of times. Of course, since we know it's the `Scalar` container that causes containerization and we wish to avoid it here, we can simply *bind* the `Seq` to the variable instead:

    my $primes := ^Inf .map: *.self;
    $ = $ for $primes;


## I Want Less

If you detest sigils, Perl 6 got something you can smile about: sigil-less variables. Just prefix the name with a backslash to indicate you don't want no stinkin' sigils:

    my \Δ = 42;
    say Δ²; # OUTPUT: «1764␤»

You don't get any free `Scalar`s with such variables and so it makes no difference between binding or assigning to them. They behave similar to how binding a value to a `$`-sigiled variable behaves, including the ability to bind `Scalar`s and make the variable mutable:

    my \Δ = my $ = 42;
    Δ = 11;
    say Δ²; # OUTPUT: «121␤»

A more common place where you might see such variables is as parameters of routines, here, these mean you want `is raw` trait applied to the parameter. The meaning exists for the `+` slurpy as well (no backslash is needed), where having it `is raw` means you won't get unwanted `Scalar` containers due to it being an `Array`:

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

One awesome feature offered by containers is default values. You may have heard that in Perl 6 `Nil` signals the absense of a value and not a value in itself. Container defaults is where it comes into play:

    my $x is default(42);
    say $x;   # OUTPUT: «42␤»

    $x = 10;
    say $x;   # OUTPUT: «10␤»

    $x = Nil;
    say $x;   # OUTPUT: «42␤»

A container's default value is given to it using the `is default` trait. Its argument is evaluated at compile time and the resultant value is used whenever the container lacks a value. Since `Nil`'s job is to signal just that, assigning a `Nil` into a container will result in the container containing its default value, not a `Nil`.

Defaults can be given to `Array` and `Hash` containers just the same and if you
wish your containers to contain a `Nil` literally when no value is present, just specify `Nil` as a default:

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

If no explit type constraint is present, the default default is an `Any` type object:

    say my $x;    # OUTPUT: «(Any)␤»
    say $x = Nil; # OUTPUT: «(Any)␤»

Note that the default values you may use in routine signatures for optional parameters are *not* the container defaults and assigning `Nil` to subroutine arguments or into parameters will *not* utilize the defaults from the signature.

## That's All, Folks

That about covers it all. The remaining beasts you'll see in the land of Perl 6 are "twigils": variables with TWO symbols before the name, but as far as containers go, they behave the same as the variables we've convered. The second symbol simply indicates *additional* information, such as whether the
variable is an implied positional or named parameter…

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

Perl 6 has a rich system of variables and containers that differs vastly from
Perl 5. It's important to understand the way it works, as affects the way iteration and flattening of lists and hashes behaves.

Assignment to variables offers valuable shortcuts, such as providing `Scalar`, `Array`, or `Hash` containers, depending on the sigil. Binding to variables allows you to bypass such shortcuts, if you so require.

Lastly, sigil-less variables exist in Perl 6 and they have similar behaviour
to how `$`-sigiled variables with binding work. When used as parameters, these
variables behave like `is raw` trait was applied to them.

Happy Holidays!