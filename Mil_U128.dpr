PROGRAM Mil_U128;               {Testprogramm fÅr 128-Bit Universal-EInschub}
{$APPTYPE CONSOLE}
{ Autor des Basis-Programmes Mil_Base.PAS: G. Englert;      Erstellt 12.04.95
  Basis-Programm als Grundlage fÅr anwender-spezifische Erweiterungen
  Achtung: Bei Erweiterungen den Namen des Programmes Ñndern in MIL_xxxx.PAS
  Wegen Jahr 2000: File-Datum unter DOS ist ab 1.1.2000 -> 01.01.80

  Der Modulbus-Rahmen besteht aus 4 x 32-BitI/O mit zugehîrigen Anpa·karten
  organisiert als 8 x 16 Bit (s. a. FE 675.010).
  OUTPUT: 6 Karten je 16 Bit = 96 Bit (OUTRE Relais-Karte FG 423.250)
  INPUT : 2 Karten je 16 Bit = 32 Bit (OIK1  Opto-Karte   FG 423.321)
  Beachten: Die Anpa·karten schalten das 32-Bit-IO automatisch auf IN oder OUT
  IdentCode MB32 = 24H
  IdentCode MB32-APK-ID Kanal 1 auf Subadr 18H
  IdentCode MB32-APK-ID Kanal 0 auf Subadr 16H
  IdentCode APK OUTRE Relais-Karte FG 423.250 ID = 05, 09-0F [H]
  IdentCode APK OIK1  Opto-Karte   FG 423.321 ID = 11-14     [H]
  Vorsicht mit den SubAdressen 32-BitIO:
  - im 16-Bit Input-Mode werden Kanal 0 u. 1 mit SubAdr 0 u. 2 ausgelesen;
  - im 16-Bit Output-Mode rÅcklesen der Daten Åber Subadr. 04 und 06 !!!!!

  Ansprechpartner fÅr den Einsatz am ESR sind
    Arno  Schwinn     Tel. 2403
    Fritz Nolden      Tel. 2407
    Dr. Markus Steck  Tel. 2406

  énderungs-Protokoll:
  05.08.1999    Et        Aus MILxBASE.PAS Åbernommen
  16.08.1999              Input-Anzeige soll bei MilTimeout rot blinken
  04.02.2000              IFK-Online Test: DataToAry;
  23.02.2000              wegen MIL-Timeout neu compiliert
  04.08.2000              Neue APK-ID-Nummern u.a. IDOut50
                          Definitionen fÅr APK-ID in Datech_1.lib ausgelagert
  07.08.2000              Funktionsanzeige APK Error
  14.08.2000              Fehler-PrÅfung wiedeer deaktiviert Rd_ID_OUT_Test
  01.12.2000              Wegen Modulbus Y neu compiliert
  15.08.2001   in DATECH_1: FG423.350 APK-ID OIKUI auf ID-Code $47 erweitert
}
{$S-}
uses
  sysutils,
  Crt32,
  UnitMil,
  Datech,
  Datech_0,
  Datech_1,
  DATECH_2;

const
 Head_Line =
      'BELAB                        MIL_U128 PCI-Mil Vers.' +
      '                    [06.2009]' +
      '                      Universal-Einschub 128Bit FE 675.010                     ';


 procedure menue_win;
  var answer: CHAR;
 begin
  Ini_Headl_Win;
  Write(Head_Line);
  Menue_Base;            {Festliegender Teil des MenÅs: s. a. DATECH_0.PAS}
  TextColor(Blue);
   {Ab hier kann der Anwender seine MenÅ-Punkte eintragen}
  GotoXY(5, 14);
  Writeln('       [M]<-- RÅckwand-Stecker [A1..H2]: Lesen/Schreiben     ');
  GotoXY(5, 15);
  Writeln('       [N]<-- Zeige Modulbus-Karten                          ');
  GotoXY(5, 16);
  Writeln('       [O]<-- Zeige Anpa·karten                              ');
  GotoXY(5, 17);
  Writeln('       [P]<-- Zeige internes Daten-Array                     ');
{  GotoXY(5, 18);
  Writeln('       [Q]<-- Lese 32-Bit-IO-APK-ID und Daten von OUTREL !!  ');
  GotoXY(5, 18);
  Writeln('       [Q]<--                                                                ');
  GotoXY(5, 19);
  Writeln('       [R]<--                                                            ');
  GotoXY(5, 20);
  Write  ('       [S]<--                                                            ');
  GotoXY(5, 21);
  Write  ('       [T]<--                                                            ');
  GotoXY(5, 22);
  Write  ('       [U]<--                                                            ');
}
  Ini_Msg_Win;
  Write('Bitte Auswahl eingeben:                                          EXIT: X-Taste ');
 end; {menue_win}
{
Bisherige Routinen f. alle Anwender gleich! Ab hier spezielle User-Routinen
}
{in DATECH.PAS definiert :
 TModAdr  = record              }
           {  AdrIfc : Byte;    }   {MIL-IFC-Adressse 8 Bit}
           {  AdrCard: Byte;    }   {APL-Mod-Bus Karten-Adr. Bit 13..8 = 5 Bit}
           {  AdrSub : Byte;    }   {APL-Mod-Bus Sub-Adr.    Bit  7..0 = 8 Bit}
           {  AdrMode: TAdrMode;} {auf vorherige oder neue Adr schreiben/lesen}
           {end;}
const
 Stecker_Max = 16;
 S_Base      = 03;
 S_Base8     = S_Base+10;
 S_OffSet    = 04;
 S_IfkNr     = 15;
 S_RdErr_Id  = 32;
 S_RdErr_Data= 55;
 Z_BaseLo    = 08;
 Z_FTastWin  = 22;

 Z_ID32      = 09;
 Z_Err       = 15;

 S_APK       = 30;
 S_Dtack     = 45;
 S_Out       = 60;

 Bit0 = 0;
 Bit1 = 1;
 Bit2 = 2;
 Bit3 = 3;
 Bit4 = 4;
 Bit5 = 5;
 Bit6 = 6;
 Bit7 = 7;
 Offset_OutRead = 4; {Subadressen fÅr RÅcklesen des Outregisters beachten!}

