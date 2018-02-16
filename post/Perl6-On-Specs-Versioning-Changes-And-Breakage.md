%% title: Perl 6: On Specs, Versioning, Changes, and… Breakage
%% date: 2017-02-17
%% desc: Details of how Perl 6 languages changes.
%% draft: true

Recently, I came across a [somewhat-frantic comment](https://stackoverflow.com/questions/48488381/perl6-comparison-operator#comment83973425_48489204) on StackOverflow describes a 2017.01 change to the type of value `.sort` returns as "ouch". It ended with a call for a blog post describing how Perl 6 approaches changes to the language.

Today, I decided to answer that call and explain everything about our versioning,
our spec, and how things like `.sort`'s return values can change.

## On Versioning

The '6' in Perl 6 is just part of the name. The language version itself is encoded
by a sequential letter, which is also the starting letter of a codename for that
release. For example, the current stable language version is `6.c "Christmas"`. The
next language release will be `6.d` with one of the proposed codename being
`"Diwali"`. The version after that will be `6.e`, then `6.f`, and so on.

If you've used Perl 6 sometime between 2015 and 2018, you likely used the "Rakudo"
compiler, which is often packaged as "Rakudo Star" distribution and versioned
with year and month of the release, e.g. release `2017.01`.

Unlike some other languages, in Perl 6, how a compiler (e.g. "Rakudo") behaves or what it implements does **not** define the Perl 6 language. The [Perl 6 language
specification](https://github.com/perl6/roast/) does. The specification consists of
a test suite of about 155,000 tests and anything that passes that test suite can
call itself a "Perl 6 compiler".

It's to *this* specification version `6.c "Christmas"` refers. It was released
on December 25, 2015 and at the time of this writing, it's the first and only
release of a stable language spec. Aside from a few error corrections, there
were *no changes to that specification*… The latest version of Rakudo still passes
every single test—it's a release requirement.

## On Changes

Ardent Perl 6 users would likely recall that there *have* been many changes since
Christmas 2015. Including the change referenced by that StackOverflow comment.
If the specification did not change and core devs are not allowed to make
changes that break 6.c specification, how could the return type of `.sort`
could have changed?

The reason is—and I hope the other core devs will forgive me for my choice of
imagery—the specification is full of holes!

![](/assets/pics/specs-and-versions/cheese1.jpg)

It doesn't (yet) cover every imaginable use and combination of features.
What happens when you try to [`print`](https://docs.perl6.org/routine/print.html)
a [`Junction`](https://docs.perl6.org/type/Junction) of strings? As far as 6.c
version of Perl 6 language is concerned, that's undefined behaviour. What object do
you get if you call `.Numeric` on an `Int` *type object* rather than an instance?
Undefined behaviour. What about the return value of `.sort`? You'll get sorted values in an `Iterable` type, but whether that type is a `Seq` or `List` is
not specified by the specification.

In my personal opinion, the 6.c spec is overly sparse in places, which is why we
saw a number of large changes in 2016 and early 2017, including the "ouch" change
the commenter on StackOverlow referred to. But… it won't stay that way forever.

## The Future

Since 6.c language release, there have been 3,129 commits to the spec. These
are the proposals for the 6.d language specification. While some of these commits
address new features, a lot of them close those holes the 6.c spec contains.
Thus, when 6.d is released, it'll look something like this:

![](/assets/pics/specs-and-versions/cheese1.jpg)

Still some undefined behaviour in it, but a lot less than in 6.c language. It
now defines that `print`ing a `Junction` will thread it; that calling
`.Numeric` on a `Numeric` type object gives a numeric equivalent of zero of
that type and a warning; and that the `.sort`'s `Iterable` return type is a
`Seq`, not a `List.

This is how 2017.01 version of Rakudo managed to change the return type of
`.sort`, despite being a compliant implementation of 6.c language. (It's also
worth noting that since that time we also implemented [an extended testing
framework](https://rakudo.party/post/Perl-6-Release-Quality-Assurance-Full-Ecosystem-Toaster) that guides our decisions on whether we actually allow changes that don't
violate the spec).

As more uses of combinations original designers haven't thought of come around,
even more holes will be covered in future language versions.

## Breaking Things

The cheese metaphor covers refinements to the specification, but there's another
set of changes the core developers some times can make: changes that violate
previous versions of the specification.

For 6.d language, the list of some of such changes is available in [our 6.d-prep repository](https://github.com/perl6/6.d-prep/blob/master/TODO/FEATURES.md) (some of the listed changes don't violate 6.c spec, but are still have significant impact so we pushed them to the next language version).

This may seem to be a contradiction: didn't I say earlier that passing 6.c
specification is part of the compiler's release requirements? The key to resolving
that contradiction lies in ability to request different language versions in
different comp units (e.g. in different modules) that are used **by the same**
program.

Specifying `use v6.c` pragma loads 6.c language. Specifying `use v6.d` (currently
available as `use v6.d.PREVIEW`) loads 6.d language. Not specifying anything
loads the newest versio the compiler supports.

Once of the changes between 6.c and 6.d languages is that `await` no longer blocks
the thread in `6.d`. We can observe this change using a small script that loads
two modules. The code between the two of them is the same, except they request
different language versions:

    # file ./C.pm6
    use v6.c;
    sub await-c is export {
        await ^10 .map: {
            start await ^5 .map: { start await Promise.in: 1 }
        }
        say "6.c version took $(now - ENTER now) secs";
    }

    # file ./D.pm6
    use v6.d.PREVIEW;
    sub await-d is export {
        await ^10 .map: {
            start await ^5 .map: { start await Promise.in: 1 }
        }
        say "6.d version took $(now - ENTER now) secs";
    }

    # $ perl6 -I. -MC -MD -e 'await-c; await-d'
    # 6.c version took 2.05268528 secs
    # 6.d version took 1.038609 secs

When we run the program, we see that 6.d version took a lot faster to complete
(in fact, if you bump the loop numbers by a factor, 6.d would still complete,
while 6.c would deadlock).

So this is the Perl 6 mechanism that lets the core developers make breaking
changes without breaking user's programs. There are some limitations to it
(e.g. methods on classes)—so for some things there will be standard
deprecation procedures. And we try to limit the number of such changes, if just
to reduce the maintenance burden alone—so don't worry about getting some weird
new language on the next language release.
