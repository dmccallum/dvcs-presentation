#!/usr/bin/perl

use strict;

my $os_type = ("\n" eq "\015") ? "MAC" : "WINIX";
my $rel;
my $sep;

if ($os_type eq "MAC") {
    $rel = ":";
    $sep = ":";
} else {
    $rel = "./";
    $sep = "/";
}

my $slides_dir = shift;
if (!$slides_dir) {
    if (-d "./slides") {
        $slides_dir = "slides";
    } else {
        $slides_dir = "content";
    }
}

my $output_dir = shift;
if (!$output_dir) {
    $output_dir = "output";
}
print "content = $slides_dir\n";
print "output = $output_dir\n";

my @slide_info;
my @toc;

open (HTML, $rel . "skel.html");
my $html = join ("", <HTML>);
close (HTML);

unless (open (LIST, "$rel$slides_dir" . $sep . "slidelist.txt")) {
  print "You you need a file called 'slidelist.txt' containing an\n";
  print "ordered list of file names for each of your slides.\n";
  exit;
}
my @slides = <LIST>;
close (LIST);

my $slide;

foreach $slide (@slides) {
    $slide =~ s/\s*\#.*//;
    $slide =~ s/^\W*//;
    $slide =~ s/\W*$//;
    if ($slide) {
        print "current slide: $slide\n";
        open (SLIDE, "$rel$slides_dir$sep$slide") ||
          die "No such slide: $slide\n";

        my $line;
        my $head = "";
        my $title = "";
        my $title_state = 0;
        my $head_state = 0; # 0: looking, 1: getting, 2: done
        while ($head_state != 2) {
            if (!($line = <SLIDE>)) {
                $head_state = 2;
                next;
            }
            if ($line =~ /<head>.*(<\/head>)?/i) {
                $head = $1;
                $head_state = $2 ? 2 : 1;
            } elsif ($head_state && $line =~ /(.*)<\/head>/i) {
                $head .= $1;
                $head_state = 2;
            } elsif ($head_state == 1) {
                $head .= $line;
            }

            if ($head_state == 1 && $title_state == 0 &&
                $line =~ /<title>(.*)(<\/title>)?/i) {
                $title = $1;
                $title_state = $2 ? 2 : 1;
            } elsif ($head_state == 1 && $title_state == 1 &&
                     $line =~ /(.*)(<\/title>)?/i) {
                $title .= $1;
                $title_state = $2 ? 2 : 1;
            } elsif ($head_state == 1 && $title_state == 1) {
                $title .= $line;
            }
        }
        if (!$head) {
            warn "slide `$slide` has no <head>\n";
        }
        if (!$title) {
            warn "slide `$slide` has no <title>\n";
        }
        if ($head_state != 2) {
            warn "never saw </head> in slide `$slide`\n";
        }
        push (@slide_info, ($slide, $head, $title));
        close (SLIDE);
    }
}

my $head;
my $title;
my $previous = "";
my $toc = "[ " . join (" | ", @toc) . " ]";

$slide = shift (@slide_info);
$slide =~ s/^\W*//;
$slide =~ s/\W*$//;
$head = shift (@slide_info);
$title = shift (@slide_info);

while ($slide) {
    my $slide_content;
    my $slide_file = $slide;
    open (SLIDE, "$rel$slides_dir$sep$slide_file");
    my $line = <SLIDE>;
    while (!($line =~ /<body>/)) {
        $line = <SLIDE>;
    }
    $line = <SLIDE>;
    while (!($line =~ /<\/body>/)) {
        $slide_content .= $line;
        $line = <SLIDE>;
    }
    close (SLIDE);

    $_ = $html;
    s/\$head/$head/ig;
    s/\$title/$title/ig;
    s/\$toc/$toc/ig;

    if ($previous) {
        s/\$previous/<a href=\"$previous\">\&lt;\&lt; Previous<\/a>/ig;
        s/\$url_previous/$previous/ig;
    } else {
        s/\$previous/\&lt;\&lt; Previous/ig;
        s/\$url_previous//ig;
    }

    $previous = $slide;

    $slide = shift (@slide_info);
    if ($slide) {
        $head = shift (@slide_info);
        $title = shift (@slide_info);
        s/\$next/<a href=\"$slide\">Next \&gt;\&gt;<\/a>/ig;
        s/\$url_next/$slide/ig;
    } else {
        s/\$next/Next \&gt;\&gt;/ig;
        s/\$url_next//ig;
    }

    s/\$content/$slide_content/ig;
    $slide_content = $_;

    unless (open (OUT_SLIDE, "> $rel$output_dir$sep$slide_file")) {
      print "can't create $output_dir$sep$slide_file\n";
    }
    print OUT_SLIDE $slide_content;
    close (OUT_SLIDE);
}
