
$string = "abdc";

# Negative lookahead.

if ($string =~ m/a(?!b)/) {
	print "\"$string\" does match the first regexp!\n";
} else {
	print "\"$string\" does NOT match the first regexp!\n"; # It does not match.
}

# Positive lookahead.

if ($string =~ m/(a)(?=(b))/) {
	print "\"$string\" does match the second regexp!\n";
	print "First match is \"$1\"\n";   # => "a"
	print "Second match is \"$2\"\n";  # => "b"
} else {
	print "\"$string\" does NOT match the second regexp!\n";
}

# Negative lookbehind.

if ($string =~ m/(?<!a)b/) {
	print "\"$string\" does match the third regexp!\n";
} else {
	print "\"$string\" does NOT match the third regexp!\n"; # It does not match.
}

# Pisitive lookbehind.

if ($string =~ m/(?<=(a))(b)/) {
	print "\"$string\" does match the fourth regexp!\n";
	print "First match is \"$1\"\n";   # => "a"
	print "Second match is \"$2\"\n";  # => "b"
} else {
	print "\"$string\" does NOT match the fourth regexp!\n";
}


