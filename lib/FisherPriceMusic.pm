package FisherPriceMusic;

# ABSTRACT: FisherPriceMusic : generate Fisher Price 3D model disk from midi file

use strict;
use warnings;

use Cwd;
use File::MimeInfo;
use MIDI;
use GD;
use OpenScad;

use Object::Tiny qw(dst);

use feature 'say';

=item new(MIDI_FILE, DST)

Check the MIDI File.

If the DST directory doen't exist : create it.

=cut
sub new {

    my($class, $midi, $dst) = @_;

    # Check midi file
    unless (-f $midi) {

        $midi //= "<unknown>";

        die "Invalid midi file '$midi' as input!\n";
    }

    # Check midi type
    my $mime_type = mimetype($midi);

    die "Invalid midi file '$midi' as input!\n"
        unless ($mime_type eq 'audio/midi'
                or $mime_type eq 'application/x-midi');

    # Check output directory or create it
    $dst //= cwd() . '/build';

    if (not -d $dst)
    {
        mkdir $dst
            or die "Impossible to create dst '" . $dst . ": $!'!\n";
    }

    my $self = $class->SUPER::new(dst => $dst);


    $self->handle_midi($midi);

    # disk_generate();

    return $self;
}

=item $obj->handle_midi(FILE)

Handle file input :

=cut
sub handle_midi
{
    my($self, $file) = @_;

    say "handle file '$file'";

    my $midi = MIDI::Opus->new({
        "from_file" => $file,
    });

    say $midi->dump({ dump_tracks => 1 });

    my $draw = $midi->draw();

    if ($draw)
    {
        my $output;
        open($output, ">test.gif");
        binmode($output);
        print {$output} $draw->gif;
        close($output);
    }
}

=item $obj->disk_generate(TITLE, AUTHOR, NOTES)

Generate scad file that can be opened with OpenScad to generate the object.

=cut
sub disk_generate
{
    my $height = 10;
    my $height_max = 20;
    my $format = 1000;

    my $o = OpenScad::->new();

    # Base du disque
    my $disk_base = $o->cylinder_simple($height, $format);

    my $max_microsillons = 10;
    my $microsillon_width = 10;
    my $space_between_microsillons = $format / ($max_microsillons * 2) - 4;

    # Contour du disque
    my $disk_external = $o->cylinder_empty($height_max, $format, $microsillon_width * 5);

    # Microsillons
    my @microsillons;

    my $separate = $max_microsillons;

    while (--$separate > 0) {

        push(@microsillons, $o->cylinder_empty(
                 $height_max,
                 $format / 2 + $space_between_microsillons * $separate,
                 $microsillon_width));
    }

    # Mise en place des notes
    my @notes;

    for (my $i= 0; $i < $max_microsillons; $i++)
    {
        push(@notes, set_note(
                 $o,
                 $microsillon_width, # taille de la note
                 $space_between_microsillons / 4, # offset
                 $height_max,
                 $format / 2 + $space_between_microsillons * $i,
                 360 / $max_microsillons * $i));

        push(@notes, set_note(
                 $o,
                 $microsillon_width, # taille de la note
                 $space_between_microsillons / 4, # offset
                 $height_max,
                 $format / 2 + $space_between_microsillons * $i
                 +  $space_between_microsillons / 2,
                 360 / $max_microsillons * $i));
    }


    # Disque de séparations
    my $disk_separate = $o->cylinder_empty($height_max, $format / 2, $microsillon_width * 5);

    # Disques du centre (trous)
    my $little_circle_size = 30;
    my $little_circle_offset = $format / 2 - 100;

    my @disks_center = (

        # 4 Cercles autour du cercle du milieu
        $o->translate(
            $little_circle_offset, 0, -1,
            $o->cylinder_simple($height_max, $little_circle_size)),
        $o->translate(
            - $little_circle_offset, 0, -1,
            $o->cylinder_simple($height_max, $little_circle_size)),
        $o->translate(
            0, $little_circle_offset, -1,
            $o->cylinder_simple($height_max, $little_circle_size)),
        $o->translate(
            0, - $little_circle_offset, -1,
            $o->cylinder_simple($height_max, $little_circle_size)),
        $o->translate(
            0, 0, -1, $o->cylinder_simple($height_max, $little_circle_size))
        );

    # Texte
    my $text =
        $o->translate(
            0, - 3 * $little_circle_offset / 4, 0,
            $o->scale(6, 6, 1,
                      $o->text("TONTON LEO", "Goha-Tibeb Zemen",
                               100, $height_max, "center")));


    my $scad = $o->difference(
        $o->union(
            $disk_base,
            $disk_external,
            @microsillons,
            @notes,
            $disk_separate,
            $text),
        @disks_center)->generate;

    my $output;
    open($output, ">test.scad");
    binmode($output);
    print {$output} $scad;
    close($output);
}


=item $obj->set_note(SIZE, OFFSET, HEIGHT, NOTE, WHEN)

Fix the note on the disk

=cut
sub set_note
{
    my($o, $size, $offset, $height, $note, $when) = @_;

    return $o->rotate(
        0, 0, $when,
        $o->translate($note + $offset / 2, 0, $height / 2,
                      $o->cube($size + $offset / 2, $size, $height)));
}


1;
__END__
