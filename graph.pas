unit graph;

interface

uses com, gen, StdCtrls, Controls, Classes, ComCtrls, Tabnotbk, Forms, Mask;

type
  TForm1 = class(TForm)
    TabbedNotebook1: TTabbedNotebook;
    Label7: TLabel;
    GroupBox1: TGroupBox;
    nagradeizlaz: TLabel;
    GroupBox8: TGroupBox;
    GroupBox11: TGroupBox;
    trazi: TButton;
    GroupBox12: TGroupBox;
    ime: TEdit;
    adresa: TEdit;
    telefon: TEdit;
    GroupBox13: TGroupBox;
    Button1: TButton;
    Button4: TButton;
    Button5: TButton;
    nagrade: TRichEdit;
    GroupBox14: TGroupBox;
    Memo1: TMemo;
    GroupBox6: TGroupBox;
    nazivpretraga: TEdit;
    Button2: TButton;
    GroupBox7: TGroupBox;
    Button3: TButton;
    GroupBox2: TGroupBox;
    sifraizlaz: TLabel;
    GroupBox3: TGroupBox;
    imeizlaz: TLabel;
    GroupBox5: TGroupBox;
    adresaizlaz: TLabel;
    GroupBox4: TGroupBox;
    telefonizlaz: TLabel;
    MaskEdit1: TMaskEdit;
    StaticText1: TStaticText;
    StaticText2: TStaticText;
    CheckBox1: TCheckBox;
    StaticText3: TStaticText;
    StaticText4: TStaticText;
    StaticText5: TStaticText;
    StaticText6: TStaticText;
    godpretraga: TMaskEdit;
    StaticText7: TStaticText;
    GroupBox15: TGroupBox;
    indexizlaz: TLabel;
    godizlaz: TLabel;
    StaticText8: TStaticText;
    StaticText9: TStaticText;
    Memo2: TMemo;
    pretragagodina: TMaskEdit;
    index: TEdit;
    sifrapretraga: TEdit;
    StaticText10: TStaticText;
    StaticText11: TStaticText;
    StaticText12: TStaticText;
    Button6: TButton;
    StatusBar1: TStatusBar;
    GroupBox9: TGroupBox;
    noviindex: TEdit;
    novagod: TMaskEdit;
    StaticText13: TStaticText;
    StaticText14: TStaticText;
    Button7: TButton;
    StaticText15: TStaticText;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure nazivpretragaKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Memo1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure traziClick(Sender: TObject);
    procedure Memo2MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;


var
  Form1: TForm1;
  baza:comm;
  baza2:comm2;

implementation

uses SysUtils;

{$R *.DFM}



procedure TForm1.FormActivate(Sender: TObject);
begin
brojUnosa:=0;
baza.ucitaj;
baza2.kreiraj;
baza2.ucitaj;
end;


procedure TForm1.Button1Click(Sender: TObject);
begin
baza.unos(Form1.ime.text,Form1.nagrade.text,Form1.adresa.text,Form1.telefon.text,strtoint(Form1.index.text));
if CheckBox1.State=cbChecked then
baza2.unos(Form1.MaskEdit1.text,true,strtoint(Form1.index.text))
else
baza2.unos(Form1.MaskEdit1.text,false,strtoint(Form1.index.text));
Form1.ime.text:='';
Form1.nagrade.text:='';
Form1.adresa.text:='';
Form1.telefon.text:='';
Form1.MaskEdit1.text:='';
Form1.index.text:='';
CheckBox1.State:=cbUnchecked;
end;

procedure TForm1.Button2Click(Sender: TObject);
var temp:integer;
begin
Form1.sifraizlaz.caption:='';
Form1.imeizlaz.caption:='';
Form1.nagradeizlaz.caption:='';
Form1.adresaizlaz.caption:='';
Form1.telefonizlaz.caption:='';
temp:=baza.nadjiponazivu(Form1.nazivpretraga.text);
  if temp<>0 then
   begin
       Form1.sifraizlaz.caption:=inttostr(osoba[temp].redbr);
       Form1.imeizlaz.caption:=osoba[temp].ime;
       Form1.nagradeizlaz.caption:=osoba[temp].nagrade;
       Form1.adresaizlaz.caption:=osoba[temp].adresa;
       Form1.telefonizlaz.caption:=osoba[temp].telefon;
   end
  else Form1.imeizlaz.caption:='Ne postoji';
end;

procedure TForm1.Button3Click(Sender: TObject);
var i:integer;
begin
Form1.sifraizlaz.caption:='';
Form1.imeizlaz.caption:='';
Form1.nagradeizlaz.caption:='';
Form1.adresaizlaz.caption:='';
Form1.telefonizlaz.caption:='';
 for i:=1 to brojUnosa do
 begin
 if osoba[i].index=strtoint(Form1.sifrapretraga.text) then
  if baza2.nadjipoindexu(strtoint(Form1.sifrapretraga.text))=Form1.godpretraga.text then
  begin
  Form1.sifraizlaz.caption:=inttostr(osoba[i].redbr);
  Form1.imeizlaz.caption:=osoba[i].ime;
  Form1.nagradeizlaz.caption:=osoba[i].nagrade;
  Form1.adresaizlaz.caption:=osoba[i].adresa;
  Form1.telefonizlaz.caption:=osoba[i].telefon;
  Form1.indexizlaz.caption:=Form1.sifrapretraga.text;
  Form1.godizlaz.caption:=baza2.nadjipoindexu(strtoint(Form1.sifrapretraga.text));
  exit;
  end;
 end;
 Form1.imeizlaz.Caption:='Ne postoji';
