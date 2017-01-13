package Travis::Bio::SequenceFactory::Subset;

#==============================================================================
# Travis::Bio::SequenceFactory::Subsets is an abstract class to handle objects
# from Bio::* associated to an id (sequence or feature)
#
# Author: Hugo Devillers, Travis Harrods
# Created: 13-JAN-2017
# Updated:
#==============================================================================

#==============================================================================
# REQUIERMENTS
#==============================================================================
use Moose;
use Travis::Utilities::Log;

# Log manager
my $log = Travis::Utilities::Log->new();

#==============================================================================
# ATTRIBUTS
#==============================================================================
# A hash ref that contains the subsets
has 'data' => (
  traits   => ['Hash'],
  is       => 'rw',
  isa      => 'HashRef',
  default  => sub{
    my %tmp = (
      'no_id' => []
    );
    return( \%tmp );
   },
  handles  => {
    getData  => 'get',
    setData  => 'set',
    hasData  => 'exists',
    keysData => 'keys'
  }
);

#==============================================================================
# BUILDER
#==============================================================================

#==============================================================================
# METHODS
#==============================================================================
# Add element(s) to data for a given key
sub addDataKey {
  my $self    = shift;
  my $element = shift; # An object or an array ref of objects
  my $key     = shift; # [Optional] the subset key id

  # Check if a key is provided
  if( !defined($key) ) {
    # Set key to the default container
    $key = 'no_id';
  } else {
    # Check if the provided key already exists
    if( !$self->hasData($key) ) {
      $self->setData( $key => [] );
    }
  }

  # Fill the data container
  if( ref($element) eq 'ARRAY' ) {
    foreach (@{$element}) {
      push @{$self->data()->{$key}}, $_;
    }
  } else {
    push @{$self->data()->{$key}}, $element;
  }
}

# Add elements to data for multiple keys
sub addDataKeys {
  my $self    = shift;
  my $element = shift; # Array ref of objects
  my $keys    = shift; # arrey ref of keys

  if( (ref($element) ne 'ARRAY') || (ref($keys) ne 'ARRAY') ) {
    $log->fatal('In addDataKeys method, arguments "element" and "keys" must'.
      ' be ArrayRef.');
  }
  if( scalar(@{$element}) != scalar(@{$keys}) ) {
    $log->fatal('In addDataKeys method, number of provided keys does not match'.
      ' with the number of provided elements.')
  }

  foreach (0..(scalar(@{$element})-1)) {
    $self->addDataKey($element->[$_], $keys->[$_]);
  }
}

# Count element for a given key
sub countDataKey {
  my $self = shift;
  my $key  = shift;

  if( $self->hasData($key) ) {
    return( scalar( @{$self->getData($key)} ) );
  } else {
    $log->warning('The provided key ('.$key.') is not set.');
    return(0);
  }
}

# Count all the elements
sub countData {
  my $self = shift;

  my $count = 0;

  foreach my $key ($self->keysData()) {
    $count += $self->countDataKey($key);
  }

  return($count);
}

no Moose;
return(1);