{const
IDOut50 : TIO_ID = [07,$30..$33];}  {ID-Nr fÅr FGF 423.241, 242}
{IDOutRe : TIO_ID = [$11..$14];}     {ID-Nr fÅr FGF 423.250}
{IDOutRel: TIO_ID = [$50..$57];}     {ID-Nr fÅr FGF 423.260}
{IDInOpto: TIO_ID = [05,09..$0F];}   {ID-Nr fÅr OIKU  FGF 423.340,41,42}
{IDInUni : TIO_ID = [08,$40..$46];}  {ID-Nr fÅr OIKUI FGF 423.350}

type
 TWrMode    = (ToggleMode, DataMode);
 TDirect    = (Auf,Ab);
 TBitChange = array [0..7] of Boolean; {wichtig fÅr blinkende Anzeige}

 TSteck8 = record
   Name    : String[2];   {konstant : Name des Steckers auf RÅckplatte}
   MBAdr   : TModAdr;     {Modulbus Adresse; SubAdr fÅr jede Aktion anders}
   SubAdrID: Byte;        {konstant = APK-ID wird von dieser SubADr gelesen}
   ApkID   : Byte;        {Anpa·karten ID}
   BytePos : (H,L);       {konstant}
   IODir   : (InNorm,OutNorm,OutSel,Undef,Error);
   DataNew : Byte;        {wichtig fÅr den Datenvergleich, wegen BitÑnderungen }
   DataOld : Byte;
   BitChange: TBitChange; {fÅr jedes Bit Input-énderungen DataNew/Old merken}
 end;

 TSteckAry = array [1..Stecker_Max] of TSteck8;
 {TIO_ID    = set of 0..255; }
const
ST : TSteckAry =   {Init Array-Daten; s.a. Init_STAry}
(
(Name:'A1'; MBAdr: (AdrIfc: 0); SubAdrID: $18; ApkID: 0; BytePos: L; IODir: Undef;  DataNew: 0; DataOld: 0),
(Name:'A2'; MBAdr: (AdrIfc: 0); SubAdrID: $18; ApkID: 0; BytePos: H; IODir: Undef;  DataNew: 0; DataOld: 0),
(Name:'B1'; MBAdr: (AdrIfc: 0); SubAdrID: $16; ApkID: 0; BytePos: L; IODir: Undef;  DataNew: 0; DataOld: 0),
(Name:'B2'; MBAdr: (AdrIfc: 0); SubAdrID: $16; ApkID: 0; BytePos: H; IODir: Undef;  DataNew: 0; DataOld: 0),
(Name:'C1'; MBAdr: (AdrIfc: 0); SubAdrID: $18; ApkID: 0; BytePos: L; IODir: Undef;  DataNew: 0; DataOld: 0),
(Name:'C2'; MBAdr: (AdrIfc: 0); SubAdrID: $18; ApkID: 0; BytePos: H; IODir: Undef;  DataNew: 0; DataOld: 0),
(Name:'D1'; MBAdr: (AdrIfc: 0); SubAdrID: $16; ApkID: 0; BytePos: L; IODir: Undef;  DataNew: 0; DataOld: 0),
(Name:'D2'; MBAdr: (AdrIfc: 0); SubAdrID: $16; ApkID: 0; BytePos: H; IODir: Undef;  DataNew: 0; DataOld: 0),
(Name:'E1'; MBAdr: (AdrIfc: 0); SubAdrID: $18; ApkID: 0; BytePos: L; IODir: Undef;  DataNew: 0; DataOld: 0),
(Name:'E2'; MBAdr: (AdrIfc: 0); SubAdrID: $18; ApkID: 0; BytePos: H; IODir: Undef;  DataNew: 0; DataOld: 0),
(Name:'F1'; MBAdr: (AdrIfc: 0); SubAdrID: $16; ApkID: 0; BytePos: L; IODir: Undef;  DataNew: 0; DataOld: 0),
(Name:'F2'; MBAdr: (AdrIfc: 0); SubAdrID: $16; ApkID: 0; BytePos: H; IODir: Undef;  DataNew: 0; DataOld: 0),
(Name:'G1'; MBAdr: (AdrIfc: 0); SubAdrID: $18; ApkID: 0; BytePos: L; IODir: Undef;  DataNew: 0; DataOld: 0),
(Name:'G2'; MBAdr: (AdrIfc: 0); SubAdrID: $18; ApkID: 0; BytePos: H; IODir: Undef;  DataNew: 0; DataOld: 0),
(Name:'H1'; MBAdr: (AdrIfc: 0); SubAdrID: $16; ApkID: 0; BytePos: L; IODir: Undef;  DataNew: 0; DataOld: 0),
(Name:'H2'; MBAdr: (AdrIfc: 0); SubAdrID: $16; ApkID: 0; BytePos: H; IODir: Undef;  DataNew: 0; DataOld: 0)
);

var
 Mil_Timeout   : LongInt;
 Mil_RdErr_ID  : LongInt;
 Mil_RdErr_Data: LongInt;

procedure BitChange_Clear;
var I,X: Byte;
begin
  for I:=1 to Stecker_Max do begin        {fÅr In u. Output-Stecker}
   ST[I].DataOld       :=  ST[I].DataNew;
   for X := 0 to 7 do ST[I].BitChange[X] := False;
  end;
end;

procedure Init_STAry;
var I,X: Byte; Kart_Num: Byte; ModAdr: TModAdr; MilErr: TMilErr;
    ModData: Word;
