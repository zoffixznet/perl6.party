%% title: Perl 6 Hands-On Workshop: Weatherapp (Part 3)
%% date: 2016-05-25
%% desc: Developing a weather reporting application. Part 3: writing tests
%% draft: True

*Be sure to read [Part 1](/post/Perl-6-Hands-On-Workshop--Weatherapp--Part-1) and [Part 2](/post/Perl-6-Hands-On-Workshop--Weatherapp--Part-2)
of this workshop first.*

There is black box testing, glass box testing, unit testing, integration testing, functional testing, system testing, end-to-end testing, sanity testing, regression testing, acceptance testing, load testing, stress testing, performance testing, usability testing, and many more types of testing.

I'll leave it for people with thicker glasses to [explain all of the
types](http://www.testingexcellence.com/types-of-software-testing-complete-list/). Today, we'll write tests that ensure our weather reporting module
works as expected, and as a bonus, you get to pick your own label for what
type of tests these are. Let's dive in!

## TDD

TDD (Test-Driven Development) is where you write a bunch of tests, ensure they
fail—because code to satisfy them isn't there yet—and then you write code
until the tests succeed. Now you can safely refactor your code without
worrying you'll break something. Rinse and repeat.

Not only do avoid having to convince yourself to bother writing tests after
your code seems to work, you also get a feel for how comfortable your interface
is to use before you even create it.

## Testing Modules

Perl 6 comes with a number of standard modules included, one of which is
a module called [`Test`](http://docs.perl6.org/language/testing)
that we'll use. The Ecosystem also has dozens of
[other test related modules](https://modules.perl6.org/#q=Test) and we'll use
two called [`Test::When`](https://modules.perl6.org/dist/Test::When) and
[`Test::META`](https://modules.perl6.org/dist/Test::META)

`Test` provides all the testing routines we'll use, `Test::When` will let
us watch for when the user actually agreed to run network tests, and
`Test::META` will keep an eye on the sanity of our distribution's META file
(more on that later).

To install `Test::When` and `Test::META`, run
`zef install Test::When Test::META` or
`panda install Test::When Test::META`,
depending on which module manager you're using.

## Testing Files

Our testing files are named with the extension `.t` and go into
`t/` directory. They will be automatically discovered and run
by module managers during installation of our module. While there is no
accepted convention in Perl 6, it is prudent to steal Perl 5's convention
of storing author and release tests in `xt/` directory. These would include
tests like testing documentation completeness or any other test failing
which does not mean the module itself is broken. No one wants their build
to stall just because you didn't document a new experimental method, so you
should avoid putting those tests into `t/`.

It's also common to prefix the names of tests with a sequential number,
e.g. `00-init.t`, `01-methods.t`, etc. It's more of an organizational
practice and in no way should your tests in one file depend on whether
tests in another file ran first.

## Boilerplate

    use Test;

    use My::Module;
    is get-stuff(), 'the right stuff', 'The stuff we received is correct';

    done-testing;

    # or

    use Test;

    plan 1;

    use My::Module;
    is get-stuff(), 'the right stuff', 'The stuff we received is correct';

The two versions above differ in that the first doesn't care how many tests
you run and the second expects exactly one test to run.