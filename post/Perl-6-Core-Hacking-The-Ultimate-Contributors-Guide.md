%% title: Perl 6 Core Hacking: The Ultimate Contributor's Guide
%% date: 2016-11-16
%% desc: How to contribute your stuff to Perl 6?
%% draft: true

On multiple occasions, someone would show up in our
[IRC channel](https://docs.perl6.org/webchat.html) and inquire about this or
that bit on how to contribute to a particular part of beast that is Perl 6.

While individual repos usually have `CONTRIBUTING.md` files, they're rather
large and detailed, yet don't cover some of the more general information, and
I'm often left either hunting for info all over the place, or guiding the
person through the process directly. But... no more! I present to you the
Ultimate Contributor's Guide to Perl 6 that should get you committing your
contribution in no time! Let's begin.

## The Map of Perl 6

There are several moving parts in Perl 6, each with its own repository.
Here's the map of how the parts fit in:

<div style="white-space: pre; font-family: monospace; font-size: 70%">
    +----------------------------------+    +-------------------------------+
    | <a href="https://github.com/perl6/roast/">Roast - The Perl 6 Specification</a> |----| <span style="color: red">(historical)</span> <a href="https://github.com/perl6/specs/">design.perl6.org</a> |
    +----------------------------------+    +-------------------------------+

    +--------+    +-----+    +--------+    +-------------+    +------------+
    | <a href="https://github.com/MoarVM/MoarVM/">MoarVM</a> |----| <a href="https://github.com/perl6/nqp/">NQP</a> |----| <a href="https://github.com/rakudo/rakudo/">Rakudo<a/> |----| <a href="https://github.com/rakudo/star/">Rakudo Star<a/> |----| <a href="http://rakudo.org">rakudo.org</a> |
    +--------+    +-----+    +--------+    +-------------+    +------------+


         +----------------+
    +----| <a href="https://github.com/perl6/docs/">docs.perl6.org</a> |
    |    +----------------+
    |
    |    +------------------+    +-------------------+
    +----| <a href="https://github.com/perl6/ecosystem/">Perl 6 Ecosystem</a> |----| <a href="https://github.com/perl6/modules.perl6.org/">modules.perl6.org</a> |
    |    +------------------+    +-------------------+
    |
    |    +-----------+
    +----| <a href="https://github.com/perl6/perl6.org/">perl6.org</a> |
         +-----------+
</div>

Clicking on the links in the above map will land you at the for that particular
piece of software or website. The exception being rakudo.org website, which
is just a Wordpress blog.

## The Parts and Pieces

**Perl 6** is a language, which is defined by the
**Roast (The Perl 6 Specification)**.
**Rakudo** is a compiler for that language that is written in Perl 6 and NQP.
**NQP**, or Not Quite Perl, is a subset of Perl 6 that's written in NQP.

The compiler generates bytecode for several supported virtual machines.
**MoarVM** is the bestest of them, although less-mature Java Virtual Machine
and JavaScript backends exist as well.

Lastly, **Rakudo Star** (sometimes written as **`R*`**) is a Rakudo distribution
that also includes the documentation and some modules. You don't *need* it and
can simply build Rakudo from source. It exists as a convenience of end-users,
since we usually pre-build binaries for several operating systems.

## Git and GitHub

All of the code lives on GitHub, but unfortunatelly teaching those two topics
is out of the scope of this guide. But don't worry. [It's easy!](https://xkcd.com/1597/)

Check out [GitHub Hello World Guide](https://guides.github.com/activities/hello-world/)
and [other guides offered by GitHub](https://help.github.com/articles/good-resources-for-learning-git-and-github/)

## Contributing to Docs

The easiest repo to contribute to is the [docs](https://github.com/perl6/docs/).
In many cases you can simply use [the online GitHub editor](https://help.github.com/articles/editing-files-in-your-repository/)
to make your changes without ever needing to fork or clone the repo.

It's also the easiest repo to get a commit bit for. If you frequently submit
changes, just ask for a commit bit [on our IRC channel](https://docs.perl6.org/webchat.html).

There are two parts of contributions you may be wishing to make:

### The Doc Content

The docs live in the `doc/` directory. The URL of the page you
want to change usually matches the file you would edit. For example
[https://docs.perl6.org/language/classtut](https://docs.perl6.org/language/classtut)
is located in `doc/Language/classtut.pod6` and
[https://docs.perl6.org/type/BagHash](https://docs.perl6.org/type/BagHash) is
located in `doc/Type/BagHash.pod6`

The exception to the rule are URLs that don't start with `language/`,
`type/`, or `programs/`, as these are dynamically generated when the site is
built. One such example is
[https://docs.perl6.org/routine/rotor](https://docs.perl6.org/routine/rotor).
If you visit that page you'll see it's created from several pages:
"class List" section title has "From List" text under it and "class Supply"
title has "From Supply" under it. That "from" link points to the class
that portion of the docs is from and that would usually be one of the `type/`
URLs that points to the `type/whatever.pod6` file where you will find that
particular routine.

#### Testing

While not required for a contribution, if you have a chance, run the content
tests by running `make xtest`. It's a somewhat lengthy test, so if you're in
a rush, run `make ctest` that will just do the basic content test.
See `make help` for all the options.

### The Doc Website

The [docs.perl6.org](https://docs.perl6.org) website itself is built via
a cron job every 15 minutes. The site processes the POD6 files in `doc/`
with [Pod::To::HTML module](http://modules.perl6.org/dist/Pod::To::HTML) so
there's a good chance your change would need to be done in that module and
after that change you will need to ask [on our IRC channel](https://docs.perl6.org/webchat.html)
(or on your Pull Request) that the module is updated on the server that builds the docs.

The rest of the HTML and assets live in `html/` and `template/` directories.
You can run the included development app with `./app-start`, after generating
the docs yourself by running `make`.

While `make` will generate all the docs, that usually takes a long time, so
if you're just changing website itself, you can run `make webdev-build`. See
`make help` for various other options.

## Contributing to Perl6.org

The site is generated every 15 minutes via a cron job. A couple of template
pieces live in `includes/` directory, while content, styles, and assets live
in `source/`.

You can generate your local version of the site by running `mowyw`
(part of [App::Mowyw *Perl 5* module](https://metacpan.org/pod/App::Mowyw)) and
you can start the local dev server by running `plackup`
(part of [Plack *Perl 5* module](https://metacpan.org/pod/Plack)). **TIP:**
delete `source/archive` directory before generating the site to save a lot of
time!

For large changes, it may be easier to work on the generated site in `online/`
directory and when you're done, to copy the changes back into the original
files.

### Blog Posts

If you run a Perl 6 blog and wish to have it listed in the "Recent Blog Post"
box on the [perl6.org homepage](https://perl6.org), simply add it to
[perlanetrc file in pl6anet.org
repo](https://github.com/stmuk/pl6anet.org/blob/master/perlanetrc)

## Contributing Modules

If you wrote a Perl 6 module and wish to add it to the Perl 6 Ecosystem,
simply add the link to your **raw** META6.json file to the end of the
[META.list](https://github.com/perl6/ecosystem/blob/master/META.list) file.
To get the raw link, just view your file on GitHub and click "Raw" button on
top, right corner.

This change is simple enough that you can use [the online GitHub
editor](https://help.github.com/articles/editing-files-in-your-repository/) to
submit it.

### Errors

Your module will show up on [modules.perl6.org](https://modules.perl6.org) the
next time it's built with cron, which takes about 1–2 hours. If your module
is not listed by then, there's likely a problem with the META file. You can
view the latest build log at
[https://modules.perl6.org/update.log](https://modules.perl6.org/update.log).
Searching for word `[error]` will find all the errors.

**TIP:** use [`Test::META`](https://modules.perl6.org/dist/Test::META) module
to detect any issues in your META file!

## Contributing to Modules.Perl6.org

The site is served by a web app that's hot-restarted after each new ecosystem
build (every 1–2 hours). Since there are few contributors to this repo and
it's meant to be a temporary thing, I won't go into the details. Simply
see the [DEPLOYMENT.md](https://github.com/perl6/modules.perl6.org/blob/master/DEPLOYMENT.md)
file to find out how to start the dev app.

## Contributing to Rakudo