begin
  if (Ifc_Test_Nr=0) then begin
   Mil_Ask_Ifc;
  end;
  for I:=1 to Stecker_Max do begin        {Dyn. Daten lîschen}
   ST[I].MBAdr.AdrIfc  := Ifc_Test_Nr;
   ST[I].MBAdr.AdrCard := 0;
   ST[I].MBAdr.AdrSub  := 0; {Subadr. mu· fÅr Aktion neu definiert werden}
   ST[I].MBAdr.AdrMode := AdrNew;
   ST[I].ApkID         := 0;
   ST[I].IODir         := Undef;
   ST[I].DataNew       := 0;
   ST[I].DataOld       := 0;
{   for X := 0 to 7 do begin
    ST[I].BitChange[X] := False;
   end;
}
  end; {for}

  BitChange_Clear;

  {32-Bit Modulbuskarte}   {Subadr fÅr 16-BitDaten R/W}       {Hi/Lo-Byte}
  ST[1].MBAdr.AdrCard := 1;  ST[1].MBAdr.AdrSub := 2;  ST[1].BytePos:= L;
  ST[2].MBAdr.AdrCard := 1;  ST[2].MBAdr.AdrSub := 2;  ST[2].BytePos:= H;
  ST[3].MBAdr.AdrCard := 1;  ST[3].MBAdr.AdrSub := 0;  ST[3].BytePos:= L;
  ST[4].MBAdr.AdrCard := 1;  ST[4].MBAdr.AdrSub := 0;  ST[4].BytePos:= H;

  ST[5].MBAdr.AdrCard := 2;  ST[5].MBAdr.AdrSub := 2;  ST[5].BytePos:= L;
  ST[6].MBAdr.AdrCard := 2;  ST[6].MBAdr.AdrSub := 2;  ST[6].BytePos:= H;
  ST[7].MBAdr.AdrCard := 2;  ST[7].MBAdr.AdrSub := 0;  ST[7].BytePos:= L;
  ST[8].MBAdr.AdrCard := 2;  ST[8].MBAdr.AdrSub := 0;  ST[8].BytePos:= H;

  ST[ 9].MBAdr.AdrCard:= 3;  ST[ 9].MBAdr.AdrSub:= 2;  ST[09].BytePos:= L;
  ST[10].MBAdr.AdrCard:= 3;  ST[10].MBAdr.AdrSub:= 2;  ST[10].BytePos:= H;
  ST[11].MBAdr.AdrCard:= 3;  ST[11].MBAdr.AdrSub:= 0;  ST[11].BytePos:= L;
  ST[12].MBAdr.AdrCard:= 3;  ST[12].MBAdr.AdrSub:= 0;  ST[12].BytePos:= H;

  ST[13].MBAdr.AdrCard:= 4;  ST[13].MBAdr.AdrSub:= 2;  ST[13].BytePos:= L;
  ST[14].MBAdr.AdrCard:= 4;  ST[14].MBAdr.AdrSub:= 2;  ST[14].BytePos:= H;
  ST[15].MBAdr.AdrCard:= 4;  ST[15].MBAdr.AdrSub:= 0;  ST[15].BytePos:= L;
  ST[16].MBAdr.AdrCard:= 4;  ST[16].MBAdr.AdrSub:= 0;  ST[16].BytePos:= H;

              {Lese fÅr jeweils 16 Bit die APK-ID}
  {z. B. Stecker 1 u. 2: SubAdr 18H; Stecker 3 u. 4: SubADr 16H}
  for I:=1 to Stecker_Max do begin
    ModAdr        := ST[I].MBAdr;
    ModAdr.AdrSub := ST[I].SubAdrID;
    Mil.Rd_ModBus (ModData, ModAdr, MilErr);
    if MilErr = No_Err then begin
     ST[I].ApkID := Lo(ModData);
     if  (ST[I].ApkID in IDOut50)   then ST[I].IODir := OutNorm;
     if  (ST[I].ApkID in IDOutRe)   then ST[I].IODir := OutNorm;
     if  (ST[I].ApkID in IDOutRel)  then ST[I].IODir := OutNorm;

     if  (ST[I].ApkID in IDInOpto)  then ST[I].IODir := InNorm;
     if  (ST[I].ApkID in IDInUni)   then ST[I].IODir := InNorm;
    end;
  end; {for}

  for I:=1 to Stecker_Max do begin  {Suche 1. Output und setze auf selektiert}
    if ST[I].IODir = OutNorm then begin
      ST[I].IODir := OutSel;
      Break;
    end; {if}
  end; {for}
end; {Init_Array}

procedure Disp_Bit_NormIN (BitData: Byte; XPosi,YPosi: Byte; ChangeData: TBitChange);
 var I: Integer;
 begin
    for I := 0 to 7 do begin
      if I = 4 then Write (Taste_Return); {Zwischraum Tetrade}
      if (I>=4) then
        GotoXY (XPosi+1,YPosi+1+I+1)
      else
        GotoXY (XPosi+1,YPosi+1+I);
      {falls sich ein Bit geÑndert hat, blinkend darstellen}
      if ChangeData[I] then TextColor(Blue +128) else  TextColor(Blue);
      if BitTst (BitData,I) then Write ('1') else Write ('0');
    end; {for}
 end; {Disp_Bit_Norm}

procedure Disp_Bit_NormOut (BitData: Byte; XPosi,YPosi: Byte);
 var I: Integer;
 begin
    TextColor(Blue);
    for I := 0 to 7 do begin
      if I = 4 then Write (Taste_Return); {Zwischraum Tetrade}
      if (I>=4) then
        GotoXY (XPosi+1,YPosi+1+I+1)
      else
        GotoXY (XPosi+1,YPosi+1+I);
      if BitTst (BitData,I) then Write ('1') else Write ('0');
    end; {for}
 end; {Disp_Bit_Norm}

procedure DispSteck8Ary;
var I : Byte; XPos, YPos : Byte;
    ModAdr: TModAdr; MilErr: TMilErr; ModData: Word;
