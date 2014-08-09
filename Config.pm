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

	# AE table.
	$self->{'ae_table'} = {};

	# Comment.
	$self->{'comment'} = 1;

	# Global parameters.
	$self->{'global'} = {
		'NetworkTCPPort' => undef,
		'MaxPDUSize' => undef,
		'MaxAssociations' => undef,
		'UserName' => undef,
		'GroupName' => undef,
	};

	# Host table.
	$self->{'host_table'} = {};

	# Host table symbolic names.
	$self->{'host_table_symb'} = {};

	# Vendor table.
	$self->{'vendor_table'} = {};

	# Process params.
	set_params($self, @params);

	# Object.
	return $self;
}

# Parse configuration.
sub parse {
	my ($self, $data) = @_;
	my $stay = 0;
	foreach my $line (split m/\n/ms, $data) {
		if ($line =~ m/^\s*#/ms || $line =~ m/^\s*$/ms) {
			next;
		}
		if (($stay == 0 || $stay == 1)
			&& $line =~ m/^\s*(\w+)\s*=\s*"?(\w+)"?\s*$/ms) {

			$stay = 1;
			$self->{'global'}->{$1} = $2;

		# Begin of host table.
		} elsif ($stay == 1
			&& $line =~ m/^\s*HostTable\s+BEGIN\s*$/ms) {

			$stay = 2;

		# End of host table.
		} elsif ($stay == 2 
			&& $line =~ m/^\s*HostTable\s+END\s*$/ms) {

			$stay = 1;

		# Host in host table.
		} elsif ($stay == 2
			&& $line =~ m/^\s*(\w+)\s*=\s*\(([\w\s,]+)\)\s*$/ms) {

			$self->{'host_table'}->{$1} = [split m/\s*,\s*/ms, $2];

		# Symbolic names in host table.
		} elsif ($stay == 2
			&& $line =~ m/^\s*(\w+)\s*=\s*([\w\s,]+)\s*$/ms) {

			$self->{'host_table_symb'}->{$1}
				= [split m/\s*,\s*/ms, $2];

		# Begin of AE table.
		} elsif ($stay == 1 && $line =~ m/^\s*AETable\s+BEGIN\s*$/ms) {
			$stay = 3;

		# End of AE table
		} elsif ($stay == 3 && $line =~ m/^\s*AETable\s+END\s*$/ms) {
			$stay = 1;

		# AE item.
		} elsif ($stay == 3
			&& $line =~ m/^\s*(\w+)\s+([\/\w]+)\s+(\w+)\s+\(([^)]+)\)\s+(.*)$/ms) {

			my ($maxStudies, $maxBytesPerStudy)
				= split m/\s*,\s*/ms, $4;
			$self->{'ae_table'}->{$1} = {
				'StorageArea' => $2,
				'Access' => $3,
				'Quota' => {
					'maxStudies' => $maxStudies,
					'maxBytesPerStudy' => $maxBytesPerStudy,
				},
				'Peers' => $5,
			};

		# Begin of vendor table
		} elsif ($stay == 1
			&& $line =~ m/^\s*VendorTable\s+BEGIN\s*$/ms) {

			$stay = 4;

		# End of vendor table.
		} elsif ($stay == 4
			&& $line =~ m/^\s*VendorTable\s+END\s*$/ms) {

			$stay = 1;

		# Item in vendor table.
		} elsif ($stay == 4
			&& $line =~ m/^\s*"([^"]+)"\s*=\s*(\w+)\s*$/ms) {

			$self->{'vendor_table'}->{$2} = $1;
		}
	}
	return;
}

# Serialize to configuration.
sub serialize {
	my $self = shift;
	my @data;
	$self->_serialize_global(\@data);
	$self->_serialize_hosts(\@data);
	$self->_serialize_vendors(\@data);
	$self->_serialize_ae(\@data);
	return join "\n", @data;
}

# Serialize AE titles.
sub _serialize_ae {
	my ($self, $data_ar) = @_;
	if (! keys %{$self->{'ae_table'}}) {
		return;
	}
	if (@{$data_ar}) {
		push @{$data_ar}, '';
	}
	if ($self->{'comment'}) {
		push @{$data_ar}, '# AE Table.';
	}
	push @{$data_ar}, 'AETable BEGIN';
	# TODO Order?
	foreach my $key (sort keys %{$self->{'ae_table'}}) {
		my $storage_area = $self->{'ae_table'}->{$key}->{'StorageArea'};
		my $access = $self->{'ae_table'}->{$key}->{'Access'};
		my $peers = $self->{'ae_table'}->{$key}->{'Peers'};
		my $max_studies = $self->{'ae_table'}->{$key}->{'Quota'}
			->{'maxStudies'};
		my $max_bytes_per_study = $self->{'ae_table'}->{$key}
			->{'Quota'}->{'maxBytesPerStudy'};
		push @{$data_ar}, "$key $storage_area $access ".
			"($max_studies, $max_bytes_per_study) $peers";
	}
	push @{$data_ar}, 'AETable END';
	return;
}

# Serialize global parameters.
sub _serialize_global {
	my ($self, $data_ar) = @_;
	if (! map { defined $self->{'global'}->{$_} ? $_ : () }
		keys %{$self->{'global'}}) {

		return;
	}
	if (@{$data_ar}) {
		push @{$data_ar}, '';
	}
	if ($self->{'comment'}) {
		push @{$data_ar}, '# Global Configuration Parameters.';
	}
	foreach my $key (sort keys %{$self->{'global'}}) {
		if (! defined $self->{'global'}->{$key}) {
			next;
		}
		my $value = $self->{'global'}->{$key};
		if ($value !~ m/^\d+$/ms) {
			$value = '"'.$value.'"';
		}
		push @{$data_ar}, $key.' = '.$value;
	}
	return;
}

# Serialize hosts table.
sub _serialize_hosts {
	my ($self, $data_ar) = @_;
	if (! keys %{$self->{'host_table'}}) {
		return;
	}
	if (@{$data_ar}) {
		push @{$data_ar}, '';
	}
	if ($self->{'comment'}) {
		push @{$data_ar}, '# Host Table.';
	}
	push @{$data_ar}, 'HostTable BEGIN';
	foreach my $key (sort keys %{$self->{'host_table'}}) {
		my ($ae, $host, $port) = @{$self->{'host_table'}->{$key}};
		push @{$data_ar}, "$key = ($ae, $host, $port)";
	}
	# TODO Alias.
	push @{$data_ar}, 'HostTable END';
	return;
}

# Serialize vendors table.
sub _serialize_vendors {
	my ($self, $data_ar) = @_;
	if (! keys %{$self->{'vendor_table'}}) {
		return;
	}
	if (@{$data_ar}) {
		push @{$data_ar}, '# Vendor Table.';
	}
	if ($self->{'comment'}) {
		push @{$data_ar}, '';
	}
	push @{$data_ar}, 'VendorTable BEGIN';
	foreach my $key (sort keys %{$self->{'vendor_table'}}) {
		my $desc = '"'.$self->{'vendor_table'}->{$key}.'"';
		push @{$data_ar}, "$desc = $key";
	}
	push @{$data_ar}, 'VendorTable END';
	return;
}

1;

__END__
