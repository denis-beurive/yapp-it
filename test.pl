use lib './parsers';

use strict;
use Parse::Eyapp;
use basic;
use multiline;
use comments;
use declarations;
use procedural;
use procedural_debug;
use Term::ANSIColor;
use Data::Dumper;

my $DEBUG = 0;

my $parser     = undef;
my $input      = undef;
my $err        = undef;
my $inputs     = undef;
my %parserConf = ();


if ($DEBUG) { %parserConf = ( yydebug => 0x1F ); }


### ----------------------------------------
### Testing "basic"
### ----------------------------------------

$parser = basic->new();

$parser->input("### go");
$parser->YYParse();

$parser->input("### titi");
$parser->YYParse();

$parser->input('@param toto');
$parser->YYParse(%parserConf);

### ----------------------------------------
### Testing "multiline"
### ----------------------------------------

print "Testing parser multiline.yp\n";
print "---------------------------\n\n";

$parser = multiline->new();
$inputs = loadTests('multiline', \$err);
unless (defined($inputs)) {
	print STDERR "ERROR: $err\n";
	exit(1);
}

foreach my $input (@{$inputs}) {
	
	print "Input:\n";
	print color 'bold blue';
	print printInput($input);
	print color 'reset';
	print "\n\n";
	
	multiline::resetParser();
	$parser->input($input);
	$parser->YYParse(%parserConf);
	
	my %declaration = multiline::getDeclaration();
	my $var         = $declaration{'var'};

	print "Found comments:\n";
	print color 'bold green';
	print "\t$var = " . join(', ', @{$declaration{'declaration'}}) . "\n";
	print color 'reset';
	print "\n";
}

print "Status: ";
if (0 == $parser->YYNberr()) {
	print color 'bold green';
	print "SUCCESS\n";
} else {
	print color 'bold red';
	print "FAILURE\n";
}
print color 'reset';
print "\n\n";

### ----------------------------------------
### Testing "declarations.yp"
### ----------------------------------------

print "Testing parser declarations.yp\n";
print "------------------------------\n\n";

$parser = declarations->new();
$inputs = loadTests('declarations', \$err);
unless (defined($inputs)) {
	print STDERR "ERROR: $err\n";
	exit(1);
}

foreach my $input (@{$inputs}) {
	
	print "Input:\n";
	print color 'bold blue';
	print printInput($input);
	print color 'reset';
	print "\n\n";
	
	declarations::resetParser();
	$parser->input($input);
	$parser->YYParse(%parserConf);
	
	my @declarations = declarations::getDeclarations();

	print "Found declarations:\n";
	print color 'bold green';
	foreach my $declaration (@declarations) {
		my $var = $declaration->{'var'};
		print "\t$var = " . join(', ', @{$declaration->{'declaration'}}) . "\n";		
	}
	print color 'reset';
	print "\n";
}

print "Status: ";
if (0 == $parser->YYNberr()) {
	print color 'bold green';
	print "SUCCESS\n";
} else {
	print color 'bold red';
	print "FAILURE\n";
}
print color 'reset';
print "\n\n";

### ----------------------------------------
### Testing "comments.yp"
### ----------------------------------------

print "Testing parser comments.yp\n";
print "--------------------------\n\n";

$parser = comments->new();
$inputs = loadTests('comments', \$err);
unless (defined($inputs)) {
	print STDERR "ERROR: $err\n";
	exit(1);
}

foreach my $input (@{$inputs}) {
	my $n = undef;
	
	print "Input:\n";
	print color 'bold blue';
	print printInput($input);
	print color 'reset';
	print "\n\n";
	
	comments::resetParser();
	$parser->input($input);
	$parser->YYParse(%parserConf);

	$n = 0;
	print "Found comments:\n";
	print color 'bold green';
	foreach my $comment (comments::getComments()) {
	 	printf ("\t%4d: \"%s\"\n", $n, join(' ', @{$comment}));
		$n++;
	}	
	print color 'reset';
	print "\n";
}

print "Status: ";
if (0 == $parser->YYNberr()) {
	print color 'bold green';
	print "SUCCESS\n";
} else {
	print color 'bold red';
	print "FAILURE\n";
}
print color 'reset';
print "\n\n";

### ----------------------------------------
### Testing "procedural.yp"
### ----------------------------------------

print "Testing parser procedural.yp\n";
print "----------------------------\n\n";

$parser = procedural->new();
$inputs = loadTests('procedural', \$err);
unless (defined($inputs)) {
	print STDERR "ERROR: $err\n";
	exit(1);
}

foreach my $input (@{$inputs}) {
	my $n = undef;
	
	print "Input:\n";
	print color 'bold blue';
	print printInput($input);
	print color 'reset';
	print "\n\n";
	
	procedural::resetParser();
	$parser->input($input);
	$parser->YYParse(%parserConf);

	print "Stack:\n";
	print color 'bold green';
	procedural->showStack("	   ");
	print color 'reset';
	print "\n\n";
}

print "Status: ";
if (0 == $parser->YYNberr()) {
	print color 'bold green';
	print "SUCCESS\n";
} else {
	print color 'bold red';
	print "FAILURE\n";
}
print color 'reset';
print "\n\n";



print "\n\n";





sub loadTests
{
	my ($inName, $outErr) = @_;
	my $dir   = undef;
	my @tests = ();
	
	$$outErr = undef;
	unless(opendir($dir, 'tests')) {
		$$outErr = "Can't opendir 'tests': $!";
		return undef;
	}
	while(readdir $dir) {
		my $path    = './tests/' . $_;
		my @parts   = ();
		my $content = undef;
		next unless -f $path;
		@parts = split(/\-/, $_);
		next if scalar(@parts) != 2;
		next if $parts[0] ne $inName;
		$content = loadFile($path, $outErr);
		unless (defined($content)) {
			return undef;
		}
		push(@tests, $content);
    }
    closedir $dir;
	return \@tests;
}

sub loadFile
{
	my ($inPath, $outErr) = @_;
	my $content = '';
	my $fd      = undef;
	
	$$outErr = undef;
	unless (open($fd, $inPath)) {
		$$outErr = "Can not open file '$inPath': $!";
		return undef;
	}
	while (<$fd>) {
		$content .= $_;
	}
	close $fd;
	return $content;
}

sub printInput
{
	my ($inInput) = @_;
	my @res   = ();
	my $n     = 0;
	my @lines = split(/\r?\n/, $inInput);
	
	foreach my $line (@lines) {
		push(@res, sprintf("\t%4d: %s", $n, $line));
		$n++;
	}
	return join("\n", @res);
}




