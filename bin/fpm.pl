#!/usr/bin/perl

use strict;
use warnings;

use Scalar::Util 'looks_like_number';
use Getopt::Long;
use Cwd;
use File::MimeInfo;
use MIDI;
use OpenScad;
use feature 'say';

my($midi1, $tempo1, $title1, $author1,
   $midi2, $tempo2, $title2, $author2, $dst, $help);

GetOptions(
    'midi|m=s'     => \$midi1,
    'tempo|t=s'    => \$tempo1,
    'title|r=s'    => \$title1,
    'author|a=s'   => \$author1,
    'midi2|m2=s'   => \$midi2,
    'tempo2|t2=s'  => \$tempo2,
    'title2|r2=s'  => \$title2,
    'author2|a2=s' => \$author2,
    'dst=s'        => \$dst,
    'help|h'       => \$help,
) or die "Incorrect usage : try 'fpm.pl -h' !\n";

if ($help)
{
    die <<END;
    usage : fpm.pl --midi  Midi file
                   --tempo Tempo of Midi file
                   --title Music Name
                   --author Name of the composer

                   --midi2 Midi file
                   --tempo2 Tempo of Midi file
                   --title2 Music Name
                   --author2 Name of the composer

                   --dst destination directory (optional - 'build' as default)
                   --h   this help.
END
}

warn "$midi1, $tempo1, $title1, $author1, $midi2, $tempo2, $title2, $author2";

# Check tempo
foreach my $tempo ($tempo1, $tempo2)
{
    next if not defined $tempo
        and not defined $tempo2;

    unless (defined $tempo
            and looks_like_number($tempo)
            and int($tempo) == $tempo)
    {

        $tempo //= "<unknown>";

        die "Unexpected tempo '$tempo'\n";
    }
}

# Check midi file
foreach my $midi ($midi1, $midi2)
{
    next if not defined $midi
        and not defined $midi2;

    unless (-f $midi) {

        $midi //= "<unknown>";

        die "Invalid midi file '$midi' as input!\n";
    }

    # Check midi type
    my $mime_type = mimetype($midi);

    die "Invalid midi file '$midi' as input!\n"
        unless ($mime_type eq 'audio/midi'
                or $mime_type eq 'application/x-midi');
}

my $is_recto_verso;

if (defined $tempo2 and defined $midi2)
{
    $is_recto_verso = 1;
}
elsif ((defined $tempo2 and not defined $midi2)
       or (defined $midi2 and not defined $tempo2))
{
    $midi2 //= "<unknown>";
    $tempo2 //= "<unknown>";

    die "Expected to midi2 '$midi2' and tempo2 '$tempo2' both defined!\n";
}

# Check output directory or create it
$dst //= cwd() . '/build';

if (not -d $dst)
{
    mkdir $dst
        or die "Impossible to create dst '" . $dst . ": $!'!\n";
}

say "Generate standard disk";

# Génération du disque
my $height = 10;
my $height_max = 20;

my $disk = OpenScad::->new();

sub set_cylinder_simple
{
    my($height, $width) = @_;

    $is_recto_verso
        ? $disk->cylinder_simple($height * 2, $width, - $height)
        : $disk->cylinder_simple($height, $width, 0)
}

sub set_cylinder_empty
{
    my($max_size, $width) = @_;

    $is_recto_verso
        ? $disk->cylinder_empty($height_max * 2, $max_size, $width, - $height_max)
        : $disk->cylinder_empty($height_max, $max_size, $width, 0)
}

sub set_note
{
    my($is_recto, $disk, $size, $offset, $height, $note, $when) = @_;

    return $disk->rotate(
        0, 0, $when,
        $disk->translate($note + $offset, 0,
                         ($is_recto ? $height / 2 : - $height / 2),
                         $disk->cube(2 * $size, $size, $height)));
}

# Base du disque
my $format = 600;
my $disk_base = set_cylinder_simple($height, $format);

my $max_microsillons = 11;
my $microsillon_width = 5;

my $separate_width = 20;

# Contour du disque
my $disk_external = set_cylinder_empty($format, $separate_width);   ;

# Microsillons
my @microsillons;
my $microsillon_start = 260;

