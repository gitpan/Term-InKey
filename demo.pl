#!/usr/local/bin/perl -w
 use lib qw(.);
 use Term::InKey;
 $|=1;
 &Clear;
 print "\nThis is a demo program for Term::InKey Ver $Term::InKey::VERSION\n";
 print "Press any key to clear the screen: ";
 $x = &ReadKey;
 &Clear;
 print "You pressed [$x]\n\n";
 print "This is a demo of ReadPassword, type few letters then type [enter]: ";
  $x = &ReadPassword('x');
 print "\nPassword you typed is [$x]\n";
 print "\nThis ends a demo program for Term::InKey Ver $Term::InKey::VERSION\n";
