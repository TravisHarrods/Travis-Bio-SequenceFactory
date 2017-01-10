use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
  module_name        => 'Travis::Bio::SequenceFactory',
  licence            => 'perl',
  dist_author        => 'Travis Harrods <travis.harrods@gmail.com>',
  dist_abstract      => 'A module to manage Bio::Seq/Bio::SeqIO objects.',
  dist_version_from  => 'lib/Travis/Bio/SequenceFactory.pm',
  requires           => {
    'Moose'          => 0,
    'Travis::Utilities::Log' => 0.01,
    'Travis::Utilities::Files' => 0.01,
    'Bio::SeqIO' => 0,
    'File::Basename' => 0
  },
  meta_merge => {
    ressources => {
      repository => 'https://github.com/TravisHarrods/Travis-Utilities-SequenceFactory'
    }
  },
  create_makefile_pl => 'traditional',
  installdir         => 'vendor'
);

$builder->create_build_script();
