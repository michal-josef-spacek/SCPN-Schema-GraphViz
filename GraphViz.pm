package SCPN::Schema::GraphViz;

use strict;
use warnings;

use Class::Utils qw(set_params);
use GraphViz2;
use Mojo::Exception;
use Scalar::Util qw(blessed);

our $VERSION = 0.01;

sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Graph title.
	$self->{'graph_title'} = 'Petri net';

	# Rank dir.
	$self->{'rank_dir'} = 'LR';

	# Print titles.
	$self->{'print_titles'} = 0;

	# Process parameters.
	set_params($self, @params);

	$self->{'graphviz'} = GraphViz2->new(
		'global' => {
			'directed' => 1,
		},
		'label' => $self->{'graph_title'},
		'rankdir' => $self->{'rank_dir'},
	);

	return $self;
}

sub to_png {
	my ($self, $scpn_schema, $output_png_file) = @_;

	if (! blessed($scpn_schema) || ! $scpn_schema->isa('SCPN::Schema')) {
		Mojo::Exception->throw('to_png: Bad SCPN::Schema object.');
	}

	my $conditions_hr = $scpn_schema->conditions;
	foreach my $condition_id (sort keys %{$conditions_hr}) {
		# TODO Colorize bullets.
		my $items = $conditions_hr->{$condition_id}->list_items;
		$self->{'graphviz'}->add_node(
			'name' => $condition_id,
			'shape' => 'circle',
			'label' => $items || '',
			$self->{'print_titles'} ? ('xlabel' => $conditions_hr->{$condition_id}->title) : (),
		);
	}

	my $events_hr = $scpn_schema->events;
	foreach my $event_id (sort keys %{$events_hr}) {
		$self->{'graphviz'}->add_node(
			'name' => $event_id,
			'label' => '',
			'shape' => 'square',
			$self->{'print_titles'} ? ('xlabel' => $events_hr->{$event_id}->title) : (),
		);

		my $input_edges_hr = {};
		foreach my $input_edge (@{$events_hr->{$event_id}->input_edges}) {
			$input_edges_hr->{$input_edge->input_condition->name}->{$event_id}->{count} //= 0;
			$input_edges_hr->{$input_edge->input_condition->name}->{$event_id}->{count}++;
			$input_edges_hr->{$input_edge->input_condition->name}->{$event_id}->{colors}
				= $input_edge->colors;
		}
		$self->_add_edge($input_edges_hr);

		my $output_edges_hr = {};
		foreach my $output_edge (@{$events_hr->{$event_id}->output_edges}) {
			$output_edges_hr->{$event_id}->{$output_edge->output_condition->name}->{count} //= 0;
			$output_edges_hr->{$event_id}->{$output_edge->output_condition->name}->{count}++;
		}
		$self->_add_edge($output_edges_hr);
	}

	return $self->{'graphviz'}->run(
		'format' => 'png:gd',
		'output_file' => $output_png_file,
	);
}

sub _add_edge {
	my ($self, $edges_hr) = @_;
	foreach my $from (sort keys %{$edges_hr}) {
		foreach my $to (sort keys %{$edges_hr->{$from}}) {
			my $num = $edges_hr->{$from}->{$to}->{count};
			my @colors = exists $edges_hr->{$from}->{$to}->{colors}
				? @{$edges_hr->{$from}->{$to}->{colors}}
				: ();
			$self->{'graphviz'}->add_edge(
				'from' => $from,
				'to' => $to,
				$num > 1 ? ('label' => $num) : (),
				@colors ? ('color' => join ':', @colors) : (),
			);
		}
	}
	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

SCPN::Schema::GraphViz - Class for drawing SCPN::Schema via GraphViz.

=head1 SYNOPSIS

 use SCPN::GraphViz;
 my $obj = SCPN::GraphViz->new(%params);
 $obj->to_png($scpn_schema, $output_png_file);

=head1 METHODS

=over 8

=item C<new(%params)>

 Constructor.

=over 8

=item * C<graph_title>

 Graph title.
 Default value is 'Petri net'.

=item * C<rank_dir>

 Rank direction.
 Default value is 'LR'.

=item * C<print_titles>

 Print titles.
 Default value is 0.

=back

=item C<to_png($scpn_schema)>

 Generate diagram to PNG file via GraphViz.
 Returns GraphViz object.

=back

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

 to_png():
         to_png: Bad SCPN::Schema object.

=head1 EXAMPLE

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

=head1 DEPENDENCIES

L<Class::Utils>,
L<GraphViz2>,
L<Mojo::Exception>,
L<Scalar::Util>.

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © Michal Špaček 2017
 BSD 2-Clause License

=head1 VERSION

0.01

=cut
