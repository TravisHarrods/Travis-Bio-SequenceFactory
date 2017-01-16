use strict;
use warnings;
use Test::More;
use File::Compare;

BEGIN {
  use_ok('Travis::Bio::SequenceFactory');
  use_ok('Bio::SeqFeature::Generic');
}

# Read a simple sequence file
ok my $sf = Travis::Bio::SequenceFactory->new(
  input  => 't/data/embl/BK006935.embl',
  format => 'embl'
);

# Create a feautre list
my @features = ();
my $f1 = Bio::SeqFeature::Generic->new(
  -start  => 17455,
  -end    => 17721,
  -strand => -1,
  -primary => 'CDS',
  -tag => {
    note => 'Transfered from Travis::Bio::SequenceFactory.',
    gene => 'TOTO1'
  }
);
push @features, $f1;
my $f2 = Bio::SeqFeature::Generic->new(
  -start  => 227742,
  -end    => 228953,
  -strand => 1,
  -primary => 'CDS',
  -tag => {
    note => 'Transfered from Travis::Bio::SequenceFactory.',
    gene => 'IMD2'
  }
);
push @features, $f2;

ok my $seqid = $sf->sequences()->[0]->seqId(), 'Get the sequence ID.';

ok $sf->addFeatureSubset('new_cds', \@features, $seqid), 'Create the subset.';

ok $sf->insertSubsetFeature('new_cds'), 'Insert features from subset.';

ok $sf->changeOutputDirectories('t/data/test_output/'), 'Setting output dir.';

ok $sf->sortSequenceFeatures(), 'Sorting features according to there location.';

ok $sf->writeSequences(), 'Write output file.';

ok -f 't/data/test_output/BK006935.embl', 'Check if output exists.';
# cannot compare file because BioPerl failed to keep feature order!!!
#is compare('t/data/test_output/BK006935.embl', 't/data/test_output/BK006935.embl.expected'), 0, 'Compare produced file with expected file.';

done_testing();
