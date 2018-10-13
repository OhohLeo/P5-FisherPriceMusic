package OpenScad::Text;

use strict;
use warnings;

use OpenScad;

use Class::Tiny qw(text size font halign valign spacing direction language script);

sub generate
{
    my($self, $level) = @_;

    return OpenScad::get_level($level) . 'text(text="' . $self->text . '"'
        . (defined $self->font ? ', font="' . $self->font . '"' : "")
        . (defined $self->size ? ', size="' . $self->size . '"' : "")
        . (defined $self->halign ? ', halign="' . $self->halign . '"' : "")
        . (defined $self->valign ? ', valign="' . $self->valign . '"' : "")
        .");";
}

1;
__END__
