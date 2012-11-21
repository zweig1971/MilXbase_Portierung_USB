PROGRAM Mil_Mag;
{$APPTYPE CONSOLE}
{ Autor des Basis-Programmes Mil_Base.Pas: G. Englert;      Erstellt 12.04.95
  Basis-Programm als Grundlage fÅr anwender-spezifische Erweiterungen
  Achtung: Bei Erweiterungen den Namen des Programmes Ñndern in MIL_xxxx.PAS
  Wegen Jahr 2000: File-Datum unter DOS ist ab 1.1.2000 -> 01.01.80

  Autor der Erweiterungen   :
  énderungen:
  23.06.95    Englert   Funktionscode-Tabelle
  29.06.95    Englert   Statusbits fÅr C0, C1, C2, C3
  13.07.95    Et        neue Functions-Code-Tabelle
  23.08.95    Et        Statusbits-Tabellen
  15.09.95    Et        Wegen zu gro·em Codesegment (ca. 64k) einige Proceduren
                        in die DATECH.PAS ausgelagert
                        z. B. Displ_PC_Stat; Displ_HS_Status; Displ_HS_Ctrl;
  21.09.95    Et        Status-Tabs erweitert: in DATECH.PAS
  06.10.95    Et        Statuslesen C0-C2 mit Timeout-Anzeige
  30.11.95    Et        MIL-Detect-Compare: Anzeige korrigiert
  08.12.95    Et        Anzeige Interrupt-Maske
  11.01.95    Et        procedure Mil-Loop Fifo leeren eingebaut
  04.02.96    Et        Status-Tabelle [5] erweitert
  14.02.96              ZusÑtzliche Unit: DATECH_1
  10.04.96              Hallsonden-Eichung mit variabler Tabelle
  02.05.96              MenÅpunkt P neu
  12.07.96              Punkt M: F10 Adr-Auswahl erweitert
  16.07.96              Punkt O: 1:1 Puls 10 V und 0 Volt
  01.08.96              F-Tasten neu belegt: Hex-Eingabe
  23.08.96              Life-Sign mit blinkendem Cursor
  12.12.96              Neue Tab: Phasensonden
showTab: Default oder File??  klÑren
  04.01.99       wegen ADC-Hardware-énderung:
                 {Sende Conversion Command: Neu 040199 <- Suchmaske!
  07.01.99       {Sende Conversion Command: Neu 070199 <- Suchmaske!
  19.03.99       nach Sw1 gleich Sw2 schicken: wegen Broadcast u.
                 Zwischenspeicher im DAC (190399)
  11.05.99       neue Unit Datech_2 mit den MagTabellen
  23.02.00       wegen MIL-Timeout neu compiliert
  17.02.09       Unterpunkt <M> um Fair-Bus funktionalitaet erweitert

}
{$S-}


uses sysutils, Crt32, UnitMil, Datech, Datech_0, Datech_1, DATECH_2;

CONST
 Head_Line =
      'BELAB                         MIL_MAG PCI-Mil Vers.' +
      '                    [06.2009]' +
      '                                  Magnetservice                     ';

procedure menue_win;
VAR answer: CHAR;
begin
  Ini_Headl_Win;
  Write(head_line);
  Menue_Base;              {Festliegender Teil des MenÅs: s. a. DATECH_1.PAS}
  TextColor(Blue);
  {Ab hier kann der Anwender seine MenÅ-Punkte eintragen}
  GotoXY(5, 14);
  Writeln('       [M]<-- Inbetriebnahme u. Status-Tabellen (ConvCmd 5F + FktCode 06,07)');
  GotoXY(5, 15);
  Writeln('       [N]<-- Soll/Ist1 + 2/Shift/Incr/0,5V/Hex (ConvCmd 5F + Fct06,07)     ');
  GotoXY(5, 16);
  Writeln('       [O]<-- Test f. gepulste Netzg. (SOLL, IST, ZEIT: fix     ) 5F, 06, 07');
  GotoXY(5, 17);
  Writeln('       [P]<-- Test f. gepulste Netzg. (SOLL, IST, ZEIT: variabel) 5F,06, 07  ');
  GotoXY(5, 18);
  Writeln('       [Q]<-- Test f. gerampte NetzgerÑte (0...+10V oder 0...-10V)           ');
  GotoXY(5, 19);
  Write  ('       [R]<-- Hallsonden Eichung (var. Tabelle,'); TextColor(Red);
                         write(' QUICK 1'); TextColor(Blue); Write(' iterativ Rampe)     ');
  GotoXY(5, 20);
  Write  ('       [S]<-- Hallsonden Eichung (var. Tabelle,'); TextColor(Red);
                         write(' QUICK 2'); TextColor(Blue);  Write(' iterativ bzw. Rampe)');
{
  GotoXY(5, 21);
  Write  ('       [T]<--                ');
  GotoXY(5, 22);
  Write  ('       [U]<--                 ');
}
  ini_msg_win;
  Write('Bitte Auswahl eingeben:                                          EXIT: X-Taste ');
 End; {menue_win}

 const
  Step_Time_Default = 50;          {500 us fÅr Quick2}
  Top_Time_Default  = 50000;       {1 sec       "   }
  Write_Fct_Code    = $06;         {fÅr Flattop}
  Read_Fct_Code     = $81;
  ADC_Conv_Wait     = 20;  {Wartezeit nach einem ADC-Konvert-Command}

                     {Ab hier sollten User-Routinen beginnen!!}
  procedure Ini_IstwMag_Win;
   begin
    Window(43, 13, 80, 17);
    TextBackground(Cyan);
    TextColor(Black);               {Setze Schriftfarbe}
    ClrScr;
   end;

  procedure Set_IstwMag_Win;
   begin
    Window(43, 13, 79, 17);
    TextBackground(Cyan);
    TextColor(Black);               {Setze Schriftfarbe}
   end;

  procedure Ini_TastMag_Win;
   begin
    Window(43, 18, 80, 20);
    TextBackground(Green);
    TextColor(Black);               {Setze Schriftfarbe}
    ClrScr;
   end;

  procedure Set_TastMag_Win;
   begin
    Window(43, 18, 80, 20);
    TextBackground(Green);
    TextColor(Black);               {Setze Schriftfarbe}
   end;

  procedure Ini_IstwDisp_Win;
   begin
    Window(02, 15 , 79, 18);
    TextBackground(Cyan);
    TextColor(Black);               {Setze Schriftfarbe}
    ClrScr;
   end;

 procedure Set_IstwDisp_Win; far; {Routine als Prozedur-Parameter einsetzbar}
  begin
   Window(02, 15, 79, 18);
   TextBackground(Cyan);
   TextColor(Black);               {Setze Schriftfarbe}
  end;

 PROCEDURE Displ_FTasten_Liste;
  Begin
     {Info-Anzeige der Bit-Belegung Funktionstasten}
      ini_info_win;
      writeln('F1 : Reset     [Fct-Code  01H]');
      writeln('F2 : Ein       [Fct-Code  02H]');
      writeln('F3 : Aus       [Fct-Code  03H]');
      writeln('F4 : +         [Fct-Code  04H]');
      writeln('F5 : -         [Fct-Code  05H]');
      writeln('F6 : Last 0..5 [Fct-Cd 14-19H]');
      writeln('F7 : Sollw1= 0 [Fct-Code  06H]');
      writeln('F8 : Sollw1    [Volt/Amp/Hex ]');
      writeln('F9 : FGen: einfache Rampe     ');
      writeln('F10: IFK-Adresse Ñndern       ');
      writeln('F11: Abfrage-Rate Quick/Slow  ');
      write  ('F12: Init FehlerÅberwachung   ');
   End; {displ_HS_Status}

 function Get_LastNr (var Num: Byte): Boolean;
  var Answer: Char;
  begin
    Get_LastNr := FALSE;
    Ini_Msg_Win;
    Write ('Bitte Last-Nummer als Dezimalzahl [0..5]  oder  [Q]uit:');
    repeat until KeyEPressed;
    Answer := NewReadKey;
    case Answer of
     '0' : begin Num := 0; Get_LastNr := TRUE; end;
     '1' : begin Num := 1; Get_LastNr := TRUE; end;
     '2' : begin Num := 2; Get_LastNr := TRUE; end;
     '3' : begin Num := 3; Get_LastNr := TRUE; end;
     '4' : begin Num := 4; Get_LastNr := TRUE; end;
     '5' : begin Num := 5; Get_LastNr := TRUE; end;
    end; {case}
  end; {Get_LastNr}

procedure Mil_NG_Puls_Vari;     {Variable Eingabe fÅr Sollwert, Istwert, Zeit}
{
 Drei Magnetsollwerte und Istwerte sollen in definierten AbstÑnden gesetzt/
  gelesen werden. Startwert ist nicht Null, sondern Flattop 1
  Abweichungen Soll-Ist soll ermittelt und max. 10 Vergleiche angezeigt werden.
}
 label 99;
 const Hist_Max = 9;
       Top_Max  = 3;
       Z_Start  = 1;

 type
  TSollIst = record
              Soll     : Integer;       {Sollwert}
              Ist      : Integer;       {Istwert}
              S_I_Diff : Integer;
              Rd_Error : Boolean;    {Zeigt Fehler beim Istwertlesen an}
            {  Zeit_Top : Word;   }  {Dauer des Flattop}
              Zeit_Top : LongInt;    {Dauer des Flattop}
              Zeit_Wait: LongInt;       {Warte, bis Istwert gelesen werden kann}
            {  Zeit_Wait: Word;   }  {Warte, bis Istwert gelesen werden kann}
              Hist_Diff: array [0..Hist_Max] of Integer; {Historische Differenzen}
             end;
 var
  FlaTop : array [1..Top_Max] of TSollIst;
  Wr_Fct_Code, Rd_Fct_Code : Byte;
  Wr_Fct_Code2 : Byte;

  MilErr : TMilErr;
  Fct    : TFct;
  RetAdr : Byte;
  OnlineErr: TOnlineErr;
  Status_Data: Word;
  Hist_Index : Byte;         {gilt fÅr Array mit den historischen Differenzen}
  Z          : Byte;
  Adress     : Word;

  procedure New_Ifc_Adr;
   VAR answer : CHAR;
   Begin
     status := FALSE;
     WHILE NOT status DO
      Begin
       Ifc_Test_Nr := Ask_Hex_Byte;
       IF ifc_test_nr IN [1..255] THEN status := TRUE;
      End;
   End; {ask_ifc}

  procedure Mag_Headline;
   begin
    Ini_Headl_Win;
    GotoXY(01,01);
    write('                            Test fÅr gepulste Magnete                           ');
    GotoXY(01,02);
    write('Schreibe in definierten AbstÑnden 3 Sollwerte u. lese Istwerte verzîgert zurÅck');
    ini_text_win;
    Ini_Msg_Win;
    Write ('Weiter mit <Space>    oder    E[X]it ');
    Set_Text_Win;
   end;

  procedure Ini_Flatop_Ary;
   var y,z : Byte;
   begin
    for y := 1 to Top_Max do
     begin
      Flatop[y].Soll     := 0;
      Flatop[y].Ist      := 0;
      Flatop[y].S_I_Diff := 0;
      Flatop[y].Rd_Error := False;
      Flatop[y].Zeit_Top := 0;
      Flatop[y].Zeit_Wait:= 0;
      for z:=0 to Hist_Max do Flatop[y].Hist_Diff[z] := 0;
     end; {for y}
   end; {Ini_Flatop_Ary}

  function Ask_Flatop (Num: Byte): Boolean;   {Erfrage Parameter von User}
   label 01;
   const Z_Start = 15;
   var Soll      : Word;
       Top, Wait : Byte;
   begin
     Ask_Flatop := True;
     Soll := Flatop[Num].Soll;                 {Rette alte Werte fÅr Abbruch}
     Top  := Flatop[Num].Zeit_Top;
     Wait := Flatop[Num].Zeit_Wait;

    repeat
      Ini_Text_Win;
      GotoXY(20,04); write(' Bitte Flat-Top Parameter eingeben!!');
      GotoXY(5,Z_Start);
      write ('Flat-Top Nummer         :      ', Num); ClrEol;

      GotoXY(5, 22);
      write ('Welchen Sollwert f. Flat-Top ', Num,' ?'); Clreol;
      Flatop[Num].Soll := Rd_Real_Sw (10.0);
      Set_Text_Win;
      GotoXY(5,Z_Start+1);
      write ('Flat-Top-Sollwert [Volt]:');
      Write_Real_10V_Bipol (Flatop[Num].Soll); ClrEol;

      Flatop[Num].Zeit_Top := 0;    {Default}
      repeat
        Set_Text_Win;
        GotoXY(1, 22); Clreol;
        Ini_Msg_Win;
        write ('Welche Dauer (max. 65 sec) fÅr FLAT-TOP ', Num, ' [ms] ?: ');
        {$I-}               {Fehleingabe zulassen: Compiler-Check ausschalten}
        readln (Flatop[Num].Zeit_Top);
        {$I+}
        if (IoResult <> 0) then
          Flatop[Num].Zeit_Top := 0    {Fehler}
        else
         begin
          if Flatop[Num].Zeit_Top = 0 then
           begin
             Ini_Err_Win;
             write ('Dauer fÅr FLAT-TOP mu· <> 0 sein!  Weiter mit beliebiger Taste');
             repeat until KeyEPressed;
           end;
         end;
      until  Flatop[Num].Zeit_Top > 0;

      Set_Text_Win;
      GotoXY(5,Z_Start+2);
      write ('Flat-Top-Dauer      [ms]:  ');
      write (Flatop[Num].Zeit_Top:5); ClrEol;

      Flatop[Num].Zeit_Wait := Flatop[Num].Zeit_Top + 1; {Als Fehler setzen}
      repeat
        Set_Text_Win;
        GotoXY(1, 22); Clreol;
        Ini_Msg_Win;
        write ('Wartezeit (max. 65 sec): Beginn Flat-Top bis Lesen Istwert ', Num, ' [ms] ? ');

        {$I-}               {Fehleingabe zulassen: Compiler-Check ausschalten}
        readln  (Flatop[Num].Zeit_Wait);
        {$I+}
        if (IoResult <> 0) then  {Fehler}
         begin
           Ini_Err_Win;
           write ('Eingabe-Fehler !!       Weiter mit beliebiger Taste ');
           repeat until KeyEPressed;
         end
        else
         begin
           Set_Text_Win;
           GotoXY(5,Z_Start+3);
           write ('Istwert lesen nach  [ms]:  ');
           write (Flatop[Num].Zeit_Wait:5); ClrEol;

           if Flatop[Num].Zeit_Wait > Flatop[Num].Zeit_Top then
            begin
              Ini_Err_Win;
              write ('Wartezeit grî·er als Flat-Top-Zeit!! Weiter mit beliebiger Taste ');
              repeat until KeyEPressed;
            end;
         end;
      until  Flatop[Num].Zeit_Wait <= Flatop[Num].Zeit_Top;

      Ini_Msg_Win;
      write ('Bisherige Eingaben akzeptieren [<CR>/N] oder Abbruch [X]: ');
      repeat until KeyEPressed;
      Ch := NewReadKey;
      if Ch = Taste_Return then Ch := 'J';
    until (Ch in ['x','X']) or (Ch in ['j','J']);

    if Ch in ['x','X'] then
     begin                                          {Abbruch!}
      Ask_Flatop           := False;
      Flatop[Num].Soll     := Soll;             {Alte Werte restaurieren}
      Flatop[Num].Zeit_Top := Top;
      Flatop[Num].Zeit_Wait:= Wait;
     end;
   end;

  procedure Ini_Flat_Win;
    var Index : Byte;
    begin
     Ini_Text_Win;
     TextColor(Brown);               {Setze Schriftfarbe}
     GotoXY(01, Z_Start);
     Write ('Test_Count:            Status:      IFC-Adr[H]:     Wr-Fct[H]:     Rd-Fct[H]:   ');
     GotoXY(01, Z_Start+1);
     Write ('Aktives Flat-Top:      R/H   :      DataSet-Nr:                                  ');
     TextColor(Brown);               {Setze Schriftfarbe}

     GotoXY(01, Z_Start+3);
{    Write ('Flatop Dauer  +Read    -- Sollwert --      Istwert         Diff. Soll-Ist       ');
}
     Write ('Flatop Dauer  +Read    -- Sollwert --      Istwert         Diff. Ist-Soll       ');
     GotoXY(01, Z_Start+4);
     Write ('  Nr   [ms]    [ms]   [Volt]    [Hex]      [Volt]              [Volt]           ');
     TextColor(Black);               {Setze Schriftfarbe}
{
     GotoXY(01, Z_Start+5);
     Write ('  00                                                                            ');
}     GotoXY(01, Z_Start+6);
     Write ('  01                                                                            ');
     GotoXY(01, Z_Start+7);
     Write ('  02                                                                            ');
     GotoXY(01, Z_Start+8);
     Write ('  03                                                                            ');

     TextColor(Brown);               {Setze Schriftfarbe}
     GotoXY(01, Z_Start+9);
     Write ('v-- Anzeige der letzten 10  Ist_Soll Differenz-Werte (N-1 = vorletzter Wert) --v');
{     Write ('v-- Anzeige der letzten 10  Soll-Ist Differenz-Werte (N-1 = vorletzter Wert) --v');
}    GotoXY(20, Z_Start+10); Write ('Diff- Flatop 1');
     GotoXY(41, Z_Start+10); Write ('Diff- Flatop 2');
     GotoXY(61, Z_Start+10); Write ('Diff- Flatop 3');

     for Index := 0 to Hist_Max do
      begin
        GotoXY(02, Z_Start+11+Index);
        Write ('N -',Index:2);
      end;
     TextColor(Black);               {Setze Schriftfarbe}
   end;

  procedure Disp_Flat_Active (Num : Byte);  {Aktives Flattop auf Bildschirm}
   var x : Byte;
   begin
     GotoXY(20, Z_Start+1); Write (Num);    {aktives Flattop}
     for x := 0 to 3 do                     {lîsche Zeiger}
      begin
        GotoXY(01, Z_Start+5+x);
        Write ('  ');
      end;

     case Num of
       0 : begin   GotoXY(01, Z_Start+5);  Write ('->');  end;
       1 : begin   GotoXY(01, Z_Start+6);  Write ('->');  end;
       2 : begin   GotoXY(01, Z_Start+7);  Write ('->');  end;
       3 : begin   GotoXY(01, Z_Start+8);  Write ('->');  end;
     end;
   end;

 function Flat_Top (Num: Byte): Boolean;
  { Die Dauer des Flattops und die Leseverzîgerung des Istwertes sollen Åber
    den Timer2 bestimmmt werden, da Timer1 fÅr MIL-Operationen reserviert ist.
    Zuerst wird Timer2 mit der Istwert-Verzîgerung geladen und dann mit
    der restlichen Zeit als Differenz: Flattop-Time minus Leseverzîgerung }
   var Top_Minus_Wait_Time : LongInt;
       Read_Time_10us      : LongInt;
       Soll_Ist_Diff       : Word;
       Temp                : Word;
   begin
    Flat_Top := False;         {Default}
    Disp_Flat_Active (Num);
    Top_Minus_Wait_Time:= Flatop[Num].Zeit_Top - Flatop[Num].Zeit_Wait; {ms!!}
    Top_Minus_Wait_Time:= Top_Minus_Wait_Time * 100;      {10 us * 100 = 1 ms}
    Read_Time_10us     := Flatop[Num].Zeit_Wait * 100;    {10 us * 100 = 1 ms}
    Fct.B.Adr := Ifc_Test_Nr;
    Fct.B.Fct := Wr_Fct_Code;
    Mil.Wr (Flatop[Num].Soll , Fct, MilErr);  {Setze Flattop Sollwert}

    Fct.B.Fct := Wr_Fct_Code + 1;     {060499: FctCode 06, 07}
    Mil.Wr (Flatop[Num].Soll , Fct, MilErr);  {Setze Flattop Sollwert}
    Mil.Timer2_Wait(Read_Time_10us);          {Read-Time abwarten; Basis 10 us}

    Fct.B.Fct := Fct_Start_Conv;          {070199} {wegen ADC-Hw-énderung}
    Mil.WrFct (Fct, MilErr);
    Mil.Timer2_Wait (ADC_Conv_Wait);

    Fct.B.Fct := Rd_Fct_Code;

    Temp:= Word(Flatop[Num].Ist);
    Mil.Rd (Temp, Fct, MilErr);   {Lese Istwert}
    Flatop[Num].Ist:= Temp;

    GotoXY(43, Z_Start+5+Num);                {Display-Position Istwert}
    if MilErr <> No_Err then
     begin
      Write ('  Rd_Err  ');
      Flatop[Num].Rd_Error := True;
      GotoXY(63, Z_Start+5+Num); Write('          ');
     end
    else
     begin
      Write_Real_10V_Bipol (Flatop[Num].Ist);
      Flatop[Num].Rd_Error := False;
{     Flatop[Num].S_I_Diff := Flatop[Num].Soll - Flatop[Num].Ist;  }
      Flatop[Num].S_I_Diff := Flatop[Num].Ist - Flatop[Num].Soll;
      Flatop[Num].Hist_Diff[Hist_Index] := Flatop[Num].S_I_Diff;
      GotoXY(63, Z_Start+5+Num); Write_Real_10V_Bipol (Flatop[Num].S_I_Diff);
     end;
    Mil.Timer2_Set(Top_Minus_Wait_Time);      {Lade Ende des Flattops}
    repeat until Mil.Timeout2;   {Warte bis zum Ende des Flattops}
   end; {Flat_Top}

  procedure Flat_Zero;
   begin
    Fct.B.Adr := Ifc_Test_Nr;
    Fct.B.Fct := Wr_Fct_Code;
    Mil.Wr (0 , Fct, MilErr);  {Setze Flattop Sollwert}
{    Disp_Flat_Active (0); }
   end;


{Anzeige der alten Differenzwerte: falls nur eine Messung gemacht wurde, auch
nur eine Zeile anzeigen. Erst nach Hist_Max Messungen, werden alle historischen
Werte angezeigt}
 procedure Disp_Hist_Ary (Test_Count: Word);
   var Index       : Byte;
       Start_Index : Byte;
       Flat_Nr : Byte;
       Rd_Index  : Integer;
       DispLn_Num: Word;

   begin
     Set_Text_Win;
     Flat_Nr   := 1;
     if Test_Count > Hist_Max then DispLn_Num := Hist_Max
     else DispLn_Num := Test_Count - 1;          {Wenig Daten, wenig anzeigen}

     for Index := 0 to DispLn_Num do
     begin
       Rd_Index := (Hist_Index - Index) - 1;  {Hist_index zeigt auf next write}
       if Rd_Index < 0 then Rd_Index := Hist_Max + 1 + Rd_Index;
       GotoXY(22, Z_Start+11+Index);
       if Flatop[Flat_Nr].Rd_Error then
        Write ('Rd_Err')
       else
         Write_Real_10V_Bipol (Flatop[Flat_Nr].Hist_Diff[Rd_Index]);
      end;

     Flat_Nr   := 2;
     if Test_Count > Hist_Max then DispLn_Num := Hist_Max
     else DispLn_Num := Test_Count - 1;          {Wenig Daten, wenig anzeigen}

     for Index := 0 to DispLn_Num do
     begin
       Rd_Index := (Hist_Index - Index) - 1;  {Hist_index zeigt auf next write}
       if Rd_Index < 0 then Rd_Index := Hist_Max + 1 + Rd_Index;
       GotoXY(43, Z_Start+11+Index);
       if Flatop[Flat_Nr].Rd_Error then
        Write ('Rd_Err')
       else
         Write_Real_10V_Bipol (Flatop[Flat_Nr].Hist_Diff[Rd_Index]);
      end;

     Flat_Nr   := 3;
     if Test_Count > Hist_Max then DispLn_Num := Hist_Max
     else DispLn_Num := Test_Count - 1;          {Wenig Daten, wenig anzeigen}

     for Index := 0 to DispLn_Num do
     begin
       Rd_Index := (Hist_Index - Index) - 1;  {Hist_index zeigt auf next write}
       if Rd_Index < 0 then Rd_Index := Hist_Max + 1 + Rd_Index;
       GotoXY(63, Z_Start+11+Index);
       if Flatop[Flat_Nr].Rd_Error then
        Write ('Rd_Err')
       else
         Write_Real_10V_Bipol (Flatop[Flat_Nr].Hist_Diff[Rd_Index]);
      end;
   end; {Disp_Hist_Ary}

 procedure Clear_Hist_Disp;
  var Index : Byte;
   begin
     Set_Text_Win;
     for Index := 0 to Hist_Max  do
      begin
        GotoXY(01, Z_Start+11+Index); ClrEol;
      end;

     TextColor(Brown);               {Setze Schriftfarbe}
     for Index := 0 to Hist_Max  do
      begin
        GotoXY(02, Z_Start+11+Index);
        Write ('N -',Index:2);
      end;
     TextColor(Black);               {Setze Schriftfarbe}
   end;

 procedure Disp_R_H;
  begin
   Fct.B.Adr := Ifc_Test_Nr;
   Fct.B.Fct := Fct_Rd_Stat0;               {Status C0}
   Mil.Rd (Status_Data, Fct, MilErr);
   GotoXY(32, Z_Start);
   if BitTst (Status_Data, 8) then          {Bit 8 gibt Ein/Aus an}
     Write ('Ein')
   else
     Write ('Aus');

   Fct.B.Fct := Fct_Rd_Stat2;               {Status C2}
   Mil.Rd (Status_Data, Fct, MilErr);
   GotoXY(32, Z_Start+1);
   if BitTst (Status_Data, 8) then          {Bit 8 gibt R/H an}
     Write ('R')
   else
     Write ('H');
  end;

 begin                        {Mil_NG_Puls}
   Mil_Ask_Ifc;
   Fct.B.Adr := Ifc_Test_Nr;
   Hist_Index := 0;
   Transf_Cnt := 0;
   Ini_Flatop_Ary;
   Mag_Headline;


{
   Ini_Text_Win;
   GotoXY(5, 22); TextColor(Brown);
   write ('Welchen Write-Function-Code fÅr Sollwert ? [CR = ',Hex_Byte(Write_Fct_Code),'H]: ');
   if Ask_Hex_Break (Adress, Byt) then
     Wr_Fct_Code := Adress
   else
     Wr_Fct_Code := Write_Fct_Code;
}
   Wr_Fct_Code := Write_Fct_Code;

   Ini_Text_Win;
   GotoXY(5, 22); TextColor(Brown);
   write ('Welchen Read-Function-Code fÅr Istwert ? [CR = ',Hex_Byte(Read_Fct_Code),'H]: ');
   if Ask_Hex_Break (Adress, Byt) then
     Rd_Fct_Code := Adress
   else
     Rd_Fct_Code := Read_Fct_Code;

   TextColor(Black);
   if not Ask_Flatop (1) then goto 99;
   if not Ask_Flatop (2) then goto 99;
   if not Ask_Flatop (3) then goto 99;

   Ini_Flat_Win;
   GotoXY(49, Z_Start+0); Write (Hex_Byte(Ifc_Test_Nr));
   GotoXY(64, Z_Start+0); Write (Hex_Byte(Wr_Fct_Code));
   GotoXY(79, Z_Start+0); Write (Hex_Byte(Rd_Fct_Code));
{
   GotoXY(22, Z_Start+5); Write_Real_10V_Bipol (0);
   GotoXY(33, Z_Start+5); Write (Hex_Word (0));
}
   GotoXY(07, Z_Start+6); Write (Flatop[1].Zeit_Top:5);
   GotoXY(15, Z_Start+6); Write (Flatop[1].Zeit_Wait:5);
   GotoXY(22, Z_Start+6); Write_Real_10V_Bipol (Flatop[1].Soll);
   GotoXY(33, Z_Start+6); Write (Hex_Word (Flatop[1].Soll));

   GotoXY(07, Z_Start+7); Write (Flatop[2].Zeit_Top:5);
   GotoXY(15, Z_Start+7); Write (Flatop[2].Zeit_Wait:5);
   GotoXY(22, Z_Start+7); Write_Real_10V_Bipol (Flatop[2].Soll);
   GotoXY(33, Z_Start+7); Write (Hex_Word (Flatop[2].Soll));

   GotoXY(07, Z_Start+8); Write (Flatop[3].Zeit_Top:5);
   GotoXY(15, Z_Start+8); Write (Flatop[3].Zeit_Wait:5);
   GotoXY(22, Z_Start+8); Write_Real_10V_Bipol (Flatop[3].Soll);
   GotoXY(33, Z_Start+8); Write (Hex_Word (Flatop[3].Soll));
   GotoXY(13, Z_Start);   Write (Transf_Cnt:8);
{
   Flat_Top (1);
   Disp_Flat_Active (0);
}   Disp_R_H;

   Ch := ' ';
   if Ch = ' ' then
     begin
      Ini_Msg_Win;
      Write('Stop/Single Step mit <SPACE>, Loop mit <CR> ,  Ende mit [X]');
      repeat until KeyEPressed;
      Ch := NewReadKey;
      if  Ch in ['x','X'] then Goto 99;
     end;

   repeat
    repeat
      Set_Text_win;
      Transf_Cnt := Transf_Cnt+ 1;
      Flat_Top (1);
      Flat_Top (2);
      Flat_Top (3);
      Hist_Index := Hist_Index + 1;                 {gilt fÅr alle drei Flattops}
      if Hist_Index = Hist_Max + 1 then Hist_Index := 0;
      GotoXY(13, Z_Start);
      Write (Transf_Cnt:8);
    until KeyEPressed or (Ch = ' ');

    if KeyEPressed then Ch := NewReadKey;
    if Ch = ' ' then
      begin
       Flat_Top (1);   {Stelle Grundwert ein}
      { Flat_Zero; }                   {Setze Magnet auf Sollwert 0}
      { Disp_Flat_Active (0); }
       Disp_Flat_Active (1);
       Disp_Hist_Ary (Transf_Cnt);                {Zeige letzte 10 Differenzwerte}
       Disp_R_H;
       Ini_Msg_Win;
       Write('Stop/Single Step mit <SPACE>, Loop mit <CR>, neue Mil-<A>dresse   Ende mit [X]');
       repeat until KeyEPressed;
      end;
    Ch := NewReadKey;

    if Ch in ['a','A'] then
     begin
       New_Ifc_Adr;
       Set_Text_Win;
       GotoXY(49, Z_Start+0); Write (Hex_Byte(Ifc_Test_Nr));
       Ini_Msg_Win;
       Write('Stop/Single Step mit <SPACE>, Loop mit <CR>, neue Mil-<A>dresse   Ende mit [X]');
       repeat until KeyEPressed;
       Ch := NewReadKey;
     end;

    Clear_Hist_Disp;
   until Ch in ['x','X'];
99: Flat_Zero;                    {Setze Magnet auf Sollwert 0}
 end; {Mil_NG_Puls_Vari}


procedure Mil_NG_Puls_Fix;     {Feste Werte fÅr Sollwert, Istwert, Zeit}
{ Drei Magnetsollwerte und Istwerte sollen in definierten AbstÑnden gesetzt/
  gelesen werden. Abweichungen Soll-Ist soll ermittelt und max. 10 Vergleiche
  angezeigt werden.
}
 label 99;
 const Hist_Max = 9;
       Top_Max  = 3;    {Anzahl der Daten pro Flattop: Soll, Top_time, Wait}
       Z_Start  = 1;
       Flat_Ary_Max = 7;           {Anzahl der vordefinierten Test-DatensÑtze}
 type
  TSollIst = record
              Soll     : Integer;       {Sollwert}
              Ist      : Integer;       {Istwert}
              S_I_Diff : Integer;
              Rd_Error : Boolean;    {Zeigt Fehler beim Istwertlesen an}
              Zeit_Top : Word;       {Dauer des Flattop}
              Zeit_Wait: Word;       {Warte, bis Istwert gelesen werden kann}
              Hist_Diff: array [0..Hist_Max] of Word; {Historische Differenzen}
             end;
  TFlatParm = record
               Soll     : Word;
               Top      : Word;
               Wait     : Word;
              end;
  TParmAry  = array [1..3] of TFlatParm;
  TFlatAry  = array [1..Flat_Ary_Max] of TParmAry;

 const
  FlatFix: TFlatAry =
  (
  ((Soll: $4000; Top: 1000; Wait:   50),
   (Soll: $0000; Top: 1000; Wait:   50),
   (Soll: $0000; Top: 1000; Wait:   50)),

  ((Soll: $4000; Top: 1000; Wait:   50),
   (Soll: $C000; Top: 1000; Wait:   50),
   (Soll: $0000; Top: 1000; Wait:   50)),

  ((Soll: $2000; Top: 1000; Wait:   50),
   (Soll: $0000; Top: 1000; Wait:   50),
   (Soll: $4000; Top: 1000; Wait:   50)),

  ((Soll: $4000; Top: 1000; Wait:   50),
   (Soll: $0000; Top: 1000; Wait:   50),
   (Soll: $7FFF; Top: 1000; Wait:   50)),

  ((Soll: $C000; Top: 1000; Wait:   50),
   (Soll: $0000; Top: 1000; Wait:   50),
   (Soll: $8000; Top: 1000; Wait:   50)),

  ((Soll: $7FFF; Top: 1000; Wait:   50),
   (Soll: $0000; Top: 1000; Wait:   50),
   (Soll: $0000; Top: 1000; Wait:   50)),

  ((Soll: $7FFF; Top: 1000; Wait:   50),
   (Soll: $8000; Top: 1000; Wait:   50),
   (Soll: $0000; Top: 1000; Wait:   50))
 );

 var
  FlaTop : array [1..Top_Max] of TSollIst;
  Wr_Fct_Code, Rd_Fct_Code : Byte;
  MilErr : TMilErr;
  Fct    : TFct;
  RetAdr : Byte;
  OnlineErr: TOnlineErr;
  Status_Data: Word;
  Hist_Index : Byte;         {gilt fÅr Array mit den historischen Differenzen}
  Z : Byte;
  Data_Set_Nr : Byte;


  procedure Mag_Headline;
   begin
    Ini_Headl_Win;
    GotoXY(01,01);
    write('                            Test fÅr gepulste Magnete                           ');
    GotoXY(01,02);
    write('Schreibe in definierten AbstÑnden 3 Sollwerte u. lese Istwerte verzîgert zurÅck');
    Ini_Text_Win;
    Ini_Msg_Win;
    Write ('Weiter mit <Space>    oder    E[X]it ');
    Set_Text_Win;
   end;

  procedure Ini_Flatop_Ary;
   var y,z : Byte;
   begin
    for y := 1 to Top_Max do
     begin
      Flatop[y].Soll     := 0;
      Flatop[y].Ist      := 0;
      Flatop[y].S_I_Diff := 0;
      Flatop[y].Rd_Error := False;
      Flatop[y].Zeit_Top := 0;
      Flatop[y].Zeit_Wait:= 0;
      for z:=0 to Hist_Max do Flatop[y].Hist_Diff[z] := 0;
     end; {for y}
   end; {Ini_Flatop_Ary}


  function Ask_Flat_Nr: Boolean;         {Erfrage Tabelle der fixen Parameter}
   label 01;
   const Z_Start = 10;
   var z,m : Byte;

   procedure Set_Flat_Parm (Num: Byte);
    var n : Byte;
    begin
     for n := 1 to 3 do
      begin
        Flatop[n].Soll      := FlatFix[Num,n].Soll;
        Flatop[n].Zeit_Top  := FlatFix[Num,n].Top;
        Flatop[n].Zeit_Wait := FlatFix[Num,n].Wait;
      end;
    end; {Set_Flat_Parm}

   begin
      Ask_Flat_Nr := False;
      Ini_Text_Win;
      GotoXY(06,04); write('Verschiedene, vordefinierte Flat-Top Parameter DatensÑtze auswÑhlbar!');

      GotoXY(01, Z_Start);
      TextColor(Brown);
      writeln (' Daten   v-- Flat-Top 1 --v     v-- Flat-Top 2 --v     v-- Flat-Top 3 --v');
      writeln (' Satz     Soll    Top  Read      Soll    Top  Read      Soll    Top  Read');
      writeln ('  Nr.    [Volt]   [ms] [ms]     [Volt]   [ms] [ms]     [Volt]   [ms] [ms]');
      TextColor(Black);

      for z := 1 to  Flat_Ary_Max do
       begin
         begin
           m := 1;
           GotoXY(04, Z_Start+3+z); Write (z);
           GotoXY(08, Z_Start+3+z); Write_Real_10V_Bipol (FlatFix[z,m].Soll);
           GotoXY(19, Z_Start+3+z); Write (FlatFix[z,m].Top:4);
           GotoXY(24, Z_Start+3+z); Write (FlatFix[z,m].Wait:4);

           m := 2;
           GotoXY(31, Z_Start+3+z); Write_Real_10V_Bipol (FlatFix[z,m].Soll);
           GotoXY(42, Z_Start+3+z); Write (FlatFix[z,m].Top:4);
           GotoXY(47, Z_Start+3+z); Write (FlatFix[z,m].Wait:4);

           m := 3;
           GotoXY(54, Z_Start+3+z); Write_Real_10V_Bipol (FlatFix[z,m].Soll);
           GotoXY(65, Z_Start+3+z); Write (FlatFix[z,m].Top:4);
           GotoXY(70, Z_Start+3+z); Write (FlatFix[z,m].Wait:4);
         end;
       end;

     Ini_Msg_Win;
     write ('Bitte Datensatz-Nr eingeben [1..',Flat_Ary_Max,'] oder Abbruch mit [Q]: ');
     repeat until KeyEPressed;
     Ch := NewReadKey;
     case Ch of
      '1' : begin Set_Flat_Parm (1); Data_Set_Nr:= 1; Ask_Flat_Nr := True; end;
      '2' : begin Set_Flat_Parm (2); Data_Set_Nr:= 2; Ask_Flat_Nr := True; end;
      '3' : begin Set_Flat_Parm (3); Data_Set_Nr:= 3; Ask_Flat_Nr := True; end;
      '4' : begin Set_Flat_Parm (4); Data_Set_Nr:= 4; Ask_Flat_Nr := True; end;
      '5' : begin Set_Flat_Parm (5); Data_Set_Nr:= 5; Ask_Flat_Nr := True; end;
      '6' : begin Set_Flat_Parm (6); Data_Set_Nr:= 6; Ask_Flat_Nr := True; end;
      '7' : begin Set_Flat_Parm (7); Data_Set_Nr:= 7; Ask_Flat_Nr := True; end;
      'q','Q' : goto 01;
     else
      begin
        Ini_Err_Win;
        write ('Keine gÅltige Datenssatz-Nr. !!    Weiter mit beliebiger Taste');
        repeat until KeyEPressed;
      end;
     end; {case}
  01:
  end; {Ask_Flat_Nr}

  procedure Ini_Flat_Win;
    var Index : Byte;
    begin
     Ini_Text_Win;
     TextColor(Brown);               {Setze Schriftfarbe}
     GotoXY(01, Z_Start);
     Write ('Test_Count:            Status:      IFC-Adr[H]:     Wr-Fct[H]:     Rd-Fct[H]:   ');
     GotoXY(01, Z_Start+1);
     Write ('Aktives Flat-Top:      R/H   :      DataSet-Nr:                                  ');
     TextColor(Brown);               {Setze Schriftfarbe}

     GotoXY(01, Z_Start+3);
{    Write ('Flatop Dauer  +Read    -- Sollwert --      Istwert         Diff. Soll-Ist       ');
}    Write ('Flatop Dauer  +Read    -- Sollwert --      Istwert         Diff. Ist-Soll       ');
     GotoXY(01, Z_Start+4);
     Write ('  Nr   [ms]    [ms]   [Volt]    [Hex]      [Volt]              [Volt]           ');
     TextColor(Black);               {Setze Schriftfarbe}

{     GotoXY(01, Z_Start+5);
     Write ('  00                                                                            ');
}    GotoXY(01, Z_Start+6);
     Write ('  01                                                                            ');
     GotoXY(01, Z_Start+7);
     Write ('  02                                                                            ');
     GotoXY(01, Z_Start+8);
     Write ('  03                                                                            ');

     TextColor(Brown);               {Setze Schriftfarbe}
     GotoXY(01, Z_Start+9);
     Write ('v-- Anzeige der letzten 10  Ist-Soll Differenz-Werte (N-1 = vorletzter Wert) --v');
     GotoXY(20, Z_Start+10); Write ('Diff- Flatop 1');
     GotoXY(41, Z_Start+10); Write ('Diff- Flatop 2');
     GotoXY(61, Z_Start+10); Write ('Diff- Flatop 3');

     for Index := 0 to Hist_Max do
      begin
        GotoXY(02, Z_Start+11+Index);
        Write ('N -',Index:2);
      end;

     TextColor(Red);
     GotoXY(08, Z_Start+11+Hist_Max+1);
     Write ('[Im LOOP-MODE keine Anzeige der Ist-Soll Differenzen N-0 ... N-9 !]');
     TextColor(Black);               {Setze Schriftfarbe}
   end;

  procedure Disp_Flat_Active (Num : Byte);  {Aktives Flattop auf Bildschirm}
   var x : Byte;
   begin
     GotoXY(20, Z_Start+1); Write (Num);    {aktives Flattop}
     for x := 0 to 3 do                     {lîsche Zeiger}
      begin
        GotoXY(01, Z_Start+5+x);
        Write ('  ');
      end;

     case Num of
{       0 : begin   GotoXY(01, Z_Start+5);  Write ('->');  end; }
       1 : begin   GotoXY(01, Z_Start+6);  Write ('->');  end;
       2 : begin   GotoXY(01, Z_Start+7);  Write ('->');  end;
       3 : begin   GotoXY(01, Z_Start+8);  Write ('->');  end;
     end;
   end;

  function Flat_Top (Num: Byte): Boolean;
  { Die Dauer des Flattops und die Leseverzîgerung des Istwertes sollen Åber
    den Timer2 bestimmmt werden, da Timer1 fÅr MIL-Operationen reserviert ist.
    Zuerst wird Timer2 mit der Istwert-Verzîgerung geladen und dann mit
    der restlichen Zeit als Differenz: Flattop-Time minus Leseverzîgerung
  }
   var Top_Minus_Wait_Time : LongInt;
       Read_Time_10us      : LongInt;
       Soll_Ist_Diff       : Word;
       Temp                : Word;
   begin
    Flat_Top := False;         {Default}
    Disp_Flat_Active (Num);
    Top_Minus_Wait_Time:= Flatop[Num].Zeit_Top - Flatop[Num].Zeit_Wait; {ms!!}
    Top_Minus_Wait_Time:= Top_Minus_Wait_Time * 100;      {10 us * 100 = 1 ms}
    Read_Time_10us     := Flatop[Num].Zeit_Wait * 100;    {10 us * 100 = 1 ms}
    Fct.B.Adr := Ifc_Test_Nr;
    Fct.B.Fct := Wr_Fct_Code;
    Mil.Wr (Flatop[Num].Soll , Fct, MilErr);          {Setze Flattop Sollwert}

    Fct.B.Fct := Wr_Fct_Code + 1;    {06.04.99: Fct 06, 07}
    Mil.Wr (Flatop[Num].Soll , Fct, MilErr);          {Setze Flattop Sollwert}
    Mil.Timer2_Wait(Read_Time_10us);         {Read-Time abwarten; Basis 10 us}

    {Sende Conversion Command: Neu 040199 ; wenn 2 ADC`s: nur 1 Convert-Cmd}
    Fct.B.Fct := Fct_Start_Conv;
    Mil.WrFct (Fct, MilErr);
    Mil.Timer2_Wait (ADC_Conv_Wait);

    Fct.B.Fct := Rd_Fct_Code;

    Temp:= Word(Flatop[Num].Ist);
    Mil.Rd (Temp, Fct, MilErr);   {Lese Istwert}
    Flatop[Num].Ist:= Temp;

    GotoXY(43, Z_Start+5+Num);                {Display-Position Istwert}
    if MilErr <> No_Err then
     begin
      Write ('  Rd_Err  ');
      Flatop[Num].Rd_Error := True;
      GotoXY(63, Z_Start+5+Num); Write('          ');
     end
    else
     begin
      Write_Real_10V_Bipol (Flatop[Num].Ist);
      Flatop[Num].Rd_Error := False;
{     Flatop[Num].S_I_Diff := Flatop[Num].Soll - Flatop[Num].Ist;  }
      Flatop[Num].S_I_Diff :=  Flatop[Num].Ist - Flatop[Num].Soll;
      Flatop[Num].Hist_Diff[Hist_Index] := Flatop[Num].S_I_Diff;
      GotoXY(63, Z_Start+5+Num); Write_Real_10V_Bipol (Flatop[Num].S_I_Diff);
     end;
    Mil.Timer2_Set(Top_Minus_Wait_Time);              {Lade Ende des Flattops}
    repeat until Mil.Timeout2;               {Warte bis zum Ende des Flattops}
   end; {Flat_Top}

  procedure Flat_Zero;
   begin
    Fct.B.Adr := Ifc_Test_Nr;
    Fct.B.Fct := Wr_Fct_Code;
    Mil.Wr (0 , Fct, MilErr);  {Setze Flattop Sollwert}
{    Disp_Flat_Active (0); }
   end;

{Anzeige der alten Differenzwerte: falls nur eine Messung gemacht wurde, auch
nur eine Zeile anzeigen. Erst nach Hist_Max Messungen, werden alle historischen
Werte angezeigt}
 procedure Disp_Hist_Ary (Test_Count: Word);
   var Index       : Byte;
       Start_Index : Byte;
       Flat_Nr : Byte;
       Rd_Index  : Integer;
       DispLn_Num: Word;

   begin
     Set_Text_Win;
     Flat_Nr   := 1;
     if Test_Count > Hist_Max then DispLn_Num := Hist_Max
     else DispLn_Num := Test_Count - 1;          {Wenig Daten, wenig anzeigen}

     for Index := 0 to DispLn_Num do
     begin
       Rd_Index := (Hist_Index - Index) - 1;  {Hist_index zeigt auf next write}
       if Rd_Index < 0 then Rd_Index := Hist_Max + 1 + Rd_Index;
       GotoXY(22, Z_Start+11+Index);
       if Flatop[Flat_Nr].Rd_Error then
        Write ('Rd_Err')
       else
         Write_Real_10V_Bipol (Flatop[Flat_Nr].Hist_Diff[Rd_Index]);
      end;

     Flat_Nr   := 2;
     if Test_Count > Hist_Max then DispLn_Num := Hist_Max
     else DispLn_Num := Test_Count - 1;          {Wenig Daten, wenig anzeigen}

     for Index := 0 to DispLn_Num do
     begin
       Rd_Index := (Hist_Index - Index) - 1;  {Hist_index zeigt auf next write}
       if Rd_Index < 0 then Rd_Index := Hist_Max + 1 + Rd_Index;
       GotoXY(43, Z_Start+11+Index);
       if Flatop[Flat_Nr].Rd_Error then
        Write ('Rd_Err')
       else
         Write_Real_10V_Bipol (Flatop[Flat_Nr].Hist_Diff[Rd_Index]);
      end;

     Flat_Nr   := 3;
     if Test_Count > Hist_Max then DispLn_Num := Hist_Max
     else DispLn_Num := Test_Count - 1;          {Wenig Daten, wenig anzeigen}

     for Index := 0 to DispLn_Num do
     begin
       Rd_Index := (Hist_Index - Index) - 1;  {Hist_index zeigt auf next write}
       if Rd_Index < 0 then Rd_Index := Hist_Max + 1 + Rd_Index;
       GotoXY(63, Z_Start+11+Index);
       if Flatop[Flat_Nr].Rd_Error then
        Write ('Rd_Err')
       else
         Write_Real_10V_Bipol (Flatop[Flat_Nr].Hist_Diff[Rd_Index]);
      end;
   end; {Disp_Hist_Ary}

 procedure Clear_Hist_Disp;
  var Index : Byte;
   begin
     Set_Text_Win;
     for Index := 0 to Hist_Max  do
      begin
        GotoXY(01, Z_Start+11+Index); ClrEol;
      end;

     TextColor(Brown);               {Setze Schriftfarbe}
     for Index := 0 to Hist_Max  do
      begin
        GotoXY(02, Z_Start+11+Index);
        Write ('N -',Index:2);
      end;
     TextColor(Black);               {Setze Schriftfarbe}
   end;

 procedure Disp_R_H;
  begin
   Fct.B.Adr := Ifc_Test_Nr;
   Fct.B.Fct := Fct_Rd_Stat0;               {Status C0}
   Mil.Rd (Status_Data, Fct, MilErr);
   GotoXY(32, Z_Start);
   if BitTst (Status_Data, 8) then          {Bit 8 gibt Ein/Aus an}
     Write ('Ein')
   else
     Write ('Aus');

   Fct.B.Fct := Fct_Rd_Stat2;               {Status C2}
   Mil.Rd (Status_Data, Fct, MilErr);
   GotoXY(32, Z_Start+1);
   if BitTst (Status_Data, 8) then          {Bit 8 gibt R/H an}
     Write ('R')
   else
     Write ('H');
  end;

 begin                        {Mil_NG_Puls}
   Mil_Ask_Ifc;
   Fct.B.Adr := Ifc_Test_Nr;
   Hist_Index := 0;
   Transf_Cnt := 0;
   Ini_Flatop_Ary;
   Mag_Headline;
   Ini_Text_Win;

   Wr_Fct_Code := Write_Fct_Code;   {Fct-Code sind jetzt ebenso fest}
   Rd_Fct_Code := Read_Fct_Code;

   if not Ask_Flat_Nr then goto 99;
   Ini_Flat_Win;
   GotoXY(49, Z_Start+0); Write (Hex_Byte(Ifc_Test_Nr));
   GotoXY(64, Z_Start+0); Write (Hex_Byte(Wr_Fct_Code));
   GotoXY(79, Z_Start+0); Write (Hex_Byte(Rd_Fct_Code));
{
   GotoXY(22, Z_Start+5); Write_Real_10V_Bipol (0);
   GotoXY(33, Z_Start+5); Write (Hex_Word (0));
}
   GotoXY(07, Z_Start+6); Write (Flatop[1].Zeit_Top:5);
   GotoXY(15, Z_Start+6); Write (Flatop[1].Zeit_Wait:5);
   GotoXY(22, Z_Start+6); Write_Real_10V_Bipol (Flatop[1].Soll);
   GotoXY(33, Z_Start+6); Write (Hex_Word (Flatop[1].Soll));

   GotoXY(07, Z_Start+7); Write (Flatop[2].Zeit_Top:5);
   GotoXY(15, Z_Start+7); Write (Flatop[2].Zeit_Wait:5);
   GotoXY(22, Z_Start+7); Write_Real_10V_Bipol (Flatop[2].Soll);
   GotoXY(33, Z_Start+7); Write (Hex_Word (Flatop[2].Soll));

   GotoXY(07, Z_Start+8); Write (Flatop[3].Zeit_Top:5);
   GotoXY(15, Z_Start+8); Write (Flatop[3].Zeit_Wait:5);
   GotoXY(22, Z_Start+8); Write_Real_10V_Bipol (Flatop[3].Soll);
   GotoXY(33, Z_Start+8); Write (Hex_Word (Flatop[3].Soll));
   GotoXY(13, Z_Start);   Write (Transf_Cnt:8);
   GotoXY(50, Z_Start+1); Write (Data_Set_Nr);             {aktiver Datensatz}
{   Disp_Flat_Active (0);  }
   Disp_R_H;

   Ch := ' ';
   if Ch = ' ' then
     begin
      Ini_Msg_Win;
      Write('Stop/Single Step mit <SPACE>, Loop mit <CR>, neue Adr mit <F10>   Ende mit [X]');
      repeat until KeyEPressed;
      Ch := NewReadKey;
      if  Ch in ['x','X'] then Goto 99;
     end;

   repeat
    repeat
      Set_Text_win;
      Transf_Cnt := Transf_Cnt+ 1;
      Flat_Top (1);
      Flat_Top (2);
      Flat_Top (3);
      Hist_Index := Hist_Index + 1;                 {gilt fÅr alle drei Flattops}
      if Hist_Index = Hist_Max + 1 then Hist_Index := 0;

      GotoXY(13, Z_Start);
      Write (Transf_Cnt:8);
    until KeyEPressed or (Ch = ' ');

    if Ch = ' ' then
      begin
       Flat_Top (1);
       Disp_Flat_Active (1);
   {    Flat_Zero;   }                           {Setze Magnet auf Sollwert 0}
   {    Disp_Flat_Active (0); }
       Disp_Hist_Ary (Transf_Cnt);                {Zeige letzte 10 Differenzwerte}
       Disp_R_H;
       Ini_Msg_Win;
       Write('Stop/Single Step mit <SPACE>, Loop mit <CR>, neue Adr mit <F10>   Ende mit [X]');
       repeat until KeyEPressed;
      end;
    Ch := NewReadKey;

   if Ch = #0 then
    begin
      Ch := NewReadKey;
      case ord (Ch) of
       Taste_F10: begin
                    New_Ifc_Adr;
                    Set_Text_Win;
                    GotoXY(49, Z_Start+0); Write (Hex_Byte(Ifc_Test_Nr));
                    Ini_Msg_Win;
                    Write('Stop/Single Step mit <SPACE>, Loop mit <CR>, neue Adr mit <F10>   Ende mit [X]');
                    repeat until KeyEPressed;
                    Ch := ' ';
                  end; {Taste_F10}
      end;  {Case}
    end;
    Clear_Hist_Disp;
   until Ch in ['x','X'];
99: Flat_Zero;                    {Setze Magnet auf Sollwert 0}
{    Disp_Flat_Active (0); }
 end; {Mil_NG_Puls_Fix}

const             {Konstanten dÅr Mag-Tab-Darstellung}
 Z_SW    = 22;
 S_Loop  = 7;
 S_RdErr = 9;
 S_SWH   = 23;   {Sollwert Hex}
 S_SWV   = 34;   {Sollwert Volt}
 S_SWA   = 52;   {Sollwert Ampere}
 S_SWX   = 73;   {Sollwert MaxAmpere}
 Sw_Amax: Real   = 0.0;     {MaxAmpere vorbesetzen}
{
type
 TSw_Mode= (V, H, A);  {Eingabe-Einheiten: Volt, Ampere, Hex
 TSw   = record
          Mode: TSw_Mode;
          Max : Real;
          User: Integer;
         end;        }


function Ask_Sw_Break (var SW : TSw): Boolean;    {wahlweise Volt, Hex, Amp}
 var  Real_Zahl : Real;     {Einlesen von User-Daten mit Abort Mîglichkeit!!}
      User_Hex  : Word;     {+/- 10V, 15 Bit mit Vorzeichen }
 begin
  Ask_Sw_Break := False;
  case SW.Mode of
   V : begin                          {+/- 10V, 15 Bit mit Vorzeichen}
          Ini_Msg_Win;
          Write('Spannung als Floating-Point Zahl oder <Q + CR> eingeb. [+/- 00.000]: ');
          {$I-}                    {Fehleingabe zulassen: Compiler-Check ausschalten}
          Readln (Real_Zahl);
          {$I+}
          if (IoResult <> 0) then              {Fehler selber abfangen!}
           begin
            Exit;
           end
          else
           begin
             Real_Zahl:=  Real_Zahl * SW.Fact;

             if abs (Real_Zahl) > Sw.Max then    {Absolutwert, weil +/- 10 Volt}
              begin
               Ini_Err_Win;
               Write('ERROR: +/- Sollwert grî·er als ',Sw.Max,' !   Weiter mit <CR>');
               ReadKey;
               Exit;
              end;
           end;

         if Real_Zahl > 9.999694825 then Real_Zahl := 9.999694825;
         Real_Zahl:= (Real_Zahl/305.1757813) * 1000000;
         Sw.User:= Round(Real_Zahl);         {Real-Zahl in Integer umwandeln}
         Ask_Sw_Break := True;
       end;

   A : begin      {Die Ampere-eingabe mu· auf den max. Wert normiert werden!!}
          Ini_Msg_Win;
          Write('Strom als Floating-Point Zahl oder <Q + CR> eingeb. [00000.0]: ');
          {$I-}                    {Fehleingabe zulassen: Compiler-Check ausschalten}
          Readln (Real_Zahl);
          {$I+}
          if (IoResult <> 0) then              {Fehler selber abfangen!}
           begin
            Exit;
           end
          else
           begin
             if abs (Real_Zahl) > Sw.Max then
              begin
               Ini_Err_Win;
               Write('ERROR: +/- Sollwert: ', Real_zahl:7:1,' grî·er als SW[Amax]: ',Sw.Max:7:1,' !   Weiter mit <CR>');
               ReadKey;
               Exit;
              end;
           end;

         if Real_Zahl > 0 then
           Real_Zahl := (Real_Zahl/Sw.Max) * 32767;
         if Real_Zahl < 0 then
           Real_Zahl := (Real_Zahl/Sw.Max) * 32768;
         Sw.User   := Round(Real_Zahl);         {Real-Zahl in Integer umwandeln}
         Ask_Sw_Break := True;
       end;

   H : begin
         if not (Ask_Hex_Break (User_Hex, Wrd)) then Exit
         else
          begin
           Sw.User      := Word(User_Hex);
           Ask_Sw_Break := True;
          end;
       end;
   end; {case}
 end; { Ask_Sw_Break }



 procedure Mil_Stat_Tabelle;  {Bits, die sich verÑndern werden farblich markiert}
  label 99;
  const
   Tab_Max = $15;

   Stat_Line =
       'Status-Bits                          MAGNETE    ' +
       '                    [11.05.1999]' +
       '                                Tabellen-öbersicht                             ';
   Zeile_Start  = 01;
   Spalte_Start = 01;
   Wait_Time    = 200000; {2 sec}
   SW_Plus      = $2000;  {+2,500 Volt}
   SW_Minus     = $E000;  {-2,500 Volt}
   Loop_Wait1: LongInt = 10000;  {0,10 sec}
   Loop_Wait2: LongInt = 100;
   Stat_Byte_Max= 2;
   Err_Bits_Max = 7;

  type
   TStat_Byte_Ary   = array [0..2] of Byte;
   TStat_Error_Byte = array [0..7] of Boolean;
   TStat_Error_Ary  = array [0..2] of TStat_Error_Byte;

  var
   Stat_Old_Bytes : TStat_Byte_Ary;
   Stat_Err_Ary   : TStat_Error_Ary;
   Loop_Wait      : LongInt;
   Read_Data,Fct_Code: Word;
   MilErr : TMilErr;
   Fct    : TFct;

   Tab_Nr    : Word;
   Zeile_Act : Byte;
   Spalte_Act: Byte;
   Data_Act  : Byte;
   Mode_Act  : Boolean;
   Byte_Act  : Byte;     {aktuelle Daten-Byte Nr}
   transf_cnt: LongInt;
   timout_cnt: LongInt;
   Ch        : Char;
   LastNr    : Byte;
   IW1, IW2  : Integer;
   First_Online: Byte;
   N,M       : Word;
   RetAdr    : Byte;
   OnlineErr : TOnlineErr;
   SW_Act    : Integer;
   SW_Valid  : Boolean;
   Sonder_Zeichen : Char;
   Stat_Valid: Boolean; {FehlerprÅfung nur nach dem 1. Lesen von 3 Status-Bytes}
   Stat_Init : Boolean;
   Err_Stat_Intrl: Boolean;
   Interl_Old    : Boolean;
   Interl_Ini    : Boolean;
   Adress        : Word;
   Displ_counter : Word;
   Single_Step   : Boolean;
   Sollw         : TSw;
   R_Zahl        : Real;
   Rampe_On      : Boolean;


 procedure Life_Sign (Mode: TLife);
  const S_Aktiv   = 7;
        Z_Aktiv   = 21;
        Life_Time1 = 5000;
        Life_Time2 = 2000;

  var Life_Wait : LongInt;
      Loop_Wait : LongInt;

  begin
    Cursor(False);
    Set_Text_Win;
    if Mode = Norm then
     begin
      If Loop_Wait = Loop_Wait1 then Life_Wait := Life_Time1
      else  Life_Wait := Life_Time2;
      Set_Text_Win;
      TextColor(Yellow);
      GotoXY(S_Aktiv, Z_Aktiv);  Write (chr($7C)); Mil.Timer2_Wait (Life_Wait);
      GotoXY(S_Aktiv, Z_Aktiv);  Write ('/');      Mil.Timer2_Wait (Life_Wait);
      GotoXY(S_Aktiv, Z_Aktiv);  Write (chr($2D)); Mil.Timer2_Wait (Life_Wait);
      GotoXY(S_Aktiv, Z_Aktiv);  Write ('\');      Mil.Timer2_Wait (Life_Wait);
      TextColor(Black);
     end
    else
     begin
       TextColor(Red+128);
       GotoXY(S_Aktiv, Z_Aktiv); Write (chr($DB));
       TextColor(Black);
     end;
   end; {Life_Sign}

type
 TSpeed     = (Slow, Medium, Fast);

const
 Fct_SW1 = $06;
 Fct_SW3 = $08;
 Fct_SW4 = $09;

 Sw1_Slow = $1000;     {Anfangsbedingung}
 Sw3_Slow = $1000;     {+10V=1.. Steigung oder-10V = F..}
 Sw4_Slow =   $30;     {Frequenz}
 Sw1_Fast = $1000;     {}
 Sw3_Fast = $1000;     {}
 Sw4_Fast =   $38;     {}

var
 Sw1, Sw3, Sw4 : Word;

procedure Start_Rampe;
 begin
   Fct.B.Adr := Ifc_Test_Nr;
   Fct.B.Fct := Fct_Reset;
   Mil.WrFct (Fct, MilErr);
   Fct.B.Fct := Fct_SW4;
   Mil.Wr (Sw4, Fct, MilErr);
   Fct.B.Fct := Fct_SW1;
   Mil.Wr (Sw1, Fct, MilErr);
   Fct.B.Fct := Fct_SW3;
   Mil.Wr (Sw3, Fct, MilErr);
 end;

procedure Stop_Rampe;
 begin
   Fct.B.Adr := Ifc_Test_Nr;
   Fct.B.Fct := Fct_Reset;
   Mil.WrFct (Fct, MilErr);
 end;

 procedure Write_Real_10A_Bipol (Data: Word);
  var Real_Zahl : Real;
      Int_Zahl  : Integer;
      Vorzeichen : Char;
 begin                        {Bit 15 ist Vorzeichen}
   if (Data and $8000) = 0 then
    begin     {positiv}
      Real_Zahl := Data * (Sw_Amax/32768);
      Vorzeichen:= '+';
    end
   else
    begin     {negativ}
      Data := (not Data) + 1;               {Zweier Komplement}
      Real_Zahl := Data * (Sw_Amax/32768);
      Vorzeichen:= '-';
   end;
   Write (Vorzeichen, Real_Zahl:9:3);
 end;

 procedure FG_Rampe_Fix (Speed: TSpeed);
  label 99;

  begin
   case Speed of
    Slow : begin
             Sw1:= Sw1_Slow;
             Sw3:= Sw3_Slow;
             Sw4:= Sw4_Slow;
           end;
    Fast : begin
             Sw1:= Sw1_Fast;
             Sw3:= Sw3_Fast;
             Sw4:= Sw4_Fast;
           end;
   end;  {case}
   Start_Rampe;
 end; {FG_Rampe_Fix}

  procedure Displ_Stat_Bits (D_Spalte, D_Zeile, D_Byte:Byte; D_Mode: Boolean; Byte_Index: Byte);
   var Idx : Byte;
       Blink_Offset: Byte;
   begin
    Blink_Offset := 0;
    Set_Text_Win;
    if D_Mode = False then                   {Fehler beim Datenlesen: Lîsche}
     begin
      for Idx := 0 to 7 do
       begin
         GotoXY(D_Spalte, D_Zeile);
         TextColor(Red);
         Write ('F');
         D_Zeile := D_Zeile + 1;
       end;
     end
    else
     begin                       {kein Fehler beim Datenlesen: Bits anzeigen!}
      for Idx := 0 to 7 do
       begin
        Blink_Offset := 0;
        GotoXY(D_Spalte, D_Zeile);

       {Vergleiche alte Statusbits mit neuem Wert, bei énderung Error-Bit setzen}
       {Falls neues Bit=1 and altes Bit=0, oder neues Bit=0 and altes Bit=1}
       if Stat_Valid then     {nur wenn Vergleichsdaten vorliegen: auswerten}
        begin
         if not (((BitTst(D_Byte,Idx) and BitTst(Stat_Old_Bytes[Byte_Index],Idx)))
                or
                (not BitTst (D_Byte,Idx) and not BitTst(Stat_Old_Bytes[Byte_Index],Idx)))
         then Stat_Err_Ary[Byte_Index,Idx] := True;
         if Stat_Err_Ary[Byte_Index,Idx] then Blink_Offset := 128;
        end;

       if BitTst (D_Byte, Idx) then
        begin
          TextColor(Blue+Blink_Offset);
          Write ('1');                      {kein Fehler}
        end
       else
        begin
          TextColor(Red+Blink_Offset);      {Fehler}
          Write ('0');
        end;  {Bit 0/1}

       D_Zeile := D_Zeile + 1;
      end;   {for}
    Stat_Old_Bytes[Byte_Index] := D_Byte; {Save neuen Wert zum nÑchsten Vergleich}
    if Byte_Index=Stat_Byte_Max then Stat_Valid:=True; {Vergleich erst, wenn 3x8Bit gespeichert}
   end; {D_Mode}
 end; {Displ_Stat_Bits}

   procedure Ini_Stat_Win;
   begin                             {Definitionen gelten bis neu definiert}
    Window(1, 1, 80, 2);             {Definiert ein Textfenster: Spalte/Zeile}
    TextBackground(Magenta);         {Setze Hintergrund fÅr Textfenster}
    TextColor(Yellow);               {Setze Schriftfarbe}
    ClrScr;                          {Clear Window}
    GotoXY(1, 1);                    {Cursor auf Anfang Fenster}
   end;

  procedure Slow_Key;
   var Zeichen : Char;
   begin
     repeat
      if KeyEpressed then
       begin
         Zeichen := NewReadKey;
         if Zeichen = #0 then Zeichen :=NewReadKey;
       end;
     until not KeyEpressed;
   end;

 procedure Displ_FTasten;
  begin
   Set_TastMag_Win;
   TextColor(Yellow);
   GotoXY(01, 01); Write('F1:Res ', 'F4:Last   ', 'F7:SW 0.0   ', 'F10:Adr  ');
   GotoXY(01, 02); Write('F2:Ein ', 'F5:+/-    ', 'F8:SW V/A/H ', 'F11:Quick');
   GotoXY(01, 03); Write('F3:Aus ', 'F6:SW 5.0 ', 'F9:FG Rampe ', 'F12:Init');
   TextColor(Black);
   Set_Text_Win;
  end;

  procedure Ini_Stat_Ary;
   var N, M : Word;
   begin
     for N := 0 to Stat_Byte_Max do
      begin
       Stat_Old_Bytes[N] := 0;
       for M := 0 to Err_Bits_Max do Stat_Err_Ary[N,M] := False;
      end;
   end;

 procedure Run_Tab (Tab_Num: Word);
  begin
     case Tab_Num of
       1 : Status_Tab1  (Spalte_Start, Zeile_Start);
       2 : Status_Tab2  (Spalte_Start, Zeile_Start);
       3 : Status_Tab3  (Spalte_Start, Zeile_Start);
       4 : Status_Tab4  (Spalte_Start, Zeile_Start);
       5 : Status_Tab5  (Spalte_Start, Zeile_Start);
       6 : Status_Tab6  (Spalte_Start, Zeile_Start);
       7 : Status_Tab7  (Spalte_Start, Zeile_Start);
       8 : Status_Tab8  (Spalte_Start, Zeile_Start);
       9 : Status_Tab9  (Spalte_Start, Zeile_Start);
      $A : Status_TabA  (Spalte_Start, Zeile_Start);
      $B : Status_TabB  (Spalte_Start, Zeile_Start);
      $C : Status_TabC  (Spalte_Start, Zeile_Start);
      $D : Status_TabD  (Spalte_Start, Zeile_Start);
      $E : Status_TabE  (Spalte_Start, Zeile_Start);
      $F : Status_TabF  (Spalte_Start, Zeile_Start);
      $10: Status_Tab10 (Spalte_Start, Zeile_Start);
      $11: Status_Tab11 (Spalte_Start, Zeile_Start);
      $12: Status_Tab12 (Spalte_Start, Zeile_Start);
      $13: Status_Tab13 (Spalte_Start, Zeile_Start);
      $14: Status_Tab14 (Spalte_Start, Zeile_Start);
      $15: Status_Tab15 (Spalte_Start, Zeile_Start);
    end; {case}
  end; {Run_Tab}

 procedure Status_Disp;
   var TempW:Word;

  begin
     Set_Text_win;
     if(FairBusUse = false) then begin
      Fct.B.Fct := Fct_Rd_Stat0;   { Lese C0-Status und zeige in bitweise an }
      Mil.Rd (read_data, Fct, MilErr);
     end else begin
       Mil.Rd_FairBus(read_data, Fair_Fct_Rd_Stat0, Fct.B.Adr, FairSVNr, MilErr);
       read_data:= read_data + Fct.B.Adr;
     end;

     if MilErr <> No_Err then
      begin
        Mode_Act   := False;
        Timout_Cnt := Timout_Cnt +1;
      end
     else
      begin  {kein Timeout}
        Mode_Act := True;
        {Hier ÅberprÅfen, ob IFK-Return-Adr = Solladr! Tîdlicher Fehler!!}
        if Lo (Read_Data) <> Lo (Fct.B.Adr) then
         begin
           Ini_Err_Win;
           Write ('ERROR: Antwort v. falscher IFK-Adr!  '); TextColor(Yellow+128);
           Write('Soll: ', Hex_Byte(Fct.B.Adr),'[H]  Ist: ', Hex_Byte(Lo(Read_Data)),'[H]');
           TextColor(Red); Write ('  [W]eiter E[x]it');
           repeat
            repeat until KeyEPressed;
             begin
              Ch := NewReadKey;
              if Ch in  ['x','X'] then Exit;
              if Ch = #0 then
               begin
                 Ch := NewReadKey;
                 case ord (Ch) of
                   Taste_F10: begin
                                Slow_Key;
                                if Ask_Hex_Break (Adress, Byt) then
                                  begin
                                   Ifc_Test_Nr := Adress;
                                   Fct.B.Adr   := Ifc_Test_Nr;
                                   Ini_Stat_Win;
                                   Write(Stat_Line);
                                   Run_Tab (Tab_Nr);
                                   Std_Msg;
                                  end;
                              end; {Taste_F10}
                 end; {case}
                end; {Ch=0}
             end;
           until Ch in ['w','W'];
           Std_Msg;
         end;
        Data_Act := Read_Data shr 8;
      end;

{xxx Data_Act := $A5; testweise}
     Byte_Act  := 0;                 {Byte-Markierung}
     Zeile_Act := 01;
     Spalte_Act:= 02;
     Displ_Stat_Bits (Spalte_Act,  Zeile_Act, Data_Act, Mode_Act, Byte_Act);

                { Lese C1-Status und zeige in bitweise an }
     if(FairBusUse = false) then begin
      Fct.B.Fct := Fct_Rd_Stat1;
      Mil.Rd (read_data, Fct, MilErr);
     end else begin
      Mil.Rd_FairBus(read_data, Fair_Fct_Rd_Stat1, Fct.B.Adr, FairSVNr, MilErr);
      read_data:= read_data + Fct.B.Adr;
     end;

     if MilErr <> No_Err then
      begin
        Mode_Act := False;
        Timout_Cnt := Timout_Cnt +1;
      end
     else
      begin  {kein Timeout}
        Mode_Act := True;
        {Hier ÅberprÅfen, ob IFK-Return-Adr = Solladr! Tîdlicher Fehler!!}
        if Lo (Read_Data) <> Lo (Fct.B.Adr) then
         begin
           Ini_Err_Win;
           Write ('ERROR: Antwort v. falscher IFK-Adr!  '); TextColor(Yellow+128);
           Write('Soll: ', Hex_Byte(Fct.B.Adr),'[H]  Ist: ', Hex_Byte(Lo(Read_Data)),'[H]');
           TextColor(Red); Write ('  [W]eiter E[x]it');
           repeat
            repeat until KeyEPressed;
             begin
              Ch := NewReadKey;
              if Ch in  ['x','X'] then Exit;
              if Ch = #0 then
               begin
                 Ch := NewReadKey;
                 case ord (Ch) of
                   Taste_F10: begin
                                Slow_Key;
                                if Ask_Hex_Break (Adress, Byt) then
                                  begin
                                   Ifc_Test_Nr := Adress;
                                   Fct.B.Adr   := Ifc_Test_Nr;
                                   Ini_Stat_Win;
                                   Write(Stat_Line);
                                   Run_Tab (Tab_Nr);
                                   Std_Msg;
                                  end;
                              end; {Taste_F10}
                 end; {case}
                end; {Ch=0}
             end;
           until Ch in ['w','W'];
           Std_Msg;
         end;
        Data_Act := Read_Data shr 8;
      end;
    Byte_Act  := 1;                 {Byte-Markierung}
    Zeile_Act := 10;
    Spalte_Act:= 02;
    Displ_Stat_Bits (Spalte_Act,  Zeile_Act, Data_Act, Mode_Act, Byte_Act);

                { Lese C2-Status und zeige in bitweise an }

     if(FairBusUse = false) then begin
      Fct.B.Fct := Fct_Rd_Stat2;
      Mil.Rd (read_data, Fct, MilErr);
     end else begin
       Mil.Rd_FairBus(read_data, Fair_Fct_Rd_Stat2, Fct.B.Adr, FairSVNr, MilErr);
       read_data:= read_data + Fct.B.Adr;
     end;

     if MilErr <> No_Err then
      begin
        Mode_Act := False;
        Timout_Cnt := Timout_Cnt +1;
      end
     else
      begin  {kein Timeout}
        Mode_Act := True;
        {Hier ÅberprÅfen, ob IFK-Return-Adr = Solladr! Tîdlicher Fehler!!}
        if Lo (Read_Data) <> Lo (Fct.B.Adr) then
         begin
           Ini_Err_Win;
           Write ('ERROR: Antwort v. falscher IFK-Adr!  '); TextColor(Yellow+128);
           Write('Soll: ', Hex_Byte(Fct.B.Adr),'[H]  Ist: ', Hex_Byte(Lo(Read_Data)),'[H]');
           TextColor(Red); Write ('  [W]eiter E[x]it');
           repeat
            repeat until KeyEPressed;
             begin
              Ch := NewReadKey;
              if Ch in  ['x','X'] then Exit;
              if Ch = #0 then
               begin
                 Ch := NewReadKey;
                 case ord (Ch) of
                   Taste_F10: begin
                                Slow_Key;
                                if Ask_Hex_Break (Adress, Byt) then
                                  begin
                                   Ifc_Test_Nr := Adress;
                                   Fct.B.Adr   := Ifc_Test_Nr;
                                   Ini_Stat_Win;
                                   Write(Stat_Line);
                                   Run_Tab (Tab_Nr);
                                   Std_Msg;
                                  end;
                              end; {Taste_F10}
                 end; {case}
                end; {Ch=0}
             end;
           until Ch in ['w','W'];
           Std_Msg;
         end;
        Data_Act := Read_Data shr 8;
      end;
    Byte_Act  := 2;                 {Byte-Markierung}
    Zeile_Act := 01;
    Spalte_Act:= 43;
    Displ_Stat_Bits (Spalte_Act,  Zeile_Act, Data_Act, Mode_Act, Byte_Act);

    Life_Sign (Norm);
    TextColor(Black);
    GotoXY (S_RdErr,Z_SW); Write (Timout_Cnt:7);

            {Lese Summeninterlock aus dem Status-Reg. der IFC}
    Set_Text_Win;
    GotoXY(43, 10); Write ('SUM-IL intern (0-aktiv): ');
    Fct.B.Adr := Ifc_Test_Nr;
    Fct.B.Fct := Fct_Rd_Status;
    Mil.Rd (Read_Data, Fct, MilErr);
    if MilErr = No_Err then
     begin                   {énderung des Intrl-Status: mit blink markieren!!}
      if BitTst (Read_Data, 12) then              {Interlock?}
       begin                  {Kein Interlock!!}
        TextColor(Blue);
        if not Interl_Ini then
         begin
          if Interl_Old then  Err_Stat_Intrl:= True;   {vorher war Interlock}
         end;
        If Err_Stat_Intrl then TextColor(Blue+128);    {blinken}
        write(' 1 ');
        Interl_Old := False;
        Interl_Ini := False;  {Nach dem 1. Durchlauf bleibt Status False}
       end
      else
       begin                        {Ja, Interlock-Fall}
         TextColor(Red);
         if not Interl_Ini then
          begin
           if not Interl_Old then Err_Stat_Intrl:= True;  {vorher kein Interl}
          end;
         if Err_Stat_Intrl then TextColor(Red+128);       {mit blinekn}
         write(' 0 ');
         Interl_Old := True;
         Interl_Ini := False;  {Nach dem 1. Durchlauf bleibt Status False}
       end;
     end
    else
     begin
       write('   ');
     end;

    Sonder_Zeichen := chr(124);  {Absolut Zeichen}
    TextColor(Black);

    {Zeige stÑndig auch den Istwert}
    Set_IstwMag_Win;
    TextColor(Brown);
    GotoXY(01, 01); Write ('ISTWERT ->  ');
    GotoXY(13, 01); Write ('IW1 [',hex_byte(Fct_Rd_Ist1),'H]');
    Write ('      IW2 [',hex_byte(Fct_Rd_Ist2),'H]');
    GotoXY(01, 02); Write ('[Hex] : '); ClrEol;
    GotoXY(01, 03); Write ('[Volt]: '); ClrEol;
    GotoXY(01, 04); Write (Sonder_Zeichen);  Write ('Hex-Diff');
                    Write (Sonder_Zeichen);  Write (': '); ClrEol;
    GotoXY(01, 05); Write ('IW1-SW [V]: ');  ClrEol;
    TextColor(Black);

    {Sende Conversion Command: Neu 040199 ; wenn 2 ADC`s: nur 1 Convert-Cmd}
    if(FairBusUse = false) then begin
     Fct.B.Fct := Fct_Start_Conv;
     Mil.WrFct (Fct, MilErr);
    end else begin
     Mil.Wr_FairBusFct(Fair_Fct_Start_Conv, Fct.B.Adr, FairSvNr, MilErr);
    end;

    Mil.Timer2_Wait (ADC_Conv_Wait);
{xxx}
    if(FairBusUse = false) then begin
     Fct.B.Fct := Fct_Rd_Ist1;
     TempW:= IW1;
     Mil.Rd (TempW, Fct, MilErr);      {Lese Istwert1}
     IW1:=TempW;
    end else begin
     TempW:= IW1;
     Mil.Rd_FairBus(TempW, Fair_Fct_Rd_Ist1, Fct.B.Adr, FairSvNr, MilErr);
     IW1:=TempW;
    end;

    if MilErr = No_Err then
     begin
       if(FairBusUse = false) then begin
        Fct.B.Fct := Fct_Rd_Ist2;
        TempW:= IW2;
        Mil.Rd (TempW, Fct, MilErr);   {Lese Istwert2}
        IW2:=TempW;
       end else begin
        TempW:=IW2;
        Mil.Rd_FairBus(TempW, Fair_Fct_Rd_Ist2, Fct.B.Adr, FairSvNr, MilErr);
        IW2:=TempW;
       end;

       GotoXY(15, 02);         Write (Hex_Word(IW1));
       Write ('           ');  Write (Hex_Word(IW2));

       GotoXY(13, 03);
       if (FairBusUse = false) then begin
        Write_Real_10V_Bipol (IW1);
        Write ('     ');
        Write_Real_10V_Bipol (IW2);
       end else begin
        Write_RealFac_10V_Bipol (IW1,RdBack_Factor,9,6);
        Write ('     ');
        Write_RealFac_10V_Bipol (IW2,RdBack_Factor,9,6);
       end;


       GotoXY(15, 04);
       if SW_Valid = True then begin
          Write (Hex_Word (abs(IW1-SW_Act)));
          GotoXY(13, 05);

          if(FairBusUse = false) then Write_Real_10V_Bipol(IW1-SW_Act)
          else Write_RealFac_10V_Bipol(IW1-SW_Act, RdBack_Factor,9,6);

       end; {no error}  {Ende: Set_IstwMag_Win;}
    end;

    Set_Text_Win;
    TextColor(Black);

    if SW_Valid then
     begin
       GotoXY (S_SWH,  Z_SW); Write (Hex_Word(SW_Act));
       GotoXY (S_SWV,  Z_SW);
       if (FairbusUse = false)  then Write_Real_10V_Bipol (SW_Act)
       else Write_RealFac_10V_Bipol(SW_Act, RdBack_Factor,9,3);
     end
    else
     begin
       GotoXY (S_SWH,  Z_SW); Write ('    ');
       GotoXY (S_SWV,  Z_SW); Write ('         ');
     end;

    if Sw_Amax = 0 then
     begin
       GotoXY (S_SWA,  Z_SW); Write('         ');
       GotoXY (S_SWX,  Z_SW); Write(' undef.');
     end
    else
     begin
       GotoXY (S_SWA,  Z_SW); Write_Real_10A_Bipol (SW_Act);
       GotoXY (S_SWX,  Z_SW); Write (Sw_Amax:7:1);
     end;

    Std_Msg;
    Set_Text_Win;
    Mil.Timer2_Wait (Loop_Wait);
  end; {Status_Disp}

 procedure Tab_Auswahl1;
  begin
  Set_Text_Win;
  GotoXY(01, 03);
  Write   ('    01 : SIS-Magnete SVE (JÑger) ');  Write ('['); TextColor (Red);
                                          Write('Standard');   TextColor (Black);  Writeln (']');
  Writeln ('    02 : Tekelec-Umlenker   (grÅn) EH-Keller (MU) ');
  Writeln ('    03 : Tekelec-NetzgerÑte (grÅn) LSB4          ');
  Writeln ('    04 : Danfysik-NetzgerÑte EH- u. HLI-Keller   ');
  Writeln ('    05 : AEG SVE 1:  SIS                         ');
  Writeln ('    06 : AEG SVE 2:  SIS                         ');
  Writeln ('    07 : AEG SVE 1, 2, 3:     ESR                ');
  Writeln ('    08 : SVE 5, 6, 7, 10, 12: ESR                ');
  Writeln ('    09 : SVE 4, 9:            ESR                ');
  Writeln ('    0A : SVE 2 - H; 3 - H                        ');
  Writeln ('    0B : SVE Brucker mit Einschub                ');
  Writeln ('    0C : SVE Brucker 8-Bit-Stat (Steerer H,V usw)');
  Writeln ('    0D : EZR-MV (Microwelle)                     ');
  Writeln ('    0E : Hochspannung                            ');
  Writeln ('    0F : HF: SIS + ESR                           ');
  Writeln ('    10 : 8-Bit-Status o. Schaltkarte             ');
  Writeln ('    11 : Phasensonden (DPX)                      ');
  Writeln ('    12 : SIS-Magnet S11MU3R (JÑger)              ');
  Writeln ('    13 : SIS + ESR mit DAC (Fîldi)               ');

  GotoXY(05, 22); TextColor(Brown);
  Write ('Bitte Status-Tabelle auswÑhlen  bzw. <CR> fÅr nÑchste Liste! ');
  GotoXY(50, 08);  write('Belegung Funktionstasten: '); TextColor(Black);
  Displ_FTasten_Liste;
  end; {Tab_Auswahl1}

 procedure Tab_Auswahl2;
  begin
  Set_Text_Win;
  GotoXY(01, 03);
  Writeln ('    14 : 15-kV Chopper                           ');
  Writeln ('    15 : UNILAC HIS-Magnete SVE 21..38U (JÑger)  ');
  Writeln ('    16 : frei                                    ');
  Writeln ('                                                 ');
  Writeln ('                                                 ');
  Writeln ('                                                 ');
  Writeln ('                                                 ');
  Writeln ('                                                 ');
  Writeln ('                                                 ');
  Writeln ('                                                 ');
  Writeln ('                                                 ');
  Writeln ('                                                 ');
  Writeln ('                                                 ');
  Writeln ('                                                 ');
  Writeln ('                                                 ');
  Writeln ('                                                 ');
  Writeln ('                                                 ');
  Writeln ('                                                 ');
  Writeln ('                                                 ');

  GotoXY(05, 22); TextColor(Brown);
  Write ('Status-Tabelle wÑhlen,   mit <CR> zurÅck oder Ende mit <00>: ');
  GotoXY(50, 08);  write('Belegung Funktionstasten: '); TextColor(Black);
  Displ_FTasten_Liste;
  end; {Tab_Auswahl1}



 begin                 {Ab hier: MainBody Mil_Stat_Tab}
  Cursor(False);
  Stat_Valid    := False;  {Noch kein Status gelesen}
  Interl_Old    := False;
  Interl_Ini    := True;   {Interlock-Status ist im INIT-Mode}
  Err_Stat_Intrl:= False;
  Single_Step   := True;
  SW_Act        := 0;

  {FairBusUse := true;}
  FairSvNr      := 1;
  RdBack_Factor := 1.1; {Der skalierungsfactor,er wird beim fairbus benutz}
                        {Beim ruecklesen der werte wir dieser wert mit dem}
                        {factor multipliziert}

  Ini_Stat_Ary;         {Init Status-Error-Bits und Status-Old-Arrray}
  GotoXY(Spalte_Start+01, Zeile_Start);
  Mil_Ask_Ifc;
  Fct.B.Adr := Ifc_Test_Nr;
  Mil_Ask_Fair;         {Abfrage ueber Fair bus oder was ?}

  if(FairBusUse = true) then Sollw.Fact:= 10/11
  else Sollw.Fact:= 1;  {Abgleich Digitale GerÑte (Werkmann)}

  Ini_Stat_Win; Write(Stat_Line);
  Ini_Text_Win; TextColor(Brown);
  GotoXY(07, 01); Write ('Tabellen mit Belegungen der STATUS-Bits fÅr Funktionscodes C0, C1, C2 ');
  TextColor(Yellow);
  GotoXY(07, 02); Write ('Hinweis: Die Bit-Anzeige 0/1 wird ROT, falls der Status sich Ñndert!! ');
  TextColor(Black);

  repeat               {Solange wiederholen, bis Zahl eingegeben wird}
    Tab_Auswahl1;
    if not (Ask_Hex_Break (Tab_Nr, Byt)) then
     begin
      Tab_Nr := $FF;
      Tab_Auswahl2;
      if not (Ask_Hex_Break (Tab_Nr, Byt)) then;
     end;
    if Tab_Nr in [1..Tab_Max] then Run_Tab (Tab_Nr);
  until (Tab_Nr in [1..Tab_Max]) or (Tab_Nr=0);

  if (Tab_Nr=0) then Exit;
  TextColor(Black);
  Ini_IstwMag_Win;
  Ini_TastMag_Win;
  Transf_Cnt  := 0;
  Timout_Cnt  := 0;
  SW_Valid    := False;           {User hat noch keinen Sollwert definiert}
  Loop_Wait   := Loop_Wait1;
  Rampe_On    := False;
  Single_Step := True;
  Displ_FTasten;
  Set_Text_win;
  Std_Msg;

  repeat
   if KeyEPressed then Ch := NewReadKey;
   if Ch = ' ' then
     begin
      Status_Disp;
      Std_Msg;
      Life_Sign (Blinc);
      repeat until KeyEPressed;
       Single_Step := True;
     end;
   if Ch = Taste_Return then Single_Step := False;
   if not Single_Step then Status_Disp;
   if Ch = #0 then
    begin
      Ch := NewReadKey;
      case ord (Ch) of
       Taste_F1 : begin
                   Slow_Key;

                   if(FairBusUse = false) then begin
                    Fct.B.Fct := Fct_Reset;
                    Mil.WrFct (Fct, MilErr);
                   end else begin
                    Mil.Wr_FairBusFct(Fair_Fct_Reset, Fct.B.Adr, FairSvNr, MilErr);
                    Mil.Wr_FairBus(Fair_Clear_PuReg, Fair_Fct_Wr_InlReg, Fct.B.Adr, FairSvNr, MilErr);
                   end;

                   Ini_Err_Win;
                   Write(' RESET');
                   Mil.Timer2_Wait(Wait_Time);          { Wartet mit Timer2}
                   Rampe_On := False;
                  end;
       Taste_F2 : begin
                   Slow_Key;
                   if(FairBusUse = false) then begin
                    Fct.B.Fct := Fct_NG_Ein;
                    Mil.WrFct (Fct, MilErr);
                   end else begin
                    Mil.Wr_FairBusFct(Fair_Fct_NG_Ein, Fct.B.Adr, FairSvNr, MilErr);
                   end;

                   Ini_Err_Win;
                   Write(' EIN');
                   Mil.Timer2_Wait(Wait_Time);          { Wartet mit Timer2}
                  end;
       Taste_F3 : begin
                   Slow_Key;

                   if(FairBusUse = false) then begin
                    Fct.B.Fct := Fct_NG_Aus;
                    Mil.WrFct (Fct, MilErr);
                   end else begin
                    Mil.Wr_FairBusFct(Fair_Fct_NG_Aus, Fct.B.Adr, FairSvNr, MilErr);
                   end;

                   Ini_Err_Win;
                   Write(' AUS');
                   Mil.Timer2_Wait(Wait_Time);          { Wartet mit Timer2}
                 end;
       Taste_F4 : begin
                   Slow_Key;
                   if Get_LastNr (LastNr) then
                    begin
                     if(FairBusUse = false) then begin
                      case LastNr of
                        0 : Fct.B.Fct := Fct_NG_Last0;
                        1 : Fct.B.Fct := Fct_NG_Last1;
                        2 : Fct.B.Fct := Fct_NG_Last2;
                        3 : Fct.B.Fct := Fct_NG_Last3;
                        4 : Fct.B.Fct := Fct_NG_Last4;
                        5 : Fct.B.Fct := Fct_NG_Last5;
                      end;
                     end else begin
                      case LastNr of
                        0 : FairFCT := Fair_Fct_NG_Last0;
                        1 : FairFCT := Fair_Fct_NG_Last1;
                        2 : FairFCT := Fair_Fct_NG_Last2;
                        3 : FairFCT := Fair_Fct_NG_Last3;
                        4 : FairFCT := Fair_Fct_NG_Last4;
                        5 : FairFCT := Fair_Fct_NG_Last5;
                      end;
                     end;

                     if(FairBusUse = false) then begin
                      Mil.WrFct (Fct, MilErr);
                     end else begin
                      Mil.Wr_FairBusFct(FairFCT, Fct.B.Adr, FairSvNr, MilErr);
                     end;

                     Ini_Err_Win;
                     Write(' LAST-Nr: ',LastNr);
                     Mil.Timer2_Wait(Wait_Time);          { Wartet mit Timer2}
                    end;
                   Std_Msg;
                  end;
       Taste_F5 : begin
                   Ini_Msg_Win;
                   Write ('Bitte PolaritÑt eingeben [+/-] : ');
                   Ch := NewReadKey;
                   case Ch of
                   '+' : begin
                          Slow_Key;

                          if(FairBusUse = false) then begin
                           Fct.B.Fct := Fct_NG_Plus;
                           Mil.WrFct (Fct, MilErr);
                          end else begin
                           Mil.Wr_FairBusFct(Fair_Fct_NG_Plus, Fct.B.Adr, FairSvNr,MilErr);
                          end;

                          Ini_Err_Win;
                          Write(' PLUS');
                          Mil.Timer2_Wait(Wait_Time);          { Wartet mit Timer2}
                         end;
                   '-' : begin
                          Slow_Key;

                          if(FairBusUse = false) then begin
                           Fct.B.Fct := Fct_NG_Minus;
                           Mil.WrFct (Fct, MilErr);
                          end else begin
                           Mil.Wr_FairBusFct(Fair_Fct_NG_Minus, Fct.B.Adr, FairSvNr, MilErr);
                          end;

                          Ini_Err_Win;
                          Write(' MINUS');
                          Mil.Timer2_Wait(Wait_Time);          { Wartet mit Timer2}
                         end;
                    end; {case}
                   Std_Msg;
                  end;
       Taste_F6 : begin
                   Slow_Key;

                   if(FairBusUse = false) then begin
                    Fct.B.Fct :=  Fct_Wr_Sw1;
                    Mil.Wr ($4000 , Fct, MilErr);

                    Fct.B.Fct :=  Fct_Wr_Sw2;   {190399 wegen Zwischenspeicher}
                    Mil.Wr ($4000 , Fct, MilErr);
                    SW_Act := $4000;
                   end else begin
                    Mil.Wr_FairBus($3A2F, Fair_Fct_Wr_Sw1, Fct.B.Adr, FairSvNr, MilErr);
                    Mil.Wr_FairBus($3A2F, Fair_Fct_Wr_Sw2, Fct.B.Adr, FairSvNr, MilErr);
                    SW_Act := $3A2F;
                   end;


                   SW_Valid := True;
                  end; {Taste_F6}
       Taste_F7 : begin
                   Slow_Key;

                   if(FairBusUse = false) then begin
                    Fct.B.Fct :=  Fct_Wr_Sw1;
                    Mil.Wr (0 , Fct, MilErr);

                    Fct.B.Fct :=  Fct_Wr_Sw2;
                    Mil.Wr (0 , Fct, MilErr);      {190399 wegen Zwischenspeicher}
                   end else begin
                    Mil.Wr_FairBus($0000, Fair_Fct_Wr_Sw1, Fct.B.Adr, FairSvNr, MilErr);
                    Mil.Wr_FairBus($0000, Fair_Fct_Wr_Sw2, Fct.B.Adr, FairSvNr, MilErr);
                   end;

                   SW_Act := 0;
                   SW_Valid := True;
                  end;

       Taste_F8 : begin
                   Slow_Key;
                    Cursor(True);
                    Ini_Msg_Win;
                    Write ('Sollwert in [V]olt, [H]ex, [A]mpere, [M]axAmp        Bitte Auswahl eingeben: ');
                    repeat until KeyEPressed;
                    Ch := NewReadKey;
                    case Ch of
                     'v','V': begin
                                Sollw.Mode:= V;
                                Sollw.Max := 10.0;
                                if Ask_Sw_Break (Sollw) then
                                 begin
                                  SW_Act := Sollw.User;
                                  if(FairBusUse = false) then begin
                                   Fct.B.Fct :=  Fct_Wr_Sw1;
                                   Mil.Wr (SW_Act , Fct, MilErr);

                                   Fct.B.Fct :=  Fct_Wr_Sw2;  {190399 wegen Zwischenspeicher}
                                   Mil.Wr (SW_Act , Fct, MilErr);
                                  end else begin
                                   Mil.Wr_FairBus(SW_Act, Fair_Fct_Wr_Sw1, Fct.B.Adr, FairSvNr, MilErr);
                                   Mil.Wr_FairBus(SW_Act, Fair_Fct_Wr_Sw2, Fct.B.Adr, FairSvNr, MilErr);
                                  end;
                                  SW_Valid := True;
                                 end;
                              end;
                     'a','A': begin
                              if(FairBusUse = false) then begin
                               if Sw_Amax = 0 then
                                begin
                                  Ini_Err_Win;
                                  Write('Achtung: max. Stromsollwert nicht definiert!!   Weiter mit <CR> ');
                                  Ch := NewReadKey;
                                  Ch := '=';   {Dummy}
                                 end
                               else
                                 begin
                                  Sollw.Mode:= A;
                                  Sollw.Max := Sw_Amax;
                                  if Ask_Sw_Break (Sollw) then
                                   begin
                                    SW_Act := Sollw.User;
                                    Fct.B.Fct :=  Fct_Wr_Sw1;
                                    Mil.Wr (SW_Act , Fct, MilErr);

                                    Fct.B.Fct :=  Fct_Wr_Sw2;  {190399 wegen Zwischenspeicher}
                                    Mil.Wr (SW_Act , Fct, MilErr);

                                    SW_Valid := True;
                                   end;
                                  end;
                              end;{if(FairBusUse=false)}
                              end;
                     'h','H': begin
                                Sollw.Mode:= H;
                                if Ask_Sw_Break (Sollw) then
                                  begin
                                   SW_Act := Sollw.User;
                                   if(FairBusUse = false) then begin
                                    Fct.B.Fct :=  Fct_Wr_Sw1;
                                    Mil.Wr (SW_Act , Fct, MilErr);

                                    Fct.B.Fct :=  Fct_Wr_Sw2;  {190399 wegen Zwischenspeicher}
                                    Mil.Wr (SW_Act , Fct, MilErr);
                                   end else begin
                                    Mil.Wr_FairBus(SW_Act, Fair_Fct_Wr_Sw1, Fct.B.Adr, FairSvNr, MilErr);
                                    Mil.Wr_FairBus(SW_Act, Fair_Fct_Wr_Sw2, Fct.B.Adr, FairSvNr, MilErr);
                                   end;
                                   SW_Valid := True;
                                  end;
                              end;
                     'm','M': begin
                               if(FairBusUse = false) then begin
                                {maximalen Stromwert definieren}
                                Ini_Msg_Win;
                                Write('max. Strom als Floating-Point Zahl oder <Q + CR> eingeb. [0000.000]: ');
                                {$I-}                    {Fehleingabe zulassen: Compiler-Check ausschalten}
                                Readln (R_Zahl);
                                {$I+}
                                if (IoResult <> 0) then Exit             {Fehler selber abfangen!}
                                else  Sw_Amax := abs (R_Zahl);
                               end;{if(FairBus = false)}
                              end;
                    end; {case}

                   if Sw_Amax = 0 then
                    begin
                     GotoXY (S_SWA,  Z_SW); Write('         ');
                     GotoXY (S_SWX,  Z_SW); Write(' undef.');
                    end;

                   if SW_Valid then
                    begin
                      Set_Text_Win;
                      TextColor(Black);
                      GotoXY (S_SWH,  Z_SW); Write (Hex_Word(SW_Act));
                      GotoXY (S_SWV,  Z_SW);
                      if(FairBusUse = false) then Write_Real_10V_Bipol (SW_Act)
                      else Write_RealFac_10V_Bipol (SW_Act, RdBack_Factor,9,6);
                      if Sw_Amax = 0 then
                       begin
                         GotoXY (S_SWA,  Z_SW); Write('         ');
                       end
                      else
                       begin
                         GotoXY (S_SWA,  Z_SW); Write_Real_10A_Bipol (SW_Act);
                         GotoXY (S_SWX,  Z_SW); Write (Sw_Amax:7:1);
                        end;
                     end; {if sw_valid}
                  end; {F8}
       Taste_F9 : begin       {Einfache Rampe fÅr Funktionsgen}
                    FG_Rampe_Fix (Slow);
                    Rampe_On := True;
                    Ini_Err_Win;
                    Write(' START RAMPE +/- 10V Slow');
                    Mil.Timer2_Wait(Wait_Time);          { Wartet mit Timer2}
                    Std_Msg;
                  end;
       Taste_F10: begin
                   Slow_Key;
                   if Ask_Hex_Break (Adress, Byt) then
                     begin
                      Ifc_Test_Nr := Adress;
                      Fct.B.Adr   := Ifc_Test_Nr;
                      Ini_Stat_Win;
                      Write(Stat_Line);
                      Run_Tab (Tab_Nr);
                     end;
                  end; {Taste_F10}
       Taste_F11: begin
                    If Loop_Wait = Loop_Wait1 then Loop_Wait := Loop_Wait2
                    else
                     Loop_Wait := Loop_Wait1;
                  end; {Taste_F11}
       Taste_F12: begin
                   Slow_Key;
                   Stat_Valid := False;  {Noch kein Status gelesen}
                   Ini_Stat_Ary;         {Init Status-Error-Bits und Status-Old-Arrray}
                   {Akt. Interl-Zustand als Referenz fÅr énderungsÅberwachg}
                   Err_Stat_Intrl := False;
                   Fct.B.Adr := Ifc_Test_Nr;
                   Fct.B.Fct := Fct_Rd_Status;
                   Mil.Rd (Read_Data, Fct, MilErr);
                   if BitTst (Read_Data, 12) then
                     Interl_Old := False     {Kein Interlock!!}
                    else
                     Interl_Old := True;     {Interlock!!}

                   Timout_Cnt := 0;
                  end; {Taste_F12}
      end;  {Case}

     if not Single_Step then
      begin
       Life_Sign (Norm);
       Run_Tab (Tab_Nr);
      end;
     Displ_FTasten;
     Std_Msg;
    end; {if Ch = #0 }
  until Ch in ['x','X'];

 99:   Cursor(True);
       if Rampe_On then Stop_Rampe;  {GerÑte im definierten Zustand lassen}
 end; {Mil_Stat_Tabelle}


procedure Write_Real_200A_Bipol (Data: Word); {200A Endwert: Write_Real_10V_Bipol (Wr_Data);}
var Real_Zahl : Real;
    Int_Zahl  : Integer;
    Vorzeichen : Char;
begin                        {Bit 15 ist Vorzeichen}
  if (Data and $8000) = 0 then
   begin     {positiv}
      Real_Zahl := Data * 610.3515626/100000;
      Vorzeichen:= '+';
   end
  else
   begin     {negativ}
     Data := (not Data) + 1;               {Zweier Komplement}
{     Real_Zahl := Data * 305.1757813/1000000;  }
     Real_Zahl := Data * 610.3515626/100000;
     Vorzeichen:= '-';
  end;

  Write (Vorzeichen, Real_Zahl:7:3);
 end;


 procedure Set_TastHall_Win;
  begin
   Window(39, 20, 80, 23);
   TextBackground(Green);
   TextColor(Black);               {Setze Schriftfarbe}
  end;

 function Ask_Intervall: Byte;
  var answer : CHAR;
      Status : Boolean;
      Zeit   : Byte;
  begin
    Ini_Text_Win;
    GotoXY(01,22); ClrEol;
    Write('Am Ende einer Iteration kann eine Wartezeit eingefÅgt werden. 0 ergibt SÑgezahn');
    Ini_Msg_Win;
    Write ('Bitte Intervall-Zeit in 0,1s-Schritten eingeben [0...100]: ');
    readln (Zeit);
    Ask_Intervall := Zeit;
    if not Zeit in [0..100] then
     begin
       status := FALSE;
       WHILE NOT status DO
        begin
          Ini_Msg_Win;
          Write ('Bitte Intervall-Zeit in 0,1s-Schritten eingeben [0...100]: ');
          readln (Zeit);
          IF Zeit in [0..100] THEN
           begin
            Ask_Intervall:= Zeit;
            status := TRUE;
           end;
        end;
     end; {if j}
  End; {ask_ifc}

 function Ask_Prozent: Byte;
  const prozent_max = 25;
  var answer : CHAR;
      Status : Boolean;
      Przent: Byte;
  begin
    status := FALSE;
    Ini_Text_Win;
    GotoXY(01,22); ClrEol;
    Write('Bei 0-Prozent: keine Iteration --> Rampenverlauf!!');
    Ini_Msg_Win;
    Write ('Bitte maximale Prozent-Abweichnung vom Sollwert-Max eingeben [0..',prozent_max,']: ');
    readln (Przent);
    Ask_Prozent := Przent;
    if not (Przent in [0..prozent_max]) then
     begin
       WHILE NOT status DO
        begin
         Ini_Msg_Win;
         Write ('Bitte maximale Prozent-Abweichnung vom Sollwert-Max eingeben [');
         TextColor (Red);
         Write ('0..',prozent_max); TextColor (Yellow); Write (']: ');
         readln (Przent);
         IF Przent in [0..prozent_max] THEN
          begin
           status := TRUE;
           Ask_Prozent := Przent;
          end;
        end;
     end; {if j}
  End; {ask_ifc}

 function Ask_Step_Time: LongInt;
  var Step_In   : LongInt;
  begin
    status := FALSE;
    Ini_Msg_Win;
    Write ('Bitte Step_Time [x 10us] eingeben  oder  <Q>uit (Default=');
    Write (Step_Time_Default); Write ('): ');
    {$I-}                    {Fehleingabe zulassen: Compiler-Check ausschalten}
    Readln (Step_In );
    {$I+}
    if (IoResult <> 0) then
      Ask_Step_Time := Step_Time_Default             {Fehler selber abfangen!}
    else
      Ask_Step_Time := Step_In;
  End; {Ask_Step_Time}

 function Ask_Top_Time: LongInt;
  var Step_In   : LongInt;
  begin
    status := FALSE;
    Ini_Msg_Win;
    Write ('Wartezeit Top_Werte [x 10us] eingeben oder <Q>uit (Default=');
    Write(Top_Time_Default); Write('): ');
    {$I-}                    {Fehleingabe zulassen: Compiler-Check ausschalten}
    Readln (Step_In );
    {$I+}
    if (IoResult <> 0) then
      Ask_Top_Time := Top_Time_Default               {Fehler selber abfangen!}
    else
      Ask_Top_Time := Step_In;
  End; {Ask_Top_Time}


 procedure Mil_SW_IW;
 label 99;
 const Tab_Index_Max = 40;
 type
  TSW_Ary  = array [0..Tab_Index_Max] of Real;

 const Z_Base = 10;
       S_SW   = 22;
       S_IW1  = 45;
       S_IW2  = 63;

       SW_Tab : TSW_Ary =
       (-10.0,
         -9.5, -9.0, -8.5, -8.0,  -7.5, -7.0, -6.5, -6.0, -5.5, -5.0,
         -4.5, -4.0, -3.5, -3.0,  -2.5, -2.0, -1.5, -1.0, -0.5,  0.0,
          0.5,  1.0,  1.5,  2.0,   2.5,  3.0,  3.5,  4.0,  4.5,  5.0,
          5.5,  6.0,  6.5,  7.0,   7.5,  8.0,  8.5,  9.0,  9.5, 10.0
       );
 var
   MilErr     : TMilErr;
   Fct        : TFct;
   Sonder_Zeichen : Char;
   Bit16_Str  : Str19 ;
   Shift_Mode : Boolean;
   Plus       : Boolean;
   Tab_Index  : Integer;
   Real_Data  : Real;
   IW1        : Word;
   IW2        : Word;
   SW_Act     : Integer;
   Rd_Cnt     : LongInt;
   Data_Ask   : Word;

 procedure Set_SW_Win;
  begin
   Window(42, 20, 80, 23);
   TextBackground(Green);
   TextColor(Black);
  end;

  procedure Show_Int_Data (I_Data: Integer);
   begin
     GotoXY(18,Z_Base-2); write(Transf_Cnt:10);
     GotoXY(S_SW+2,Z_Base+1); Writeln(hex_word(I_Data));
     GotoXY(S_SW-2,Z_Base+2); Write_Real_10V_Bipol (I_Data);
     Hex_Bin_Str (I_Data, Bit16_Str);
     GotoXY(S_SW-5,Z_Base+5); Write(Bit16_Str);
   end;

 procedure Write_SW (SW_Data: Word);
  begin
   Set_Text_Win;
   Transf_Cnt:= Transf_Cnt + 1;
   Show_Int_Data (SW_Data);
   Fct.B.Fct := Fct_Wr_Sw1;
   Mil.Wr (SW_Data, Fct, MilErr);

   Fct.B.Fct := Fct_Wr_Sw2;
   Mil.Wr (SW_Data, Fct, MilErr);
  end;


 begin
   Mil_Ask_Ifc;
   Plus      := True;
   Shift_Mode:= False;
   Tab_Index := 20;
   Transf_Cnt:= 0;
   Rd_Cnt    := 0;

   Fct.B.Adr := Ifc_Test_Nr;
   Fct.B.Fct := Fct_Wr_Sw1;
   Sonder_Zeichen := chr(124);  {Absolut Zeichen}

   Ini_Text_Win;
   GotoXY(15,01); Write('----- Schreibe Sollwert-Daten auf den MIL-BUS -----');
   GotoXY(15,03); Write('Sollwert-Daten kînnen auf drei Arten festgelegt werden: ');
   GotoXY(04,04); Write(' - aus einer Tabelle fester Werte mit den Pfeiltasten ',chr($19),' ',chr($18),' oder  ');
   GotoXY(04,05); Write(' - durch Bitschieben    (F1) und anschlie·end  <-- -->    oder ');
   GotoXY(04,06); Write(' - als Inkremente +/- 1 (F2) zum aktuellen Wert mit den Pfeiltasten <-- -->');

   GotoXY(02,Z_Base-2); write('Wr-Data-Cnt: ');
   GotoXY(18,Z_Base-2); write(Transf_Cnt:10);

   GotoXY(32,Z_Base-2); write('Rd-Data-Cnt: ');
   GotoXY(48,Z_Base-2); write(Rd_Cnt:10);

   TextColor (Brown);
   GotoXY(02,Z_Base);   write('IFK-Adr [H]: ');
   GotoXY(S_SW,Z_Base);   write('SW [06H]');
   GotoXY(S_IW1,Z_Base);  write('IW1 [81H]');
   GotoXY(S_IW2,Z_Base);  write('IW2 [82H] ');
   TextColor (Black);

   GotoXY(02,Z_Base+1); write('[Hex]      :');
   GotoXY(02,Z_Base+2); write('[Volt]     :');
   GotoXY(02,Z_Base+3); Write (Sonder_Zeichen);  Write ('Hex-Diff');
                        Write (Sonder_Zeichen);  Write (' : '); ClrEol;

   GotoXY(02,Z_Base+5); writeln('Data[BIN]  : ');
   GotoXY(17,Z_Base+6); write('MSB             LSB');
   GotoXY(40,Z_Base+6); write('MSB             LSB');

   TextColor (Brown);
   GotoXY(02,20); Write('Tab-Index [',Tab_index_Max,']: ');
   GotoXY(02,21); Write('Mode          : ');
   TextColor (Black);

   GotoXY(18,20); Write (Tab_Index:2);
   GotoXY(18,21);
   if Shift_Mode then Write ('Shift-Mode') else Write ('Incr-Mode ');

   Write_Data := 0;
   GotoXY(15,Z_Base);       Write(Hex_Byte (Ifc_Test_Nr));;
   GotoXY(S_SW+2,Z_Base+1); Writeln(hex_word(Write_Data));
   GotoXY(S_SW-2,Z_Base+2); Write_Real_10V_Bipol (Write_Data);
   Hex_Bin_Str (Write_Data, Bit16_Str);
   GotoXY(S_SW-5,Z_Base+5); Write(Bit16_Str);

   Set_Text_Win;
   TextColor(Brown);
   GotoXY(42,17); write('Belegung Funktions- u. Sondertasten: ');
   Set_SW_Win;
   TextColor(Yellow);
   GotoXY(01, 01); Write('F1: SW Bit Shift/Incr   F5 :  SW 0.0 ');
   GotoXY(01, 02); Write('F2: SW Hex-Eingabe      F10:  IfcAdr ');
   GotoXY(01, 03); Write('F3: SW Plus          <- -> Shift/Incr');
   GotoXY(01, 04); Write('F4: SW Minus         ', chr($19),'   ', chr($18),' SW-TAB    ');
   TextColor(Black);

   Ch := ' ';
   if Ch = ' ' then
     begin
      Ini_Msg_Win;
      Write('Step/Stop <Space>, Loop <CR>, Funkt.- u. Sondertasten benutzen!   Ende mit [X]');
     end;

   repeat
    Set_Text_Win;
    {Sende Conversion Command: Neu 040199 ; Convert_Cmd nur 1 x nîtig}
    Fct.B.Fct := Fct_Start_Conv;
    Mil.WrFct (Fct, MilErr);
    Mil.Timer2_Wait (ADC_Conv_Wait);

    Fct.B.Fct := Fct_Rd_Ist1;
    Mil.Rd (IW1, Fct, MilErr);   {Lese Istwert}
    if MilErr = No_Err then
     begin
       Rd_Cnt := Rd_Cnt+1;
       GotoXY(48,Z_Base-2); write(Rd_Cnt:10);
       Fct.B.Fct := Fct_Rd_Ist2;
       Mil.Rd (IW2, Fct, MilErr);   {Lese Istwert}
       GotoXY(S_IW1+2,Z_Base+1);  Write (Hex_Word(IW1));
       GotoXY(S_IW2+2,Z_Base+1);  Write (Hex_Word(IW2));
       GotoXY(S_IW1-2,Z_Base+2);  Write_Real_10V_Bipol (IW1);
       GotoXY(S_IW2-2,Z_Base+2);  Write_Real_10V_Bipol (IW2);
       Hex_Bin_Str (IW1, Bit16_Str);
       GotoXY(S_IW1-5,Z_Base+5); Write(Bit16_Str);

       GotoXY(S_IW1+2,Z_Base+3);   {Differenz SW IW1}
       SW_Act := Write_Data;
         if IW1 >  SW_Act then  Write (Hex_Word (IW1 - SW_Act));
         if IW1 <  SW_Act then  Write (Hex_Word (SW_Act - IW1));
         if IW1 =  SW_Act then  Write (Hex_Word (0));

       GotoXY(S_IW2+2,Z_Base+3);   {Differenz SW IW2}
         if IW2 >  SW_Act then  Write (Hex_Word (IW2 - SW_Act));
         if IW2 <  SW_Act then  Write (Hex_Word (SW_Act - IW2));
         if IW2 =  SW_Act then  Write (Hex_Word (0));
     end   {no error}
    else
     begin
       GotoXY(S_IW1+2,Z_Base+1);  Write ('    ');
       GotoXY(S_IW2+2,Z_Base+1);  Write ('    ');
       GotoXY(S_IW1-2,Z_Base+2);  Write ('          ');
       GotoXY(S_IW2-2,Z_Base+2);  Write ('          ');
       GotoXY(S_IW1-5,Z_Base+5);  Write ('                   ');
       GotoXY(S_IW1+2,Z_Base+3);  Write ('    ');
       GotoXY(S_IW2+2,Z_Base+3);  Write ('    ');
     end;

    if KeyEPressed then Ch := NewReadKey;
    if Ch = ' ' then
      begin
       Ini_Msg_Win;
       Write('Step/Stop <Space>, Loop <CR>, Funkt.- u. Sondertasten benutzen!   Ende mit [X]');
       repeat until KeyEPressed;
      end;

    if Ch = #0 then
     begin
       Ch := NewReadKey;
       case ord (Ch) of
       Taste_F1 : begin
                   Set_Text_Win;
                   if Shift_Mode then Shift_Mode:= False
                   else Shift_Mode:= True;
                   GotoXY(18,21);
                   if Shift_Mode then Write ('Shift-Mode') else Write ('Incr-Mode ');
                  end;
       Taste_F2 : begin
                   if Ask_Hex_Break (Data_Ask, Wrd) then
                    begin
                     Write_Data := Data_Ask;
                     Write_SW (Write_Data);
                    end;
                  end;
       Taste_F3 : begin
                    Plus := True;
                    Write_Data := Write_Data and $7FFF;
                    Show_Int_Data (Write_Data);
                  end;
       Taste_F4 : begin
                    Plus := False;
                    Write_Data := Write_Data or $8000;
                    Show_Int_Data (Write_Data);
                  end;
       Taste_F5 : begin
                   Write_Data := 0;
                   Tab_Index := 20;
                   Set_Text_Win;
                   GotoXY(18,20); Write (Tab_Index:2);
                   Write_SW (Write_Data);
                  end;
       Taste_F10: begin
                     New_Ifc_Adr;
                     Fct.B.Adr := Ifc_Test_Nr;
                     Set_Text_Win;
                     GotoXY(15,Z_Base); Write(Hex_Byte (Ifc_Test_Nr));;
                     Ini_Msg_Win;
                     Write('Step/Stop <Space>, Loop <CR>, Funkt.- u. Sondertasten benutzen!   Ende mit [X]');
                     repeat until KeyEPressed;
                  end; {Taste_F10}
       Taste_Pfeil_Links : begin
                            if Shift_Mode then
                              begin
                                if Plus then
                                 begin
                                   if Write_Data = $0000 then Write_Data := $1
                                   else Write_Data := Write_Data shl 1;
                                 end
                                else  {minus}
                                 begin
                                   Write_Data := Write_Data and $7FFF;
                                   if Write_Data = $0000 then Write_Data := 1
                                   else Write_Data:= Write_Data shl 1;
                                   Write_Data := Write_Data or $8000;
                                 end;
                              end {if Shift-Mode}
                             else
                              begin   {Increment-Mode}
                                Write_Data := Write_Data - 1;
                              end;
                             Write_SW (Write_Data);
                           end;  {Taste_Pfeil_Links}
        Taste_Pfeil_Rechts: begin
                             if Shift_Mode then
                               begin
                                if Plus then
                                 begin
                                   if Write_Data = $0000 then Write_Data := $8000
                                   else Write_Data := Write_Data shr 1;
                                 end
                                else  {minus}
                                 begin
                                   Write_Data := Write_Data and $7FFF;
                                   if Write_Data = $0000 then Write_Data := $8000;
                                   Write_Data:= Write_Data shr 1;
                                   Write_Data := Write_Data or $8000;
                                 end;
                               end {if Shift-Mode}
                             else
                               begin   {Increment-Mode}
                                 Write_Data := Write_Data + 1;
                               end;
                              Write_SW (Write_Data);
                         end;  {Taste_Pfeil_Rechts}
        Taste_Pfeil_Auf   : begin
                             Tab_Index := Tab_Index + 1;
                             if Tab_Index > Tab_Index_Max then Tab_Index := Tab_Index_Max;
                             Real_Data := SW_Tab[Tab_Index];
                             Write_Data := Conv_Real_Hex (Real_Data);
                             Set_Text_Win;
                             GotoXY(18,20); Write (Tab_Index:2);
                             Write_SW (Write_Data);
                            end;
        Taste_Pfeil_Ab   : begin
                             Tab_Index := Tab_Index - 1;
                             if Tab_Index < 0 then  Tab_Index := 0;
                             Real_Data := SW_Tab[Tab_Index];
                             Write_Data := Conv_Real_Hex (Real_Data);
                             Set_Text_Win;
                             GotoXY(18,20); Write (Tab_Index:2);
                             Write_SW (Write_Data);
                           end;
      end;  {Case}

      Ini_Msg_Win;
      Write('Step/Stop <Space>, Loop <CR>, Funkt.- u. Sondertasten benutzen!   Ende mit [X]');
     end; {if Ch = #0 }

     Mil.Timer2_Wait(10000);    {Anzeige verlangsamen}
   until Ch in ['x','X'];

99:
 end; {Mil_SW_IW}

function Rd_Real: Real;    {Max. 65 sec, wegen Timer 2}
var Status    : Boolean;
    Real_Zahl : Real;
begin
  Status := FALSE;
  repeat
   Ini_Msg_Win;
   Write('Bitte Flie·komma-Zahl eingeben [Format 00.0]: ');
   {$I-}                    {Fehleingabe zulassen: Compiler-Check ausschalten}
   Readln(Real_Zahl);
   {$I+}
   if (IoResult <> 0) or (Real_Zahl > 65.0) or (Real_Zahl < 0.1) then
    begin                                           {Fehler selber abfangen!}
     Ini_Err_Win;
     Write('ERROR: Format falsch oder Zahl nicht 0.1..65.0 !! Weiter mit <CR>');
     ReadKey;
    end
   else
     Status := True;
  until Status = True;
  Rd_Real   := Real_Zahl;    {Real-Zahl in Integer umwandeln}
end; {Get_Real_10}

 procedure Mil_NG_Rampe;
 label 99;
 const Ref_Time       = 3.2;
       Z_Base         = 15;

 type TVorz = (Plus, Minus, Bipolar);
      TDirection = (Up, Down);
 var
  MilErr  : TMilErr;
  Fct     : TFct;
  Polar   : TVorz;
  Delta_U : Integer;
  Delta_T : LongInt;
  Zeichen : Char;
  Zeit    : Real;
  Sollwert: LongInt;
  Direction: TDirection;

 function Ask_Time (var Mode: TVorz; var D_U: Integer; var D_T: LongInt): Boolean;
  label 1;
  var Factor : Real;
  begin
   Ask_Time := False;
   Mode := Plus;
   D_U  := 0;
   D_T  := 0;
   Ini_Text_Win;
   Ini_Msg_Win;                                            {, [B]ipolar}
   Write ('Vorzeichen f. Rampe eingeben: Abruch <Esc>, <CR> fÅr +, [M] fÅr -: ');
   Zeichen := NewReadKey;
   case Zeichen of
     #27    : goto 1;
    'm','M' : Mode := Minus;
   end;

   Ini_Text_Win;
   GotoXY(1, 22); Clreol;
   Write ('[Rampenzeit 0.1 ... 65.0 sec]');
   Zeit := Rd_Real;

   if Zeit = Ref_Time then   {Sollwert alle 100 us incrementieren = 3.2 sec}
    begin     {normalerweise Timer 2: Ein Tick = 10 us; 10 x 10 us = 100 us}
      D_U  := 1;        {Delta U: Spannung um 1 inkrementieren}
      D_T  := 3;        {bei 33 Mhz-CPU: Timer2 + 40 us MIL-Transfer + Software= 100us}
    end;

   if Zeit > Ref_Time then
    begin {wenn die Zeit > 3.2 sec: Zeit zwischen 2 Sollwerten lÑnger}
      D_U  := 1;
      D_T  := Round (10 * (Zeit/Ref_Time));
    end {Zeit > 3.2}
   else
    begin
      D_U  := Round (Ref_Time/Zeit);   {Spannungsstufen grî·er, min. Time}
      D_T  := 3; {bei 33 Mhz CPU:Timer2 + 40 us Mil-Transfer + 30us Software=100us}
    end; {Zeit < 3.2}
   Ask_Time := True;
1:
  end; {Ask_Time}

 begin
   Transf_Cnt:= 0;
   Mil_Ask_Ifc;
   if not Ask_Time (Polar, Delta_U, Delta_T) then goto 99;

   Fct.B.Adr := Ifc_Test_Nr;
   Fct.B.Fct := Write_Fct_Code;

   Ini_Text_Win;
   GotoXY(25,02); Write('----- Rampentest fÅr Magnete -----');
   GotoXY(05,22); TextColor (Red);
   Write('Aus GeschwindigkeitsgrÅnden: Im Loop-Mode keine MIL-Transfer-Anzeige!!');
   TextColor (Black);
   GotoXY(25,05); write  ('Function-Word (Fct + Adr): ',hex_word(Fct.W),' [H]');

   GotoXY(10,8);   Write ('Transfer-Count : ');
   GotoXY(10,9);   Write ('Data     [Hex] : ');
   TextColor (Yellow);
   GotoXY(27,11); write (chr($18));
   GotoXY(27,12); write ('Falls Cursor hier blinkt: Loop-Mode!!! ');
   TextColor(Black);
   GotoXY(10,10);  Write ('         [Volt]: ');

   GotoXY(10,Z_Base);   Write ('PolaritÑt           : ');
   if Polar = Plus then Write ('Plus ') else Write ('Minus');
   GotoXY(10,Z_Base+1); write ('Rampenzeit  [sec   ]:  '); Write (Zeit:4:1);
   GotoXY(10,Z_Base+2); write ('Zeitabstand [us    ]: '); Write (Delta_T * 10 + 40 + 30);
   GotoXY(10,Z_Base+3); write ('Inkremente  [Anzahl]: '); Write (Delta_U);
   GotoXY(10,Z_Base+4); write ('            [Volt  ]: '); Write_Real_10V_Bipol (Delta_U);

   Sollwert  := 0;
   Direction := Up;
   Mil.Wr (Sollwert, Fct, MilErr);    {Magnet auf Sollwert=0 einstellen}

   Ch := ' ';
   if Ch = ' ' then
     begin
      Ini_Msg_Win;
      Write('Stop/Single Step mit <SPACE>, Loop mit <CR> ,  Ende mit [X]');
      repeat until KeyEPressed;
      Ch := NewReadKey;
      if  Ch in ['x','X'] then Goto 99;
     end;

   if not (Ch = ' ') then     {Blinkenden Cursor auf Loop-Anzeige}
    begin
      Set_Text_Win;
      GotoXY (27,10);
    end;

   repeat
    repeat
      if Polar = Plus then
       begin
         if Direction = Up then
          begin                                  {up}
            Sollwert := Sollwert + Delta_U;
            if Sollwert >= $7FFF then
             begin
              Sollwert  := $7FFF;
              Direction := Down;
             end;
          end
         else
          begin                                  {Down}
            Sollwert := Sollwert - Delta_U;
            if Sollwert <= 0 then
             begin
              Sollwert  := 0;
              Direction := Up;
             end;
          end; {if Direction}
       end
      else
       begin                                     {PolaritÑt Minus}
         if Direction = Up then
          begin                                  {up}
            Sollwert := Sollwert - Delta_U;
            if Sollwert < -$8000 then
             begin
              Sollwert  := $8000;
              Direction := Down;
             end;
          end
         else
          begin                                  {Down}
            Sollwert := Sollwert + Delta_U;
            if (Sollwert > $FFFF) then
             begin
              Sollwert  := 0;
              Direction := Up;
             end;
          end; {if Direction}
       end;

      Mil.Wr (Sollwert, Fct, MilErr);
      Mil.Timer2_Wait(Delta_T);
    until KeyEPressed or (Ch = ' ');

    if Ch = ' ' then
      begin
       Set_Text_win;
       Transf_Cnt := Transf_Cnt+ 1;
       GotoXY (27,8);  Write (Transf_Cnt);
       GotoXY (27,9);  Write (Hex_Word(Sollwert));
       GotoXY (27,10); Write_Real_10V_Bipol (Sollwert);

       Ini_Msg_Win;
       Write('Stop/Single Step mit <SPACE>, Loop mit <CR> ,  Ende mit [X]');
       repeat until KeyEPressed;
       Set_Text_Win;
       GotoXY (27,8);  ClrEol;
       GotoXY (27,9);  ClrEol;
       GotoXY (27,10); ClrEol;
      end;
    Ch := NewReadKey;
   until Ch in ['x','X'];
 99:
 end; {Mil_NG_Rampe}

 procedure Mil_WrHall_Var_IwDisp_Quick1 (Wr_Data: Word);
  LABEL 99;
  const
   Tab_Index_Max = 16;
   Sw_Fname  = 'C:\PC_MIL\IFB_MAGF.TAB';   {Filename fÅr Fast-Tabelle}
   TimeIndex = 10000;
   Step_Time = 10;     {Wartezeit fÅr nÑchsten Sollwert * 10 us}
   Displ_Intervall = 10000;  {Wartezeit x 10 us}
   Iterat_Max = 10;
   Iterat_Wert_Max = 200;     {feste Vorgabe}
   Iterat_Wert_Min = 10;     {feste Vorgabe}

   X_Gaus_HX  = 23;   {Spalte, Zeile fÅr Gau·-Anzeige}
   Z_Gaus_HX  = 11;
   X_Gaus_KG  = 22;
   Z_Gaus_KG  = 12;

  type
   THallSet  = record
                Volt : Word;
                Gaus : Real;
                MWert: Real;
               end;

   THallAry  = array [0..Tab_Index_Max] of THallSet;
   TFile_SwTab = file of THallAry;

 const
  HallSw: THallAry =
  (
  (Volt: $0000; Gaus:  0.0; MWert: 0.0),
  (Volt: $04F7; Gaus:  1.0; MWert: -5.45),
  (Volt: $0A86; Gaus:  2.0; MWert: 0),
  (Volt: $0FE4; Gaus:  3.0; MWert: 0),
  (Volt: $1544; Gaus:  4.0; MWert: 0),
  (Volt: $1ABA; Gaus:  5.0; MWert: 3.73),
  (Volt: $2018; Gaus:  6.0; MWert: 0),
  (Volt: $259C; Gaus:  7.0; MWert: 0),
  (Volt: $2AE6; Gaus:  8.0; MWert: 0),
  (Volt: $3098; Gaus:  9.0; MWert: 0),
  (Volt: $363B; Gaus: 10.0; MWert: 150.0),
  (Volt: $3BC5; Gaus: 11.0; MWert: 0),
  (Volt: $41C4; Gaus: 12.0; MWert: 0),
  (Volt: $47E8; Gaus: 13.0; MWert: 0),
  (Volt: $4EB9; Gaus: 14.0; MWert: 0),
  (Volt: $5676; Gaus: 15.0; MWert: 523.64),
  (Volt: $5FCD; Gaus: 16.0; MWert: 0)
  );

  var
   SwTab      : THallAry;
   SwFile     : TFile_SwTab;
   I          : Byte;
   Loop       : Boolean;
   Single_Step: Boolean;
   Intervall  : LongInt;
   Prozent    : Byte;
   error_cnt  : LONGINT;
   MilErr     : TMilErr;
   Fct        : TFct;
   Data_Increment : Word;
   Tab_Index  : Integer;
   Wr_Gaus    : Real;
   Gaus_Hex   : Word;
   File_Ok    : Boolean;
   SW_Top     : Word;
   SW_Old     : Word;       {Dient als globaler Sollwert-Speicher fÅr procedure
                             Mil_WrSoft}
   Default_Tab: Boolean;

  procedure Show_Tab;
   const Z_Offset = 5;
   var I      : Byte;
       Tab_SW : Word;
   begin
     Ini_Text_Win;
     TextColor (Brown);
     GotoXY(01,02); TextColor(Yellow);
     if Default_Tab then
      Write (' ********** DEFAULT  - TABELLE **********')
     else
      Write (' Sollwert-Tabelle: ', Sw_Fname);

     TextColor(Brown);
     GotoXY(01,03);
     Write ('MagFeld   SW         Sollwert     Sollwert       MWert');
     GotoXY(01,04);
     Write (' [kG]    [Hex]        [Volt]      [Ampere]       [Gau·]');
     TextColor (Black);

     for I := 0 to Tab_Index_Max do                        {Init fÅr Tabelle}
      begin
        Tab_SW :=  SwTab [I].Volt;
        GotoXY(01,I+Z_Offset); write(SwTab [I].Gaus:5:2);
        GotoXY(10,I+Z_Offset); write(hex_word(Tab_SW));
        GotoXY(20,I+Z_Offset); Write_Real_10V_Bipol  (Tab_SW);
        GotoXY(35,I+Z_Offset); Write_Real_200A_Bipol (Tab_SW);
        GotoXY(50,I+Z_Offset); Write(SwTab [I].MWert:5:2);
      end; {for}
    Ini_Msg_Win;
    write ('Weiter mit beliebiger Taste!!');
    repeat until KeyEPressed;
   end; {Show_Tab}


  procedure Mil_WrSoft (SW_New: Word; SoftFct: TFct; MilErr: TMilErr);
  { Diese Routine fÑhrt zu einem neuen Sollwert nur in definierten Schritten. bis der
    Dazu mu· der letzte Sollwert gespeichert werden!
  }
   var SW_New_Int : Integer;
       SW_Old_Int : Integer;
   begin
     SoftFct.B.Fct := Fct_Wr_Sw1;
     SW_New_Int := SW_New;
     SW_Old_Int := SW_Old;
     while SW_New_Int <> SW_Old_Int do
      begin
        if SW_New_Int > SW_Old_Int  then SW_Old_Int := SW_Old_Int + 1;
        if SW_New_Int < SW_Old_Int  then SW_Old_Int := SW_Old_Int - 1;
        Mil.Wr (SW_Old_Int, SoftFct, MilErr);
        Set_Text_Win;
        Transf_Cnt := Transf_Cnt+ 1;
        GotoXY(17,10); write(transf_cnt:10);
        GotoXY(47,11); write(hex_word(SW_Old_Int));
        GotoXY(55,11); Write_Real_10V_Bipol  (SW_Old_Int);
        GotoXY(68,11); Write_Real_200A_Bipol (SW_Old_Int);
        Mil.Timer2_Wait(Step_Time);
      end; {while}
     SW_Old := SW_Old_Int;       {Rette den alten Sollwert}
   end; {Mil_WrSoft}

  procedure WrSW_Spezial_Fast (SW: Real; SW_Max: Real; Delta: Integer);
  {FÅr Magnetsonden-Messungen ist es gewÅnscht, einen Sollwert iterativ zu
   schreiben: z. B. SW -100, N x (SW +/- 200), SW                              }
   var SW_Real : Real;
       SW_Int  : Integer;
       Test_Intervall : LongInt;
       N : Word;
   begin
     Fct.B.Fct := Fct_Wr_Sw1;

     {Beginn der Iterationen}
     SW_Real := SW - Delta;              { 1. Wert: Sollwert -  Counts }
     SW_Int  := Round (SW_Real);         {Real in Integer umwandeln}
     Mil_WrSoft  (SW_Int, Fct, MilErr);  {Mil.Wr}

     for N := 1 to Iterat_Max do
      begin
        SW_Real := SW + 2*Delta;
        SW_Int  := Round (SW_Real);         {Real in Integer umwandeln}
        Mil_WrSoft  (SW_Int, Fct, MilErr);  {Mil.Wr}

        SW_Real := SW - 2*Delta;
        SW_Int  := Round (SW_Real);         {Real in Integer umwandeln}
        Mil_WrSoft  (SW_Int, Fct, MilErr);  {Mil.Wr}
      end; {for}

     SW_Real := SW;                      {Ende: Sollwert einstellen}
     SW_Int  := Round (SW_Real);         {Real in Integer umwandeln}
     Mil_WrSoft  (SW_Int, Fct, MilErr);  {Mil.Wr}
   end;  {WrSW_Spezial}

 procedure Displ_Istwerte (IX: Word);   {IX =Tab-Index}
  const
    Gaus_Const = 0.610351562;
    Z_Base_IW = 03;
    X_IW_KSPV  = 16;
    X_IW_HALL  = 30;
    X_IW_Delta = 41;
    X_IW_MWERT = 53;
    X_IW_STDAW = 67;
    Z_Pos_IW3 = 12;
    X_Pos_IW3 = 18;    {neu im TextFenster!!}

 var Life_Mode   : TLife_XY;
     KSPV_Real   : Real;
     KSPV_Int    : Integer;
     Delta_Real  : Real;
     Delta_Int   : Integer;
     MWert_Real  : Real;
     Std_Abw_Real: Real;

   procedure get_data (Num : Byte);
    var Rd_Dta : Word;
    begin
     Set_IstwDisp_Win; TextColor(Yellow);
     Fct.B.Fct := Fct_Start_Conv;          {070199} {wegen ADC-Hw-énderung}
     Mil.WrFct (Fct, MilErr);
     Mil.Timer2_Wait (ADC_Conv_Wait);

     case Num of
      1: Fct.B.Fct := Fct_Rd_Ist1; {81 IW1}
      2: Fct.B.Fct := Fct_Rd_Ist2; {82 IW2}
      3: Fct.B.Fct := Fct_Rd_Ist3; {83 IW3}
     end;

     Mil.Rd (Rd_Dta, Fct, MilErr);
     IF MilErr  <> No_Err THEN
      Begin
        timout_cnt := timout_cnt + 1;
        rd_timeout := TRUE;
        TextColor (Black);
        case Num of
         1: begin
             GotoXY(X_IW_Hall  , Z_Base_IW);  Write('    ');
             GotoXY(X_IW_Delta , Z_Base_IW);  Write('       ');
             GotoXY(X_IW_STDAW , Z_Base_IW);  Write('       ');
           end;
         2: begin
             GotoXY(X_IW_Hall  , Z_Base_IW+1);  Write('    ');
             GotoXY(X_IW_Delta , Z_Base_IW+1);  Write('       ');
             GotoXY(X_IW_STDAW , Z_Base_IW+1);  Write('       ');
            end;
         3: begin
             Set_Text_Win;
             GotoXY(47,Z_Gaus_KG); Write('    ');
             GotoXY(55,Z_Gaus_KG); Write('          ');
             Set_IstwDisp_Win;
            end;
         end; {case}
      End
     ELSE
      Begin  {kein Timeout}
       rd_timeout  := FALSE;
       KSPV_Real   := (SwTab [IX].Gaus * 1000)/Gaus_Const;
       KSPV_Int    := Round (KSPV_Real);            {Real in Integer umwandeln}
       MWert_Real  := SwTab [IX].MWert;

       case Num of
        1: begin
            Delta_Real  := (Rd_Dta - KSPV_Real) * Gaus_Const;
            Std_Abw_Real:= Delta_Real - MWert_Real;
            GotoXY(X_IW_KSPV  , Z_Base_IW);  TextColor(Blue);  Write(hex_word(KSPV_Int)); TextColor(White);
            GotoXY(X_IW_Hall  , Z_Base_IW);                    Write(hex_word(Rd_Dta));
            GotoXY(X_IW_Delta , Z_Base_IW);                    Write(Delta_Real:7:1);
            GotoXY(X_IW_MWERT , Z_Base_IW);  TextColor(Blue);  Write(MWert_Real:7:1);     TextColor(White);
            GotoXY(X_IW_STDAW , Z_Base_IW);                    Write(Std_Abw_Real:7:1);
           end;
        2: begin
            Delta_Real  := (Rd_Dta - KSPV_Real) * Gaus_Const;
            Std_Abw_Real:= Delta_Real - MWert_Real;
            GotoXY(X_IW_KSPV  , Z_Base_IW+1);  TextColor(Blue);  Write(hex_word(KSPV_Int)); TextColor(White);
            GotoXY(X_IW_Hall  , Z_Base_IW+1);                    Write(hex_word(Rd_Dta));
            GotoXY(X_IW_Delta , Z_Base_IW+1);                    Write(Delta_Real:7:1);
            GotoXY(X_IW_MWERT , Z_Base_IW+1);  TextColor(Blue);  Write(MWert_Real:7:1);     TextColor(White);
            GotoXY(X_IW_STDAW , Z_Base_IW+1);                    Write(Std_Abw_Real:7:1);
           end;
        3: begin
             Set_Text_Win;
             GotoXY(47,Z_Gaus_KG); write(hex_word(Rd_Dta));
             GotoXY(55,Z_Gaus_KG); Write_Real_10V_Bipol (Rd_Dta);
             Set_IstwDisp_Win;
           end;
        end; {case}
      End;
    end; {get_data}

  begin
    Life_Mode.Mode    := Norm;      {Parameter fÅr Lebenszeichen definieren}
    Life_Mode.PosX    := 01;        {02;}
    Life_Mode.PosY    := 01;        {12;}
    Life_Mode.Time    := Life_Time_Slow;
    Life_Mode.Disp_Win:= Set_IstwDisp_Win; {Darstellungs-Fenster}
    Life_Sign_XY (Life_Mode);
    get_data (1);
    get_data (2);
    get_data (3);
  end; {Displ_Istwerte}

 Begin
        {Sw-Tabelle Default-Werten fÅllen}
  for I := 0 to Tab_Index_Max do                        {Init fÅr Tabelle}
   begin
     SwTab [I].Volt   := HallSw [I].Volt;
     SwTab [I].Gaus   := HallSw [I].Gaus;
     SwTab [I].MWert  := HallSw [I].MWert;
  end;

  File_Ok := False;
  I := 0;
  Assign (SwFile, Sw_Fname);
  {$I-}                            {Compiler Check aus, Error selber abfangen}
  Reset(SwFile);
  {$I+}
  if IoResult <> 0 then                             {PrÅfe, ob File existiert}
    begin
     Default_Tab := True;
     Ini_Text_Win;
     Ini_Err_Win;
     Write('ERROR: Datei ',Sw_Fname,' fehlt. Default Datei anlegen? [J/N]: ');
     if ReadKey in ['j','J'] then
      begin
        for I := 0 to Tab_Index_Max do                        {Init fÅr Tabelle}
         begin
           SwTab [I].Volt   := HallSw [I].Volt;
           SwTab [I].Gaus   := HallSw [I].Gaus;
           SwTab [I].MWert  := HallSw [I].MWert;
        end;
        ReWrite(SwFile);                        {existiert nicht: File erzeugen}
        Write(SwFile,SwTab);                   {Tabelle in File speichern}
        Close(SwFile);
        File_Ok := True;
       end; {if j}
    end
   else
    begin
     Default_Tab := False;
     Read (SwFile, SwTab);                   { File existiert: Lese Tabelle}
     Close(SwFile);
     File_Ok := True;
    end;

    Fct.B.Adr := Ifc_Test_Nr;
    Fct.B.Fct := Fct_Wr_Sw1;
    Loop      := False;
    Ini_Text_Win;
    Tab_Index  := 0;
    SW_Old     := 0;
    transf_cnt := 0;
    error_cnt  := 0;
    timout_wr  := 0;
    Data_Increment := 0;
    Intervall  := 0;
    Prozent    := 0;

    Show_Tab;
    Ini_Text_Win;
    TextColor (Yellow);
    GotoXY(16,02); Write('**************  Variable Tabelle Quick1 ***************');
    TextColor (Black);
    GotoXY(15,03); Write('----- Schreibe Daten auf den MIL-BUS mit Fct-Code -----');
    GotoXY(10,04); Write('Sollwert-Daten kînnen in definierten Inkrementen verÑndert werden. ');
    GotoXY(05,05); Write('Die Tasten F1...F4 bestimmen Inkr-Wert, Pfeiltasten <- u. -> die Richtung.');
    GotoXY(10,06); Write('Falls Pfeiltasten dauernd gedrÅckt werden: Wiederholtes Senden!!');
    GotoXY(05,07); Write('TabWerte iterativ mit [SW_TAB, '); Write (Iterat_Max);
    Write (' x SW_TAB -/+'); TextColor (White); Write(Iterat_Wert_Max); TextColor(Black); Write(' ,SW_TAB] u. 10x(+/-');
    TextColor(White); Write (Iterat_Wert_Min); TextColor(Black); Write (')');

    Textcolor (Brown);
    GotoXY(25,08); write  ('Function-Word (Fct + Adr): ');
    TextColor(Black); Write (hex_word(Fct.W));
    TextColor(Brown); Write(' [H]');

    GotoXY(2, 10);        Write('Wr-Data-Cnt :                                [Hex]     [VOLT]    [max.200 AMP]');
    GotoXY(2, 11);        write('Gau·-Tab [H]:                 Write-Data   :                    ',chr($F7),'         ');
    GotoXY(2, Z_Gaus_KG); write('Gau·-Tab[kG]:                 Istwert [83H]:                                         ');
    TextColor(Black);
    GotoXY(47,11); write(hex_word(wr_data));
    GotoXY(55,11); Write_Real_10V_Bipol (Wr_Data);

    TextColor(Brown);
    GotoXY(06,18); write('Inkrment[H] : ');
    GotoXY(06,19); write('Zeit x 0.1s : ');
    GotoXY(06,20); write(chr($25),' v. TOPwert: ');
    GotoXY(06,21); write('Rampe x us  : ');
    TextColor(Black);
    GotoXY(20,18); write(Hex_Word(Data_Increment));
    GotoXY(21,19); {write(Intervall:3);}
    GotoXY(21,20); {write(Prozent:3);  }
    GotoXY(21,21); write(Step_Time * 10);

    Set_TastHall_Win;
    TextColor(Yellow);
    GotoXY(01, 01); Write('F1:1    F5 :SW 0.0  F11:SW iterativ      ');
    GotoXY(01, 02); Write('F2:10   F6 :SW Tab  F12:Tabelle speichern');
    GotoXY(01, 03); Write('F3:100  F7 :SW Hex  <- -> Incr neg/pos   ');
    GotoXY(01, 04); Write('F4:1000 F10:IfcAdr  ', chr($19),'   ', chr($18),' TAB auf/ab     ');

    Ini_IstwDisp_Win;
    TextColor(Yellow);
    GotoXY(13, 01); Write('KERN   SPIN     IW HALL    DELTA   [G]    MWERT     STD ABW [G]');
    GotoXY(13, 02); Write('Vorgabe [H]      [Hex]     IWHall-Vorg     [G]      Delta-MWert');
    GotoXY(01, 03); Write('HALL [81H]:');
    GotoXY(01, 04); Write('HALL [82H]:');

    Set_Text_Win;
    TextColor(Brown);
    GotoXY(39,17); write('Belegung Funktions- u. Sondertasten: ');
    TextColor(Black);

    Mil.Reset;                            { clear fifo }
    Cursor(False);
    Ini_Msg_Win;
    Write('Funktions- u. Sondertasten benutzen!     Ende mit [X]');

    repeat
     Displ_Istwerte (Tab_Index);
     if KeyEPressed then
      begin
       Ch := NewReadKey;
       if Ch = #0 then                  {Sonder-Tasten Abfrage}
        begin
         Ch := NewReadKey;
         case ord (Ch) of
           Taste_F1 : begin
                       Data_Increment := 1;
                       Set_Text_Win;
                       GotoXY(20,18); write(Hex_Word(Data_Increment));
                      end;
           Taste_F2 : begin
                       Data_Increment := $10;
                       Set_Text_Win;
                       GotoXY(20,18); write(Hex_Word(Data_Increment));
                      end;
           Taste_F3 : begin
                       Data_Increment := $100;
                       Set_Text_Win;
                       GotoXY(20,18); write(Hex_Word(Data_Increment));
                     end;
           Taste_F4 : begin
                       Data_Increment := $1000;
                       Set_Text_Win;
                       GotoXY(20,18); write(Hex_Word(Data_Increment));
                      end;
           Taste_F5 : begin
                       Tab_Index := 0;
                       Wr_Data := HallSw [Tab_Index].Volt;
                       Set_Text_Win;
                       GotoXY(X_Gaus_HX, Z_Gaus_KG-1); write(Hex_Word(Wr_Data));
                       Wr_Gaus := HallSw [Tab_Index].Gaus;
                       GotoXY(X_Gaus_KG, Z_Gaus_KG); write(Wr_Gaus:5:2);
                       Mil_WrSoft  (Wr_Data, Fct, MilErr);   {Mil.Wr}
                      end;
           Taste_F6 : begin
                        Set_IstwDisp_Win;        {Lîsche Istwerte}
                        GotoXY(12,03);
                        GotoXY(12,04);
                        Set_Text_Win;
                        Wr_Data := SwTab [Tab_Index].Volt;
                        Wr_Gaus := SwTab [Tab_Index].Gaus;
                        TextColor(Blue);
                        GotoXY(X_Gaus_HX, Z_Gaus_KG-1); write(Hex_Word(Wr_Data));
                        GotoXY(X_Gaus_KG, Z_Gaus_KG); write(Wr_Gaus:5:2);
                        TextColor(Black);
                        WrSW_Spezial_Fast (Wr_Data, SW_Top, Iterat_Wert_Max);
                        WrSW_Spezial_Fast (Wr_Data, SW_Top, Iterat_Wert_Min);
                      end;
           Taste_F7 : begin
                        if (Ask_Hex_Break (Wr_Data, Wrd)) then
                         begin
                           Set_Text_Win;
                           GotoXY(47, 12); ClrEol;
                           Ini_Msg_Win;
                           Write('Funktions- u. Sondertasten benutzen!     Ende mit [X]');
                           WrSW_Spezial_Fast (Wr_Data, SW_Top, Iterat_Wert_Max);
                           WrSW_Spezial_Fast (Wr_Data, SW_Top, Iterat_Wert_Min);
                         end;
                        Ini_Msg_Win;
                        Write('Funktions- u. Sondertasten benutzen!     Ende mit [X]');
                      end;
          Taste_F10: begin
                        New_Ifc_Adr;
                        Fct.B.Adr := Ifc_Test_Nr;
                        Set_Text_Win;
                        TextColor(Brown);
                        GotoXY(25,08); Write  ('Function-Word (Fct + Adr): ');
                                       TextColor(Black); Write(hex_word(Fct.W)); Write(' [H]');
                        Ini_Msg_Win;
                        Write('Funktions- u. Sondertasten benutzen!     Ende mit [X]');
                        repeat until KeyEPressed;
                     end; {Taste_F10}

          Taste_F11: begin   {aktuelle Wr-Daten nochmals iterativ schreiben}
                       WrSW_Spezial_Fast (Wr_Data, SW_Top, Iterat_Wert_Max);
                       WrSW_Spezial_Fast (Wr_Data, SW_Top, Iterat_Wert_Min);
                     end; {Taste_F10}
          Taste_F12: begin
                       Ini_Err_Win;
                       Write ('GeÑnderten Tabellenwert wirklich abspeichern [J/N] ?: ');
                       Ch := NewReadKey;
                       if Ch in ['j','J'] then
                        begin
                          {$I-}   {Compiler Check aus, Error selber abfangen}
                          Reset(SwFile);
                          {$I+}
                          if IoResult <> 0 then    {PrÅfe, ob File existiert}
                             ReWrite(SwFile)  {existiert nicht: File erzeugen}
                          else
                             SwTab [Tab_Index].Volt := Wr_Data;
                          Write(SwFile,SwTab);  {Tabelle in File speichern}
                          Close(SwFile);
                         end;  {ja}
                        Ini_Msg_Win;
                        Write('Funktions- u. Sondertasten benutzen!     Ende mit [X]');
                      end; {Taste_F12}
          Taste_Pfeil_Links : begin
                                 Wr_Data := Wr_Data - Data_Increment;
                                 Set_Text_win;
                                 GotoXY(20,18); write(Hex_Word(Data_Increment));
                                 Fct.B.Fct := Fct_Wr_Sw1;
                                 Mil_WrSoft  (Wr_Data, Fct, MilErr);  {Mil.Wr}
                               end;

           Taste_Pfeil_Rechts: begin
                                Wr_Data := Wr_Data + Data_Increment;
                                Set_Text_win;
                                GotoXY(20,18); write(Hex_Word(Data_Increment));
                                Fct.B.Fct := Fct_Wr_Sw1;
                                Mil_WrSoft  (Wr_Data, Fct, MilErr);   {Mil.Wr}
                               end;
           Taste_Pfeil_Auf   : begin
                                Tab_Index := Tab_Index + 1;
                                if Tab_Index > Tab_Index_Max then Tab_Index := Tab_Index_Max;
                                Set_Text_Win;
                                TextColor(Blue);
                                Wr_Gaus := SwTab [Tab_Index].Gaus;
                                GotoXY(X_Gaus_KG, Z_Gaus_KG); write(Wr_Gaus:5:2);
                                Gaus_Hex := SwTab [Tab_Index].Volt;
                                GotoXY(X_Gaus_HX, Z_Gaus_KG-1); write(Hex_Word(Gaus_Hex));
                                TextColor(Black);
                               end;
           Taste_Pfeil_Ab   : begin
                                Tab_Index := Tab_Index - 1;
                                if Tab_Index < 0 then  Tab_Index := 0;
                                Set_Text_Win;
                                TextColor(Blue);
                                Wr_Gaus := SwTab [Tab_Index].Gaus;
                                GotoXY(X_Gaus_KG, Z_Gaus_KG); write(Wr_Gaus:5:2);
                                Gaus_Hex := SwTab [Tab_Index].Volt;
                                GotoXY(X_Gaus_HX, Z_Gaus_KG-1); write(Hex_Word(Gaus_Hex));
                                TextColor(Black);
                               end;
         end;  {Case}
       end;    {if char = 0}
      end; {if keypressed}
     until Ch in ['x','X'];
   99:  Cursor(True);
 end; {Mil_WrHall_Var_IwDisp_Quick1}


 procedure Mil_WrHall_Var_IwDisp_Quick2 (Wr_Data: Word);
  LABEL 99;
  const
   Tab_Index_Max = 16;
   Sw_Fname  = 'C:\PC_MIL\IFB_MAGS.TAB';   {Filename fÅr Fast-Tabelle}
   TimeIndex = 10000;
   Displ_Intervall = 10000;  {Wartezeit x 10 us}
   Iterat_Max = 10;
   Iterat_Wert_Max = 200;    {feste Vorgabe}
   Iterat_Wert_Mid = 100;
   Iterat_Wert_Min = 10;     {feste Vorgabe}
   Gaus_Max   = $6000;  {speziell fÅr Quick2}
   X_Gaus_HX  = 23;     {Spalte, Zeile fÅr Gau·-Anzeige}
   Z_Gaus_HX  = 11;
   X_Gaus_KG  = 22;
   Z_Gaus_KG  = 12;

  type
   THallSet  = record
                Volt : Word;
                Gaus : Real;
                MWert: Real;
               end;

   THallAry  = array [0..Tab_Index_Max] of THallSet;
   TFile_SwTab = file of THallAry;

 const
  HallSw: THallAry =
  (
  (Volt: $0000; Gaus:  0.0; MWert: 0.0),
  (Volt: $04F7; Gaus:  1.0; MWert: -5.45),
  (Volt: $0A86; Gaus:  2.0; MWert: 0),
  (Volt: $0FE4; Gaus:  3.0; MWert: 0),
  (Volt: $1544; Gaus:  4.0; MWert: 0),
  (Volt: $1ABA; Gaus:  5.0; MWert: 3.73),
  (Volt: $2018; Gaus:  6.0; MWert: 0),
  (Volt: $259C; Gaus:  7.0; MWert: 0),
  (Volt: $2AE6; Gaus:  8.0; MWert: 0),
  (Volt: $3098; Gaus:  9.0; MWert: 0),
  (Volt: $363B; Gaus: 10.0; MWert: 150.0),
  (Volt: $3BC5; Gaus: 11.0; MWert: 0),
  (Volt: $41C4; Gaus: 12.0; MWert: 0),
  (Volt: $47E8; Gaus: 13.0; MWert: 0),
  (Volt: $4EB9; Gaus: 14.0; MWert: 0),
  (Volt: $5676; Gaus: 15.0; MWert: 523.64),
  (Volt: $5FCD; Gaus: 16.0; MWert: 0)
  );

  var
   SwTab      : THallAry;
   SwFile     : TFile_SwTab;
   I          : Byte;
   Loop       : Boolean;
   Single_Step: Boolean;
   Intervall  : LongInt;
   Prozent    : Byte;

   error_cnt  : LONGINT;
   MilErr     : TMilErr;
   Fct        : TFct;
   Data_Increment : Word;
   Tab_Index  : Integer;
   Wr_Gaus    : Real;
   Gaus_Hex   : Word;
   File_Ok    : Boolean;
   SW_Top     : Word;
   SW_Old     : Word;       {Dient als globaler Sollwert-Speicher fÅr procedure
                             Mil_WrSoft}
   Default_Tab: Boolean;
   Step_Time  : LongInt;     {Wartezeit fÅr nÑchsten Sollwert * 10 us}
   Top_Time   : LongInt;
   Top_Time_Real: Real;

  procedure Show_Tab;
   const Z_Offset = 5;
   var I      : Byte;
       Tab_SW : Word;
   begin
     Ini_Text_Win;
     TextColor (Brown);
     GotoXY(01,02); TextColor(Yellow);
     if Default_Tab then
      Write (' ********** DEFAULT  - TABELLE **********')
     else
      Write (' Sollwert-Tabelle: ', Sw_Fname);

     TextColor(Brown);
     GotoXY(01,03);
     Write ('MagFeld   SW         Sollwert     Sollwert       MWert');
     GotoXY(01,04);
     Write (' [kG]    [Hex]        [Volt]      [Ampere]       [Gau·]');
     TextColor (Black);

     for I := 0 to Tab_Index_Max do                        {Init fÅr Tabelle}
      begin
        Tab_SW :=  SwTab [I].Volt;
        GotoXY(01,I+Z_Offset); write(SwTab [I].Gaus:5:2);
        GotoXY(10,I+Z_Offset); write(hex_word(Tab_SW));
        GotoXY(20,I+Z_Offset); Write_Real_10V_Bipol  (Tab_SW);
        GotoXY(35,I+Z_Offset); Write_Real_200A_Bipol (Tab_SW);
        GotoXY(50,I+Z_Offset); Write(SwTab [I].MWert:5:2);
      end; {for}
    Ini_Msg_Win;
    write ('Weiter mit beliebiger Taste!!');
    repeat until KeyEPressed;
   end; {Show_Tab}


  procedure Mil_WrSoft (SW_New: Word; SoftFct: TFct; MilErr: TMilErr);
  { Diese Routine fÑhrt zu einem neuen Sollwert nur in definierten Schritten. bis der
    Dazu mu· der letzte Sollwert gespeichert werden!
  }
   var SW_New_Int : Integer;
       SW_Old_Int : Integer;
   begin
     SoftFct.B.Fct := Fct_Wr_Sw1;
     SW_New_Int := SW_New;
     SW_Old_Int := SW_Old;
     while SW_New_Int <> SW_Old_Int do
      begin
        if SW_New_Int > SW_Old_Int  then SW_Old_Int := SW_Old_Int + 1;
        if SW_New_Int < SW_Old_Int  then SW_Old_Int := SW_Old_Int - 1;
        Mil.Wr (SW_Old_Int, SoftFct, MilErr);
        Set_Text_Win;
        Transf_Cnt := Transf_Cnt+ 1;
        GotoXY(17,10); write(transf_cnt:10);
        GotoXY(47,11); write(hex_word(SW_Old_Int));
        GotoXY(55,11); Write_Real_10V_Bipol  (SW_Old_Int);
        GotoXY(68,11); Write_Real_200A_Bipol (SW_Old_Int);
        Mil.Timer2_Wait(Step_Time);
      end; {while}
     SW_Old := SW_New;       {Rette den alten Sollwert}
   end; {Mil_WrSoft}

  procedure WrSW_Spezial_Fast (SW: Real; Delta: Integer);
  {FÅr Magnetsonden-Messungen ist es gewÅnscht, einen Sollwert iterativ zu
   schreiben: z. B. SW -100, N x (SW +/- 200), SW                              }
   var SW_Real : Real;
       SW_Int  : Integer;
       Test_Intervall : LongInt;
       N : Word;
   begin
     SW_Int    := 0;
     Fct.B.Fct := Fct_Wr_Sw1;
     {Beginn der Iterationen}
     SW_Real := SW - Delta;              { 1. Wert: Sollwert -  Counts }
     SW_Int  := Round (SW_Real);         {Real in Integer umwandeln}
     Mil_WrSoft  (SW_Int, Fct, MilErr);  {Mil.Wr}

     for N := 1 to Iterat_Max do
      begin
        SW_Real := SW_Real + Delta;
        SW_Int  := Round (SW_Real);
        Mil_WrSoft  (SW_Int, Fct, MilErr);
         Mil.Timer2_Wait(Top_Time);

        SW_Real := SW_Real - Delta;
        SW_Int  := Round (SW_Real);         {Real in Integer umwandeln}
        Mil_WrSoft  (SW_Int, Fct, MilErr);  {Mil.Wr}
         Mil.Timer2_Wait(Top_Time);
      end; {for}
     SW_Real := SW;                      {Ende: Sollwert einstellen}
     SW_Int  := Round (SW_Real);         {Real in Integer umwandeln}
     Mil_WrSoft  (SW_Int, Fct, MilErr);  {Mil.Wr}
   end;  {WrSW_Spezial}

 procedure Mil_WrSoft_Quick2 (SW_New: Word);
   var SW_New_Int : Integer;
       SW_Old_Int : Integer;
   begin
     Fct.B.Fct := Fct_Wr_Sw1;
     SW_Old_Int    := SW_Old;
     SW_New_Int    := SW_New;

     while SW_New_Int <> SW_Old_Int do
      begin
        if SW_New_Int > SW_Old_Int  then                 {Neuer Wert>}
         begin
          if (SW_New_Int  - SW_Old_Int) >= Iterat_Wert_Min then
              SW_Old_Int := SW_Old_Int   + Iterat_Wert_Min
          else
              SW_Old_Int := SW_Old_Int   + 1;
         end;

       if SW_New_Int < SW_Old_Int  then
         begin
          if (SW_New_Int  - SW_Old_Int) <= (-Iterat_Wert_Min) then
              SW_Old_Int := SW_Old_Int -   Iterat_Wert_Min
          else
              SW_Old_Int := SW_Old_Int  - 1;
         end;

        Mil.Wr (SW_Old_Int, Fct, MilErr);
        Set_Text_Win;
        Transf_Cnt := Transf_Cnt+ 1;
        GotoXY(17,10); write(transf_cnt:10);
        GotoXY(47,11); write(hex_word(SW_Old_Int));
        GotoXY(55,11); Write_Real_10V_Bipol  (SW_Old_Int);
        GotoXY(68,11); Write_Real_200A_Bipol (SW_Old_Int);
        Mil.Timer2_Wait(0);
      end; {while}
     SW_Old := SW_Old_Int;       {Rette den alten Sollwert}
   end; {Mil_WrSoft_Quick2}

 procedure Wr_Quick2 (SW_New: Word);
  var X : Word;
  begin
    for X := 1 to 5 do
     begin
      Mil_WrSoft_Quick2 (Gaus_Max);
      Mil_WrSoft_Quick2 (0);
     end;

    Mil.Timer2_Wait(2000000);
    Mil_WrSoft_Quick2 (SW_New);
    Mil.Timer2_Wait(Top_Time);
    WrSW_Spezial_Fast (SW_New, Iterat_Wert_Max);
    WrSW_Spezial_Fast (SW_New, Iterat_Wert_Min);
  end; {Wr_Quick2}

 procedure Displ_Istwerte (IX: Word);   {IX =Tab-Index}
  const
    Gaus_Const = 0.610351562;
    Z_Base_IW = 03;
    X_IW_KSPV  = 16;
    X_IW_HALL  = 30;
    X_IW_Delta = 41;
    X_IW_MWERT = 53;
    X_IW_STDAW = 67;
    Z_Pos_IW3 = 12;
    X_Pos_IW3 = 18;    {neu im TextFenster!!}

 var Life_Mode   : TLife_XY;
     KSPV_Real   : Real;
     KSPV_Int    : Integer;
     Delta_Real  : Real;
     Delta_Int   : Integer;
     MWert_Real  : Real;
     Std_Abw_Real: Real;

   procedure get_data (Num : Byte);
    var  Rd_Dta : Word;
    begin
     Set_IstwDisp_Win; TextColor(Yellow);
     Fct.B.Fct := Fct_Start_Conv;          {070199} {wegen ADC-Hw-énderung}
     Mil.WrFct (Fct, MilErr);
     Mil.Timer2_Wait (ADC_Conv_Wait);
     case Num of
      1: Fct.B.Fct := Fct_Rd_Ist1; {81 IW1}
      2: Fct.B.Fct := Fct_Rd_Ist2; {82 IW2}
      3: Fct.B.Fct := Fct_Rd_Ist3; {83 IW3}
     end;

     Mil.Rd (Rd_Dta, Fct, MilErr);
     IF MilErr  <> No_Err THEN
      Begin
        timout_cnt := timout_cnt + 1;
        rd_timeout := TRUE;
        TextColor (Black);
        case Num of
         1: begin
             GotoXY(X_IW_Hall  , Z_Base_IW);  Write('    ');
             GotoXY(X_IW_Delta , Z_Base_IW);  Write('       ');
             GotoXY(X_IW_STDAW , Z_Base_IW);  Write('       ');
           end;
         2: begin
             GotoXY(X_IW_Hall  , Z_Base_IW+1);  Write('    ');
             GotoXY(X_IW_Delta , Z_Base_IW+1);  Write('       ');
             GotoXY(X_IW_STDAW , Z_Base_IW+1);  Write('       ');
            end;
         3: begin
             Set_Text_Win;
             GotoXY(47,Z_Gaus_KG); Write('    ');
             GotoXY(55,Z_Gaus_KG); Write('          ');
             Set_IstwDisp_Win;
            end;
         end; {case}
      End
     ELSE
      Begin  {kein Timeout}
       rd_timeout  := FALSE;
       KSPV_Real   := (SwTab [IX].Gaus * 1000)/Gaus_Const;
       KSPV_Int    := Round (KSPV_Real);            {Real in Integer umwandeln}
       MWert_Real  := SwTab [IX].MWert;

       case Num of
        1: begin
            Delta_Real  := (Rd_Dta - KSPV_Real) * Gaus_Const;
            Std_Abw_Real:= Delta_Real - MWert_Real;
            GotoXY(X_IW_KSPV  , Z_Base_IW);  TextColor(Blue);  Write(hex_word(KSPV_Int));  TextColor(White);
            GotoXY(X_IW_Hall  , Z_Base_IW);                    Write(hex_word(Rd_Dta));
            GotoXY(X_IW_Delta , Z_Base_IW);                    Write(Delta_Real:7:1);
            GotoXY(X_IW_MWERT , Z_Base_IW);  TextColor(Blue);  Write(MWert_Real:7:1);      TextColor(White);
            GotoXY(X_IW_STDAW , Z_Base_IW);                    Write(Std_Abw_Real:7:1);
           end;
        2: begin
            Delta_Real  := (Rd_Dta - KSPV_Real) * Gaus_Const;
            Std_Abw_Real:= Delta_Real - MWert_Real;
            GotoXY(X_IW_KSPV  , Z_Base_IW+1);  TextColor(Blue);  Write(hex_word(KSPV_Int)); TextColor(White);
            GotoXY(X_IW_Hall  , Z_Base_IW+1);                    Write(hex_word(Rd_Dta));
            GotoXY(X_IW_Delta , Z_Base_IW+1);                    Write(Delta_Real:7:1);
            GotoXY(X_IW_MWERT , Z_Base_IW+1);  TextColor(Blue);  Write(MWert_Real:7:1);     TextColor(White);
            GotoXY(X_IW_STDAW , Z_Base_IW+1);                    Write(Std_Abw_Real:7:1);
           end;
        3: begin
             Set_Text_Win;
             GotoXY(47,Z_Gaus_KG); write(hex_word(Rd_Dta));
             GotoXY(55,Z_Gaus_KG); Write_Real_10V_Bipol (Rd_Dta);
 {            Set_IstwDisp_Win;   }
           end;
        end; {case}
      End;
    end; {get_data}

  begin
    Life_Mode.Mode    := Norm;      {Parameter fÅr Lebenszeichen definieren}
    Life_Mode.PosX    := 01;        {02;}
    Life_Mode.PosY    := 01;        {12;}
    Life_Mode.Time    := Life_Time_Slow;
    Life_Mode.Disp_Win:= Set_IstwDisp_Win; {Darstellungs-Fenster}
    Life_Sign_XY (Life_Mode);

    get_data (1);
    get_data (2);
    get_data (3);
  end; {Displ_Istwerte}


 Begin
               {Sw-Tabelle Default-Werten fÅllen}
  for I := 0 to Tab_Index_Max do                        {Init fÅr Tabelle}
   begin
     SwTab [I].Volt   := HallSw [I].Volt;
     SwTab [I].Gaus   := HallSw [I].Gaus;
     SwTab [I].MWert  := HallSw [I].MWert;
  end;

  File_Ok := False;
  I := 0;
  Assign (SwFile, Sw_Fname);
  {$I-}                            {Compiler Check aus, Error selber abfangen}
  Reset(SwFile);
  {$I+}
  if IoResult <> 0 then                             {PrÅfe, ob File existiert}
    begin
     Default_Tab := True;
     Ini_Text_Win;
     Ini_Err_Win;
     Write('ERROR: Datei ',Sw_Fname,' fehlt. Default Datei anlegen? [J/N]: ');
     if ReadKey in ['j','J'] then
      begin
        for I := 0 to Tab_Index_Max do                        {Init fÅr Tabelle}
         begin
           SwTab [I].Volt   := HallSw [I].Volt;
           SwTab [I].Gaus   := HallSw [I].Gaus;
           SwTab [I].MWert  := HallSw [I].MWert;
        end;
        ReWrite(SwFile);                        {existiert nicht: File erzeugen}
        Write(SwFile,SwTab);                   {Tabelle in File speichern}
        Close(SwFile);
        File_Ok := True;
       end; {if j}
    end
   else
    begin
     Default_Tab := False;
     Read (SwFile, SwTab);                   { File existiert: Lese Tabelle}
     Close(SwFile);
     File_Ok := True;
    end;

    Fct.B.Adr := Ifc_Test_Nr;
    Fct.B.Fct := Fct_Wr_Sw1;
    Loop      := False;
    Ini_Text_Win;
    Tab_Index  := 0;
    SW_Old     := 0;
    transf_cnt := 0;
    error_cnt  := 0;
    timout_wr  := 0;
    Data_Increment := 0;
    Intervall  := 0;
    Prozent    := 0;
    Step_Time := Ask_Step_Time;
    Top_Time  := Ask_Top_Time;

    Show_Tab;
    Ini_Text_Win;
    TextColor (Yellow);
    GotoXY(16,02); Write('**************  Variable Tabelle Quick2 ***************');
    TextColor (Black);
    GotoXY(15,03); Write('----- Schreibe Daten auf den MIL-BUS mit Fct-Code -----');
    GotoXY(10,04); Write('Sollwert-Daten kînnen in definierten Inkrementen verÑndert werden. ');
    GotoXY(05,05); Write('Die Tasten F1...F4 bestimmen Inkr-Wert, Pfeiltasten <- u. -> die Richtung.');
    GotoXY(10,06); Write('Falls Pfeiltasten dauernd gedrÅckt werden: Wiederholtes Senden!!');

    GotoXY(02,07); TextColor(Yellow);
    Write('SW_TAB, Gau·-Max[H]:');      TextColor(White); Write(Hex_Word(Gaus_Max)); TextColor(Yellow);
    Write (', SW 0.0, SW_TAB, '); Write ('Iterat. '); TextColor (White);
    Write (Iterat_Max);                 TextColor(Yellow);
    Write(' x SW_TAB - ');              TextColor (White); Write(Iterat_Wert_Max);
    Write('/'); Write(Iterat_Wert_Min); TextColor(Yellow); Write(', SW_TAB');

    Textcolor (Brown);
    GotoXY(25,08); write  ('Function-Word (Fct + Adr): ');
    TextColor(Black); Write (hex_word(Fct.W));
    TextColor(Brown); Write(' [H]');

    GotoXY(2, 10);        Write('Wr-Data-Cnt :                                [Hex]     [VOLT]    [max.200 AMP]');
    GotoXY(2, 11);        write('Gau·-Tab [H]:                 Write-Data   :                    ',chr($F7),'         ');
    GotoXY(2, Z_Gaus_KG); write('Gau·-Tab[kG]:                 Istwert [83H]:                                         ');
    TextColor(Black);
    GotoXY(47,11); write(hex_word(wr_data));
    GotoXY(55,11); Write_Real_10V_Bipol (Wr_Data);

    TextColor(Brown);
    GotoXY(06,18); write('Inkrment[H]  :');
    GotoXY(06,19); write('              ');
    GotoXY(06,20); write('Top-Zeit[sec]:');
    GotoXY(06,21); write('Step-Zeit[us]:');
    TextColor(Black);
    GotoXY(21,18); write(Hex_Word(Data_Increment));
    GotoXY(21,19);
    Top_Time_Real:= (Top_Time * 10/1000000);
    GotoXY(21,20); write(Top_Time_Real:4:2);
    GotoXY(21,21); write(Step_Time * 10);

    Set_TastHall_Win;
    TextColor(Yellow);
    GotoXY(01, 01); Write('F1:1    F5 :SW 0.0  F11:SW iterativ      ');
    GotoXY(01, 02); Write('F2:10   F6 :SW Tab  F12:Tabelle speichern');
    GotoXY(01, 03); Write('F3:100  F7 :SW Hex  <- -> Incr neg/pos   ');
    GotoXY(01, 04); Write('F4:1000 F10:IfcAdr  ', chr($19),'   ', chr($18),' TAB auf/ab     ');

    Ini_IstwDisp_Win;
    TextColor(Yellow);
    GotoXY(13, 01); Write('KERN   SPIN     IW HALL    DELTA   [G]    MWERT     STD ABW [G]');
    GotoXY(13, 02); Write('Vorgabe [H]      [Hex]     IWHall-Vorg     [G]      Delta-MWert');
    GotoXY(01, 03); Write('HALL [81H]:');
    GotoXY(01, 04); Write('HALL [82H]:');

    Set_Text_Win;
    TextColor(Brown);
    GotoXY(39,17); write('Belegung Funktions- u. Sondertasten: ');
    TextColor(Black);

    Mil.Reset;                            { clear fifo }
    Cursor(False);
    Ini_Msg_Win;
    Write('Funktions- u. Sondertasten benutzen!     Ende mit [X]');

    repeat
     Displ_Istwerte (Tab_Index);
     if KeyEPressed then
      begin
       Ch := NewReadKey;
       if Ch = #0 then                  {Sonder-Tasten Abfrage}
        begin
         Ch := NewReadKey;
         case ord (Ch) of
           Taste_F1 : begin
                       Data_Increment := 1;
                       Set_Text_Win;
                       GotoXY(21,18); write(Hex_Word(Data_Increment));
                      end;
           Taste_F2 : begin
                       Data_Increment := $10;
                       Set_Text_Win;
                       GotoXY(21,18); write(Hex_Word(Data_Increment));
                      end;
           Taste_F3 : begin
                       Data_Increment := $100;
                       Set_Text_Win;
                       GotoXY(21,18); write(Hex_Word(Data_Increment));
                     end;
           Taste_F4 : begin
                       Data_Increment := $1000;
                       Set_Text_Win;
                       GotoXY(21,18); write(Hex_Word(Data_Increment));
                      end;
           Taste_F5 : begin
                       Tab_Index := 0;
                       Wr_Data := HallSw [Tab_Index].Volt;
                       Wr_Gaus := HallSw [Tab_Index].Gaus;
                       Set_Text_Win;
                       TextColor(Blue);
                       GotoXY(X_Gaus_HX, Z_Gaus_KG-1); write(Hex_Word(Wr_Data));
                       GotoXY(X_Gaus_KG, Z_Gaus_KG); write(Wr_Gaus:5:2);
                       TextColor(Black);
                       WrSW_Spezial_Fast (Wr_Data, Iterat_Wert_Mid);
                      end;
           Taste_F6 : begin
                        Set_IstwDisp_Win;        {Lîsche Istwerte}
                        Set_Text_Win;
                        Wr_Data := SwTab [Tab_Index].Volt;
                        Wr_Gaus := SwTab [Tab_Index].Gaus;
                        TextColor(Blue);
                        GotoXY(X_Gaus_HX, Z_Gaus_KG-1); write(Hex_Word(Wr_Data));
                        GotoXY(X_Gaus_KG, Z_Gaus_KG);   write(Wr_Gaus:5:2);
                        TextColor(Black);
                        Wr_Quick2 (Wr_Data);
                      end;
           Taste_F7 : begin
                        if (Ask_Hex_Break (Wr_Data, Wrd)) then
                         begin
                           Set_Text_Win;
                           GotoXY(47, 12); ClrEol;
                           Ini_Msg_Win;
                           Write('Funktions- u. Sondertasten benutzen!     Ende mit [X]');
                           Wr_Quick2 (Wr_Data);
                         end;
                        Ini_Msg_Win;
                        Write('Funktions- u. Sondertasten benutzen!     Ende mit [X]');
                      end;
          Taste_F10: begin
                        New_Ifc_Adr;
                        Fct.B.Adr := Ifc_Test_Nr;
                        Set_Text_Win;
                        TextColor(Brown);
                        GotoXY(25,08); Write  ('Function-Word (Fct + Adr): ');
                                       TextColor(Black); Write(hex_word(Fct.W)); Write(' [H]');
                        Ini_Msg_Win;
                        Write('Funktions- u. Sondertasten benutzen!     Ende mit [X]');
                        repeat until KeyEPressed;
                     end; {Taste_F10}

          Taste_F11: begin    {aktuelle Wr-Daten nochmals iterativ schreiben}
                       Wr_Quick2 (Wr_Data);
                      end; {Taste_F10}
          Taste_F12: begin
                       Ini_Err_Win;
                       Write ('GeÑnderten Tabellenwert wirklich abspeichern [J/N] ?: ');
                       Ch := NewReadKey;
                       if Ch in ['j','J'] then
                        begin
                          {$I-}   {Compiler Check aus, Error selber abfangen}
                          Reset(SwFile);
                          {$I+}
                          if IoResult <> 0 then    {PrÅfe, ob File existiert}
                             ReWrite(SwFile)  {existiert nicht: File erzeugen}
                          else
                             SwTab [Tab_Index].Volt := Wr_Data;
                          Write(SwFile,SwTab);  {Tabelle in File speichern}
                          Close(SwFile);
                         end;  {ja}
                        Ini_Msg_Win;
                        Write('Funktions- u. Sondertasten benutzen!     Ende mit [X]');
                      end; {Taste_F12}
          Taste_Pfeil_Links : begin
                                 Wr_Data := Wr_Data - Data_Increment;
                                 Set_Text_win;
                                 GotoXY(20,18); write(Hex_Word(Data_Increment));
                                 Fct.B.Fct := Fct_Wr_Sw1;
                                 Mil_WrSoft  (Wr_Data, Fct, MilErr);  {Mil.Wr}
                               end;

           Taste_Pfeil_Rechts: begin
                                Wr_Data := Wr_Data + Data_Increment;
                                Set_Text_win;
                                GotoXY(20,18); write(Hex_Word(Data_Increment));
                                Fct.B.Fct := Fct_Wr_Sw1;
                                Mil_WrSoft  (Wr_Data, Fct, MilErr);   {Mil.Wr}
                               end;
           Taste_Pfeil_Auf   : begin
                                Tab_Index := Tab_Index + 1;
                                if Tab_Index > Tab_Index_Max then Tab_Index := Tab_Index_Max;
                                Set_Text_Win;
                                TextColor(Blue);
                                Wr_Gaus := SwTab [Tab_Index].Gaus;
                                GotoXY(X_Gaus_KG, Z_Gaus_KG); write(Wr_Gaus:5:2);
                                Gaus_Hex := SwTab [Tab_Index].Volt;
                                GotoXY(X_Gaus_HX, Z_Gaus_KG-1); write(Hex_Word(Gaus_Hex));
                                TextColor(Black);
                               end;
           Taste_Pfeil_Ab   : begin
                                Tab_Index := Tab_Index - 1;
                                if Tab_Index < 0 then  Tab_Index := 0;
                                Set_Text_Win;
                                TextColor(Blue);
                                Wr_Gaus := SwTab [Tab_Index].Gaus;
                                GotoXY(X_Gaus_KG, Z_Gaus_KG); write(Wr_Gaus:5:2);
                                Gaus_Hex := SwTab [Tab_Index].Volt;
                                GotoXY(X_Gaus_HX, Z_Gaus_KG-1); write(Hex_Word(Gaus_Hex));
                                TextColor(Black);
                               end;
         end;  {Case}
       end;    {if char = 0}
      end; {if keypressed}
     until Ch in ['x','X'];
   99:  Cursor(True);
 end; {Mil_WrHall_Var_IwDisp_Quick2}

                                          {Bis hierher User-Erweiterungen !!}
BEGIN   { Hauptprogramm MIL-BASE }
  Ifc_Test_Nr := 0;
  Dual[1].Adr := 0;        {Init Dual-Mode Array}
  Dual[1].Fct := 0;
  Dual[1].Dta_ok := False;
  Dual[1].Dta := 0;
  Dual[2].Adr := 0;
  Dual[2].Fct := 0;
  Dual[2].Dta_ok := False;
  Dual[2].Dta := 0;

  REPEAT
    menue_win;
    User_Input := NewReadKey;
    loop := TRUE;
    IF User_Input IN ['0'..'9'] THEN loop := FALSE;
    CASE User_Input OF
     '0'      : Mil_Detect_Ifc;
     '1'      : Mil_Detect_Ifc_Compare;
     '2'      : begin
                  if Check_Ifc_Adr(Ifc_Test_Nr) then Mil_Rd_HS_Ctrl (Ifc_Test_Nr);
                end;
     '3'      : begin
                  if Check_Ifc_Adr(Ifc_Test_Nr) then Mil_Rd_HS_Status (Ifc_Test_Nr);
                end;
     '4'      : begin
                  if Check_Ifc_Adr(Ifc_Test_Nr) then Mil_Stat_All (Ifc_Test_Nr);
                end;
     '5'      : begin
                  Convert_Hex_Volt;
                end;
     '6'      : begin
                  Int_Mask;
                end;
     '7'      : begin
                  if Check_Ifc_Adr(Ifc_Test_Nr) then Mil_HS_Stat_Cmd (Ifc_Test_Nr);
                end;
     '9'      : begin
		  if Check_Ifc_Adr(Ifc_Test_Nr) then Mil_Echo (Ifc_Test_Nr);
                end;
     'a', 'A' : Mil_Ask_Ifc;
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
                  if Check_Ifc_Adr(Ifc_Test_Nr) then Mil_Rd_Data;
		end;
     'f', 'F' : begin
                  Functioncode_Table;
                end;
     'g', 'G' : begin
                  Mil_Data := Ask_Data;
		  Mil_WrData (Mil_Data);
                end;
     'h', 'H' : begin
		  if Check_Ifc_Adr(Ifc_Test_Nr) then Mil_Wr_Fctcode;
                end;
     'i', 'I' : begin
                  if Check_Ifc_Adr(Ifc_Test_Nr) THEN
                   begin
		     Mil_Wr(Mil_Data);
                   end;
                end;
     'j', 'J' : begin
		  if Check_Ifc_Adr(Ifc_Test_Nr) then
		    begin
		     Mil_Data := Ask_Data;
		     Mil_Wr_Rd (Mil_Data);
 		    end;
                end;
     'k', 'K' : begin
		  if Check_Ifc_Adr(Ifc_Test_Nr) then Mil_Loop;
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
                  Mil_Stat_Tabelle;
                end;
     'n', 'N' : begin
                  Mil_SW_IW;
                end;
     'o', 'O' : begin
                  Mil_NG_Puls_Fix;
                end;
     'p', 'P' : begin
                  Mil_NG_Puls_Vari;
                end;
     'q', 'Q' : begin
                  Mil_NG_Rampe;
                end;
     'r', 'R' : begin
                  Mil_Ask_Ifc;
                  Mil_Data := 0;
	          Mil_WrHall_Var_IwDisp_Quick1 (Mil_Data);
                end;
     's', 'S' : begin
                  Mil_Ask_Ifc;
                  Mil_Data := 0;
	          Mil_WrHall_Var_IwDisp_Quick2 (Mil_Data);
                end;
     't', 'T' : begin

                end;

     'u', 'U' : begin               {Testweise, soll S ersetzen}
                end;
    End; {CASE}
  UNTIL user_input in ['x','X'];
  Window(1, 1, 80, 25);
  TextBackground(Black);

  PCI_DriverClose(PCIMilCardNr);

  ClrScr;
END. {mil_mag}