begin
  Set_Text_Win;
  GotoXY(S_RdErr_ID,   Z_FTastWin-3); TextColor(Red); Write (Mil_RdErr_ID:8);
  GotoXY(S_RdErr_Data, Z_FTastWin-3); TextColor(Red); Write (Mil_RdErr_Data:8);

  for I := 1 to Stecker_Max do begin
   XPos := S_Base + ((I+2)*S_Offset);
   YPos := Z_BaseLo;    TextColor(Black);
   GotoXY(XPos,YPos-3); Write(ST[I].Name);  TextColor(Blue);
   GotoXY(XPos,YPos-2); Write(Hex_Byte(ST[I].DataNew));
   GotoXY(XPos,YPos-1); TextColor(White);
   case ST[I].IODir of
    InNorm    : begin
                 Write ('IN ');
                 Disp_Bit_NormIn (ST[I].DataNew, XPos, YPos, ST[I].BitChange);
                end;
    OutNorm   : begin
                 Write ('OUT');
                 Disp_Bit_NormOut (ST[I].DataNew, XPos, YPos);
                end;
    OutSel    : begin TextColor(Yellow+128);
                 Write ('OUT');
                 Disp_Bit_NormOut (ST[I].DataNew, XPos, YPos);
                end;
    Undef     : begin
                 Write ('AP?');
                 GotoXY(XPos,YPos-2); Write('  '); {Lîsche DataNew}
                end;
    Error     : begin
                 TextColor(Red); Write ('ID?');
                 GotoXY(XPos,YPos-2); Write('  '); {Lîsche DataNew}
                end;
   end; {cas}
  end; {for I}
end; {DispSteck8Ary}


procedure DataToAry;   {lese Daten von Hardware -> SteckerArray}
var I,X: Byte; ModAdr: TModAdr; MilErr: TMilErr; ModData: Word;
    Life_Mode   : TLife_XY;
begin
  Life_Mode.Mode    := Norm;      {Parameter fÅr Lebenszeichen definieren}
  Life_Mode.PosX    := S_IfkNr-13;
  Life_Mode.PosY    := Z_FTastWin-3;
  Life_Mode.Time    := Life_Time_Fast;
  Life_Mode.Disp_Win:= Set_Text_Win; {Darstellungs-Fenster}
  Life_Sign_XY (Life_Mode);

   for I:=1 to Stecker_Max do begin
    ModAdr        := ST[I].MBAdr;
    ModAdr.AdrSub := ST[I].SubAdrID;
    Mil.Rd_ModBus (ModData, ModAdr, MilErr);
    if MilErr = No_Err then
     begin
      ST[I].ApkID := Lo(ModData);   {Stelle fest, ob noch gueltige APK-ID da ist}
      if not ((ST[I].ApkID in IDOut50) or (ST[I].ApkID in IDOutRe) or (ST[I].ApkID in IDOutRel)
         or (ST[I].ApkID in IDInOpto) or (ST[I].ApkID in IDInUni))
       then ST[I].IODir := Undef;
     end
    else     {Fehler beim Lesen ModulID}
     begin
      ST[I].IODir := Error;
      Mil_RdErr_ID := Mil_RdErr_ID +1;
     end;  {if MilErr}

    ModAdr := ST[I].MBAdr;    {SubAdr 0 oder 2 fÅr 16Bit-Daten ist im Array definiert}
    if ST[I].IODir in [OutNorm,OutSel] then begin  {korrigiere SubAdr fÅr rÅcklesen}
      ModAdr.AdrSub := ModAdr.AdrSub + Offset_OutRead;
    end;
    Mil.Rd_ModBus (ModData, ModAdr, MilErr);
    if MilErr = No_Err then begin
      if ST[I].BytePos=L then ST[I].DataNew:=Lo(ModData) else ST[I].DataNew:= Hi(ModData);
      {Vergleiche neue mit alten Daten, falls unterschiedlich: markiere Bits}
      if ST[I].DataNew <> ST[I].DataOld then begin
       for X:= 0 to 7 do begin  {UberprÅfe alle 8 Bits auf énderung}
         if not ((BitTst(ST[I].DataNew,X) and BitTst(ST[I].DataOld,X)) or
            (not BitTst(ST[I].DataNew,X) and not BitTst(ST[I].DataOld,X))) then begin
            ST[I].BitChange[X] := True;  {dauerhaft setzten, bis allgemeines clear}
         end; {Bits sind unterschiedlich: also war eine énderung}
       end; {for X}
       ST[I].DataOld := ST[I].DataNew; {merke neue Daten}
      end;  {if new<>old}
     end
    else
     begin
      Mil_RdErr_Data := Mil_RdErr_Data +1;
     end; {MilErr=No_Err}

{    else begin
      inc (Mil_Timeout); TextColor(red);
      GotoXY(S_Timeout, Z_FTastWin-3);  Write (Mil_Timeout:8);
    end; }  {if no millerr}
  end; {for}
end; {DataToAry}

procedure FTast_Win_RW;
 begin
  Set_Text_Win; TextColor(Brown);
{  GOTOXY(03, Z_FTastWin-3); Write('Belegung F-Tasten'); }
  Window (03, Z_FTastWin, 80, 23);
  TextBackground(Green);
  TextColor(Yellow);        {Setze Schriftfarbe}
  Writeln (' F1.....F8      F9            F10          F11                F12           ');
  TextColor(Blue);
  Write (' 1..PIN..8   OutData[H]     IFK-Adr   Init I/O-Hardw    Reset IN Anzeige    ');
 end;

procedure Sel_OutStecker (Direct: TDirect);
var I,X,X_Sel : Integer; {Out-Stecker markieren fÅr Datenausgabe mit FTASTEN}
    OutAry : array [1..Stecker_Max] of Integer;
begin
  for I:=1 to Stecker_Max do OutAry[I]:= 0;  {Clear Array}
  X := 0;  X_Sel := 0;
  for I:=1 to Stecker_Max do begin     {Suche u. merke alle OutStecker}
   if (ST[I].IODir=OutSel) or (ST[I].IODir=OutNorm) then begin
    X := X+1;
    OutAry[X]:= I;
    if (ST[I].IODir=OutSel) then X_Sel := X; {merke im Array, welcher Output selektiert ist}
   end;
  end;  {for}

  if X = 0 then Exit else begin   {Abort, wenn kein Output-Stecker vorhanden}
     if Direct = Ab then begin    {Stecker abwÑrts wÑhlen}
       if X > 1 then begin
         if X_SEL > 1 then begin
           X:=X_SEL;
           ST[OutAry[X_Sel]].IODir := OutNorm;  {Alten Output deselektieren}
         end else X:= 2;
         if OutAry[X-1] > 0 then begin
          X := X-1;
          I := OutAry[X];
          ST[I].IODir := OutSel;            {Uff, neuen OutStecker selektiert}
         end;
       end; {if X>1}
     end else begin             {Stecker aufwÑrts wÑhlen}
       if X_SEL > 0 then begin
        X:=X_SEL;
        ST[OutAry[X_Sel]].IODir := OutNorm;  {Alten Output deselektieren}
       end else begin X:= 0; end;
       if OutAry[X+1] > 0 then begin
         X := X+1;
         I := OutAry[X];
         ST[I].IODir := OutSel;      {Uff, neuen OutStecker selektiert}
       end else ST[OutAry[X_Sel]].IODir := OutSel;;
     end; {Direct auf}
  end; {if X=0}