my $space_between_microsillons =
    ($format - $microsillon_start - 2 * $separate_width) / $max_microsillons;

my $separate = $max_microsillons;

while (--$separate > 0) {

    push(@microsillons, set_cylinder_empty(
             $microsillon_start +
             ($space_between_microsillons + $microsillon_width) * $separate,
             $microsillon_width));
}

# Mise en place des notes
my %notes2disk = (
    "Gs4" => [ 0, 1 ],
    "As4" => [ 1, 0 ],
    "C5" => [ 1, 1 ],
    "Cs5" => [ 2, 0 ],
    "Ds5" => [ 2, 1 ],
    "F5" => 3,
    "G5"  => 4,
    "Gs5"  => 5,
    "As5" => 6,
    "C6" => 7,
    "Cs6" => 8,
    "Ds6" => 9,
    "F6"  => 10,
);

my(@notes, %notes_stats, $time, $is_verso, $tempo);

say "Read midi file";

foreach my $midi ($midi1, $midi2)
{
    next if not defined $midi
        and not defined $midi2;

    if ($time > 0)
    {
        undef $is_verso;
        $tempo = $tempo2;
    }
    else
    {
        $is_verso = 1;
        $tempo = $tempo1;
    }

    $time = 0;

    $midi = MIDI::Opus->new({
        from_file => $midi,
        include   => [ qw(note_on) ],
        event_callback => \&handle_note,
    });

    sub handle_note
    {
        my(undef, $delta_time, undef, $note, $duration) = @_;

        $time += $delta_time;

        return unless $duration > 0;

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
                 $height_max,
                 # note
                 $microsillon_start
                 + ($space_between_microsillons + $microsillon_width) * $nb,
                 # angle
                 $radius));
    }

}

# Disque de séparations
my $disk_separate = set_cylinder_empty($microsillon_start, $separate_width);

# Disques du centre (trous)
my $little_circle_size = 30;
my $little_circle_offset = 200; # + $little_circle_size / 2;

my @disks_center = (

    # 4 Cercles autour du cercle du milieu
    $disk->translate(
        $little_circle_offset, 0, -1,
        set_cylinder_simple($height_max, $little_circle_size)),
    $disk->translate(
        - $little_circle_offset, 0, -1,
        set_cylinder_simple($height_max, $little_circle_size)),
    $disk->translate(
        0, $little_circle_offset, -1,
        set_cylinder_simple($height_max, $little_circle_size)),
    $disk->translate(
        0, - $little_circle_offset, -1,
        set_cylinder_simple($height_max, $little_circle_size)),

    # Disque au centre
    $disk->translate(
        0, 0, -1, set_cylinder_simple($height_max, $little_circle_size * 2))
    );

# Texte
my @texts;

my $up_and_down = 1 / 2;

foreach my $text ($title1, $author1)
{
    next unless defined $text;

    push(@texts, $disk->translate(
             0,  $up_and_down * $little_circle_offset, 0,
             $disk->scale(4, 4, 1,
                          $disk->text($text, "Goha-Tibeb Zemen",
                                      100, $height_max, "center"))));

    $up_and_down = ($up_and_down > 0) ? - 2 / 3 : 1 / 2;
}

$up_and_down = - 1 / 2;

foreach my $text ($title2, $author2)
{
    next unless defined $text;

    push(@texts, $disk->translate(
             0,  $up_and_down * $little_circle_offset, - 2 * $height,
             $disk->scale(4, -4, 1,
                          $disk->text($text, "Goha-Tibeb Zemen",
                                      100, $height_max, "center"))));

    $up_and_down = ($up_and_down > 0) ? - 1 / 2 : 2 / 3;
}

my $scad = $disk->difference(
    $disk->union(
        $disk_base,
        $disk_external,
        @microsillons,
        @notes,
        $disk_separate,
        @texts),
    @disks_center)->generate;

my $output;
open($output, ">test.scad");
binmode($output);
print {$output} $scad;
close($output);

say "Scad file succesfully generated!";

say "notes presents:" . join(", ", sort keys %notes_stats);

foreach my $note (keys %notes_stats) {
    delete $notes2disk{$note};
}

say "notes absents:" . join(", ", sort keys %notes2disk);
