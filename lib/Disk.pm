package Disk;

use strict;
use warnings;

use parent qw(Exporter OpenScad);

use Class::Tiny qw(name face1 face2);

use Data::Dumper;
use Math::Trig;

use constant {
    FORMAT => 600,
    HEIGHT => 10,
    HEIGHT_TEXT => 15,
    HEIGHT_MAX => 20,
    MICROGROOVE_START => 260,
    MICROGROOVE_WIDTH => 5,
    MICROGROOVE_MAX => 11,
    SEPARATE_WIDTH => 20,
};

# Notes
our $NOTES2DISK = {
    "GS4" => [ 0, 1 ],
    "As4" => [ 1, 0 ],
    "C5" => [ 1, 1 ],
    "Cs5" => [ 2, 0 ],
    "Ds5" => [ 2, 1 ],
    "E5" => [ 3, 0 ],
    "F5" => [ 3, 1 ], 
    "G5"  => 4,
    "Gs5"  => 5,
    "A5" => 6,
    "B5" => 7,
    "C6" => 8,
    "D6" => 9,
    "F6"  => 10,
};

our @EXPORT = qw($NOTES2DISK);

sub is_both_sides
{
    defined shift->face2
}

sub set_text
{
    my($self, $radius, $text, $size, $height) = @_;

    my $circumference = 2 * pi * $radius;
    my $text_size = length $text;
    my $font_size = $circumference / $text_size;
    my $step_angle = 360 / $text_size;

    my @results;
    
    for (my $i = 0; $i < $text_size; $i++)
    {
	push(@results, 
	     $self->rotate (
	     	 0, 0, - $i * $step_angle,
		 $self->translate(
		     0, $radius + $font_size / 2, 0, 
		     $self->text(
			 substr($text, $i, 1), 
			 "Courier New; Style = Bold", 
			 $size,
			 $height,
			 "center", "center"))));
	    
    }

    @results
}

sub set_note
{
    my($self, $size, $offset, $height, $note, $when) = @_;

    return $self->rotate(
        0, 0, $when,
        $self->translate($note + $offset, 0,
                         ($self->is_both_sides ? $height / 2 : - $height / 2),
                         $self->cube(2 * $size, $size, $height)));
}

sub set_notes
{
    my($self, $notes) = @_;

    my $note_str = $MIDI::number2note{$note};

    my $disk_nb = $notes2disk{$note_str};

    unless (defined $disk_nb) {
	die "Invalid note '$note_str'!\n";
    }

    $notes_stats{$note_str}++;

    my $radius = $time / $tempo;

    if ($radius > 360) {
	die "Too many notes!\n";
    }

    my($nb, $is_up);

    if (ref $disk_nb eq "ARRAY")
    {
	($nb, $is_up) = @$disk_nb;
    }
    else
    {
	($nb, $is_up) = ($disk_nb, 1);
    }

    warn "HERE! $time => $note, $radius, disk:$nb, $duration";

    push(@notes, set_note(
	     $is_verso,
	     $disk,
	     # taille de la note
	     $microsillon_width,
	     # offset / microsillon
	     $is_up ? $microsillon_width : - $microsillon_width * 2,
	     # épaisseur
	     HEIGHT_MAX,
	     # note
	     $microsillon_start
	     + ($space_between_microsillons + $microsillon_width) * $nb,
	     # angle
	     $radius));
}

sub set_cylinder_simple
{
    my($self, $height, $width) = @_;

    $self->is_both_sides
        ? $self->cylinder_simple($height * 2, $width, - $height)
        : $self->cylinder_simple($height, $width, 0)
}

sub set_cylinder_empty
{
    my($self, $max_size, $width) = @_;

    $self->is_both_sides
        ? $self->cylinder_empty(HEIGHT_MAX * 2, $max_size, $width, - HEIGHT_MAX)
        : $self->cylinder_empty(HEIGHT_MAX, $max_size, $width, 0)
}

sub generate
{
    my($self, $dst) = @_;

    my $disk_base = $self->set_cylinder_simple(HEIGHT, FORMAT);
    my $disk_external = $self->set_cylinder_empty(FORMAT, SEPARATE_WIDTH);   

    my @microgrooves;

    my $space_between_microgroove =
	(FORMAT - MICROGROOVE_START - 2 * SEPARATE_WIDTH) / MICROGROOVE_MAX;

    my $separate = MICROGROOVE_MAX;

    while (--$separate > 0) {

	push(@microgrooves, $self->set_cylinder_empty(
		 MICROGROOVE_START +
		 ($space_between_microgroove + MICROGROOVE_WIDTH) * $separate,
		 MICROGROOVE_WIDTH));
    }
    
    # Disque de séparations
    my $disk_separate = $self->set_cylinder_empty(MICROGROOVE_START, SEPARATE_WIDTH);

    # Disques du centre (trous)
    my $little_circle_size = 30;
    my $little_circle_offset = 200; # + $little_circle_size / 2;

    my @disks_center = (

	# 4 Cercles autour du cercle du milieu
	$self->translate(
	    $little_circle_offset, 0, -1,
	    $self->set_cylinder_simple(HEIGHT_MAX, $little_circle_size)),
	$self->translate(
	    - $little_circle_offset, 0, -1,
	    $self->set_cylinder_simple(HEIGHT_MAX, $little_circle_size)),
	$self->translate(
	    0, $little_circle_offset, -1,
	    $self->set_cylinder_simple(HEIGHT_MAX, $little_circle_size)),
	$self->translate(
	    0, - $little_circle_offset, -1,
	    $self->set_cylinder_simple(HEIGHT_MAX, $little_circle_size)),

	# Disque au centre
	$self->translate(
	    0, 0, -1, $self->set_cylinder_simple(HEIGHT_MAX, $little_circle_size * 2))
	);

    # Texte
    my @texts;
    my $factor = 1; 

    foreach my $face ($self->face1, $self->face2)
    {
	$face // next;
   
	if (defined(my $title = $face->title)) {
	    push(@texts, $self->set_text(110, $title, 120, $factor * HEIGHT_TEXT));
	}

	if (defined(my $author = $face->author)) {
	    push(@texts, $self->set_text(70, $author, 120, $factor * HEIGHT_TEXT));
	}

	$factor = -1;
    }
    
    my $scad = $self->difference(
	$self->union(
	    $disk_base,
	    $disk_external,
	    @microgrooves,
	    #@notes,
	    $disk_separate,
	    @texts),
	@disks_center)->generate;

    my $output;
    open($output, ">$dst/test.scad");
    binmode($output);
    print {$output} $scad;
    close($output);
}

1;
__END__