end; {Sel_OutStecker}


procedure WriteToStecker (WrMode: TWrMode; Param: Byte);
var I:Byte; ModData: Word; ModAdr: TModAdr; MilErr: TMilErr;
    TempData: Word;
begin
    for I:=1 to Stecker_Max do begin    {Suche den selektierten Out-Stecker}
     if ST[I].IODir = OutSel then begin
       ModAdr        := ST[I].MBAdr;
       ModAdr.AdrSub := ModAdr.AdrSub  + Offset_OutRead;
       Mil.Rd_ModBus (ModData, ModAdr, MilErr);   {Lese Daten vom OutRegister}
       if MilErr <> No_Err then Exit;
       case WrMode of
        DataMode  : TempData:= Param;  {Param = neues DatenByte [H]}
        ToggleMode: begin          {Param = Toggle Bit-Nr}
                     if ST[I].BytePos = L then TempData := Lo(ModData)
                     else  TempData := Hi(ModData);
                     if   BitTst(TempData,Param) then TempData:=BitClr(TempData,Param)
                     else TempData:=BitSet(TempData,Param);
                    end;
       end; {case}

       {TempData  =geÑndertes DatenByte; 16-Bit zum Schreiben vorbereiten}
       if ST[I].BytePos=L then begin
         TempData := TempData and $00FF;          {Daten im LoByte}
         ModData  := ModData  and $FF00;
         ModData  := ModData  or Lo(TempData);
       end else begin
         TempData := (TempData shl 8);   {Daten ins HiByte}
         ModData  := TempData or (ModData and $00FF);
{         ModData  := ModData or Hi(TempData); }
       end; {if}

       ModAdr.AdrSub := ST[I].MBAdr.AdrSub; {SubAdr R/W sind unterschiedlich!!}
       Mil.Wr_ModBus (ModData, ModAdr, MilErr);  {Daten zum 32Bit IO}
       DataToAry;     {Wegen Single Step: neue OUT-Daten ins Array}
       DispSteck8Ary; {und gleich anzeigen}
       Break; {For Schleife verlassen}
     end; {if SEL}
    end; {for}
end; {WriteToStecker}

procedure  U128_RdWr;
 label 99;
 var I,X: Integer;  User_Word: Word;
     Retour_Adr  : Byte; OnlineErr  : TOnlineErr;

 procedure RdWr_Init;
   var I,X: Integer;
  begin
   Mil_Timeout := 0;
   Init_STAry;
   Ini_Text_Win;   TextColor(Yellow);
   GotoXY(12,02); Write('Auswahl des Ausgangs-Steckers mit den Pfeil-Tasten <- -> ');
   GotoXY(05,03); Write('Blinkender Stecker mit F1...F8 bitweise Ñnderbar oder Hexeingabe mit F9 ');
   GotoXY(02,04); Write('Die Eingangsbits blinken, wenn sich ihr Zustand geÑndert hat (Reset mit F12)');

   TextColor(Black);
   GotoXY(S_Base,Z_BaseLo-3);  Write('Stecker -> ');
   GotoXY(S_Base,Z_BaseLo-2);  Write('Data [H]-> ');
   GotoXY(S_Base,Z_BaseLo-1);  Write('Funktion-> ');
   for I := 1 to 8 do
    begin
     if I = 5 then Write (Taste_Return);
     if (I>=5) then begin
      GotoXY(S_Base  ,Z_BaseLo+I+1);  Write('Bit',(I-1):1);
      GotoXY(S_Base+6,Z_BaseLo+I+1);  Write('Pin',(I):1);
      end
     else begin
      GotoXY(S_Base  ,Z_BaseLo+I);  Write('Bit',(I-1):1);
      GotoXY(S_Base+6,Z_BaseLo+I);  Write('Pin',(I):1);
     end;
    end;

   GotoXY(S_IfkNr-12,     Z_FTastWin-3); Write ('IFK-Adr[H]: ');
   GotoXY(S_IfkNr,        Z_FTastWin-3); TextColor(Blue);   Write (Hex_Byte(Ifc_Test_Nr));
   GotoXY(S_RdErr_Id-11,  Z_FTastWin-3); TextColor(Black);  Write ('RdErr_ID: ');
   GotoXY(S_RdErr_Data-12,Z_FTastWin-3); TextColor(Black);  Write ('RdErr_Data: ');

