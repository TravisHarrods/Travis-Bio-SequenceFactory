package Travis::Bio::SequenceFactory;

#==============================================================================
# Travis::Bio::SequenceFactory provides a class to handle a group of
# sequences.
#
# Author: Hugo Devillers, Travis Harrods
# Created: 29-FEB-2016
# Updated: 12-JAN-2017
#==============================================================================

#==============================================================================
# REQUIERMENTS
#==============================================================================
use Moose;
use Bio::SeqIO;
#use threads;
#use threads::shared;
use Travis::Bio::SequenceFactory::Sequence;
use Travis::Bio::SequenceFactory::BioFormat;
use Travis::Bio::SequenceFactory::FeatureSubsets;
use Travis::Utilities::Files;
use Travis::Utilities::Log;

# loggin manager
my $log = Travis::Utilities::Log->new();

#==============================================================================
# ATTRIBUTS
#==============================================================================
our $VERSION = 0.01;
# Input path
has 'input' => (
   is      => 'rw',
   isa     => 'Str',
   default => ''
);

# Input format
has 'format' => (
   is       => 'rw',
   isa     => 'Str',
   default => ''
);

# bioFormat object to control input format (regex part)
has 'bio_format' => (
   is      => 'ro',
   isa     => 'Travis::Bio::SequenceFactory::BioFormat',
   default => sub {
                     my $bio_format = Travis::Bio::SequenceFactory::BioFormat->new();
                     return($bio_format);
                  }
);

# sequence array
has 'sequences' => (
  traits      => ['Array'],
  is          => 'rw',
  isa         => 'ArrayRef[Travis::Bio::SequenceFactory::Sequence]',
  default     => sub{ [] },
  handles     => {
    addSequence    => 'push',
    countSequences => 'count',
    getSequence    => 'get'
  },
  trigger     => \&_edit_sequences
);

# sequence index (id => index)
has 'sequence_index' => (
  traits      => ['Hash'],
  is          => 'rw',
  isa         => 'HashRef',
  default     => sub{ {} },
  handles     => {
    getSequenceIndex  => 'get',
    setSequenceIndex  => 'set',
    testSequenceIndex => 'exists',
    enumSequenceIndex => 'keys',
    listSequenceIndex => 'kv'
  }
);

# a structure that can contain different subsets of features
has 'feature_subsets' => (
  is       => 'rw',
  isa      => 'Travis::Bio::SequenceFactory::FeatureSubsets',
  default  => sub{
    my $tmp = Travis::Bio::SequenceFactory::FeatureSubsets->new();
    return($tmp);
  },
  handles  => {
    getFeatureSubset => 'getSubset',
    addFeatureSubset => 'addSubset',
    hasFeatureSubset => 'hasSubset'
  }
);

# Iterator variable
has 'sequence_order' => (
  traits   => ['Array'],
  is       => 'rw',
  isa      => 'ArrayRef',
  default  => sub{ [] },
  handles  => {
    countSequenceOrder => 'count',
    addSequenceOrder   => 'push',
    getSequenceOrder   => 'get'
  }
);

# Iterator attribute for sequence
has 'sequence_iter' => (
  traits  => ['Counter'],
  is      => 'rw',
  isa     => 'Int',
  default => -1,
  handles => {
    nextSeqIter     => 'inc',
    previousSeqIter => 'dec',
    resetSeqIter    => 'reset'
  }
);

# sequence container (for the iterator)
has 'sequence' => (
  is => 'rw',
  isa => 'Ref'
);

#==============================================================================
# BUILDER
#==============================================================================
sub BUILD
{
   my $self = shift;

   # If an input is provided
   if( $self->input() ne '' ) {
      # If a format is provided
      if( $self->format() ne '' ) {
         $self->addInputPath( $self->input(), $self->format() );
      }
      else {
         $self->addInputPath( $self->input() );
      }
   }
}

#==============================================================================
# TRIGGER
#==============================================================================
sub _edit_sequences {
  my $self = shift;

  # Check if and new sequence has been added
  if( $self->countSequences() > $self->countSequenceOrder() ) {
    $self->addSequenceOrder( $self->countSequences() - 1 );
  }

  # TODO: a lot of control for deleting sequences an changing order!
}

