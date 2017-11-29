use strict;
use warnings;

use SCPN::Schema::GraphViz;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($SCPN::Schema::GraphViz::VERSION, 0.01, 'Version.');