end;




procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
baza.sacuvaj;
baza2.sacuvaj;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
baza.zamena(Form1.ime.text,Form1.nagrade.text,Form1.adresa.text,Form1.telefon.text);
Form1.ime.text:='';
Form1.nagrade.text:='';
Form1.adresa.text:='';
Form1.telefon.text:='';
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
if Form1.ime.Text='' then
 begin
 Application.messagebox('Morate uneti prezime i ime','Treba mi ime',0);
 exit;
 end;
if Form1.index.Text='' then
 begin
 Application.messagebox('Morate uneti broj indexa','Treba mi broj indexa',0);
 exit;
 end;
if not Form1.MaskEdit1.Modified then
 begin
 Application.messagebox('Morate uneti godinu','Treba mi godina',0);
 exit;
 end;

baza.brisanje(Form1.ime.text);
if baza2.izbaci(strtoint(Form1.index.text),Form1.MaskEdit1.text) then Form1.StatusBar1.SimpleText:='osoba izbacena ...'
else Form1.StatusBar1.SimpleText:='Ne postoji...';
Form1.ime.text:='';
Form1.nagrade.text:='';
Form1.adresa.text:='';
Form1.telefon.text:='';
Form1.index.text:='';
Form1.MaskEdit1.text:='';
end;

procedure TForm1.nazivpretragaKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var i,brojch:integer;
    temp:string;
begin
brojch:=Form1.nazivpretraga.GetTextLen;
Memo1.Lines.Clear;
for i:=1 to 500 do
 begin
 temp:=osoba[i].ime;
 if strlicomp(pchar(Form1.nazivpretraga.text),pchar(temp),brojch)=0 then
  begin
  if osoba[i].ime='' then exit;
  Memo1.Lines.Add(osoba[i].ime);
  end;
 end;
end;

procedure TForm1.Memo1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var i:integer;
begin
if Memo1.Lines[Memo1.CaretPos.y]<>'' then
 begin
 for i:=1 to 500 do
 if osoba[i].ime=Memo1.Lines[Memo1.CaretPos.y] then
  begin
       Form1.sifraizlaz.caption:=inttostr(osoba[i].redbr);
       Form1.imeizlaz.caption:=osoba[i].ime;
       Form1.nagradeizlaz.caption:=osoba[i].nagrade;
       Form1.adresaizlaz.caption:=osoba[i].adresa;
       Form1.telefonizlaz.caption:=osoba[i].telefon;
       Form1.indexizlaz.caption:=inttostr(osoba[i].index);
       Form1.godizlaz.caption:=baza2.nadjipoindexu(osoba[i].index);
  end;
 end;
end;



procedure TForm1.traziClick(Sender: TObject);
var i,j:integer;
begin
GroupBox8.Caption:='Godina *** / ' + pretragagodina.Text;
Memo2.Clear;
for i:=1 to 500 do
 begin
 if baza2.nadjipoindexu(i)=pretragagodina.Text then
  begin
  for j:=1 to 500 do
  if osoba[j].index=i then
   Memo2.Lines.Add(osoba[j].ime+'  {'+baza2.vratistatus(i)+'}');
  end;
 end;
end;



procedure TForm1.Memo2MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var j:integer;
begin
if Memo2.Lines[Memo2.CaretPos.y]<>'' then
 begin
 for j:=1 to 500 do
 if osoba[j].ime=Memo1.Lines[Memo1.CaretPos.y] then
  begin
  nazivpretraga.Text:=osoba[j].ime;
  TabbedNotebook1.ActivePage:='Pretraga';
  end;
 end;
end;


procedure TForm1.Button6Click(Sender: TObject);
var i:integer;
begin
StatusBar1.SimpleText:='ne postoje studenti u toj godini ...';
for i:=1 to 500 do
 begin
  if baza2.izbaci(i,pretragagodina.text) then
  begin
  baza.brisanje(baza.indexuime(i));
  StatusBar1.SimpleText:='godina i studenti izbrisani ...';
  end;
 end;
end;

procedure TForm1.Button7Click(Sender: TObject);
var i:integer;
begin
baza2.zameni(strtoint(index.text),MaskEdit1.text,strtoint(noviindex.text),novagod.text);
for i:=1 to 500 do
 begin
 if ime.text=osoba[i].ime then
 osoba[i].index:=strtoint(noviindex.text);
 StatusBar1.SimpleText:='zamena uspesno obavljena ...';
 index.text:='';
 ime.text:='';
 MaskEdit1.text:='';
 noviindex.text:='';
 novagod.text:='';
 exit;
 end;
StatusBar1.SimpleText:='ne postoji ...';
end;

end.
