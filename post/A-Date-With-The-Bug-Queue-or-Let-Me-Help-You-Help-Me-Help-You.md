%% title: A Date With The Bug Queue or Let Me Help You Help Me Help You
%% date: 2016-07-10
%% desc: Lessons learned from going through 1,300+ bug reports
%% draft: True

Recently, I decided to undertake a quick little journey down to the
[Perl 6's Bug Queue](https://rt.perl.org/). A quest for fame and profit—some
easy game to hunt for sport. There's plenty of tickets, so how hard can
it be? The quick little journey turned out to be long and big, but I've
learned some good lessons in the process.

![](/assets/pics/date-with-bug-queue/found-tickets.png)

Right away, I hit a snag. Some tickets looked hard. On some, it wasn't clear
what the correct goal was. And some looked easy, but I wasn't sure whether
I wanted to work on them just yet. While the ticket queue has the tag system,
I needed some personal tags. Something special just for me....

## The Ticket Trakr

So I wrote a [nice little helper app—Ticket
Trakr](https://github.com/zoffixznet/perl6-Ticket-Trakr). It fetches all the
tickets from the bug queue onto one page and lets me tag each of them
with any combination of:

* Try to fix
* Easy
* Tests needed
* Needs core member decision
* Needs spec decision
* Check ticket later
* Needs checking if it's still broken
* Too hard
* Not interested

![](/assets/pics/date-with-bug-queue/trakr.png)

The app worked great! I quickly started going through the queue, looking over
the tickets, testing if the bugs were still there, and estimating whether
I could and wanted to fix them. And after a full weekend of clicking, tagging,
testing, closing, taking an occasional break to
[hunt bears with a mortar](https://www.youtube.com/watch?v=VEsP7XR4EDA),
more closing, testing, tagging, and clicking, I... was through just 200
tickets, which is only 15% of the queue:

![](/assets/pics/date-with-bug-queue/number-done.png)

And so I've learned the first lesson.

## LESSON 1: Going Through Bug Reports is a Full Time Job

Whenever I see someone ask how they can contribute, the basket of offers they
receive generally contains: docs, marketing, modules and libraries, or bug
fixing. Going through the ticket queue doesn't seem to be considered a task
on itself. The ticket queue is just a place where you find the bugs to fix,
right?

What may not be obvious is the bug queue contains an extraordinary amount of
work that can be performed by less skilled contributors to *make it easier
for highly-skilled—and by extension much scarcer—contributors to fix bugs.*
Let's see what those are:

### Deciding On Whether The Report Should Be Accepted

Just because you have 1,000 tickets in your bug queue doesn't mean you have
1,000 bugs. Here are some things that might end up as a ticket:

* **Poor bug reports:** reply, asking for a decent test case or the missing
information
* **Bug reports for an unrelated project:** move them (or, for the lazy, just close with explanation)
* **Feature proposals:** ping core members and users for discussion
* **A feature confused for a bug:** explain the confusion; *add to documentation if this confusion happens often*
* **Incorrectly used code that were never meant to work:** offer a correct example; improve documentation, if needed
* **People asking for help with their code:** redirect to appropriate help channels; improve documentation, if this happens often
* **Patches for other bugs:** apply the patches, move them to the appropriate
ticket, or make them easier to merge (e.g. make a Pull Request)
* **Duplicate bug reports:** point out the dupe and close the report
* **Spam:** grab some white bread and have a lunch break

This is a lot of work, but this is just the basics. What else can a person
new to the project can contribute?

## Debugging

So we've cleaned up our queue and now we have a few reports that appear to have
at least some sort of a [six-legged](https://www.google.com/search?q=how+many+legs+do+bugs+have) quality to them. Sure, we're new to
the project and don't even where to begin fixing them, but that doesn't mean
we can't play around with code to narrow down the problem.




