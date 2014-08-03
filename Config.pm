package Dicom::DCMTK::DCMQRSCP::Config;

# Pragmas.
use strict;
use warnings;

# Modules.
use Class::Utils qw(set_params);

# Version.
our $VERSION = 0.01;

# Constructor.
sub new {
	my ($class, @params) = @_;
	my $self = bless {}, $class;

	# Process params.
	set_params($self, @params);

	# Object.
	return $self;
}

1;

__END__