{   GotoXY(S_Timeout-13,Z_FTastWin-3); Write ('MilTimeout: ');  TextColor(Blue);
    GotoXY(S_Timeout, Z_FTastWin-3);   Write (Mil_Timeout:8);
}
   FTast_Win_RW;
   Set_Text_Win;
   DataToAry;
   BitChange_Clear;
   DispSteck8Ary;
   Std_Msg;
  end; {RdWr_Init}


 begin
  Mil_RdErr_ID:= 0;  Mil_RdErr_Data := 0;
  RdWr_Init;
  Ch := NewReadKey;
  repeat
   if Ch = ' ' then
    begin
     Std_Msg;
     Single_Step := True;
     //ST[I].MBAdr.AdrIfc  := Ifc_Test_Nr;  {Zuerst prÅfen, ob IFK noch vorhanden ist}
     Mil.Ifc_Online (Ifc_Test_Nr, Retour_Adr, OnlineErr); { TOnlineErr= (NoErr, WrTo, RdTo, AdrErr)}
     if OnlineErr <> NoErr then
      begin
       Ini_Text_Win;  TextColor(Red);
       Write ('FATALER FEHLER: keine IFK online!!');
       repeat until KeyEPressed;
       Exit;
      end;

     DataToAry;
     DispSteck8Ary;
     repeat until KeyEPressed;
     Ch := NewReadKey;
    end;

   if Ch = #13 then Single_Step := False;
   if not Single_Step then
    begin
     //ST[I].MBAdr.AdrIfc  := Ifc_Test_Nr;  {Zuerst prÅfen, ob IFK noch vorhanden ist}
     Mil.Ifc_Online (Ifc_Test_Nr, Retour_Adr, OnlineErr); { TOnlineErr= (NoErr, WrTo, RdTo, AdrErr)}
     if OnlineErr <> NoErr then
      begin
       Ini_Text_Win; TextColor(Red);
       Write ('FATALER FEHLER: keine IFK online!!');
       repeat until KeyEPressed;
       Exit;
      end;
     DataToAry;
     DispSteck8Ary;
    end;

   if Ch = #0 then                  {Sonder-Tasten Abfrage}
    begin
     Ch := NewReadKey;
     case ord (Ch) of
      Taste_F1 : begin
                   WriteToStecker (ToggleMode, Bit0);
                 end;
      Taste_F2 : begin
                   WriteToStecker (ToggleMode, Bit1);
                 end;
      Taste_F3 : begin
                   WriteToStecker (ToggleMode, Bit2);
                 end;
      Taste_F4 : begin
                   WriteToStecker (ToggleMode, Bit3);
                 end;
      Taste_F5 : begin
                   WriteToStecker (ToggleMode, Bit4);
                 end;
      Taste_F6 : begin
                   WriteToStecker (ToggleMode, Bit5);
                 end;
      Taste_F7 : begin
                   WriteToStecker (ToggleMode, Bit6);
                 end;
      Taste_F8 : begin
                   WriteToStecker (ToggleMode, Bit7);
                 end;
      Taste_F9 : begin
                   if Ask_Hex_Break (User_Word, Byt) then begin
                     WriteToStecker (DataMode, User_Word);
                   end;
                   Std_Msg;
                 end;
      Taste_F10 : begin
                   Mil_Ask_Ifc;
                   RdWr_Init;
                 end;
      Taste_F11 : begin
                   RdWr_Init;
                 end;
      Taste_F12: begin
                  BitChange_Clear;
                  DispSteck8Ary;
{                  Mil_Timeout:=0;
                  GotoXY(S_Timeout, Z_FTastWin-3); TextColor(Blue);
                  Write (Mil_Timeout:8);
}                 end;
      Taste_Pfeil_Links : begin
                           Sel_OutStecker (Ab);
                           DispSteck8Ary;
                          end;
      Taste_Pfeil_Rechts: begin
                           Sel_OutStecker (Auf);
                           DispSteck8Ary;
                          end;
    end;  {Case}
   end;
  if KeyEPressed then Ch := NewReadKey;
 until Ch in ['x','X'];
 99:  Cursor(True);
end; {U128_RdWr}

procedure  ShowSteckAry;
var I,Xpos,YPos: Byte;
begin
  Init_STAry;
  Ini_Text_Win;
  GotoXY(S_Base-1,Z_BaseLo-2);  Write('Name      ->');
  GotoXY(S_Base-1,Z_BaseLo-1);  Write('IFK-Adr[H]->');
  GotoXY(S_Base-1,Z_BaseLo-0);  Write('Mod-Adr[H]->');
  GotoXY(S_Base-1,Z_BaseLo+1);  Write('Sub-Adr[H]->');
  GotoXY(S_Base-1,Z_BaseLo+2);  Write('SuAdrID[H]->');
  GotoXY(S_Base-1,Z_BaseLo+3);  Write('ApkID  [H]->');
  GotoXY(S_Base-1,Z_BaseLo+4);  Write('Hi/Lo-Byte->');
  GotoXY(S_Base-1,Z_BaseLo+5);  Write('IO-Direkt ->');
  GotoXY(S_Base-1,Z_BaseLo+6);  Write('DtaNew [H]->');
  GotoXY(S_Base-1,Z_BaseLo+7);  Write('DtaOld [H]->');
  TextColor(Blue);

  for I := 1 to Stecker_Max do begin
   XPos := S_Base + ((I+2)*S_Offset);
   YPos := Z_BaseLo;
   with ST[I] do begin
    GotoXY(XPos,YPos-2);  Write (Name);
    GotoXY(XPos,YPos-1);  Write (Hex_Byte(MBAdr.AdrIfc));
    GotoXY(XPos,YPos-0);  Write (Hex_Byte(MBAdr.AdrCard));
    GotoXY(XPos,YPos+1);  Write (Hex_Byte(MBAdr.AdrSub));
    GotoXY(XPos,YPos+2);  Write (Hex_Byte(SubAdrID));
    GotoXY(XPos,YPos+3);  Write (Hex_Byte(ApkID));
    GotoXY(XPos,YPos+4);
                          case BytePos of
                            L :  Write ('Lo');
                            H :  Write ('Hi');
                          else   Write ('??'); end;
    GotoXY(XPos,YPos+5);
                         case IODir of
                           InNorm    :  Write ('Inp');
                           OutNorm   :  Write ('Out');
                           OutSel    :  Write ('Sel');
                           Undef     :  WRite ('Udf');
                         end;
    GotoXY(XPos,YPos+6);  Write (Hex_Byte(DataNew));
    GotoXY(XPos,YPos+7);  Write (Hex_Byte(DataOld));
   end; {with}
  end;  {for}

  Ini_Msg_Win;
  Write ('Weiter mit  <Space> ');
  Ch := NewReadKey;
end; {ShowSteckAry}



{Gilt nur fÅr OUTREL-Karten: weil nur dann SubAdr 4 und 6 aktiv}
procedure Rd_ID_OUT_Test;   {lese Daten von Hardware}
const MaxCard = 4;
type
 TCardErr  = record
              ApkID : LongInt;
              Dtack : LongInt;
              OutReg: LongInt;
              Err_FcTo     : LongInt;
              Err_RdTo     : LongInt;
              Err_WrTo     : LongInt;
              Err_IoAdr    : LongInt;
              Err_IoAdrMode: LongInt;
             end;

