%% title: Perl 6 Is The Future And You Are Missing Out
%% date: 2016-08-17
%% desc: The perfectly objective truth about why Perl 6 rocks
%% draft: True

You guys are too easy! Any time I write something about Perl 6, you argue for
*days* about a minute feature I pointed out. So, I figured I'd write the
**absolute objective truth** about why Perl 6 is the language of the future
and why **you are missing out**! And when you're dying from exhaustion from
arguing over whether I am right, the Earth's supplies of ice-cream cones shall
be mine. Why?

![](/assets/pics/ice-cream.jpg)

I just like ice-cream cones... Let's begin!

## Parentheses Are So 1980s

Does your Language-of-Choice™ require you to type endless streams of
[gawd dammed parentheses](https://xkcd.com/297/)? Is the compiler too stupid
to know what you mean without them? Well, I've good news!

    sub things { ... }

    if $thing {
        do things;
    }

    say 'This is so awesome!';
    say 42.base: 16;

Perl 6 lets you omit parentheses when the meaning is obvious, like any
sane computer language of the 21st century should do. This includes `if`/`else`
conditionals, `given` blocks, subroutine calls, and the `:` syntax lets you
get rid of stupid parentheses on method calls as well. Good riddance!!

## I See Cores! Cores Everywhere!

You can spin up 32-core VMs on [Google Compute
Engine](https://cloud.google.com/compute/docs/) quite cheaply, yet
your Language-of-Choice™ still requires you to do write a bunch of stupid
boilerplate. Thank god for Perl 6!

    say 'oh my';
    start say 'a new thread you say?';

    react {
        whenever sub things { for ^1000 { rand.emit } } {
            "Holy crap! I got $^value from an asynchronous event loop!!!!";
        }
    }

    my $c = Channel.new;
    for ^100 -> $number {
        start {
            sleep $number;
            $c.send: "So wow! A hundred threads! This one is $number";
        }
    }

    loop {
        $c.receive -> $item {
            say "$item received after {now - INIT now} seconds";
        }
    }
