#!/usr/bin/env perl

use strict;
use warnings;

use SCPN::Schema;
use SCPN::Schema::GraphViz;
use File::Temp;
use IO::Barf qw(barf);

# Schema.
my $schema = <<'END';
{
        "events":{
                "copier":{
                        "input_edges":[
                                {"condition":"entry_point_condition"}
                        ],
                        "output_edges":[
                                {"condition":"copy_resutls", "count":3}
                        ]
                }
        },
        "case":{
                "entry_point_condition":{
                        "init_config":{"value":"bullet"}
                }
        }
}
END
my $temp1 = File::Temp->new->filename;
barf($temp1, $schema);

# Schema object.
my $scpn_schema = SCPN::Schema->new;
$scpn_schema->build_schema_from_json($temp1);
unlink $temp1;

# Object.
my $obj = SCPN::Schema::GraphViz->new;

# Generate PNG file.
my $temp2 = File::Temp->new->filename;
$obj->to_png($scpn_schema, $temp2);

# List file.
system('ls -l '.$temp2);

# Output like:
# -rw-r--r-- 1 skim skim 508 Nov 29 22:13 /tmp/PsYcWWsZmI