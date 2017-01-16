use strict;
use Test::More tests => 4;

BEGIN {
  use_ok('Travis::Bio::SequenceFactory');
}

# Read a simple sequence file
ok my $sf = Travis::Bio::SequenceFactory->new(
  input  =>  't/data/fasta/single.fasta'
), 'Reading single.fasta file.';

# Test simple data accessions
is $sf->countSequences(), 1, 'Counting the number of stored sequences.';
ok $sf->testSequenceIndex('YMR298W'), 'Accessing a sequence ID.';