{ TMilErr       = (No_Err, Fc_To, Rd_To, Wr_To, Io_Adr, Io_AdrMode);}

 TRdErrAry = array [1..MaxCard] of TCardErr;
var
    ModAdr: TModAdr; MilErr: TMilErr; ModData: Word;
    Life_Mode           : TLife_XY;  ApkID: Byte;
    RdErr_ID, RdErr_Dta : LongInt;
    Fct       : TFct;
    RdErrAry  : TRdErrAry;

 procedure Ini_Err_Disp;
  var N : Byte;
  begin
   Ini_Text_Win; TextColor(Blue);
   GotoXY(25,Z_ID32-5);    Write ('  Lese-Test fÅr 128-Bit-IO');
   GotoXY(25,Z_ID32-4);    Write ('4x32-Bit + OUTREL FG 423.260');
   GotoXY(S_APK-3,  Z_ID32-2); Write ('APK-ID');
   GotoXY(S_Dtack-3,Z_ID32-2); Write ('DTACK');
   GotoXY(S_Out-3,  Z_ID32-2); Write ('OUT-REG');

   GotoXY(S_APK-6,  Z_ID32-1); Write ('SubAdr 16+18H');
   GotoXY(S_Dtack-6,Z_ID32-1); Write ('  Fct: CAH');
   GotoXY(S_Out-6,  Z_ID32-1); Write ('SubAdr 04+06');

   GotoXY(S_APK-25, Z_ID32+0);  Write ('32Bit-IO [1]: ');
   GotoXY(S_APK-25, Z_ID32+1);  Write ('32Bit-IO [2]: ');
   GotoXY(S_APK-25, Z_ID32+2);  Write ('32Bit-IO [3]: ');
   GotoXY(S_APK-25, Z_ID32+3);  Write ('32Bit-IO [4]: ');
  end; {Ini_Err_disp}


 procedure Ini_RdErrAry;
  var N : Byte;
  begin
    for N:= 1 to MaxCard do
     begin
        RdErrAry[N].ApkID := 0;
        RdErrAry[N].Dtack := 0;
        RdErrAry[N].OutReg:= 0;
        RdErrAry[N].Err_FcTo     := 0;
        RdErrAry[N].Err_RdTo     := 0;
        RdErrAry[N].Err_WrTo     := 0;
        RdErrAry[N].Err_IoAdr    := 0;
        RdErrAry[N].Err_IoAdrMode:= 0;
     end; {for}
  end;

 procedure Disp_RdErr_Ary;
  var N: Byte;
  begin
   Set_Text_Win;
   TextColor(Red);
   for N := 0 to MaxCard-1 do
    begin  GotoXY(S_APK,   Z_ID32+N);  Write (RdErrAry[N+1].ApkID:8); end;
   for N := 0 to MaxCard-1 do
    begin  GotoXY(S_Dtack, Z_ID32+N);  Write (RdErrAry[N+1].Dtack:8); end;
   for N := 0 to MaxCard-1 do
    begin  GotoXY(S_OUT,   Z_ID32+N);  Write (RdErrAry[N+1].OutReg:8); end;

    N := 1;   {Karte 1}
    GotoXY(S_OUT,   Z_Err+1);   Write (RdErrAry[N].Err_FcTo:8);
    GotoXY(S_OUT,   Z_Err+2);   Write (RdErrAry[N].Err_RdTo:8);
    GotoXY(S_OUT,   Z_Err+3);   Write (RdErrAry[N].Err_WrTo:8);
    GotoXY(S_OUT,   Z_Err+4);   Write (RdErrAry[N].Err_IoAdr:8);
    GotoXY(S_OUT,   Z_Err+5);   Write (RdErrAry[N].Err_IoAdrMode:8);
  end;

 function Check_Dtack_Err: Boolean;
   var  IfkCA_Stat: TIfkCAStat;
   begin
    Check_Dtack_Err:= False;  {Default}
    Fct.B.Adr := Ifc_Test_Nr;
    Fct.B.Fct := Fct_Rd_GlobalStat;   {CA[H]: globaler Status IFK};
    Mil.Rd (IfkCA_Stat.W, Fct, MilErr);
    if not (Pigy_Dtack_Err in IfkCA_Stat.B)  then    {Dtack ist 0-aktiv}
     begin
       Check_Dtack_Err:= True;
       Fct.B.Fct:= Fct_Clr_DtackErr;       {Bit zurÅcksetzen}
       Mil.WrFct (Fct, MilErr);
     end;
   end;  {Check_Dtack_Err}

 procedure Check_Mil_Err (Idx: Byte; Err: TMilErr);
  begin
   case Err of
    Fc_To : RdErrAry[Idx].Err_FcTo := RdErrAry[Idx].Err_FcTo + 1;
    Rd_To : RdErrAry[Idx].Err_RdTo := RdErrAry[Idx].Err_RdTo + 1;
    Wr_To : RdErrAry[Idx].Err_WrTo := RdErrAry[Idx].Err_WrTo + 1;
    Io_Adr: RdErrAry[Idx].Err_IoAdr:= RdErrAry[Idx].Err_IoAdr+ 1;
    Io_AdrMode: RdErrAry[Idx].Err_IoAdrMode:= RdErrAry[Idx].Err_IoAdrMode+ 1;
   end; {case}
  end; {Check_Mil_Err}


 procedure RdIO_Cards;      {wegen Timeout-Fehler geschrieben}
  var I : Byte;
  begin
    for I := 1 to 4 do        {alle vier 32Bit-IO-Karten prÅfen}
     begin
       ModAdr.AdrCard:= I;
       {1. Anpass-Karte}
       ModAdr.AdrSub := ModSub_Adr_Apk0ID;         {Anpa·karten0 Ident}
       Mil.Rd_ModBus (ModData, ModAdr, MilErr);    {ID nr. 1}
       if MilErr = No_Err then
        begin
         ApkID := Lo(ModData);   {Stelle fest, ob noch gueltige APK-ID da ist}
         if ApkID = 0 then
          begin
            RdErrAry[I].ApkID := RdErrAry[I].ApkID + 1;
          end;
        end;
       if Check_Dtack_Err then  RdErrAry[I].Dtack := RdErrAry[I].Dtack + 1;

       {1.OutRegister rÅcklesen}
       ModAdr.AdrSub := 4;      {RÅcklesreg}
       Mil.Rd_ModBus (ModData, ModAdr, MilErr);
       if MilErr <> No_Err then
        begin
          RdErrAry[I].OutReg := RdErrAry[I].OutReg + 1;
          Check_Mil_Err (I, MilErr);
        end;
       if Check_Dtack_Err then  RdErrAry[I].Dtack := RdErrAry[I].Dtack + 1;

       {2. Anpass-Karte}
       ModAdr.AdrSub := ModSub_Adr_Apk1ID;    {Anpa·karten1 Ident}
       Mil.Rd_ModBus (ModData, ModAdr, MilErr);    {ID nr. 2}
       if MilErr = No_Err then
        begin
         ApkID := Lo(ModData);   {Stelle fest, ob noch gueltige APK-ID da ist}
         if ApkID = 0 then
          begin
            RdErrAry[I].ApkID := RdErrAry[I].ApkID + 1;
          end;
        end;
       if Check_Dtack_Err then  RdErrAry[I].Dtack := RdErrAry[I].Dtack + 1;

       {2.OutRegister rÅcklesen}
       ModAdr.AdrSub := 6;         {RÅcklesereg}
       Mil.Rd_ModBus (ModData, ModAdr, MilErr);
       if MilErr <> No_Err then
        begin
          RdErrAry[I].OutReg := RdErrAry[I].OutReg + 1;
          Check_Mil_Err (I, MilErr);
        end;
     end;  {for}
   end; {RdIO_Cards}

 begin
    Ini_RdErrAry;
    ModAdr.AdrIfc := Ifc_Test_Nr;
    ModAdr.AdrMode:= AdrNew;
    Mil.Reset;  {PC-Karte auf definierte Werte}
    Ini_Text_Win;
    Ini_Err_Disp;

    Cursor(False);
    Std_Msg;
    Ch := NewReadKey;
    repeat
     if Ch = ' ' then
      begin
       Std_Msg;
       Single_Step := True;
       RdIO_Cards;
       Disp_RdErr_Ary;
       repeat until KeyEPressed;
       Ch := NewReadKey;
      end;
     if Ch = #13 then Single_Step := False;
     if not Single_Step then
      begin
       RdIO_Cards;
       Disp_RdErr_Ary;
      end;
    if KeyEPressed then Ch := NewReadKey;
   until Ch in ['x','X'];
 { 99:  Cursor(True); }
 end; {Rd_ID_OUT_Test}

