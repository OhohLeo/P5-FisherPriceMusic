package OpenScad;

use strict;
use warnings;

use OpenScad::Text;
use OpenScad::Cube;
use OpenScad::Cylinder;
use Data::Dumper;

use Class::Tiny qw(type args contains);

sub BUILD
{
    my $self = shift;

    if (not defined $self->contains)
    {
        $self->contains([]);
    }
}

sub args_get
{
    my($self, $name) = @_;

    return ($self->args // return undef)->{$name};
}

=head2 BOOLEAN OPERATIONS

=over 4

=item $obj->intersection(ELEMENTS)

Creates the intersection of all child nodes. This keeps the
overlapping portion (logical and).

Only the area which is common or shared by all children is retained.

May be used with either 2D or 3D objects, but don't mix them.

=cut
sub intersection
{
    my $self = shift;

    # TODO :CHECK
    # May be used with either 2D or 3D objects, but don't mix them.

    my $intersection = OpenScad->new(
        type => "intersection",
        contains => [ @_ ]);

    push(@{$self->contains}, $intersection);

    $intersection;
}

sub union
{
    my $self = shift;

    # TODO :CHECK
    # May be used with either 2D or 3D objects, but don't mix them.

    my $union = OpenScad->new(
        type => "union",
        contains => [ @_ ]);

    push(@{$self->contains}, $union);

    $union;
}

sub difference
{
    my $self = shift;

    # TODO :CHECK
    # May be used with either 2D or 3D objects, but don't mix them.

    my $difference = OpenScad->new(
        type => "difference",
        contains => [ @_ ]);

    push(@{$self->contains}, $difference);

    $difference;
}

=back

=head2 TRANSFORMATIONS

=over 4

=item $obj->translate(x, y, z, element)

=cut
sub translate
{
    my($self, $x, $y, $z, $element) = @_;

    my $translate = OpenScad->new(
        type => "translate",
        args => { x => $x,
                  y => $y,
                  z => $z },
        contains => [ $element ]);

    push(@{$self->contains}, $translate);

    $translate
}

=item $obj->rotate(x, y, z, element)

=cut
sub rotate
{
    my($self, $x, $y, $z, $element) = @_;

    my $rotate = OpenScad->new(
        type => "rotate",
        args => { x => $x,
                  y => $y,
                  z => $z },
        contains => [ $element ]);

    push(@{$self->contains}, $rotate);

    $rotate
}

=item $obj->scale(x, y, z, element)

=cut
sub scale
{
    my($self, $x, $y, $z, $element) = @_;

    my $scale = OpenScad->new(
        type => "scale",
        args => { x => $x,
                  y => $y,
                  z => $z },
        contains => [ $element ]);

    push(@{$self->contains}, $scale);

    $scale
}

=item $obj->linear_extrude(HEIGHT, ELEMENT, ...)

=cut
sub linear_extrude
{
    my($self, $height, @elements) = @_;

    my $linear_extrude = OpenScad->new(
        type => "linear_extrude",
        args => { h => $height },
        contains => \@elements);

    push(@{$self->contains}, $linear_extrude);

    $linear_extrude
}
=back

=head2 3D OBJECTS

=over 4

=item $obj->cube(X, Y, Z)

=cut
sub cube
{
    my($self, $x, $y, $z) = @_;

    return OpenScad::Cube::->new(
        x => $x,
        y => $y,
        z => $z,
        center => 1)
}

=item $obj->cylinder()

Creates a cylinder or cone centered about the z axis. When center is true, it is also centered vertically along the z axis.

Parameter names are optional if given in the order shown here. If a parameter is named, all following parameters must also be named.

=cut
sub cylinder_simple
{
    my($self, $h, $r, $z) = @_;

    return $self->translate(0, 0, $z,
                            OpenScad::Cylinder::->new(
                                h => $h,
                                r => $r));
}

sub cylinder_empty
{
    my($self, $h, $r, $d, $z) = @_;

    $z //= 0;

    return $self->difference(
        $self->cylinder_simple($h, $r, $z),
        $self->translate(0, 0, $z - 1,
                         $self->cylinder_simple($h + 2, $r - $d, 0)));
}

=item $obj->text(TEXT, FONT, SIZE, HEIGHT, HALIGN, VALIGN)

=cut
sub text
{
    my($self, $text, $font, $size, $height, $halign, $valign) = @_;

    return $self->linear_extrude(
        $height, OpenScad::Text::->new(
            text => $text,
            font => $font,
            size => $size,
            halign => $halign,
            valign => $valign,
        ))
}

sub generate
{
    my($self, $level) = @_;

    $level //= 0;

    my $actual_level = get_level($level);

    my $contains;

    foreach my $element (@{$self->contains})
    {
        $contains .= "\n" . $element->generate($level + 1);
    }

    $self->type // return $contains;

    if ($self->type eq "intersection"
        or $self->type eq "union"
        or $self->type eq "difference") {

        return sprintf(
            "%s%s(){%s\n%s}",
            $actual_level, $self->type, $contains, $actual_level);
    }
    elsif ($self->type eq "translate"
           or $self->type eq "rotate"
           or $self->type eq "scale")
    {
        return sprintf(
            "%s%s([%d, %d, %d])%s",
            $actual_level, $self->type,
            $self->args_get('x'), $self->args_get('y'), $self->args_get('z'),
            $contains);
    }

    elsif ($self->type eq "linear_extrude")
    {
        return sprintf(
            "%s%s(height = %d) {%s\n%s}",
            $actual_level, $self->type,
            $self->args_get('h'),
            $contains, $actual_level);
    }
}

sub get_level
{
    "  " x shift
}

1;
__END__
