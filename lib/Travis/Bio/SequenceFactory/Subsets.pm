package Travis::Bio::SequenceFactory::Subsets;

#==============================================================================
# Travis::Bio::SequenceFactory::Subsets is an abstract class to handle subsets
# objects: Travis::Bio::SequenceFactory::Subset
#
# Author: Hugo Devillers, Travis Harrods
# Created: 12-JAN-2017
# Updated:
#==============================================================================

#==============================================================================
# REQUIERMENTS
#==============================================================================
use Moose;
use Travis::Bio::SequenceFactory::Subset;

#==============================================================================
# ATTRIBUTS
#==============================================================================
# A hash ref that contains the subsets
has 'subsets' => (
  traits   => ['Hash'],
  is       => 'rw',
  isa      => 'HashRef',
  default  => sub{ {} },
  handles  => {
    getSubset => 'get',
    setSubset => 'set',
    hasSubset => 'exists'
  }
);

#==============================================================================
# BUILDER
#==============================================================================

#==============================================================================
# METHODS
#==============================================================================
# Add element(s) to data
sub addSubset {
  my $self    = shift;
  my $ssid    = shift; # The subset id
  my $element = shift; # An object or an array ref of objects
  my $key     = shift; # [Optional] the subset key id

  # Check if the subset id already exists
  if( !$self->hasSubset($ssid) ) {
    # Create an new subset
    my $subset = Travis::Bio::SequenceFactory::Subset->new();
    $self->setSubset( $ssid => $subset );
  }

  # Fill the subset
  if( ref($key) eq 'ARRAY') {
    $self->getSubset($ssid)->addDataKeys($element, $key);
  } else {
    $self->getSubset($ssid)->addDataKey($element, $key);
  }
  return(1);
}

no Moose;
return(1);
