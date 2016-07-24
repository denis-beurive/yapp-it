package Args;
   
use warnings;
use strict;
  
sub new {
	my $class = shift; 
 	my $self = {
 		list => []
 	};
 	bless($self, $class);
 	return($self);
}

sub add {
 	my $self = shift;
 	my ($inArg) = @_;
 	unshift(@{$self->{list}}, $inArg);
 	return $self;
}

sub get {
 	my $self = shift;
 	my ($inOptReset) = @_;
 	my @copy = @{$self->{list}};
 	$inOptReset = defined $inOptReset ? $inOptReset : 0;
 	if ($inOptReset) {
 		$self->reset();
 	}
 	return \@copy;
}

sub reset {
	my $self = shift;
	$self->{list} = [];
}

if (0) {
	
	require Data::Dumper;

	my $args = new Args();
	$args->add(1)
	     ->add(2);

	my @l = $args->get();
	print Data::Dumper::Dumper(\@l);

	@l = $args->get(1);
	print Data::Dumper::Dumper(\@l);

}


1;