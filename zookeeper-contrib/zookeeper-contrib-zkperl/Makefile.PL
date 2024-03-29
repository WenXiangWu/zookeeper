# Net::ZooKeeper - Perl extension for Apache ZooKeeper
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use 5.008_008;

use Config;
use ExtUtils::MakeMaker;
use Getopt::Long;

my $ZOO_MAJOR_VERSION = 3;
my $ZOO_REQUIRED_VERSION = qr{^$ZOO_MAJOR_VERSION\.\d+.\d+$}ismx;

my @zk_inc_paths;
my @zk_lib_paths;

my $with_sasl2 = 0;
my @sasl2_inc_paths;
my @sasl2_lib_paths;

GetOptions(
    'zookeeper-include=s' => \@zk_inc_paths,
    'zookeeper-lib=s' => \@zk_lib_paths,
    'with-sasl2!' => \$with_sasl2,
    'sasl2-include=s' => \@sasl2_inc_paths,
    'sasl2-lib=s' => \@sasl2_lib_paths
);

my $zk_inc = (join(' ', map("-I$_", @zk_inc_paths)) . ' -I.');
my $zk_libs = (join(' ', map("-L$_", @zk_lib_paths)) . ' -lzookeeper_mt');

my $cc = $Config{'cc'};
my $check_file = 'build/check_zk_version';

my $check_out = qx($cc $zk_inc -o $check_file $check_file.c $zk_libs 2>&1);

if ($?) {
    if ($check_out =~ /zookeeper_version\.h/) {
        die("Could not determine ZooKeeper version:\n\n$check_out");
    }
    else {
        ## keep in sync with build/check_zk_version.h
        die("Net::ZooKeeper requires at least ZooKeeper version 3.1.1\n");
    }
}

chomp(my $zk_ver = qx($check_file));

if ($? >> 8 != 0) {
  die "Couldn't check zookeeper version: $zk_ver: $r";
}
elsif ($zk_ver !~ $ZOO_REQUIRED_VERSION) {
  warn "Net::ZooKeeper requires ZooKeeper 3.x, found $zk_ver!";
}

my @inc = ($zk_inc);
my @libs = ($zk_libs);
my %mmopt = ();

if ($with_sasl2) {
    push(@inc, join(' ', map("-I$_", @sasl2_inc_paths)));
    push(@libs, join(' ', map("-L$_", @sasl2_lib_paths)) . ' -lsasl2');
    $mmopt{DEFINE} = '-DHAVE_CYRUS_SASL_H';
}

WriteMakefile(
    'INC'          => join(' ', @inc),
    'LIBS'         => \@libs,
    'NAME'         => 'Net::ZooKeeper',
    'VERSION_FROM' => 'ZooKeeper.pm',
    'clean'        => { 'FILES' => 'build/check_zk_version.o' },
    %mmopt,
);
