#!/usr/bin/perl
########################################################################
# asciiImages.pl      --- Squid Script (Converts images into ascii art)#
# g0tmi1k 2011-03-25  --- Original Idea: http://prank-o-matic.com      #
########################################################################
# Note ~ Requires ImageMagick, Ghostscript and jp2a                    #
#    sudo apt-get -y install imagemagick ghostscript jp2a              #
########################################################################
use IO::Handle;
use LWP::Simple;
use POSIX strftime;

$debug = 1;                               # Debug mode - create log file
$ourIP = "127.0.0.1";                  # Our IP address
$baseDir = "/var/www/html/images";                # Needs be writable by 'nobody'
$baseURL = "http://".$ourIP."/images";       # Location on websever
$convert = "/usr/bin/convert";            # Path to convert
$identify = "/usr/bin/identify";          # Path to identify
$jp2a = "/usr/bin/jp2a";                  # Path to jp2a
$ENV{TERM} = 'xterm';

$|=1;
$asciify = 0;
$count = 0;
$pid = $$;

if ($debug == 1) { open (DEBUG, '>>/tmp/asciiImages_debug.log'); }
autoflush DEBUG 1;

print DEBUG "########################################################################\n";
print DEBUG strftime ("%d%b%Y-%H:%M:%S\t Server: $baseURL/\n",localtime(time()));
print DEBUG "########################################################################\n";
system("killall convert");
while (<>) {
   chomp $_;
   #print DEBUG "Input string: $_\n";
   ($url, $ip, $ident, $method, @kvpair) = split(" ",$_);
   if ($_ =~ /(.*\.(png|bmp|tiff|ico|jpg|jpeg))/i) {                         # Image format
      if ($debug == 1) { print DEBUG "Input: $url\n"; }                          # Let the user know

      $ext = ($url =~ m/([^.]+)$/)[0];
      $file = "$baseDir/$pid-$count";                                            # Set filename + path
      $filename = "$pid-$count";                                                 # Set filename

      getstore($url,"$file.$ext");                                                      # Save image
      system("chmod", "a+r", "$file.$ext");                                        # Allow access to the file
      if ($debug == 1) { print DEBUG "Fetched image: $file.$ext\n"; }                 # Let the user know

      $asciify = 1;                                                              # We need to do something with the image
   }
   else {                                                                        # Everything not a image
      print "$url\n";                                                              # Just let it go
      if ($debug == 1) { print DEBUG "Pass: $url\n"; }                             # Let the user know
   }

   if ($asciify == 1) {                                                          # Do we need to do something?
      if ($_ !=~ /(.*\.(jpg|jpeg))/i) {                                          # Select everything other image type to jpg
         system("$convert", "$file.$ext", "$file.jpg");                               # Convert images so they are all jpgs for jp2a
         #system("rm", "$file");                                                 # Remove originals
         if ($debug == 1) { print DEBUG "Converted to jpg: $file.jpg\n"; }       # Let the user know
      }
      else {
         system("mv", "$file.$ext", "$file.jpg");
      }
      system("chmod", "a+r", "$file.jpg");                                       # Allow access to the file

      $size = `$identify $file.jpg | cut -d" " -f 3`;
      chomp $size;
      if ($debug == 1) { print DEBUG "Image size: $size ($file)\n"; }

      system("$jp2a $file.jpg --invert | $convert -font Courier-Bold label:\@- -size $size $file-ascii.$ext");   # PNGs are smaller than jpg
      #system("rm $file.jpg");
      system("chmod", "a+r", "$file-ascii.$ext");
      if ($debug == 1) { print DEBUG "Asciify: $file-ascii.$ext\n"; }

      print "$baseURL/$filename-ascii.$ext\n";
      if ($debug == 1) { print DEBUG "Output: $baseURL/$filename-ascii.$ext, From: $url\n"; }
   }
   $asciify = 0;
   $count++;
}

close (DEBUG);
