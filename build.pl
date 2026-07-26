#!/usr/bin/perl
# 22 Arkadaş - diyalog derleyicisi
# 22 karakter x 25 sahne x 10 tur x (1 arkadaş cümlesi + 3 cevap seçeneği) = 22.000 cümle
use strict;
use warnings;
use utf8;
use JSON::PP;
binmode(STDOUT, ":encoding(UTF-8)");
use File::Path qw(make_path);

my $ROOT = $0; $ROOT =~ s{[^/\\]+$}{}; $ROOT = '.' if $ROOT eq '';
chdir $ROOT or die "chdir: $!";

# ---------- veri ----------
my $chars = do './src/characters.pl' or die "characters.pl: $@ $!";
my @scenes;
for my $f (1..5) {
  my $s = do "./src/scenes$f.pl" or die "scenes$f.pl: $@ $!";
  push @scenes, @$s;
}
printf "Karakter: %d, sahne: %d\n", scalar @$chars, scalar @scenes;
die "25 sahne olmali, " . scalar(@scenes) . " var\n" unless @scenes == 25;

# ---------- doğrulama ----------
for my $sc (@scenes) {
  die "$sc->{id}: 10 tur olmali (" . scalar(@{$sc->{beats}}) . ")\n" unless @{$sc->{beats}} == 10;
  my $bi = 0;
  for my $b (@{$sc->{beats}}) {
    die "$sc->{id}/$bi: 2 arkadas varyanti olmali\n" unless @{$b->{f}} == 2;
    die "$sc->{id}/$bi: 3 secenek olmali\n"          unless @{$b->{o}} == 3;
    for my $o (@{$b->{o}}) {
      die "$sc->{id}/$bi: her secenek 2 varyantli olmali\n" unless @$o == 2;
      for my $v (@$o) { die "$sc->{id}/$bi: en+tr cifti olmali\n" unless @$v == 2 }
    }
    $bi++;
  }
}

# ---------- karakter tarzı: ara sıra araya giren ünlem ----------
my %FLAVOUR = (
  mate        => ["Right then.","Eh, bak."],
  soft        => ["Aww.","Ay canım."],
  loud        => ["Listen, listen!","Dinle, dinle!"],
  thoughtful  => ["Actually, you know what?","Aslında, bak ne diyeceğim?"],
  blunt       => ["Look.","Bak."],
  precise     => ["Okay, so.","Tamam, şöyle."],
  dry         => ["Ha!","Ha!"],
  calm        => ["Slow down a second.","Bir saniye yavaşla."],
  energetic   => ["Come on!","Hadi ama!"],
  direct      => ["Honestly?","Açıkçası?"],
  shy         => ["Um...","Şey..."],
  warm        => ["Oh, my dear.","Ah canım benim."],
  motivating  => ["Listen up!","Beni dinle!"],
  sarcastic   => ["Oh, wonderful.","Oh, harika."],
  formal      => ["If I may.","İzin verirsen."],
  chatty      => ["Oh, by the way!","Ha bu arada!"],
  storyteller => ["You know,","Biliyor musun,"],
  quiet       => ["Hmm.","Hmm."],
  slang       => ["Yo.","Yo."],
  friendly    => ["Right.","Tamam."],
  passionate  => ["Ay!","Ay!"],
  easygoing   => ["Yeah.","Evet."],
);

# ---------- yardımcılar ----------
sub h {  # deterministik hash -> aynı karakter+sahne+tur her zaman aynı cümleyi verir
  my $s = join('|', @_);
  my $x = 7919;
  for my $c (unpack 'U*', $s) { $x = ($x * 131 + $c) % 1000003 }   # 2^53 sinirinin altinda kalir
  return $x;
}

sub fill {
  my ($txt, $c, $tr) = @_;
  $txt =~ s/\{(\w+)\}/
      my $k = $1;
      my $v = ($tr && defined $c->{$k.'Tr'}) ? $c->{$k.'Tr'} : $c->{$k};
      defined $v ? $v : "{$k}"
  /ge;
  $txt =~ s/^(\p{Ll})/\u$1/;   # slot cümle başına geldiyse büyük harf
  return $txt;
}

my %LVL = (A1=>0, A2=>0, B1=>1, B2=>1);

# ---------- üretim ----------
make_path('data/chars');
my $json = JSON::PP->new->utf8->canonical;
my ($total, @index) = (0);

