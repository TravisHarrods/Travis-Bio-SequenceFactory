package Travis::Bio::SequenceFactory::BioFormat;

#==============================================================================
# Travis::Bio::SequenceFactory::BioFormat allows to validate file format/extension.
#
# Author: Hugo Devillers
# Created: 17-MAR-2016
# Updated: 10-JAN-2017
#==============================================================================

#==============================================================================
# REQUIERMENTS
#==============================================================================
# CPAN modules
use Moose;

#==============================================================================
# ATTRIBUTS
#==============================================================================
has 'ext_to_format' => (
   traits   => ['Hash'],
   is       => 'rw',
   isa      => 'HashRef',
   default  => sub {
      {
         embl  => 'embl',
         fasta => 'fasta',
         fsa   => 'fasta',
         gb    => 'genbank'
      }
   },
   handles  => {
      findExtFormat => 'get',
      setExtFormat  => 'set',
      testExtFormat => 'exists'
   }
);

has 'format_to_ext' => (
   traits   => ['Hash'],
   is       => 'rw',
   isa      => 'HashRef',
   default  => sub {
      {
         embl    => 'embl',
         fasta   => 'fasta',
         genbank => 'gb'
      }
   },
   handles  => {
      findFormatExt => 'get',
      setFormatExt  => 'set',
      testFormatExt => 'exists'

   }
);

has 'format_to_regex' => (
   traits   => ['Hash'],
   is       => 'ro',
   isa      => 'HashRef',
   default  => sub {
      {
         embl    => 'embl',
         fasta   => 'fasta|fsa',
         genbank => 'gb'
      }
   },
   handles => {
      findFormatRegex => 'get',
      testFormatRegex => 'exists'
   }
);


no Moose;
return(1);
