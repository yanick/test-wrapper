use strict;
use warnings;

use Test::More tests => 3;                      # last test to print

use Test::More;
use Test::Wrapper;

test_wrap( 'like' ); 

my $t = like "foo" => qr/bar/;

ok ! $t->is_success;

test_wrap( 'is_deeply', prefix => 'w_' );

$t = w_is_deeply( { a => 1 }, { a => 2 } );

ok ! $t->is_success;

is_deeply [ 1..5 ], [1..5], 'original test left alone';

