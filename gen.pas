unit gen;

interface

uses SysUtils;

type
       comm2=class
        procedure kreiraj;
        procedure unos(a1:string;a2:boolean;a3:integer);
        procedure sacuvaj;
        procedure ucitaj;
        function nadjipoindexu(a1:integer):string;
        function nadjiporedbr(a1:integer):string;
        function izbaci(a1:integer;a2:string):boolean;
        function vratistatus(a1:integer):string;
        function zameni(a1:integer;a2:string;a3:integer;a4:string):boolean;
        end;
       genn=record
        index:integer;
        godina:string[2];
        budzet:boolean;
        redbr:integer;
        end;
       pok=^generacija;
       generacija=record
        info:genn;
        sled:pok
       end;

var
 poctk,rep:pok;
 brojUnosa2:integer;

implementation

procedure comm2.kreiraj;
 begin
 poctk:=nil;
 brojUnosa2:=0;
 end;

procedure comm2.unos(a1:string;a2:boolean;a3:integer);
 var tek:pok;
 begin
 new(tek);
 tek^.sled:=nil;
 tek^.info.godina:=a1;
 tek^.info.budzet:=a2;
 tek^.info.index:=a3;
 brojUnosa2:=brojUnosa2+1;
 tek^.info.redbr:=brojUnosa2;
 if poctk=nil then
 begin
 poctk:=tek; rep:=tek;
 end
 else
 begin
 rep^.sled:=tek;
 rep:=tek;
 end;
 end;

procedure comm2.sacuvaj;
 var x:file of genn;
     tek:pok;
 begin
  assign(x,'data.gen');
  rewrite(x);
  tek:=poctk;
 while tek<>nil do
  begin
  write(x,tek^.info);
  tek:=tek^.sled;
  end;
  close(x);
 end;

procedure comm2.ucitaj;
 var x:file of genn;
     tek:pok;
 begin
 AssignFile(x,'data.gen');
 reset(x);
 while not EOF(x) do
  begin
  new(tek);
  read(x,tek^.info);
  brojUnosa2:=brojUnosa2+1;
  tek^.sled:=nil;
   if poctk=nil then
    begin
    poctk:=tek; rep:=tek;
    end
    else
    begin
     rep^.sled:=tek;
     rep:=tek;
    end;
  end;
  close(x);
 end;

function comm2.nadjipoindexu(a1:integer):string;
 var tek:pok;
 begin
  tek:=poctk;
  while tek<>nil do
  begin
  if tek^.info.index=a1 then
  begin
  nadjipoindexu:=tek^.info.godina;
  exit;
  end;
  tek:=tek^.sled;
  end;
  nadjipoindexu:='Ne postoji';
 end;

function comm2.nadjiporedbr(a1:integer):string;
 var tek:pok;
 begin
  tek:=poctk;
  while tek<>nil do
  begin
  if tek^.info.redbr=a1 then
  begin
  nadjiporedbr:=tek^.info.godina;
  exit;
  end;
  tek:=tek^.sled;
  end;
  nadjiporedbr:='Ne postoji';
 end;

function comm2.vratistatus(a1:integer):string;
 var tek:pok;
 begin
  tek:=poctk;
  while tek<>nil do
  begin
  if tek^.info.index=a1 then
  begin
  if tek^.info.budzet then  vratistatus:='budzet' else vratistatus:='samofinansirajuci';
  exit;
  end;
  tek:=tek^.sled;
  end;
 end;


function comm2.izbaci(a1:integer;a2:string):boolean;
 var tek,temp,pre:pok;
 begin
  tek:=poctk;
  pre:=nil;
  temp:=nil;
  while tek<>nil do
   begin
    if (tek^.info.index=a1) and (tek^.info.godina=a2) then
      begin
       brojUnosa2:=brojUnosa2-1;
       temp:=tek;
       if pre=nil then poctk:=tek^.sled else pre^.sled:=tek^.sled;
       dispose(temp);
       izbaci:=true;
       exit;
      end
     else
      begin
       pre:=tek;
       tek:=tek^.sled;
      end;
   end;
 izbaci:=false;
 end;

function comm2.zameni(a1:integer;a2:string;a3:integer;a4:string):boolean;
 var tek:pok;
 begin
  tek:=poctk;
  while tek<>nil do
   begin
    if (tek^.info.index=a1) and (tek^.info.godina=a2) then
     begin
      tek^.info.index:=a3;
      tek^.info.godina:=a4;
      zameni:=true;
      exit;
     end;
    tek:=tek^.sled;
   end;
   zameni:=false;
 end;




end.
