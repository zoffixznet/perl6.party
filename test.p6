#my List $list := ^4000 .grep: *.is-prime;
#.say for $list;

my $list := (1, 2, 3);
say $list.perl;
say "Item: $_" for $list;

# OUTPUT:
# (1, 2, 3)
# Item: 1
# Item: 2
# Item: 3


my $listish = (1, 2, 3);
say $listish.perl;
say "Item: $_" for $listish;

# OUTPUT:
# $(1, 2, 3)
# Item: 1 2 3