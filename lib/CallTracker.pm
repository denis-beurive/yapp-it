package CallTracker;
   
use warnings;
use strict;



use constant TYPE_VARIABLE => 0;
use constant TYPE_FUNCTION => 1;

sub new {
    my $class = shift;
    my ($inFunctionDetector) = @_;
    my $self = {
        # List the calls in the order they are discovered by the (YAPP) parser.
        # Each element of the list is a reference to "$function->{<function name>}->[]".
        calls => [],
        # Calls' repository, referenced by functions' names.
        # key: <name of the function>
        # value: { args       => [[<arguments for the first call>], [<arguments for the second call>...]],
        #          seenInArgs => <number of times the fonction has been seen within arguments>,
        #          count      => <number of times the function has been called so far> }
        # Also: args => { type => TYPE_VARIABLE, name => <argument name>}
        #       or
        #       args => { type => TYPE_FUNCTION, name => <argument name>, index => <number of times the __CALLED__ fonction has been seen within arguments>}
        #       The <number of times the fonction has been seen within arguments> stats at 0.
        functions => {},
        # Function call in order to determine whether a name refers to a function or not.
        functionDetector => $inFunctionDetector
    };

    bless($self, $class);
    return($self);
}

sub reset {
    my $self = shift;

    $self->{calls}     = [];
    $self->{functions} = {};
}

sub addCall {
    my $self = shift;
    my ($inFunctionName, $inArgs) = @_;
    my $functionDetector = $self->{functionDetector};
    my @args = ();

    # Create an entry in the calls' repository.
    unless(exists($self->{functions}->{$inFunctionName})) {
        $self->{functions}->{$inFunctionName} = { args => [], seenInArgs => 0, count => 0 };
    }

    # Scan the function's arguments.
    foreach my $arg (@{$inArgs}) {
        if (&$functionDetector($arg)) {
            push(@args, { type => TYPE_FUNCTION, name => $arg, index => $self->{functions}->{$arg}->{seenInArgs} });
            $self->{functions}->{$arg}->{seenInArgs} += 1;
        } else {
            push(@args, { type => TYPE_VARIABLE, name => $arg });
        }
    }

    # Add the call into the calls' repository.
    push(@{$self->{functions}->{$inFunctionName}->{args}}, \@args);
    $self->{functions}->{$inFunctionName}->{count} += 1;

    # Add (the reference to) the newly detected call to the __ORDERED__ list of calls.
    my $index = $self->{functions}->{$inFunctionName}->{count} - 1;
    unshift(@{$self->{calls}}, {
        function => $inFunctionName,
        index => $index
        # args => $self->{functions}->{$inFunctionName}->{args}->[$index]
    });

    return $self;
}

sub traverse {
    my $self = shift;
    my ($inFunctionName, $inCallIndex, $inOptProcessVariable, $inOptProcessFunction) = @_;
    my @args = @{$self->{functions}->{$inFunctionName}->{args}->[$inCallIndex]};

    my $defaultProcessVariable = sub {
        my ($inVariableNane) = @_;
    };

    my $defaultProcessFunction = sub {
        my ($inFunctionName, $inArgs) = @_;
    };


    $inOptProcessVariable = defined $inOptProcessVariable ? $inOptProcessVariable : \&$defaultProcessVariable;
    $inOptProcessFunction = defined $inOptProcessFunction ? $inOptProcessFunction : \&$defaultProcessFunction;

        

    # We choose to traverse the siblings from riht to left.
    for (my $i=int(@args)-1; $i>-1; $i--) {
        my $arg = $args[$i];
        if (TYPE_VARIABLE == $arg->{type}) {
            # print "  " . $arg->{name} . "\n";
            &$inOptProcessVariable($arg->{name});
            next;
        }
        # This is not a variable... so this is a function's call.
        $self->traverse($arg->{name}, $arg->{index}, $inOptProcessVariable, $inOptProcessFunction);        
    }

    # You can traverse the siblings from left to right or the other way...
    # It doe not matter.
    # foreach my $arg (@args) {
    #     # Is the argument a variable ?
    #     if (TYPE_VARIABLE == $arg->{type}) {
    #         print "  " . $arg->{name} . "\n";
    #         next;
    #     }
    #     # This is not a variable... so this is a function's call.
    #     $self->traverse($arg->{name}, $arg->{index});
    # }
    
    # print $inFunctionName . '():' . int(@args) . "\n";
    &$inOptProcessFunction($inFunctionName, \@args);
}

sub toDot {
    my $self = shift;
    my @nodes = ();
    my @edges = ();
    my %functionsIndexes = {};
    my %variablesIndexes = {};
    my $functionDetector = $self->{functionDetector};

    # Create the node for the functions.
    foreach my $function (keys %{$self->{functions}}) {
        unless (exists($functionsIndexes{$function})) {
            $functionsIndexes{$function} = 0;
        }
        push(@nodes, $functionsIndexes{$function} . " [label=\"$function\"]");
        $functionsIndexes{$function} += 1;
    }

    # Create de nodes for the variables.
    foreach my $function (keys %{$self->{functions}}) {
        my @args = @{$self->{functions}->{$function}};

        # Create the nodes for the arguments (which may be functions).
        for (my $i=0; $i<count(@args); $i++) {
            my $arg = $args[$i];

            if (&$functionDetector($arg)) {
                next;
            } 

            unless (exists($variablesIndexes{$arg})) {
                $variablesIndexes{$arg} = 0;
            }

            push(@nodes, $variablesIndexes{$arg} . " [label=\"$arg\"]");
            $variablesIndexes{$arg} += 1;
        }
    }



}

sub dump {
    my $self = shift;

    my $processVariable = sub {
        my ($inVariableNane) = @_;
        print "$inVariableNane\n";
    };

    my $processFunction = sub {
        my ($inFunctionName, $inArgs) = @_;
        print "$inFunctionName:" . int(@{$inArgs}) . "\n";
    };

    $self->traverse($self->{calls}->[0]->{function}, 0, \&$processVariable, \&$processFunction);
}

sub debug {
    my $self = shift;
    require Data::Dumper;
    print Data::Dumper::Dumper($self->{calls});
    print Data::Dumper::Dumper($self->{functions});
}



1;
