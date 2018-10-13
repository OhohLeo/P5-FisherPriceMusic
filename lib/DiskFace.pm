package Note;

use strict;
use warnings;

use Class::Tiny qw(note delta_time duration);


package DiskFace;

use Data::Dumper;
use Scalar::Util 'looks_like_number';
use File::MimeInfo;
use MIDI;
use Disk;

use Class::Tiny qw(name midi tempo title author notes full_duration);

sub BUILD
{
    my($self, $args) = @_;

    my($name, $midi, $tempo, $title, $author) = @$args{qw(name midi tempo title author)};
    
    # Check tempo
    if (defined $tempo
	and not (looks_like_number($tempo)
		 and int($tempo) == $tempo))
    {
        die "$name: invalid tempo '$tempo'\n";
    }

    $self->tempo($tempo);

    # Check midi file
    unless (-f $midi)
    {
	$midi //= "<unknown>";
	die "$name: invalid midi file '$midi' as input!\n";
    }

    # Check midi type
    my $mime_type = mimetype($midi);
    unless ($mime_type eq 'audio/midi'
	    or $mime_type eq 'application/x-midi')
    {
	die "$name: invalid midi file type '$midi' as input!\n"
    }

    $self->name($name);
    $self->title($title);
    $self->author($author);
    $self->notes([]);
    $self->full_duration(0);
    
    # Read midi file 
    $self->midi(MIDI::Opus->new({
        from_file => $midi,
        include   => [ qw(note_on) ],
        event_callback => $self->get_note,
    }));
}

sub get_note
{
    my $self = shift;

    return sub {
	
	my(undef, $delta_time, undef, $note, $duration) = @_;
	
	return unless $duration > 0;

	# Check note validity
	$note = $MIDI::number2note{$note};
	my $res = $Disk::NOTES2DISK->{$note};
	unless (defined $res)
	{
	    die "$self->name: invalid note '$note'\n";
	}
	
	# Insert each note
	push(@{$self->notes}, Note::->new(
		 note => $note,
		 delta_time => $delta_time,
		 duration => $duration));
	
	# Calculate full duration
	$self->full_duration(
	    $self->full_duration + $duration + $delta_time);
    }
}

sub display
{
    my $self = shift;
    
    return sprintf("%s: full=%d notes %s",
		   $self->name,
		   $self->full_duration, join(
	    " ", map { sprintf("%s[%d-%d]", $_->note, $_->delta_time, $_->duration) } 
		       @{$self->notes}))
}

1;
__END__
