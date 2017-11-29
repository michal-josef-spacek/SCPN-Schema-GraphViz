use strict;
use warnings;

use SCPN::GraphViz;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($SCPN::GraphViz::VERSION, 0.01, 'Version.');
