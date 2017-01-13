package Travis::Bio::SequenceFactory::Sequence;

#==============================================================================
# Travis::Bio::SequenceFactory::Sequence handles a Bio::Seq object.
#
# Author: Hugo Devillers, Travis Harrods
# Created: 29-FEB-2016
# Updated: 11-JAN-2017
#==============================================================================

#==============================================================================
# REQUIERMENTS
#==============================================================================
# CPAN modules
use Moose;
use File::Basename;

# Bio perl modules
use Bio::SeqIO;

# Travis' modules
use Travis::Utilities::Log;
use Travis::Bio::SequenceFactory::BioFile;


#==============================================================================
# LOGGING
#==============================================================================
my $log = Travis::Utilities::Log->new();


#==============================================================================
# ATTRIBUTS
#==============================================================================
# Complete input path (dir+file name)
has 'input_path' => (
   is       => 'ro',
   isa      => 'Str',
   required => 1,
   init_arg => 'input',
   trigger  => \&_checkInputPath
);

# Input format
has 'input_format' => (
   is      => 'ro',
   isa     => 'Str',
   default => ''
);

# Complete output path (dir+file name)
has 'output_path' => (
   is       => 'ro',
   isa      => 'Str',
   default  => '',
   init_arg => 'output'
);

# Output format
has 'output_format' => (
   is      => 'ro',
   isa     => 'Str',
   default => '',
);

# Input file manager
has 'input_handler' => (
   is      => 'rw',
   isa     => 'Travis::Bio::SequenceFactory::BioFile',
   lazy    => 1,
   default => sub {
      my $self = shift;
      my $handler;
      if( $self->input_format ne '' ) {
          $handler = Travis::Bio::SequenceFactory::BioFile->new(
            path   => $self->input_path(),
            format => $self->input_format
         );
      } else {
         $handler = Travis::Bio::SequenceFactory::BioFile->new(
            path   => $self->input_path()
         );
      }
      return($handler);
   },
   handles => {
      getInputPath   => 'getPath',
      getInputFormat => 'getFormat'
   }
);

# Output file manager
has 'output_handler' => (
   is      => 'rw',
   isa     => 'Travis::Bio::SequenceFactory::BioFile',
   lazy    => 1,
   default => sub {
      my $self = shift;
      my $handler;
      if( $self->output_path() ne '' ) {
         if( $self->output_format ne '' ) {
            $handler = Travis::Bio::SequenceFactory::BioFile->new(
               path   => $self->output_path(),
               format => $self->output_format
            );
         } else {
            $handler = Travis::Bio::SequenceFactory::BioFile->new(
               path   => $self->output_path()
            );
         }
      } else {
         $handler = Travis::Bio::SequenceFactory::BioFile->new(
            path => $self->input_path()
         );
         if( $self->output_format() ne '' ) {
            $handler->setFormat( $self->output_format() );
         }
      }
      return($handler);
   },
   handles => {
      getOutputPath      => 'getPath',
      getOutputFormat    => 'getFormat',
      getOutputDirectory => 'getDirectory',
      setOutputPath      => 'setPath',
      setOutputFormat    => 'setFormat',
      setOutputDirectory => 'setDirectory'
   }
);

# The Bio::Seq data
has 'bioseq' => (
   is          => 'rw',
   isa         => 'Maybe[Bio::Seq]',
   default     => undef,
   handles     => {
      seqId          => 'display_id',
      getDescription => 'desc',
      getSequence    => 'seq',
      getLength      => 'length',
      getFeatures    => 'get_SeqFeatures',
      getAnnotations => 'annotation',
      removeFeatures => 'remove_SeqFeatures',
      addFeature     => 'add_SeqFeature'
   }
);

# Internal Id: by default it is equeal to self->seqId() but to avoid confusion
# when considering several sequences with the same id (or unknown id) in the
# sequenceFactory a different internal id can be set
has 'seqInternalId' => (
   is      => 'rw',
   isa     => 'Str',
   default => ''
);

# Indicate if the bioseq is a richSeq (contains annotations and features)
has 'is_rich_seq' => (
   is      => 'rw',
   isa     => 'Bool',
   default => 0,
   reader  => 'getRichSeq',
   writer  => 'setRichSeq'
);

