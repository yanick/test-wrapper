package Test::Wrapper;

use Moose;

no warnings qw/ uninitialized /;  # I know, I'm a bad boy

use Test::Builder;

has [qw/ diag output todo /] => ( is => 'ro', );

sub BUILD {
    my $self = shift;

    # we don't need the commenting
    $self->{diag} =~ s/^\s*#//mg;
}

sub is_success {
    return $_[0]->output =~ /^ok/;
}

sub import {
    my ( $class, @subs ) = @_;

    my ($package) = caller;

    for (@subs) {

        my $to_wrap = join '::', $package, $_;

        my $original = eval '\&' . $to_wrap;

        my $proto = prototype $to_wrap;
        $proto &&= "($proto)";

        my $builder = Test::Builder->new;
        $builder->{Have_Plan}        = 1;
        $builder->{Have_Output_Plan} = 1;
        $builder->{Expected_Tests}   = 1;

        no warnings qw/ redefine /;

        eval <<"END";


    sub $to_wrap $proto {
        my ( \$output, \$failure, \$todo );
        \$builder->output( \\\$output );
        \$builder->failure_output( \\\$failure);
        \$builder->todo_output( \\\$todo );

        \$original->( \@_ );

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

