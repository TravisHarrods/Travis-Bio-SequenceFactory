use strict;
use warnings;
use Test::More;

BEGIN {
  use_ok('Travis::Bio::SequenceFactory');
  use_ok('Bio::SeqFeature::Generic');
}

# Read a simple sequence file
ok my $sf = Travis::Bio::SequenceFactory->new();

# Create a list of features
my @features = ();
my $ssid  = "ssid01";
my $seqid = "seqid01";
my $f1 = Bio::SeqFeature::Generic->new(
  -start  => 10,
  -end    => 20,
  -strand => 1,
  -primary => 'gene'
);
my $f2 = Bio::SeqFeature::Generic->new(
  -start  => 100,
  -end    => 200,
  -strand => -1,
  -primary => 'gene'
);
push @features, $f1;
push @features, $f2;

ok $sf->addFeatureSubset($ssid, \@features, $seqid), 'Create a feature subset.';

ok $sf->hasFeatureSubset($ssid), 'Check if a subset exists.';

ok !$sf->hasFeatureSubset('failed_id'), 'check for an unknown subset.';


done_testing();