# Feature type (primary tag) level
has 'feature_level' => (
   traits => ['Hash'],
   is     => 'rw',
   isa    => 'HashRef',
   default => sub{
      {
         gene => 1,
         mobile_element => 1,
         mRNA  => 2,
         CDS   => 3,
         other => 4
      }
   },
   handles => {
      hasFeatureLevel => 'exists',
      getFeatureLevel => 'get'
   }
);

#==============================================================================
# BUILDER
#==============================================================================
# Builder
sub BUILD
{
   my $self = shift;

   # input_path attribute is mandatory

   # If the Bio::Seq object is not provided, check for an input_path and load
   # the first sequence.
   if( !defined( $self->bioseq() ) ) {
      $log->trace('No Bio::Seq object provided. Trying to open input_path.');
      # Check for possible Bio::SeqIO failure(s)
      eval {
         my $in_seq = Bio::SeqIO->new(
            -file   => $self->getInputPath(),
            -format => $self->getInputFormat()
         );

         # Get the first sequence and store it
         my $seq = $in_seq->next_seq();
         $self->bioseq($seq);
      };
      if( $@ ) {
         # An error occured!
         $log->fatal('An error occured while running Bio::SeqIO parser: '.$@);
      }
   }

   # Check if the Bio::Seq if is a RichSeq
   if( $self->bioseq()->isa('Bio::Seq::RichSeq') ) {
      $self->setRichSeq(1);
   }

   # Set the default internal id
   $self->seqInternalId( $self->seqId() );
}


#==============================================================================
# TRIGGERS
#==============================================================================
# Check if the provided input path exists
sub _checkInputPath {
   my $self       = shift;
   my $input_path = shift;

   # Check if the input is reachable
   if( !(-f $input_path) ) {
      $log->fatal('Cannot reach the input file ('.$input_path.').');
   }
}


#==============================================================================
# PRIVATE METHODS
#==============================================================================
# Convert numeric in string comparable value (add 0)
sub _num2str {
   my $self  = shift;
   my $value = shift;
   my $max_zero = 20; # Very large limit!

   my $to_add = $max_zero - length($value);
   my $prefix = "0"x$to_add;
   return( $prefix.$value);
}
# Feature sort factor
# From a given feature, create an comparison indice (based on feature type and
# start).
sub _sortFeatureFactor {
   my $self = shift;
   my $feature = shift; # A SeqFeature object


   my $factor = $self->_num2str($feature->start()).'.';

   if($self->hasFeatureLevel( $feature->primary_tag()) ) {
      $factor .= $self->getFeatureLevel( $feature->primary_tag() );
   }
   else {
      $factor .= $self->getFeatureLevel( 'other' );
   }

   return($factor);
}

#==============================================================================
# PUBLIC METHODS
#==============================================================================
# write: write the bioseq into a file (with Bio::SeqIO)
sub write {
   my $self   = shift;
   my $append = shift;

   # If no append argument provided => false
   if( !defined($append) ) {
      $append = 0;
   }

   # Generate the output path
   my $output_path = '>'.$self->getOutputPath();

   # Switch to append mode if required
   if( $append ) {
      $output_path = '>'.$output_path;
   }

   eval {
      # Create a Bio::SeqIO to write the bioseq attribute
      my $output_io = Bio::SeqIO->new(
         -file   => $output_path,
         -format => $self->getOutputFormat()
      );

      # Write the Bio::Seq data
      $output_io->write_seq($self->bioseq());
   };
   if($@) {
      $log->fatal('Failed to write the sequence '.$self->seqId().
         ' into output file '.$output_path.': '.$@);
   }
}

# addFeatures: add a list of features
sub addFeatures {
   my $self     = shift;
   my $features = shift; # An ref to an Array of SeqFeature

   foreach my $feature ( @{$features} ) {
      $self->addFeature( $feature );
   }
}

# sortFeatures: sorts features from the current Bio::Seq object
sub sortFeatures {
   my $self = shift;

   # Only RichSeq objects have features
   if( $self->getRichSeq() ) {
      # Extract features
      my @features = $self->getFeatures();

      # Sort features according to the factor
      @features = sort { $self->_sortFeatureFactor($a) cmp $self->_sortFeatureFactor($b) } @features;

      # Replace the feature list
      $self->removeFeatures();
      $self->addFeatures( \@features );

   }
   else {
      # Nothing to do
      $log->trace('The sequence '.$self->seqId().' has no feature to sort.');
   }

}

no Moose;

return(1);
