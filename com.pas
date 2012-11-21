unit com;

interface

uses SysUtils;

type
   comm=class
       procedure unos(a1,a2,a3,a4:string;a5:integer);
       procedure zamena(a1,a2,a3,a4:string);
       procedure brisanje(a1:string);
       function nadjiponazivu(a1:string):integer;
       procedure ucitaj;
       procedure sacuvaj;
       function indexuime(a1:integer):string;
   end;
   ucenik=record
       redbr:integer;
       ime:string[20];
       nagrade:string[200];
       adresa:string[20];
       telefon:string[16];
       index:integer;
   end;

var
  osoba:array[1..500] of ucenik;
  brojUnosa:integer;

implementation

procedure comm.unos(a1,a2,a3,a4:string;a5:integer);
 var j:integer;
 begin
  brojUnosa:=brojUnosa+1;
  if brojUnosa>1 then
   for j:=brojUnosa downto 1 do
    begin
    osoba[j+1]:=osoba[j];
    end;
  with osoba[1] do
    begin
    redbr:=brojUnosa;
    ime:=a1;
    nagrade:=a2;
    adresa:=a3;
    telefon:=a4;
    index:=a5;
    end;

 end;

procedure comm.zamena(a1,a2,a3,a4:string);
 var i:integer;
 begin
  for i:=1 to 500 do
   begin
    if osoba[i].ime=a1 then
     begin
      with osoba[i] do
       begin
        ime:=a1;
        nagrade:=a2;
        adresa:=a3;
        telefon:=a4;
       end;
     end
    else {Form1.naziv.text:='Ne postoji'};
   end;
 end;

procedure comm.brisanje(a1:string);
 var i,j,temp:integer;
 begin
  for i:=1 to 500 do
   begin
    temp:=i;
    if osoba[i].ime=a1 then
     begin
      brojUnosa:=brojUnosa-1;
      for j:=temp to 100 do
       begin
       if j<=500 then osoba[j]:=osoba[j+1];
       end;
     end
     else {Form1.naziv.text:='Ne postoji'};
   end;
 end;

function comm.nadjiponazivu(a1:string):integer;
 var i:integer;
 begin
  for i:=1 to 500 do
   begin
    if osoba[i].ime=a1 then
    begin
    nadjiponazivu:=i;
    exit;
    end;
   end;
  nadjiponazivu:=0;
 end;

procedure comm.ucitaj;
  var i:integer;
      x:file of ucenik;
  begin
    i:=0;
    Assign(x,'data');
    reset(x);
  while not eof(x) do
    begin
    i:=i+1;
    read(x,osoba[i]);
    end;
    close(x);
    brojUnosa:=i;
  end;

procedure comm.sacuvaj;
 var i:integer;
     x:file of ucenik;
 begin
  Assign(x,'data');
  rewrite(x);
  for i:=1 to brojUnosa do
  begin
   write(x,osoba[i]);
  end;
  close(x);
 end;

function comm.indexuime(a1:integer):string;
 var i:integer;
 begin
  for i:=1 to 500 do
   begin
    if osoba[i].index=a1 then
     begin
      indexuime:=osoba[i].ime;
      exit;
     end;
    indexuime:='Ne postoji';
   end;
 end;

end.
