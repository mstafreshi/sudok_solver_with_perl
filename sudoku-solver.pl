#!/usr/local/bin/perl
#
# Another sudoku solver with Perl!
#
# Programmer : Mohsen Safari
# Email      : safari.tafreshi@gmail.com
# Website     : safarionline.ir
#ا 
# read sudoku tables from named file provided at command line
# or read it from standard input.
# each line has one sudoku challenge!
# blank entries must be specified with .(dot) or 0(zero).
# Examples:
#
# 4.....8.5.3..........7......2.....6.....8.4......1.......6.3.7.5..2.....1.4......
# 52...6.........7.13...........4..8..6......5...........418.........3..2...87.....
# 6.....8.3.4.7.................5.4.7.3..2.....1.6.......2.....5.....8.6......1....
# 48.3............71.2.......7.5....6....2..8.............1.76...3.....4......5....
# ....14....3....2...7..........9...3.6.1.............8.2.....1.4....5.6.....7.8...
#
# Usage:
# $ echo 4.....8.5.3..........7......2.....6.....8.4......1.......6.3.7.5..2.....1.4...... | perl sudoku-solver.pl
# $ perl sudoku-solver.pl file
#
 
use warnings;
use strict;
 
my (@parray, @moves, @adjacent, %possibility_hash);
#
# A little house keeping! calculate each row, column, and sqaure indexs
# and finally calculate all adjacent of each entry.
#
{
	my (@rindex, @cindex, @sqindex);
	my (@r, @c, @sq);
	my ($r, $c, $sq);
	my (%hash, $j);
	# first index of each sqaure.
	my @sq_start = (0, 3, 6, 27, 30, 33, 54, 57, 60); 
 
	foreach(0 .. 8) {
		my @arr;
		for(my $iter = $_; $iter <= 80; $iter += 9){
			push @arr, $iter;
		}
		# fill indexes of each column.
		$cindex[$_] = [@arr];
 
		# Calculate indexes of each row.
		$rindex[$_] = [$_ * 9 .. $_ * 9 + 8];
 
		$j = $sq_start[$_];
		# fill indexes of each square
		$sqindex[$_] = [$j, $j+1,$j+2,$j+9,$j+10,$j+11,$j+18,$j+19,$j+20];
	}
 
	foreach(0 .. 80) {
		$r = int($_ / 9);
		$c = $_ % 9;
 
		if ($r <= 2) {
			if($c <= 2) { $sq = 0 } elsif ($c <= 5) { $sq = 1 } else { $sq = 2}
		}
		elsif ($r <= 5) {
			if($c <= 2) { $sq = 3 } elsif ($c <= 5) { $sq = 4 } else { $sq = 5}
		}
		else {
			if($c <= 2) { $sq = 6 } elsif ($c <= 5) { $sq = 7 } else { $sq = 8}
		} 	
 
		@r  = @{$rindex[$r]};
		@c  = @{$cindex[$c]};
		@sq = @{$sqindex[$sq]};
		%hash = ();
 
		foreach my $j ((@r, @c, @sq)) {
			$hash{$j}++;
		}
		# fill adjacent indexes of each entry.
		$adjacent[$_] = [sort {$a <=> $b} keys %hash];
	}
}
 
#
# print sudoku table is a readable and familar format
#
sub print_sudoku {
	print "+---+---+---+", "\n";
	for (my $i = 0; $i <= $#parray; $i++) {
		if ( $i % 3 == 0) {
			print "|";
		}
		print $parray[$i] != 0 ? $parray[$i] : ".";
		print "|\n" if ( ($i + 1) % 9 == 0);
 
		if ( ($i + 1) % 27 == 0) {
			print "+---+---+---+", "\n";
		}
	}
}
 
#
# Print sudoku table. each entry that has not a specified value
# will be filled with its possible values.
#
sub display {
	find_possibilities(-1);
	print "+-----------------------------+-----------------------------+-----------------------------+" , "\n";
	for (my $i = 0; $i <= $#parray; $i++) {
		if ( $i % 9 == 0) {
			print "|";
		}
		if ($parray[$i] != 0) {
			print "    $parray[$i]    |";
		}
		else {
			my $b = $possibility_hash{$i};
			my $s = "";
			$s .= $_ foreach (@{$b});
			$s = " " . $s . " " while length $s < 9;
			$s = substr($s, 0, length($s) - 1) if length $s > 9;
			print $s, "|";
		}
 
		print "\n" if ( ($i + 1) % 9 == 0);
 
		if ( ($i + 1) % 27 == 0) {
			print "+-----------------------------+-----------------------------+-----------------------------+" , "\n";
		}
	}
}
 
#
# when no progress is available we would rollback to previous move
#
sub rollback {
	if (!@moves) {
		print STDERR "Moves array is empty!\n";
		exit 1;
	}
 
	my $r = pop @moves;
	$parray[$r->[0]] = 0;
	return ($r->[0], $r->[1]);
}
 
#
# find possibilities of each no valued entries.
#
sub find_possibilities {
	my (%hash, @arr, @tmp);
	my @iterate =  $_[0] == -1 ? (0 .. 80) : @{$adjacent[$_[0]]};
 
	delete @possibility_hash{@iterate};
	foreach my $i (@iterate) {
		next if $parray[$i] != 0;
		%hash = ();
		@arr = ();
 
		@tmp = @parray[@{$adjacent[$i]}];
		$hash{$_}++ foreach((@tmp));
		foreach (1..9) {
			push @arr, $_ if not exists $hash{$_};
		}		
		return -1 if !@arr;
		$possibility_hash{$i} = [@arr];
	}
	return 1;
}
 
#
# find best move at current position
#
sub find_best_move {
	my $spot_be = shift;
	my $must_not_be = shift;
 
	my (@su, @tmp);
 	if ($spot_be >= 0) {
		foreach(@{$possibility_hash{$spot_be}}) {
			return ($spot_be, $_) if $_ > $must_not_be;
		}
		return (-1, -1); 
	}
 
	for(my $i = 0; $i <= $#parray; $i++) {
		next if $parray[$i] != 0;
		push @su, "$i @{$possibility_hash{$i}}";
	}
	@su = sort { length $a <=> length $b } @su;
 
	foreach my $i (@su){
		@tmp = split " ", $i;
		for (my $j = 1; $j <= $#tmp; $j++) {
			return ($tmp[0], $tmp[$j]) if $tmp[$j] != $must_not_be; 
		}
	}
	# if no move is available return (-1, -1) to rollback
	return (-1, -1);
}
 
my ($spot, $value, $try, $last);
my ($spot_be, $must_not_be) = (-1, -1);
 
#
# while there is a line at standard input or named file...
# each line is a sudoku.
#
while (<>) {
	chomp;
	if (length != 81) {
		print STDERR "Invalid sudoku entry!\n";
		next;
	}	
	s/\./0/g;
	@parray = split "";
	print_sudoku;
	display;
	$try = 0;
	$last = -1;
	while (1) {
		if (find_possibilities($last) == -1) {
			($spot_be, $must_not_be) = rollback;
			$last = $spot_be;
			next;
		}
		last if !keys %possibility_hash;
 
		($spot, $value) = find_best_move $spot_be, $must_not_be;
		if ($spot == -1 and $value == -1) {
			($spot_be, $must_not_be) = rollback;
			$last = $spot_be;
			next;
		}
		$parray[$spot] = $value;
		push @moves, [$spot, $value];
		$spot_be = $must_not_be = -1;
		$try = $try + 1;
		$last = $spot;
	}
	print "Moves: $try\n";
	print_sudoku;
	print "@" x 13, "\n" if !eof();
}