for my $c (@$chars) {
  my $lvl = $LVL{$c->{level}} // 0;
  my $fl  = $FLAVOUR{$c->{style}} || ["Well.","Şey."];
  my @dialogues; my $csent = 0;

  for my $sc (@scenes) {
    my @turns;
    my $bi = 0;
    for my $b (@{$sc->{beats}}) {
      # arkadaşın cümlesi: seviyeye göre varyant + karaktere özgü ara söz
      my $fv = $b->{f}[$lvl];
      my ($fen, $ftr) = (fill($fv->[0], $c, 0), fill($fv->[1], $c, 1));
      if ($bi > 0 && h($c->{id}, $sc->{id}, $bi, 'flav') % 4 == 0) {
        $fen = "$fl->[0] $fen";
        $ftr = "$fl->[1] $ftr";
      }

      # üç cevap seçeneği: hangi yazımın kullanılacağı karaktere göre değişir
      my @opts;
      for my $oi (0..2) {
        my $vi = h($c->{id}, $sc->{id}, $bi, $oi) % 2;
        my $ov = $b->{o}[$oi][$vi];
        push @opts, { en => fill($ov->[0], $c, 0), tr => fill($ov->[1], $c, 1) };
      }

      push @turns, { f => { en => $fen, tr => $ftr }, o => \@opts };
      $csent += 4;   # 1 arkadaş cümlesi + 3 seçenek
      $bi++;
    }
    push @dialogues, {
      id => $sc->{id}, title => $sc->{title}, emoji => $sc->{emoji}, cat => $sc->{cat},
      intro => fill($sc->{intro}, $c, 1), turns => \@turns,
    };
  }

  # bonus: "Arkadaşını tanı" - sabit cevaplı kişisel sorular
  my @QA = (
    ["Where do you live?","Nerede yaşıyorsun?","I live in {city}.","{city} şehrinde yaşıyorum."],
    ["What do you do?","Ne iş yapıyorsun?","I am {job}. I work at {work}.","{job} olarak çalışıyorum. {work} yerindeyim."],
    ["How old are you?","Kaç yaşındasın?","I am $c->{age} years old.","$c->{age} yaşındayım."],
    ["Which football team do you support?","Hangi futbol takımını tutuyorsun?","{team}, always. Never anyone else.","Her zaman {team}. Başkası asla."],
    ["Who is your favourite player?","En sevdiğin oyuncu kim?","{player}, without question.","Tartışmasız {player}."],
    ["What do you drink?","Ne içersin?","{drink}. Every single day.","{drink}. Her gün."],
    ["What is your favourite food?","En sevdiğin yemek ne?","{food}. I could eat it forever.","{food}. Ömür boyu yiyebilirim."],
    ["What do you eat for breakfast?","Kahvaltıda ne yersin?","{breakfast}, nearly every morning.","Neredeyse her sabah {breakfast}."],
    ["Do you have a pet?","Evcil hayvanın var mı?","Pets? Well, {pet}.","Evcil hayvan mı? Şöyle: {pet}."],
    ["Tell me about your family.","Bana aileni anlat.","I have {family}.","Benim {family} var."],
    ["What are your hobbies?","Hobilerin neler?","{hobby}. That is how I switch off.","{hobby}. Kafamı böyle dağıtıyorum."],
    ["What music do you listen to?","Ne müzik dinliyorsun?","{music}, mostly.","Çoğunlukla {music}."],
    ["What is your favourite film?","En sevdiğin film ne?","{film}. I have seen it too many times.","{film}. Fazla çok izledim."],
    ["What are you watching now?","Şu an ne izliyorsun?","{series} at the moment.","Şu an {series}."],
    ["What is your dream?","Hayalin ne?","My dream is {dream}.","Hayalim {dream}."],
    ["Where do you want to travel?","Nereye seyahat etmek istersin?","{place}. It is top of my list.","{place}. Listemin başında."],
    ["Where did you go on your last holiday?","Son tatilinde nereye gittin?","I went to {lastHol}. It was lovely.","{lastHol} gittim. Çok güzeldi."],
    ["How do you get around?","Nasıl gidip geliyorsun?","I use {transport}.","{transport} kullanıyorum."],
    ["What weather do you like?","Nasıl hava seversin?","I love {weather}.","{weather} bayılırım."],
    ["What do you say all the time?","Sürekli ne dersin?","{phrase} I say it too much.","{phrase} Fazla söylüyorum."],
    ["Where are you from?","Nerelisin?","I am from {city}.","{city} şehrindenim."],
    ["Do you like your job?","İşini seviyor musun?","Being {job} is hard some days, but yes.","{job} olmak bazı günler zor ama evet, seviyorum."],
    ["What do you do at the weekend?","Hafta sonu ne yaparsın?","{hobby}, and I see {family}.","{hobby} yaparım, bir de {family} görürüm."],
    ["Do you cook?","Yemek yapar mısın?","Yes. {food} is my speciality.","Evet. Spesiyalim {food}."],
  );
  my @qa = map { {
    q => { en => fill($_->[0], $c, 0), tr => fill($_->[1], $c, 1) },
    a => { en => fill($_->[2], $c, 0), tr => fill($_->[3], $c, 1) },
  } } @QA;

  my %out = (%$c, dialogues => \@dialogues, qa => \@qa, sentences => $csent);
  open my $fh, '>:raw', "data/chars/$c->{id}.json" or die $!;
  print $fh $json->encode(\%out);
  close $fh;

  $total += $csent;
  push @index, {
    map { $_ => $c->{$_} } qw(id name full emoji color age level voice city cityTr job jobTr team bio)
  };
  $index[-1]{sentences} = $csent;
  $index[-1]{dialogues} = scalar @dialogues;
  printf "  %-8s %-3s %2d diyalog %5d cümle\n", $c->{id}, $c->{level}, scalar @dialogues, $csent;
}

open my $ix, '>:raw', 'data/index.json' or die $!;
print $ix $json->encode({ friends => \@index, total => $total,
                          scenes => [ map { { id=>$_->{id}, title=>$_->{title}, emoji=>$_->{emoji}, cat=>$_->{cat} } } @scenes ] });
close $ix;

print "\n======================================\n";
printf "TOPLAM: %d cümle (%d arkadaş x %d cümle)\n", $total, scalar @$chars, $total / @$chars;
print "======================================\n";
die "HATA: 22000 bekleniyordu, $total bulundu\n" unless $total == 22000;
print "Dogrulandi: tam 22.000 cumle.\n";
