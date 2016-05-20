%% title: Perl 6 Hands-On Workshop: Weatherapp [Part 1]
%% date: 2016-05-18
%% draft: True

*Welcome to the Perl 6 Hands-On Workshop, or Perl 6 HOW, where instead of
learning about a specific feature or technique of Perl 6, we'll be learning
to build entire programs or modules.*

*Knowing a bunch of method calls won't make you a good programmer. In fact,
actually writing the code of your program is not where you spend most of
your time. There're requirements, design, documentation, tests, usability
testing, maintenance, bug fixes, distribution of your code, and more.*

*This Workshop will cover those areas. But by no means should you accept
what you learn as authoritative commandments, but rather as reasoned tips.
It's up to you to think about them and decide whether to adopt them.*

## Project: "Weatherapp"

In this installment of *Perl 6 HOW* we'll learn how to build an application
that talks to a Web service using its API (Application Programming Interface).
The app will tell us weather at a location we provide.
Sounds simple enough! Let's jump in!

## Preparation

I'm be using Linux with bash shell. If you aren't, you can get a
[good distro](http://www.bodhilinux.com/) and run it in [VirtualBox](https://www.virtualbox.org/wiki/Downloads), or just try to find
what the equivalent commands are on your OS. It should be fairly easy.

I'll also be using [`git`](https://git-scm.com/) for version control. It's
not required that you use this type of version control and you can skip all
the `git` commands in the text. However, using version control lets you
play around with your code and not worry about breaking everything,
especially when you [store your repository somewhere online](https://github.com/). I highly
recommend you familiarize yourself with it.

To start, we'll create an empty directory `Weatherapp` and initialize a new
git repository inside:

    mkdir Weatherapp
    cd !$
    git init

## Design Docs: "Why?"

Before we write down a single line of code we need to know a clear answer
for what problem you're trying to solve. The "tell weather" is ridiculously
vague. Do we need real-time, satellite-tracked wind speeds and pressures
or is temperature alone for one day for just the locations within United States
is enough? The answer will drastically change the amount of code written and
the web service we'll choose to use—and some of those are rather expensive.

Let's write the first bits of our design docs: the purpose of the code.
This helps define the scope of the project and lets us evaluate what tools
we'll need for it and whether it is at all possible to implement.

I'll be using [Markdown](https://daringfireball.net/projects/markdown/syntax)
for all the docs. Let's create `DESIGN.md` file in our app's directory and
write out our goal:

    # Purpose

    Provide basic information on the current weather for a specified location.
    The information must be provided for as many countries as possible and
    needs to include temperature, possibility of precipitation, wind
    speed, humidex, and windchill. The information is to be provided
    for the current day only (no hourly or multi-day forecasts).

And commit it:

    git add DESIGN.md
    git commit -m 'Start basic design document'
    git push

With that single paragraph, we significantly clarified what we expect
our app to be able to do. Be sure to pass it by your client and resolve all
ambiguities. At times, it'll feel like you're just annoying them with
questions answers to which should be "obvious," but a steep price tag
for your work is more annoying. Besides, your questions can often bring to
light things the client haven't even though of.

Anyway, time to go shopping!

## Research and Prior Art

Before we write anything, let's see if someone already wrote it for us.
Searching [the ecosystem](http://modules.perl6.org/) for `weather` gives
zero results, at the time of this writing, so it looks like if we want
this in pure Perl 6, we have to write it from scratch. Lack of Perl 6
implementation doesn't *always* mean you have to write anything, however.

What zealots who endlessly diss everything that isn't their favourite language
don't tell you is their closet is full of reinvented wheels, created for
no good reason. You can use C libraries with [NativeCall](http://docs.perl6.org/language/nativecall),
most of Perl 5 modules with
[Inline::Perl5](http://modules.perl6.org/repo/Inline::Perl5), and there's
[a handful of other Inlines](http://modules.perl6.org/#q=Inline) in the
ecosystem, including Python and Ruby. When instead of spending several weeks
designing, writing, and testing code you can just use someone's library that
did all that already, you are a winner!

That's not to say such an approach is always the best one. First, you're
adding extra dependencies that can't be automatically installed by
[`panda`](http://modules.perl6.org/dist/panda) or
[`zef`](https://modules.perl6.org/dist/zef). The C library you used might
not be available at all for the system you're deploying your code on.
`Inline::Perl5` requires perl compiled with `-fPIC`, which may not be the
case on user's box. And your client may refuse to involve Python without
ever giving you a reason why. This is a decision you'll have to make yourself.



---



Imagine writing 10,000 lines of code and then throwing it all away.
Turns out when the client said "easy to use,"
they meant being able to access the app without a password, but you took it
to mean a "smart" UI that figures out user's setup and stores it together
with their account information. Ouch.

Our weather reporting app as
a script run by one user from command line will be vastly different than
the same app but run by millions of users per day from a Web application.
