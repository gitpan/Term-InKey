package Term::InKey;

require Exporter;
use strict qw(vars);
use vars qw(@ISA @EXPORT $VERSION);
@ISA = qw(Exporter);
@EXPORT = qw(ReadKey Clear);

$VERSION = 1.00;

sub WinReadKey {
	my $y;
        eval {
		require Win32::Console;
		import Win32::Console;

		my $console = new Win32::Console STD_INPUT_HANDLE ;

		my $mode = $console->Mode || die $^E;
		$mode &= ~(ENABLE_LINE_INPUT | ENABLE_ECHO_INPUT);
		$console->Mode($mode) || die $^E;    

		$console->Flush || die $^E;

		$y = $console->InputChar(1);
		die $^E unless defined($y);
        };
	die "Not implemented on $^O: $@" if $@;
	$y;
}

sub BadReadKey {
	system "stty raw -echo";
	my $ch = getc;
	system "stty -raw echo";
	$ch;
}

sub ReadKey {
	if ($^O =~ /Win32/i) {
		return &WinReadKey;
	};

	my $save;

	eval {
                require POSIX;
		import POSIX;

		$save = new POSIX::Termios;
	};
	return &BadReadKey if $@;

	$save->getattr(0);

	my $x = new POSIX::Termios;

	$x->getattr(0);

	my %flags;

	&getit($x, \%flags);

	# +raw

	$flags{'i'} &= ~(IGNBRK|BRKINT|PARMRK|ISTRIP
                                   |INLCR|IGNCR|ICRNL|IXON);

	$flags{'o'} &= ~OPOST;

	$flags{'l'} &= ~(ECHO|ECHONL|ICANON|ISIG|IEXTEN);

	$flags{'c'} &= ~(CSIZE|PARENB);
	$flags{'c'} |= CS8;

	&setit($x, \%flags);

	$x->setattr(0);

	my $ch = getc;
	
	$save->setattr(0);

	$ch;
}

sub getit {
	my ($x, $flags) = @_;
	foreach (qw(i o c l)) {
		my $meth = $x->can("get${_}flag");
		$flags->{$_} = &$meth($x);
	}
}

sub setit {
	my ($x, $flags) = @_;
	foreach (qw(i o c l)) {
		my $meth = $x->can("set${_}flag");
		&$meth($x, $flags->{$_});
	}
}

sub WinClear {
        eval {
		require Win32::Console;
		import Win32::Console;

	        my $console = new Win32::Console(STD_OUTPUT_HANDLE) || die $^E;
		$console->Cls || die $^E;
        	$console->Display;
	        $console->Select(STD_OUTPUT_HANDLE) || die $^E;
        };
	&BadClear if $@;
}


sub BadClear {
	if ($^O =~ /Win/i || $^O =~ /Dos/i) {
		system "cls";
		return;
	}

	system "clear";
}

sub Clear {
	if ($^O =~ /Win32/i) {
		&WinClear;
		return;
	}
	
	my $cls = undef if undef;

	unless (defined($cls)) {
		$cls = ''; # Avoid warnings

		my $speed = 9600;

		eval {
                        require POSIX;
			import POSIX;

			my $x = new POSIX::Termios;
			POSIX::Termios::getattr($x, 0);
			$speed = $x->getospeed;
		};

		eval {
                        require Term::Cap;
			my $emu = $ENV{'TERM'} || 'vt100';
		        my $term = Term::Cap->Tgetent({'TERM' => $emu,
				'OSPEED' => $speed});
		        $cls = $term->Tputs('cl');
		};
	}

	unless ($cls) {
		&BadClear;
		return;
	}

	my $desc = select;
	select STDOUT;
	my $pipe = $|;
	$| = 1;
	print $cls;

	$| = $pipe;
	select $desc;
}

1;
__END__

=head1 NAME

Term::InKey - Perl extension for clearing the screen and receiving a keystroke.

=head1 SYNOPSIS

        use Term::InKey;

        print "Press any key to clear the screen: ";
        $x = &ReadKey;
        &Clear;
        print "You pressed $x\n";

=head1 DESCRIPTION

This module implements Clear() to clear screen and ReadKey() to receive
a keystroke, on UNIX and Win32 platforms. As opposed to B<Term::ReadKey>,
it does not contain XSUB code and can be easily installed on Windows boxes.

=head1 TODO

Write a function to receive a keystroke with time out. Easy with select()
on UNIX.

=head1 COMPLIANCE

This module works only on UNIX systems and Win32 systems.

=head1 AUTHOR

Raz Information Systems, B<razinf@cpan.org>, B<raz@raz.co.il>.

=head1 COPYRIGHT

This module is free and is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<stty>, L<tcsetattr>, L<termcap>, L<Term::Cap>, L<POSIX>, L<Term::ReadKey>.

=cut
