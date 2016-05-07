%% title: There Are Traitors In Our Midst! [Part 2]
%% date: 2016-05-03
%% draft: True

# PART II: Custom Traits

Custom traits obviously pack a lot of power into a few characters... wouldn't
it be awesome if you could create your own? It wouldn't be Perl if you couldn't!

## The Basics

Traits are subs that you simply declare with:

    multi trait_mod:<is> ( *signature goes here* ) { *body goes here* }

The signature specifies what the trait applies to and how it's used. One example
can be `Variable $v, :$config!`. Such a trait would apply to variables only
and would be specified as `is config` or `is config('some argument')`. Notice
how the name of the parameter and the word after `is` match.

The body is where the magic happens, but keep in mind:
traits are applied at *compile time*, so some things won't be available to your
traits.

## Assign Default Values

Imagine you have an app that has a bunch of configuration. Let's
create App::Config module that exports a custom trait `is config` to load
that configuration from a JSON file:

    # ./test-config.json:
    {
        "name": "Bender",
        "input": "beer"
    }

    # ./App/Config.pm6
    1: unit module App::Config;
    2: multi trait_mod:<is> (Variable $v, :$from-config!) is export {
    3:     my $conf = from-json slurp 'test-config.json';
    4:     my $name = $from-config ~~ Str ?? $from-config !! $v.var.VAR.name.substr: 1;
    5:     $v.var   = $conf{ $name } // die 'Unknown configuration variable';
    6: }

    # ./app.p6
    1: use App::Config;
    2: my $name  is from-config;
    3: my $input is from-config;
    4: my $robot is from-config('name');
    5: say "$robot\'s name is $name and he likes $input";

    # OUTPUT:
    # Bender's name is Bender and he likes beer

Before we examine the trait's definition, let's take a look at how it's used in
`app.p6`. On line 1 we simply `use` our config module.
On lines 2 and 3 we have `is from-config` next to variables and that's it.
So how does the trait figure out what config values to load? Thanks to Perl 6's
powerful Meta Object Protocol, the trait can actually look up what the variable
is called. We do that on line 4, in `App/Config.pm6`
in the `!!` condition. The `.substr` is used,
because the `.name` method returns the sigil as well.

Line 4 in `app.p6` also shows a way to pass arguments to traits. In this case,
we use the argument as the name of the config variable, to avoid using the name
of the variable it is assigned to. On line 4, in `App/Config.pm6`, we test
whether the `$from-config` parameter is a string, which would indicate the
argument was passed (the value is a `Bool` without any arguments).

The results are great! Our `app.p6`'s code is very clean, without any repetition
of names, and yet, we have awesome configuration capabilities. If you were to
switch from JSON to, say, database-driven configuration, just modify your
trait's definition. The rest of the app will still work the same.