#==============================================================================
# METHODS
#==============================================================================
# Add sequence from an input path
sub addInputPath {
   my $self   = shift;
   my $input  = shift; # An input path (string)
   my $format = shift; # Input format (string)
   my $files;          # Will contain the Travis::Utilities::Files object

   # Create the files container
   # Can identify extension from the provided format ?
   if( defined($format) ) {
      if( $self->bio_format()->testFormatRegex($format) ) {
         $files = Travis::Utilities::Files->new(
            input  => $input,
            format => $self->bio_format()->findFormatRegex($format)
         );
      }
      else {
         $files = Travis::Utilities::Files->new( input => $input );
      }
   }
   else
   {
      $files = Travis::Utilities::Files->new( input => $input );
   }

   # Foreach file get all the sequences
   my $previous_rec = $self->countSequences(); # Number of already recorded sequences
   while( $files->next() ) {
      # NOTE: Travis::Bio::SequenceFactory::Sequence can direcly treat a single input path
      # if the corresponding file only contain one sequence. To consider files
      # that contain more than one sequence, files a parsed first with BioPerl

      # Evalutation if Bio::SeqIO can parse the provided file
      eval {
         my $input_file = $files->get_path();
         my $keep_file = 1; # By default the current file is considered

         # If no format provided try to identify it from the file extension
         if( !defined($format) ) {
            'a' =~ /a/; # Clear regex var $1
            $input_file =~ /\.(\w+)$/;
            if( !defined($1) ) {
               $keep_file = 0;
               $log->warning('The file '.$input_file.' has no known format '.
                  'and no file extension. File ignored.');
            }
            else {
               # Check if the found extension corresponds to a known format
               if( $self->bio_format()->testExtFormat($1) ) {
                  $format = $self->bio_format()->findExtFormat($1);
               }
               else {
                  # The extension cannot be resolved
                  $keep_file = 0;
                  $log->warning('The file '.$input_file.' has no known format '.
                     'and its extension cannot be resolved. File ignored.');
               }
            }
         }

         # Try to open the file with BioPerl if the format is known
         if( $keep_file ) {
            my $seq_io = Bio::SeqIO->new(
               -file   => $input_file,
               -format => $format
            );

            # Read each sequence from this file
            while( my $seq_in = $seq_io->next_seq() ) {
               # Create the BioSeq::sequence object
               my $new_seq = Travis::Bio::SequenceFactory::Sequence->new(
                  input  => $input_file,
                  bioseq => $seq_in,
                  format => $format
               );

               # Add the current sequence in the index and store the sequence
               my $id = $new_seq->seqId();
               if( $self->testSequenceIndex( $id ) ) {
                  # The current sequence id is already used
                  my $alter_id = 2;
                  while( $self->testSequenceIndex( $id.'_'.$alter_id )) {
                     $alter_id++;
                  }

                  # Set the new internal id
                  $id = $id.'_'.$alter_id;
                  $new_seq->seqInternalId($id);
               }

               # Store the index and the sequence
               $self->setSequenceIndex( $id => $self->countSequences() );
               #TODO: to switch into shared var => shared_clone($new_seq)...
               $self->addSequence( $new_seq );
            }
         }
      };
      if($@) {
         # An error occured while reading the current file !
         $log->error('Failed to open/read the file '.$files->basename().': '.$@);
      }
   }

   # Count the number of added sequences
   my $added = $self->countSequences() - $previous_rec;
   if( $added == 0 ) {
      # Nothing imported => raise an error
      $log->fatal('Nothing imported from '.$input.'. Please check your path.');
   }
   else {
      $log->trace(' * Added '.$added.' sequences from '.$input.'.');
   }
}

