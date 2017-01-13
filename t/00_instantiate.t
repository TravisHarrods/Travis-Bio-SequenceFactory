use strict;
use Test::More tests => 2;

BEGIN {
  use_ok('Travis::Bio::SequenceFactory');
}

ok my $sf = Travis::Bio::SequenceFactory->new();
