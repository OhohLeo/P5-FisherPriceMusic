package OpenScad::Cylinder;

use strict;
use warnings;

use OpenScad;

use Class::Tiny qw(h r r1 r2 d d1 d2 center);

# h : height of the cylinder or cone
# r  : radius of cylinder. r1 = r2 = r.
# r1 : radius, bottom of cone.
# r2 : radius, top of cone.
# d  : diameter of cylinder. r1 = r2 = d /2.
# d1 : diameter, bottom of cone. r1 = d1 /2
# d2 : diameter, top of cone. r2 = d2 /2
# (NOTE: d,d1,d2 require 2014.03 of later. Debian is currently know to be behind this)
# center
# false (default), z ranges from 0 to h
# true, z ranges from -h/2 to +h/2
# $fa : minimum angle (in degrees) of each fragment.
# $fs : minimum circumferential length of each fragment.
# $fn : fixed number of fragments in 360 degrees. Values of 3 or more override $fa and $fs
# $fa, $fs and $fa must be named. click here for more details,.

# TODO: Check minimum parameter required

sub generate
{
    my($self, $level) = @_;

    return OpenScad::get_level($level) . "cylinder(h=" . $self->h
        . ((defined $self->r) ? ", r=" . $self->r
                             : ", r1=" . $self->r1 . " r2=" . $self->r2)
        . ((defined $self->d) ? ", d=" . $self->d : "")
        . ((defined $self->d1) ? ", d1=" . $self->d1 : "")
        . ((defined $self->d2) ? ", d2=" . $self->d2 : "")
        . ", center=" . ((defined $self->center) ? "true" : "false") . ", \$fa=1);";
}

1;
__END__
