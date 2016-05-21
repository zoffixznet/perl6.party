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
I realized it sucked.

Don't be like me.

##




Our weather reporting app as
a script run by one user from command line will be vastly different than
the same app but run by millions of users per day from a Web application.
