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
