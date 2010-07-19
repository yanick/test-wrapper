package Test::Wrapper;

use Moose;


use Test::Builder;

use Moose::Exporter;

no warnings qw/ uninitialized /;    # I know, I'm a bad boy

Moose::Exporter->setup_import_methods(
as_is => [ 'test_wrap' ] );
    


has [qw/ diag output todo /] => ( is => 'ro', );

sub BUILD {
    my $self = shift;

    # we don't need the commenting
    $self->{diag} =~ s/^\s*#//mg;
}

sub is_success {
    return $_[0]->output =~ /^ok/;
}

#sub import {
#   my ( $class, @subs ) = @_;

#   my ($package) = caller;

#   @_ = ( \@subs );

#   goto &test_wrap;
#}

=head2 test_wrap( $test | \@tests, %params )

Wraps the given test or tests such that, when invoked, they will
not emit TAP output but return a C<Test::Wrapper> object.

The parameters the function accept are:

=over

=item prefix 

If defined, a wrapped function named '$prefix_<original_name>' will
be created, and the original test function will be left alone.

    use Test::More;
    use Test::Wrapper;

    test_wrap( 'like', prefix => 'wrapped_' );

    like "foo" => qr/bar/;   # will emit TAP

                             # will not emit TAP
    my $test = wrapped_like( "yadah" => qw/ya/ );

=back


=cut

sub test_wrap {
    my ( $test, %args ) = @_;

    my @tests = ref $test ? @$test : ($test);

    $DB::single = 1;
    my ($package) = caller;

    for ( @tests ) {

    my $to_wrap = join '::', $package, $args{prefix}.$_;

    my $original = join '::', $package, $_;
    my $original_ref = eval '\&'.$original;

    my $proto = prototype $original_ref;
    $proto &&= "($proto)";

    no warnings qw/ redefine /;

    eval <<"END";

    sub $to_wrap $proto {
        local \$Test::Builder::Test = {
            %\$Test::Builder::Test
        };
        my \$builder = bless \$Test::Builder::Test, 'Test::Builder';

        \$builder->{Have_Plan}        = 1;
        \$builder->{Have_Output_Plan} = 1;
        \$builder->{Expected_Tests}   = 1;

        my ( \$output, \$failure, \$todo );
        \$builder->output( \\\$output );
        \$builder->failure_output( \\\$failure);
        \$builder->todo_output( \\\$todo );

        \$original_ref->( \@_ );

        return Test::Wrapper->new(
            output => \$output,
            diag => \$failure,
            todo => \$todo,
        );

        }
END

    die $@ if $@;
}
}

use overload
  'bool' => 'is_success',
  '""'   => sub { $_[0]->diag };

1;

