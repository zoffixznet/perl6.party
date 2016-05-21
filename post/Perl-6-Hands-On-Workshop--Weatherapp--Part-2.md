%% title: Perl 6 Hands-On Workshop: Weatherapp [Part 2]
%% date: 2016-05-22
%% draft: True

*Be sure to read [Part 1 of this workshop](/post/Perl-6-Hands-On-Workshop--Weatherapp--Part-1) first.*

Imagine writing 10,000 lines of code and then throwing it all away.
Turns out when the client said "easy to use,"
they meant being able to access the app without a password, but you took it
to mean a "smart" UI that figures out user's setup and stores it together
with their account information. Ouch.

The last largish piece of code where I didn't bother writing design docs
was 948 lines of code and documentation. That doesn't include a couple of
supporting plugins and programs I wrote using it. I had to blow it all
up and re-start from scratch. There weren't any picky clients involved. The
client was me and in the first 10 seconds of using that code in a real program,
I realized it sucked. Don't be like me.

Today, we'll write a detailed design for our weather reporting program. There
are plenty of books and opinions on the subject, so I won't tell you how
*you* should do design. I'll tell you how *I* do it and if at the end you'll
decide that I'm an idiot, well... at least I tried.

## The Reason

It's pretty easy to convince yourself that writing design docs is a waste
of time. The reason for such a feeling is because design future-proofs the
software and us, squishy sacks of snot and muscle,
really like the type of
stuff we can touch, see, and run right away. However, unless you can hold
all the workings of your program entirely into your head at once, you'll
benefit from jotting down the design first.

Here are some of the arguments against doing so I heard from others or thought
about myself:

### It's more work / More time consuming

That's only true if you consider the amount of work done today or in the
next couple of weeks. Unless it's a one-off script that can die after that time,
you'll have to deal with new features added, current features modified,
appearances of new technologies and deprecation of old ones.

If you never sat down and actively thought about how your piece of software will
handle those things, it'll be more work to change them later on, because you'll
have to change the architecture of already-written code and that might mean
rewriting the entire program in extreme cases.

There are worse fates than a rewrite, however. How about being stuck with
awful software for a decade or more? It does everything you want it to,
if you add a couple of convoluted hacks no one know how to maintain.
You can't really change it, because it's
a lot of work and too many things depend on it working the way it is right now.
Sure, the interface is abhorrent, but at least it works. And you can pretend
that piece of code doesn't really exist, until your boss tells you to add
a new feature to it.

### Yeah, tell it to my boss!

You tell them! Listen, if your boss tells you to write a complicated program
in one hour... which parts of it would you leave unimplemented, for the client
to complain about? Which parts of it would you leave buggy? Which parts
of it would you leave unsecure?

Because you're doing the same thing when you don't bother with the design,
don't bother with the tests, and don't bother with the documentation. The
only difference is the time when people find out how screwed everyone is
is further in the future, which lets you delude yourself into thinking those
parts can be omitted.

Just as you would tell your boss they aren't giving you enough time in the
case I described above, tell the same if you don't have the time to write down the design or the docs. If they insist the software must get finished sooner,
explain to them the repercussion of omitting the steps you plan to omit, so that
when shit hits the fan, it's on them.

### I think better in code

This is the trap I myself used to fall into more often than I care to admit.
You start writing your "design" by explaining which class goes where and
which methods it has and... five minutes in you realize writing all that in code
is more concise anyway, so you abandon the idea and start programming.

The cause for that is your design is too detailed. The more of the design
you can write without having to rely on specific details of an
implementation, the more robust your application will be and as time
goes on and technologies comes and go, what your app is supposed to do remains
clear and in human language.

To give you a real-world example: 8–10 years ago, the biggest argument I had
with other web developers was the width of the website. You see, 760–780 pixel
maximum width was the golden standard, because some people had 800x600 monitor
resolutions and so, if you account for the scrollbar's width, the 780 pixel
website fit perfectly without horizontal scrolling. I didn't think of those
people as people, and often used 900 pixel widths... or even 1000px, when
I was feeling especially rebellious.

Now, imagine implementation-specific design docs that address that detail:
"The website must be 780 pixels in width." Made sense in the past, but is
completely ludicrous today. A better phrasing should've been
"The website must avoid horizontal scrolling."

The other reason to avoid writing your design in code is we're more attached
to code than to mere words. If you spent an hour writing and debugging a
clever class, it's a bit painful to just erase it entirely, because you realized
your design is less than perfect. While you don't have to debug or be
clever about a couple of paragraphs of text.

If I'm writing a program that extracts stuff from some protocol and
passes it around inside of messages,
I can easily change what those messages are like without having to rewrite
the *code* for my parser or the protocol implementation.

### The benefits

Along with the aforementioned benefits of having a written design document,
there are two more that are more obvious: tests and user documentation.

A well-written and complete design document is the human-language version
of decent machine-language tests. It's easier to do TDD (Test Driven
Development), which we'll do in the next post in this series, and your tests
are less reliant on the specifics of the implementation, so that they
don't blow up every time you make a change.

Also, a huge chunk of your design document can be
re-used for user documentation. We'll see that
first-hand we we get to that part.

## The Design

By this point, we have two groups of readers: those who are convinced
we need a design and those who need to keep track of the line count
of their programs to cry about when they have to rewrite them from scratch,
(well, three groups: those who already think I'm an idiot).

We'll pop open `DESIGN.md` that we started in [Part 1](/post/Perl-6-Hands-On-Workshop--Weatherapp--Part-1) and add to it.

### Throw Away Your Code

The best code is not the most clever, most documented, or most tested. It's
the one that's easiest to throw away and replace. And you can add and
remove features and react to technology changes by throwing away code
and replacing it with better code. Since replacing the entire program
each time is expensive, we need to construct our program out of
*pieces* each of which is easy to throw away and replace.

Our weather program is something we want to run from a command line.
If we shove all of our code into a script, we're faced with a problem tomorrow,
when we decide to share our creation with our friends in a form of a
web application.

We can avoid that issue by packing all functionality into a module that
provides a function. A tiny script can call that function and print the
output to the terminal and a web application can provide the output to
the web browser.

We have another weakness on the other end of the app: the weather service we
use. It's entirely out of our control whether it continues to be
fast enough and cheap enough or exists at all. A dozen of now-defuct pastebin
modules I wrote are a testament to how frequently a service can disappear.

We have to reduce the amount of code we'd need to replace, should
[OpenWeatherMap](www.openweathermap.org) disappear. We can do that by creating
an abstraction of what a weather service is like and implementing as much
as we can inside that abstraction, leaving only the crucial bits in
an OpenWeatherMap-specific class.

Let's write the general outline into our `DESIGN.md`:

```
    # GENERAL OUTLINE

    The implementation is a module that provides a function to retrieve
    weather information. Currently supported service
    is [OpenWeatherMap](www.openweathermap.org), but the implementation
    must allow for easy replacement of services.
```

### Details

Let's put on the shoes of someone who will be using our code and think
about the easiest and least error-prone way to do so.

First, how will a call to our function look like? The
[API](http://www.openweathermap.org/current) tells us all we need is a
city name, and if we want to include a country, just plop its code in after
the city, separated with a comma. So, how about this:

    my $result = weather-for 'Brampton,ca';
