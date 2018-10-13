package OpenScad::Cube;

use strict;
use warnings;

use OpenScad;

use Class::Tiny qw(h r x y z center);

sub generate
{
    my($self, $level) = @_;

    return OpenScad::get_level($level) . "cube(size="
        . ((defined $self->x or $self->y or $self->z) ?
        ( "[" . $self->x . ", ". $self->y . ", ". $self->z . "]") : $self->h)
        . ", center=" . ((defined $self->center) ? "true" : "false") . ");";
}

1;
__END__
