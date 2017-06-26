    sub powers-under-huge-of {
        Seq.new: class :: does Iterator {
            has int $.n is required;
            has int $!power = 0;
            has int $!max;

            submethod TWEAK { $!max = floor 500_000 × 10.log / $!n.log }

            method pull-one {
                $!power ≥ $!max
                    ?? IterationEnd
                    !! $!n ** $!power++
            }
            method count-only         {      −$!power       + $!max }
            method bool-only          { so    $!power       < $!max }
            method skip-one           { not ++$!power       > $!max }
            method skip-at-least (\n) { not  ($!power += n) > $!max }
        }.new: :$^n
    }

    my $powers := powers-under-huge-of 42;

    if $powers {
        say "Time after getting Bool: {now - INIT now}";

        say "We got $powers.elems() powers!";
        say "Time after getting count: {now - INIT now}";

        say "Fetching last one...";
        say $powers.skip($powers.elems-1).tail;
        say "Time after getting last elem: {now - INIT now}";
    }


    # OUTPUT:
    # Time after getting Bool: 0.0074300
    # We got 30802 powers!
    # Time after getting count: 25.6478771
    # Fetching last 10...
    # Time after getting last 10 elems: 25.6634408