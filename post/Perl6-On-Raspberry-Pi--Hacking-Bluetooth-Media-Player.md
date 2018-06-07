%% title: Perl 6 on Raspberry Pi: Hacking a Bluetooth Media Player
%% date: 2018-06-04
%% desc: Step by step guide of building a media player using Rspberry Pi computer and Perl 6
%% draft: true

As some know, recently, I acquired a Perl6mobile! The car is awesome in every
way, except for one: playing music. I connect my phone via bluetooth to play
it. The fast-forward feature doesn't work (apparently, it's my phone), but
worst of all I can only skip tracks one-by-one; can't move into different
folders directly.

The solution? Build a Pi, stick Perl 6 on it, and make the platest of the
car match the contents :)


# Part I: Setting Up The Pi

## Hardware

I got myself the [Raspberry Pi 3 Model B+ Ultimate Kit](https://www.canakit.com/raspberry-pi-3-model-b-plus-ultimate-kit.html), along with
[LCD Touchscreen Display](https://www.canakit.com/raspberry-pi-lcd-display-touchscreen.html) and [a case for it](https://www.canakit.com/oneninedesign-pi-case.html). If working with a different Pi, keep in mind you need about]
1.4GB of RAM+swap to build [Rakudo Perl 6 compiler](https://rakudo.org/), so
lower-RAMmed Pi's might not cut it.

To setup the software, you'll either need a keyboard or a way to SSH to your
pi via WiFi or USB cable. By default there's no on-screen keyboard, sadly,
so you won't be able to use the touchscreen alone to do any of the setup.

First, connect the flat strip display cable to the display by sliding up the clip on the connector, inserting the cable, matching the metal portions on the
cable to those inside of the connector, and sliding the clip back into locking
position. Connect the other end to the Pi, to the connector marked "display".
The instructions say you should install the microSD card last, but with the
cable and the case in the way, I installed it right away.

Next, you have the option to [follow these other instructions](https://www.modmypi.com/blog/raspberry-pi-7-touch-screen-assembly-guide) and hook up the
power to the display to come from your Pi. I didn't realize that was an option
before I hooked everything up, so I powered the Pi and the display with two
separate power supplies.

The case isn't an official Pi product, and it proved slightly annoying to
get installed into. First, get the Pi and the display into the case, but
don't screw the Pi in yet. Ensure the edges of the USB connectors stick out from the case or the screw holes won't align. Screw in the case with the
screws that came with it, then screw the Pi into the holes on the display.
A magnetic screwdriver or tweezers will come in handy, especially for the
screw that's right under a piece of case's plastic.

Next, install the two heatsinks by peeling the protecting tape and sticking
them onto the CPU and the Ethernet/USB controller.

## Software

Hook up the power to the display and the Pi and it'll boot up.

If you're going to SSH remotely as opposed to using the physical keyboard,
then touch raspberry menu icon in the corner. Then go to
`Preferences->Raspberry Pi Configuration`. In `Interfaces` tab, ensure `SSH`
is enabled. Then touch the raspberry menu again, `Shutdown -> Reboot` (I had
to reboot, not sure if that's necessary).

For network, simply hooking up Ethernet cable into Pi's port and the other
end to my router worked for me. To figure out the IP of the Pi, I looked at the
status list on the router's web page
([192.168.0.1](http://192.168.0.1)). Now, grab the box
you'll be ssh'ing from, and ssh into the Pi. The default user is `pi` and
password is `raspberry`:

    ssh pi@192.168.0.106
    Enter password: raspberry

    pi@raspberrypi:~ $

### Add New User

This is sorta optional. I like using my own user, so I'll set one up:

    sudo adduser zoffix
    sudo adduser zoffix sudo
    sudo chmod 700 /home/zoffix

Now log out from the `pi` user and log in as your new user. I'll also set up
keys to not have the thing ask me for password all the time:

    logout

    ssh zoffix@192.168.0.106
    ssh-keygen
    echo 'ssh-rsa AAAA[...]PBCT zoffix@VirtualBox' >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys

Test the key setup works:

    logout
    ssh zoffix@192.168.0.106

I tried to dump the default `pi` user, but it refused because a process
was using it:

    sudo deluser -remove-home pi

So I just locked the account:

    sudo passwd --lock pi

### Install Needed Software

We'll install the on-screen keyboard to use with our touchscreen as well
as the tools needed to build Rakudo Perl 6.

    sudo apt-get update && sudo apt-get -y upgrade &&
    sudo apt-get install -y matchbox-keyboard build-essential git

Personally, the original steps failed for me and were unable to find
`matchbox-keyboard` package, however, running the following commands and
re-running the original ones fixed it:

    sudo apt-get autoremove && sudo apt-get -f install &&
    sudo apt-get update && sudo apt-get upgrade -y

I also like to pre-install some of the tools I use and build latest and
greatest Perl 5, so I could use Perl 5 modules via
[`Inline::Perl5`](https://modules.perl6.org/repo/Inline::Perl5). You
can do so too, but this stuff is optional.

    sudo apt-get -y install curl aptitude libssl-dev wget htop zip sqlite3 time

    \curl -L https://install.perlbrew.pl | bash
    echo 'source ~/perl5/perlbrew/etc/bashrc' >> ~/.bashrc
    source ~/.bashrc

    # NOTE: substitute 5.26.2, for whatever current latest version is
    # You can find it out by running `perlbrew available`
    perlbrew install perl-5.26.2 --notest -Duseshrplib -Dusemultiplicity
    perlbrew switch perl-5.26.2

I tried to get the on-screen keyboard to work on the login screen, but failed
and gave up. Instead, I made the Pi to auto-log in as my user:

    sudo raspi-config

    # Select (3) Boot Options
    # Select (B1) Desktop/CLI
    # Select Desktop Autologin

### WiFi

Since the Pi will be in my car, I won't have Ethernet connection. Time to
setup the WiFi. I had two access points: my router at home and the hotspot
mode on my [sexy smartphone](https://www.essential.com/).

Using the WiFi widget on Pi's desktop didn't work out for me, so I ssh'ed into
it and did the setup using command line commands.

First, I had to set the country for the WiFi. This is likely not needed on
models earlier than Pi 3 B+ and the reason B+ needs it is so 5G networking can
choose correct frequency bands:

    sudo raspi-config

    # Select (4) Localization Options
    # Select (I4) Change Wi-Fi Country
    # Pick your country

If you don't already know the SSID of the access point you're going to connect
to, you can scan for it:

    sudo iwlist wlan0 scan

Now, set up the access points:

    sudo pico /etc/wpa_supplicant/wpa_supplicant.conf

I'm going to add both of my access points to that file, setting priority
to my home access point so that if both my phone and my home AP are
connectable, the home one gets chosen. The `ssid` is the name of the access
point and the `psk` is the passphrase.


    network={
            ssid="HomeAccessPoint"
            psk="tehPassword"
            priority=1
    }

    network={
            ssid="ZofAP"
            psk="AnotherPassword"
            priority=2
    }

If you don't want to stick passphrases in plain text, look up
`wpa_passphrase` and use the hash (unquoted) it generates instead of the
quoted plaintext pass.

    man wpa_passphrase

If your access point is unsecured, instead of `psk` key, set:

    key_mgmt=NONE

Reboot the Pi and it should connect up:

    sudo reboot

### Build Rakudo Perl 6

To get `perl6`, you can try seeing how [Debian pre-built 3rd-party compiler-only packages](https://rakudo.org/files/rakudo/third-party) work out for you.
I'm going to go with building-from-scratch route.

To build Rakudo, you need about 1.4GB of RAM+swap. My Pi had 927MB of RAM and
100MB of swap, so the first step was to bump the swap:

    sudo pico /etc/dphys-swapfile

Then bump the number in that file for this var. I went for 2GB of swap:

    CONF_SWAPSIZE=2000

Save, and then reboot the Pi:

    sudo reboot

Next, I'm going to set up
[my trusty update bash alias](https://github.com/zoffixznet/r):

    git clone https://github.com/rakudo/rakudo/ ~/rakudo
    echo 'export PATH="$HOME/rakudo/install/bin:$HOME/rakudo/install/share/perl6/site/bin:$PATH"' >> ~/.bashrc
    echo 'alias update-perl6='\''
        cd ~/rakudo && git checkout master && git pull &&
        git checkout $(git describe --abbrev=0 --tags) &&
        perl Configure.pl --gen-moar --gen-nqp --backends=moar &&
        make && make install'\''' >> ~/.bashrc
    source ~/.bashrc

And then just install rakudo and then zef. This took about 25 minutes on
my Pi.

    update-perl6
    cd $(mktemp -d)
    git clone https://github.com/ugexe/zef.git .
    perl6 -Ilib bin/zef install .

We're all set!

# Part II: Programming a GTK-based BlueTooth Media Player

Half a dozen years ago, I implemented parts of Bluetooth file transfer spec
from scratch in Perl 5, to load pictures from my phone. It was a fun
experience and I'd love to eventually do the same in Perl 6 to connect my Pi
and my car, today's not the day. Not only doing so would make this tutorial
even larger than it already is, thanks to living in an apartment building,
trying to test out some Bluetooth code involves dealing with man's worst
friend: pants.

To simplify the matters, I'm going to use Perl 6 to hack up a nice interface
to control some Bluetooth-connectable, audio-playing thingamajig on my Pi.

### Bluetoothing


