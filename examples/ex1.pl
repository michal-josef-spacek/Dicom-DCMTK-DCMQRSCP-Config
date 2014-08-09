#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Dicom::DCMTK::DCMQRSCP::Config;

# Object.
my $obj = Dicom::DCMTK::DCMQRSCP::Config->new(
        'ae_table' => {
                'ACME_PUB' => {
                        'Access' => 'R',
                        'Peers' => 'ANY',
                        'Quota' => {
                                'maxBytesPerStudy' => '24mb',
                                'maxStudies' => '10',
                        },
                        'StorageArea' => '/dicom/ACME_PUB',
                },
                'ACME_PRV' => {
                        'Access' => 'RW',
                        'Peers' => 'Acme',
                        'Quota' => {
                                'maxBytesPerStudy' => '24mb',
                                'maxStudies' => '10',
                        },
                        'StorageArea' => '/dicom/ACME_PRV',
                },
        },
        'comment' => 1,
        'global' => {
                'GroupName' => 'dcmtk',
                'MaxAssociations' => 20,
                'MaxPDUSize' => 8192,
                'NetworkTCPPort' => 104,
                'UserName' => 'dcmtk',
        },
        'host_table' => {
                'Acme_1' => [
                        'ACME_DN1',
                        'acme',
                        10001
                ],
                'Acme_2' => [
                        'ACME_DN2',
                        'acme',
                        10001
                ],
                'Acme_3' => [
                        'ACME_DN3',
                        'acme',
                        10001
                ],
        },
        'host_table_symb' => {
                'Acme' => [
                        'Acme_1',
                        'Acme_2',
                        'Acme_3',
                ],
        },
        'vendor_table' => {
                'Acme' => 'ACME CT Company',
        },
);

# Serialize and print
print $obj->serialize."\n";

# Output:
# TODO