#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Cwd;
use Disk;
use DiskFace;
use feature 'say';

my($midi, $tempo, $title, $author,
   $midi2, $tempo2, $title2, $author2, $dst, $help);

GetOptions(
    'midi|m=s'     => \$midi,
    'tempo|t=s'    => \$tempo,
    'title|r=s'    => \$title,
    'author|a=s'   => \$author,
    'midi2|m2=s'   => \$midi2,
    'tempo2|t2=s'  => \$tempo2,
    'title2|r2=s'  => \$title2,
    'author2|a2=s' => \$author2,
    'dst=s'        => \$dst,
    'help|h'       => \$help,
) or die "Incorrect usage : try 'fpm.pl -h' !\n";

if (not defined $midi 
    or not defined $tempo
    or $help)
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

                   --dst destination directory (optional - 'output' as default)
                   --h   this help.
END
}

# Check output directory or create it
$dst //= cwd() . '/output';
if (not -d $dst)
{
    mkdir $dst
        or die "Impossible to create dst '" . $dst . ": $!'!\n";
}

say "Generate standard disk";
my $face1 = DiskFace::->new(
    name => "face1",
    midi => $midi,
    tempo => $tempo, 
    title => $title,
    author => $author);

say $face1->display;

my $disk = Disk::->new(
    name => "disk",
    face1 => $face1);

$disk->generate($dst);

say "Scad file succesfully generated!";

