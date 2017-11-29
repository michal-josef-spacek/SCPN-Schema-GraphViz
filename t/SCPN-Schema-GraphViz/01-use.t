use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('SCPN::Schema::GraphViz');
}

# Test.
require_ok('SCPN::Schema::GraphViz');