begin                      { Hauptprogramm }
  Ifc_Test_Nr := 0;
  Mod_Test_Nr := 0;
  PCI_MilCardOpen:=false;
  repeat
    Menue_Win;
    User_Input  := NewReadKey;
    Single_Step := True;
    case User_Input of
     '0'      : Mil_Detect_Ifc;
     '1'      : Mil_Detect_Ifc_Compare;
     '2'      : begin
		  Mil_Ask_Ifc;
                  Mil_Rd_HS_Ctrl (Ifc_Test_Nr);
                end;
     '3'      : begin
		{  Mil_Ask_Ifc;                    }
                {  Mil_Rd_HS_Status (Ifc_Test_Nr); }
                end;
     '4'      : begin
		  Mil_Ask_Ifc;
                  Mil_Stat_All (Ifc_Test_Nr);
                end;
     '5'      : begin
                  Convert_Hex_Volt;
                end;
     '6'      : begin
                  Int_Mask;
                end;
     '8'      : begin
		  Mil_Ask_Ifc ;
                  Mil_Echo (Ifc_Test_Nr);
                end;
     '9'      : begin
		  Mil_Ask_Ifc ;
                  Mil_IfkMode;
                end;
     'a', 'A' :  Mil_Ask_Ifc;
     'b', 'B' : begin
		 Mil_Ask_Ifc;
                 Mil_Rd_Ifc_Stat (Ifc_Test_Nr);
                end;
     'c', 'C' : begin
                  Mil_Rd_Status;
                end;
     'd', 'D' : begin
                  Mil_Rd_Fifo;
                end;
     'e', 'E' : begin
		  Mil_Ask_Ifc;
                  Mil_Rd_Data;
		end;
     'f', 'F' : begin
                  Functioncode_Table;
                end;
     'g', 'G' : begin
		  Mil_Ask_Ifc;
                  if Ask_Data_Break (Mil_Data) then Mil_WrData (Mil_Data);
                end;
     'h', 'H' : begin
		  Mil_Ask_Ifc;
		  Mil_Wr_Fctcode;
                end;
     'i', 'I' : begin
		  Mil_Ask_Ifc;
                  Mil_Data := 0;
                  Mil_Wr (Mil_Data);
                end;
     'j', 'J' : begin
		  Mil_Ask_Ifc;
                  if Ask_Data_Break (Mil_Data) then Mil_Wr_Rd (Mil_Data);
                end;
     'k', 'K' : begin
		  Mil_Ask_Ifc;
		  Mil_Loop;
                end;
     'l', 'L' : begin
                  Mil_Dual_Mode;
                end;
     'y', 'Y' : begin
                  Modul_Bus;
                end;
     'z', 'Z' : begin
                  Telefon;
                end;
     {Ab hier User-Erweiterungen!!}
          'm', 'M' : begin
                       U128_RdWr;
                     end;
          'n', 'N' : begin
                       Mil_Displ_IO_Modul;
                     end;
          'o', 'O' : begin
                       Modul_APK;
                     end;
          'p', 'P' : begin
                       ShowSteckAry;
                     end;
          'q', 'Q' : begin              {geht nur mit 4 OUTREL-Karten}
{                       Mil_Ask_Ifc;
                       Rd_ID_OUT_Test;
}                     end;
          'r', 'R' : begin
                     end;
          's', 'S' : begin
                     end;
          't', 'T' : begin
                     end;
          'u', 'U' : begin
                     end;
    end; {CASE}
  until user_input in ['x','X'];
  Window(1, 1, 80, 25);
  TextBackground(Black);

  PCI_DriverClose(PCIMilCardNr);

  ClrScr;
end. {mil_U128}