# Insert features from a subset into sequence data
sub insertSubsetFeature {
  my $self = shift;
  my $ssid = shift;

  # Check if required subset exists
  if( $self->hasFeatureSubset($ssid) ) {
    # Get the list of data ID (it is supposed to be sequence ID)
    foreach my $id ( $self->getFeatureSubset($ssid)->keysData() ) {
      # Detect the no ID subset of features
      if( $id ne 'no_id' ) {
        # Check if the sequence ID exists
        if( $self->testSequenceIndex($id) ) {
          # Get the sequence index
          my $index = $self->getSequenceIndex($id);

          # Add features into the corresponding sequence
          foreach my $feat ( @{$self->getFeatureSubset($ssid)->getData($id)} ) {
            $self->sequences()->[$index]->addFeature($feat);
          }
        } else {
          # Unknown sequence ID
          $log->fatal('Unknown sequence ID ('.$id.') from feature subset '.
            $ssid.'.');
        }
      } else {
        # Check if features are stored in the no id subset
        if( scalar(@{$self->getFeatureSubset($ssid)->getData('no_id')}) > 0) {
          $log->warning('The feature subset '.$ssid.' contains features that'.
            ' are not associated to known sequence.');
        }
      }
    }
  } else {
    $log->fatal('The required feature subset ('.$ssid.') does not exists.');
  }
  return(1);
}

# Sort all the features from all sequences
sub sortSequenceFeatures {
  my $self = shift;

  foreach ( $self->enumSequenceIndex() ) {
     $self->sequences()->[$self->getSequenceIndex($_)]->sortFeatures();
  }
  return(1);

}

#*******************************************************************************
# ITERATORS
#*******************************************************************************
# Iterators on sequences
sub nextSequence {
  my $self = shift;

  if( $self->sequence_iter() < $self->countSequenceOrder() - 1 ) {
    # There is a next sequence
    $self->nextSeqIter();
    # Load the sequence ref into the sequence attribute
    $self->sequence($self->getSequence($self->getSequenceOrder($self->sequence_iter())));
    # Return true
    return(1);
  } else {
    # There is no next sequence, reset iterator
    $self->resetSeqIter();
    # TODO: reset $self->sequence()
    # Return false
    return(0);
  }
}

#*******************************************************************************
# ACTIONS ON PATHS / IO
#  - changeOutputDirectory:   change one output directory
#  - changeOutputDirectories: change all output directories
#  - writeSequence:           write one sequence to output
#  - writeSequences:          write all sequences to output
#*******************************************************************************

# Function to change a given output directory
sub changeOutputDirectory {
   my $self   = shift;
   my $seq_id = shift; # Target Seq id (string)
   my $output = shift; # New output directory

   # NOTE: no need to check output directory validity, this validation is
   # performed by a trigger from the bioFile module

   # All arguments are mandatory
   if( !defined($output) or !defined($seq_id) ) {
      $log->fatal('Missing information to change output directory.');
   }

   if( $self->testSequenceIndex($seq_id) ) {
      $self->sequences()->[$self->getSequenceIndex($seq_id)]->setOutputDirectory($output);
   }
   else {
      $log->fatal('Unknown sequence id: '.$seq_id.'.');
   }
   return(1);
}

# Function to change all the output directories
sub changeOutputDirectories {
   my $self   = shift;
   my $output = shift; # New output directory (string or ArrayRef)

   # It is possible to provide a list of output directory (as many as stored
   # sequences)
   if( ref($output) eq 'ARRAY') {
      if( scalar(@{$output}) == $self->countSequences() ) {
         foreach ( $self->enumSequenceIndex() ) {
            my $o = shift @{$output};
            $self->changeOutputDirectory( $_, $o );
         }
      }
   }

   # Same output directory for all sequences
   foreach ( $self->enumSequenceIndex() ) {
      $self->changeOutputDirectory( $_, $output );
   }
   return(1);
}

# Write one given sequence into its corresponding output path
sub writeSequence {
   my $self   = shift;
   my $seq_id = shift; # Target Seq id (string)

   # The seq_id argument is mandatory
   if( !defined($seq_id) ) {
      $log->fatal('You must provide a sequence ID to write it into a file.');
   }

   if( $self->testSequenceIndex($seq_id) ) {
      $self->sequences()->[$self->getSequenceIndex($seq_id)]->write();
   }
   return(1);
}

# Write all sequences
sub writeSequences {
   my $self = shift;

   foreach ( $self->enumSequenceIndex() ) {
      $self->sequences()->[$self->getSequenceIndex($_)]->write();
   }
   return(1);
}

no Moose;

return(1);
