package Travis::Bio::SequenceFactory::BioFile;

#==============================================================================
# Travis::Bio::SequenceFactory::bioFile allows to handle and manage a file written in a
# regular biological format (such as embl, genbank, ...).
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
use File::Basename;

# Travis' modules
use Travis::Utilities::Log;

extends 'Travis::Bio::SequenceFactory::BioFormat';



#==============================================================================
# LOGGING
#==============================================================================
my $log = Travis::Utilities::Log->new();

#==============================================================================
# ATTRIBUTS
#==============================================================================
# Complete path of the considered file
has 'path' => (
   is       => 'rw',
   isa      => 'Str',
   required => 1,
   reader   => 'getPath',
   writer   => 'setPath',
   trigger  => \&_checkPath
);

# NOTE: to avoid conflict while initialising the object 'directory' and 'file'
# cannot be set via the builder (init_arg = undef).
has 'directory' => (
   is       => 'rw',
   isa      => 'Str',
   default  => '',
   init_arg => undef,
   reader   => 'getDirectory',
   writer   => 'setDirectory',
   trigger  => \&_checkDirectory
);

has 'file' => (
   is       => 'rw',
   isa      => 'Str',
   default  => '',
   init_arg => undef,
   reader   => 'getFile',
   writer   => 'setFile',
   trigger  => \&_checkFile
);

has 'format' => (
   is       => 'rw',
   isa      => 'Str',
   default  => '',
   reader   => 'getFormat',
   writer   => 'setFormat',
   trigger  => \&_checkFormat
);


#==============================================================================
# TRIGGER
#==============================================================================
# Check path setting and (re)set if necessary 'directory' and 'file' attributes
sub _checkPath {
   my $self = shift;
   my $path = shift;

   # Explode path into dir/file
   my ($file, $directory, $suffix) = fileparse($path);

   if($self->getFile() ne $file) {
      $self->setFile($file);
   }

   if($self->getDirectory() ne $directory) {
      $self->setDirectory($directory);
   }
}

# Check file setting and (re)set if necessary the 'format' attribute
sub _checkFile {
   my $self = shift;
   my $file = shift;

   # Explode path into dir/file
   my ($p_file, $p_directory, $p_suffix) = fileparse($self->getPath());

   # If the file is different from the path, change the path
   if($p_file ne $file) {
      $self->setPath($p_directory.$file);
   }

   # If the format of the file is different from the stored format, change it
   my $current_format = $self->getFormat();
   # Get the file extension
   'a'=~/a/; # Clear regex catcher
   $file =~ /\.(\w+)$/;
   if( !defined($1) ) {
      $log->trace('No extention found from file name: '.$file.'.');

      if( $current_format eq '' ) {
         # No format provided and no extention
         $log->fatal('The file ('.$file.') has no extention and you did not '.
            'provide a format.');
      }
   }
   if( $self->testExtFormat($1) ) {
      if( $current_format ne $self->findExtFormat($1) ) {
         $self->setFormat( $self->findExtFormat($1) );
      }
   } else {
      if( $current_format eq '' ) {
         $log->fatal('Unknown file format. Please provide a file with a valid'.
            ' extention or with a format');
      } else {
         $log->trace('The file extension is not known. The file format will '.
            'not be changed ('.$current_format.'.');
      }
   }
}

# Check format setting
sub _checkFormat {
   my $self   = shift;
   my $format = shift;

   # Check if the format is supported
   if( !$self->testFormatExt($format) ) {
      $log->fatal('Non-supported format: '.$format.'.');
   }

   # Check if file ext match with the changed format
   my $current_file = $self->getFile();
   # Get the file extension
   'a'=~/a/; # Clear regex catcher
   $current_file =~ /\.(\w+)$/;
   # NOTE: if the file extention is unknown or not defined format setting
   # will not modify file name to keep access to the file.
   if( !defined($1) ) {
      # The current file has no extension. It is recommanded to add one!
      $log->trace('File name without extension can be source of errors.');
   } else {
      # Compare formats
      if( $self->testExtFormat($1) ) {
         if( $format ne $self->findExtFormat($1) ) {
            my $new_ext = $self->findFormatExt($format);
            $current_file =~ s/\.\w+$/\.$new_ext/;
            $self->setFile($current_file);
         }
      } else {
         $log->trace('File extention does not fit with known format.');
      }
   }
}

# Check directory setting
sub _checkDirectory {
   my $self = shift;
   my $directory = shift;

   # A directory name must end with a /
   if(!($directory =~ /\/$/) ) {
      $self->setDirectory($directory.'/');
   }
   else {
      # Check if the directory exists
      $self->validateDirectory();

      # Explode path into dir/file
      my ($p_file, $p_directory, $p_suffix) = fileparse($self->getPath());

      if($p_directory ne $directory) {
         $self->setPath($directory.$p_file);
      }
   }
}


#==============================================================================
# METHODS
#==============================================================================
# Test if the path exists
sub existsPath {
   my $self = shift;

   if( -f $self->getPath() ) {
      return(1);
   } else {
      return(0);
   }
}

# Test and create if necessary the directory
sub validateDirectory {
   my $self = shift;

   if( !(-d $self->getDirectory()) ) {
      # Split into sub directories
      my @subdir = split(/\//, $self->getDirectory());
      # List of directories that should not be tested
      my %skip = ('.' => 1, '..' => 1);
      my $current_sub = '';
      foreach my $s (@subdir) {
         $current_sub .= $s.'/';
         if( $s ne '' & !exists($skip{$s}) ) {
            if(! -d $current_sub ) {
               # Try to create the sub directory
               eval {
                  mkdir $current_sub;
               };
               if($@) {
                  $log->fatal('Failed to create the sub-directory ('.
                     $current_sub.'): '.$@);
               } else {
                  $log->trace('The sub-directory '.$current_sub.
                     ' has been created.');
               }
            }
         }
      }
   }
}

no Moose;

return(1);
