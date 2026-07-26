#!/usr/bin/perl
# Basit statik dosya sunucusu (sadece yerel test icin) - perl server.pl 8123
use strict; use warnings;
use IO::Socket::INET;
use IO::Select;
use File::Basename;
my $here = $0; $here =~ s{\\}{/}g; chdir dirname($here) or die "chdir: $!";
my $port = $ARGV[0] || 8123;
my $srv = IO::Socket::INET->new(LocalAddr=>'127.0.0.1', LocalPort=>$port,
                                Proto=>'tcp', Listen=>20, ReuseAddr=>1)
  or die "port $port acilamadi: $!\n";
$| = 1;
print "http://localhost:$port/\n";
my %TYPE = (html=>'text/html; charset=utf-8', css=>'text/css; charset=utf-8',
            js=>'application/javascript; charset=utf-8', json=>'application/json; charset=utf-8',
            svg=>'image/svg+xml', png=>'image/png', ico=>'image/x-icon');
my $sel = IO::Select->new;
while (my $cl = $srv->accept) {
  # tarayici bazen bos socket acar; 3 sn icinde istek gelmezse kapat (yoksa sunucu kilitlenir)
  $sel->add($cl);
  unless ($sel->can_read(3)) { $sel->remove($cl); close $cl; next }
  $sel->remove($cl);
  my $req = <$cl>;
  while (defined(my $l = <$cl>)) { last if $l =~ /^\s*$/ }
  if (!$req or $req !~ m{^GET\s+(\S+)}) { close $cl; next }
  my $path = $1; $path =~ s/\?.*//; $path = '/index.html' if $path eq '/';
  $path =~ s/%([0-9A-Fa-f]{2})/chr hex $1/ge;
  $path =~ s/\.\.//g;
  my $file = '.' . $path;
  if (open my $fh, '<:raw', $file) {
    local $/; my $body = <$fh>; close $fh;
    my ($ext) = $file =~ /\.(\w+)$/;
    my $type = $TYPE{lc($ext // '')} || 'application/octet-stream';
    print $cl "HTTP/1.1 200 OK\r\nContent-Type: $type\r\nContent-Length: " . length($body)
            . "\r\nCache-Control: no-cache\r\nConnection: close\r\n\r\n$body";
  } else {
    print $cl "HTTP/1.1 404 Not Found\r\nContent-Length: 9\r\nConnection: close\r\n\r\nNot found";
  }
  close $cl;
}
