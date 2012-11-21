program Mil_Adac;
{$APPTYPE CONSOLE}
{ Autor des Basis-Programmes Mil_Base.Pas: G. Englert;      Erstellt 12.04.95
  Basis-Programm als Grundlage fÅr anwender-spezifische Erweiterungen
  Achtung: Bei Erweiterungen den Namen des Programmes Ñndern in MIL_xxxx.PAS
  Wegen Jahr 2000: File-Datum unter DOS ist ab 1.1.2000 -> 01.01.80


   Displ_HS_Status;
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

  29.11.95    Et        Ausbau zum 16-Bit DAC-ADC-Testprogramm FG 429 043
  05.12.95    Et        ADC-Abgleich
  08.12.95    Et        DAC-Abgleich mit Bit-Shiften
  08.02.96    Et        Konvert Hex-Volt; Punkt E: Lesen
  03.05.96    Et        Punkt M: Sollwert schreiben erweitert
  10.11.97    Et        Punkt M: 2. Anzeige mit 0..10V = 16-bit DAC
  09.12.98    Et        Bei Adc-Abgleich (Q) Wartezeit eingefÅgt:  Mil.Timer2_Wait (20);
  15.12.98    Et        FTasten belegt
        Ab hier kînnen geÑnderte Stellen mit dem énderungscode gesucht werden
  05.01.99  Et  050199  Read_ADC: Reihenfolge Trigger, Wait, Read neu
  29.03.99  Et  290399  Q: Read ADC auf minimal 200 us verlÑngert
                        Åberall nach StartConvert !!!
  31.03.99              R, S Time 200
  23.02.00              wegen MIL-Timeout neu compiliert
  20.01.04  MZ  200104  Punkt S: Fehler in der Auswertung und andere korregiert
  18.05.05  MZ  180505  rd_wait von 50 auf 70 geaendert. Wunsch von RW
  15.02.07  MZ  150207  rd_wait von 70 auf 200 geaendert.Wunsch von RW
  19.02.07  MZ  190207  rd_wait von 70 auf 200 geaendert.Wunsch von RW
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

CONST
 Head_Line =
      'BELAB                        MIL_ADAC PCI-Mil Vers.' +
      '                    [06.2009]' +
      '                        16Bit/+-10V DAC/ADC [FG 429 044]                     ';


procedure menue_win;
VAR answer: CHAR;
begin
  Ini_Headl_Win;
  Write(Head_Line);
  Menue_Base;            {Festliegender Teil des MenÅs: s. a. DATECH_1.PAS}
  TextColor(Blue);

  GotoXY(5, 14);
  Writeln('       [M]<--  DAC 703/701 +10V/Shift/Incr/0,5V/Hex  (ConvCmd 5F, Fct 06,07');
  GotoXY(5, 15);
  Writeln('       [N]<--  DAC 703 Abgleich ------------(Fixe Sollwerte als Hex-Daten) ');
  GotoXY(5, 16);
  Writeln('       [O]<--  DAC 703 LinearitÑt ----------(N*1V Sollwerte + Voltmeter)   ');
  GotoXY(5, 17);
  Writeln('       [P]<--  DAC 703/ADC 71 Test ---------(Bitweises l/r schieben) mit 5F');
  GotoXY(5, 18);
  Writeln('       [Q]<--  ADC 71  Abgleich ------------(Offset, Gain, Null)     mit 5F');
  GotoXY(5, 19);
  Writeln('       [R]<--  Autom. Vergl.DAC->ADC [0..10V] (Vorgabe max. Abweich) mit 5F');
  GotoXY(5, 20);
  Writeln('       [S]<--  Autom. Vergl.DAC->ADC [+/-10V] (Vorgabe max. Abweich) mit 5F');
{                                                                        GotoXY(5, 20);
  Writeln('       [S]<--                                                            ');
  GotoXY(5, 21);
  Writeln('       [T]<--                                                            ');
}
  Ini_Msg_Win;
  Write('Bitte Auswahl eingeben:                                          EXIT: X-Taste ');

 End; {menue_win}
{xxx Ab hier sollten User-Erweiterungen beginnen!!}
var
Single_Step: Boolean;              {Globale Variable}


 type TLife = (Norm, Blink);

 procedure Life_Sign (Mode: TLife);
  const S_Aktiv   = 04;
        Z_Aktiv   = 15;
        Life_Time1 = 5000;
        Life_Time2 = 2000;
  var Life_Wait : LongInt;
  begin
    Cursor (False);
    Set_Text_Win;
    if Mode = Norm then
     begin
      Life_Wait := Life_Time1;
      Set_Text_Win;
      TextColor(Yellow);
      GotoXY(S_Aktiv, Z_Aktiv);  Write (chr($7C)); Mil.Timer2_Wait (Life_Wait);
      GotoXY(S_Aktiv, Z_Aktiv);  Write ('/');      Mil.Timer2_Wait (Life_Wait);
      GotoXY(S_Aktiv, Z_Aktiv);  Write (chr($2D)); Mil.Timer2_Wait (Life_Wait);
      GotoXY(S_Aktiv, Z_Aktiv);  Write ('\');      Mil.Timer2_Wait (Life_Wait);
     end
    else
     begin
       TextColor(Red+128);
       GotoXY(S_Aktiv, Z_Aktiv); Write (chr($B2));
     end;
    TextColor(Black);
    Cursor(True);
   end; {Life_Sign}



procedure Mil_DAC_SetSw;
  LABEL 99;
  const Z_Base = 13;
        Tab_Index_Max = 40;
 type
  TSW_Ary  = array [0..Tab_Index_Max] of Real;

 const
   SW_Tab : TSW_Ary =
    ( -10.0, -9.5, -9.0, -8.5, -8.0, -7.5, -7.0, -6.5, -6.0, -5.5,
      - 5.0, -4.5, -4.0, -3.5, -3.0, -2.5, -2.0, -1.5, -1.0, -0.5,

      0.0,  0.5,  1.0,  1.5,  2.0,  2.5,  3.0,  3.5,  4.0,  4.5,
      5.0,  5.5,  6.0,  6.5,  7.0,  7.5,  8.0,  8.5,  9.0,  9.5,
     10.0
     );

   VAR
     error_cnt  : LONGINT;
     MilErr : TMilErr;
     Fct    : TFct;
     OnlineErr  : TOnlineErr;
     RetAdr     : Byte;
     Bit16_Str  : Str19 ;
     Shift_Mode : Boolean;
     Tab_Index  : Integer;
     Real_Data  : Real;
     Loop       : Boolean;

 procedure Set_SW_Win;
  begin
   Window(42, 20, 80, 23);
   TextBackground(Green);
   TextColor(Black);
  end;

 procedure Write_SW (SW_Data: Word);
  begin
   Set_Text_Win;
   Transf_Cnt:= Transf_Cnt + 1;
   GotoXY(18,10); write(transf_cnt:10);
   GotoXY(31,13); write(hex_word(SW_Data));
   GotoXY(25,14); Write_Real_10V_Bipol (SW_Data);
   Hex_Bin_Str (SW_Data, Bit16_str);
   GotoXY(22,15);  Write(Bit16_str);
   {Sollwert auch als 0..+10V anzeigen}
   GotoXY(45,14); Write_Real_10V_Unipol (SW_Data);
   Mil.Wr (SW_Data, Fct, MilErr);
  end;

  begin
    Mil_Ask_Ifc;
    Tab_index := 20;
    Loop := False;

    Ini_Text_Win;
    GotoXY(5, 10);
    TextColor(Red);               {Setze Schriftfarbe}
    Write('Beachten: Abgleich erst sinnvoll nach 5 Minuten Warmlauf der Hardware!! ');
    TextColor(Black);               {Setze Schriftfarbe}
    GotoXY(5, 22);
    write ('Welchen Write-Function-Code [06, 07, 08, 09] ??');
    Fct.B.Adr := Ifc_Test_Nr;
    Fct.B.Fct := ask_hex_byte;

    Ini_Text_Win;
    transf_cnt := 0;
    error_cnt  := 0;
    timout_wr  := 0;
    Shift_Mode := False;

    TextColor(Brown);               {Setze Schriftfarbe}
    GotoXY(25,01); write('----- Schreibe DAC-Sollwert -----');
    GotoXY(15,03); Write('Sollwert-Daten kînnen auf drei Arten festgelegt werden: ');
    GotoXY(04,04); Write(' - aus einer Tabelle fester Werte mit den Pfeiltasten ',chr($19),' ',chr($18),' oder  ');
    GotoXY(04,05); Write(' - durch Bitschieben    (F1) und anschlie·end  <-- -->    oder ');
    GotoXY(04,06); Write(' - als Inkremente +/- 1 (F2) zum aktuellen Wert mit den Pfeiltasten <-- -->');

    GotoXY(25,08); write  ('Function-Word (Fct + Adr): ',hex_word(Fct.W),' [H]');
    GotoXY(6, 10); writeln('Wr-Data-Cnt: ');
    GotoXY(22,11); writeln('^  ^');

    GotoXY(27,12); writeln('[+/- 10V]');
    GotoXY(46,12); writeln('[0...10V]');
    GotoXY(06,13); writeln('Write-Data[H]: ');
    GotoXY(31,13); write(hex_word(write_data));
    GotoXY(06,14); writeln('Data   [Volt]: ');
    GotoXY(25,14); Write_Real_10V_Bipol (Write_Data);

    GotoXY(06,15); writeln('Data    [BIN]: ');
    GotoXY(22,16); write('MSB             LSB');
    TextColor(Black);
    Hex_Bin_Str (Write_Data, Bit16_str);
    GotoXY(22,15);  Write(Bit16_str);

    TextColor (Brown);
    GotoXY(02,20); Write('Tab-Index [',Tab_index_Max,']: ');
    GotoXY(02,21); Write('Mode          : ');
    TextColor (Black);
    GotoXY(18,20); Write (Tab_Index:2);
    GotoXY(18,21);
    if Shift_Mode then Write ('Shift-Mode') else Write ('Incr-Mode ');

    Set_Text_Win;
    TextColor(Brown);
    GotoXY(42,17); write('Belegung Funktions- u. Sondertasten: ');
    Set_SW_Win;
    TextColor(Yellow);
    GotoXY(01, 01); Write('F1: SW Bit-Shift   F5 :  SW 0.0       ');
    GotoXY(01, 02); Write('F2: SW Increment   F10:  IfcAdr       ');
    GotoXY(01, 03); Write('F3:                <- -> Shift  / Incr');
    GotoXY(01, 04); Write('F4: SW Hex-Input   ', chr($19),'   ', chr($18),' SW-TAB       ');
    TextColor(Black);

    Mil.Reset;                            { clear fifo }
    Ch := ' ';
    if Ch = ' ' then
      begin
       Ini_Msg_Win;
       Write('Stop/Single Step mit <SPACE>, Loop mit <CR> ,  Ende mit [X]');
      end;

    repeat
     if KeyEPressed then Ch := NewReadKey;
     if not (Ch = ' ') then Loop := True;

     if Ch = #0 then
      begin
        Loop := False;
        Ch := NewReadKey;
        case ord (Ch) of
        Taste_F1 : begin
                    Set_Text_Win;
                    Shift_Mode := True;
                    GotoXY(18,21);
                    Write ('Shift-Mode');
                    Ch := ' ';
                   end;
        Taste_F2 : begin
                    Set_Text_Win;
                    Shift_Mode := False;
                    GotoXY(18,21);
                    Write ('Incr-Mode ');
                    Ch := ' ';
                   end;
        Taste_F3 : begin
                   end;
        Taste_F4 : begin
                     Write_Data := ask_hex_word;
                     Write_SW (Write_Data);
                     Ch := ' ';
                   end;
        Taste_F5 : begin
                    Write_Data := 0;
                    Tab_Index := 20;
                    Set_Text_Win;
                    GotoXY(18,20); Write (Tab_Index:2);
                    Write_SW (Write_Data);
                    Ch := ' ';
                  end;
        Taste_F10: begin
                      New_Ifc_Adr;
                      Fct.B.Adr := Ifc_Test_Nr;
                      Set_Text_Win;
                      GotoXY(25,08); write  ('Function-Word (Fct + Adr): ',hex_word(Fct.W),' [H]');
                      Ini_Msg_Win;
                      Write('Step/Stop <Space>, Loop <CR>, Funkt.- u. Sondertasten benutzen!   Ende mit [X]');
                      Ch := ' ';
                   end; {Taste_F10}

        Taste_Pfeil_Links : begin
                             if Shift_Mode then
                               begin
                                 if Write_Data = $0000 then
                                   Write_Data := 1
                                 else
                                   Write_Data := Write_Data shl 1;
  {                                else
                                   begin
                                     if not (Write_Data = $8001) then
                                        Write_Data := Write_Data shl 1;
                                   end;} {if Data 0000}
                               end {if Shift-Mode}
                              else
                               begin   {Increment-Mode}
                                 Write_Data := Write_Data - 1;
                               end;
                              Write_SW (Write_Data);
                              Ch := ' ';
                            end;  {Taste_Pfeil_Links}
         Taste_Pfeil_Rechts: begin
                              if Shift_Mode then
                                begin
                                  if Write_Data = $0000 then
                                    Write_Data := $8000
                                  else
                                    Write_Data := Write_Data shr 1;
  {                                 else
                                    begin
                                      if not (Write_Data = $8000) then
                                         Write_Data := Write_Data shr 1;
                                    end; }
                                end {if Shift-Mode}
                              else
                                begin   {Increment-Mode}
                                  Write_Data := Write_Data + 1;
                                end;
                               Write_SW (Write_Data);
                               Ch := ' ';
                          end;  {Taste_Pfeil_Rechts}
         Taste_Pfeil_Auf   : begin
                              Tab_Index := Tab_Index + 1;
                              if Tab_Index > Tab_Index_Max then Tab_Index := Tab_Index_Max;
                              Real_Data := SW_Tab[Tab_Index];
                              Write_Data := Conv_Real_Hex (Real_Data);
                              Set_Text_Win;
                              GotoXY(18,20); Write (Tab_Index:2);
                              Write_SW (Write_Data);
                              Ch := ' ';
                             end;
         Taste_Pfeil_Ab   : begin
                              Tab_Index := Tab_Index - 1;
                              if Tab_Index < 0 then  Tab_Index := 0;
                              Real_Data := SW_Tab[Tab_Index];
                              Write_Data := Conv_Real_Hex (Real_Data);
                              Set_Text_Win;
                              GotoXY(18,20); Write (Tab_Index:2);
                              Write_SW (Write_Data);
                              Ch := ' ';
                            end;
       end;  {Case}

       Ini_Msg_Win;
       Write('Step/Stop <Space>, Loop <CR>, Funkt.- u. Sondertasten benutzen!   Ende mit [X]');
      end; {if Ch = #0 }

     if Loop then Write_SW (Write_Data);

     if Ch = ' ' then
       begin
        Write_SW (Write_Data);
        Ini_Msg_Win;
        Write('Step/Stop <Space>, Loop <CR>, Funkt.- u. Sondertasten benutzen!   Ende mit [X]');
        repeat until KeyEPressed;
       end;

    until Ch in ['x','X'];
 99:
end; {Mil_DAC_SetSw}

procedure  Mil_DAC_Abgleich;
  LABEL 99;
   VAR
     error_cnt  : LONGINT;
     MilErr     : TMilErr;
     Fct        : TFct;
     OnlineErr  : TOnlineErr;
     RetAdr     : Byte;
     Bit16_Str  : Str19 ;

     PROCEDURE Displ_DAC_Abgleich;
      begin
      {Info-Anzeige}
       ini_info_win;
       writeln(' Feste Werte fÅr DAC-Abgleich ');
       writeln('Taste Text   [Hex]    [Volt]  ');
       writeln('------------------------------');
       writeln;
       writeln('F1    Offset  0000   0.000000 ');
       writeln('F2    Gain    7FFF   9.999694 ');

{       writeln('F1    Gain    7FFF   9.999694 ');
       writeln('F2    Offset  0000   0.000000 ');
}      writeln('F3   -Fscale  8000 -10.000000 ');
       writeln;
       writeln('F4   +Hscale  4000  +5.000000 ');
       writeln('F5   -Hscale  C000  -5.000000 ');
      end; {Displ_DAC_Abgleich;}

   Begin
    Mil_Ask_Ifc;
    Ini_Text_Win;
    GotoXY(5, 10);
    TextColor(Red);               {Setze Schriftfarbe}
    Write('Beachten: Abgleich erst sinnvoll nach 5 Minuten Warmlauf der Hardware!! ');
    TextColor(Black);               {Setze Schriftfarbe}
    GotoXY(5, 22);
    write ('Welchen Write-Functions-Code [06, 07, 08, 09] ??');
    Fct.B.Adr := Ifc_Test_Nr;
    Fct.B.Fct := ask_hex_byte;

    transf_cnt := 0;
    error_cnt  := 0;
    timout_wr  := 0;
    Write_Data  := $0000;

    Ini_Text_Win; TextColor(Blue);
    GotoXY(25,02); write('---------- LinearitÑt DAC ----------');
    GotoXY(25,03); write  ('Function-Word (Fct + Adr): ',hex_word(Fct.W),' [H]');
    GotoXY(6, 11); writeln('Wr-Data-Cnt  : ');
    GotoXY(6, 12); writeln('Timeout      : ');
    GotoXY(25,12); write(timout_wr:10);

    GotoXY(6, 13); writeln('Write-Data[H]: ');
    GotoXY(31,13); write(hex_word(write_data));
    GotoXY(6, 15); writeln('DAC [Volt]   : ');

    GotoXY(06,16); writeln('    Data[BIN]: ');
    GotoXY(22,17); write('MSB             LSB');

    Displ_DAC_Abgleich;
    Mil.Reset;                            { clear fifo }
    Ch := ' ';
    if Ch = ' ' then
      begin
       Ini_Msg_Win;
       Write('Stop/Single Step mit <SPACE>, Loop mit <CR> ,  Ende mit [X]');
       repeat until KeyPressed;
       Ch := ReadKey;
       if Ch = #0 then
        begin
          Ch := ReadKey;
          case ord (Ch) of
           Taste_F1 : write_data := $0000;
           Taste_F2 : write_data := $7FFF;
           Taste_F3 : write_data := $8000;
           Taste_F4 : write_data := $4000;
           Taste_F5 : write_data := $C000;
          end;
          Ch := ' ';
        end;
       if  Ch in ['x','X'] then Goto 99;
      end;

    Ch := ' ';
    repeat
     repeat
       Set_Text_win; TextColor(Black);
       Transf_Cnt := Transf_Cnt + 1;
       GotoXY(25,11); write(transf_cnt:10);
       GotoXY(31,13); writeln(hex_word(write_data));
       GotoXY(25,15); Write_Real_10V_Bipol (Write_Data);
       Hex_Bin_Str (Write_Data, Bit16_str);
       GotoXY(22,16);  Write(Bit16_str);

       Mil.Ifc_Online (Ifc_Test_Nr, RetAdr, OnlineErr);
       if OnlineErr = NoErr then
          Mil.Wr (Write_Data, Fct, MilErr)
       else
         begin
          timout_wr := timout_wr + 1;
          GotoXY(25, 12); write(timout_wr:10);
         end;
     until KeyPressed or (Ch = ' ');

     if Ch = ' ' then
       begin
        Ini_Msg_Win;
        Write('Stop/Single Step mit <SPACE>, Loop mit <CR> ,  Ende mit [X]');
        repeat until KeyPressed;
       end;

     if Ch = #0 then
      begin
        Ch := ReadKey;
        case ord (Ch) of
         Taste_F1 : write_data := $0000;
         Taste_F2 : write_data := $7FFF;
         Taste_F3 : write_data := $8000;
         Taste_F4 : write_data := $4000;
         Taste_F5 : write_data := $C000;
        end;
        Ch := ' ';
      end;
     if Keypressed then Ch := ReadKey;
  until Ch in ['x','X'];
   99:
end; {Mil_DAC_Abgleich}

procedure  Mil_DAC_Lin;
  LABEL 99;
const
 scale_null      = $0;     scale_null_str = '  0,000 00 V';
 scale_pos_full  = $7FFF;  scale_pos_str  = ' +9,999 60 V';
 scale_neg_full  = $8000;  scale_neg_str  = '-10,000 00 V';

 dac_set20  = $7FFF;  dac_str20 = '+ 9,999 60 V';
 dac_set19  = $7333;  dac_str19 = '+ 8,999 64 V';
 dac_set18  = $6667;  dac_str18 = '+ 7,999 68 V';
 dac_set17  = $599A;  dac_str17 = '+ 6,999 72 V';
 dac_set16  = $4CCC;  dac_str16 = '+ 5,999 76 V';
 dac_set15  = $4000;  dac_str15 = '+ 4,999 80 V';
 dac_set14  = $3333;  dac_str14 = '+ 3,999 84 V';
 dac_set13  = $2667;  dac_str13 = '+ 2,999 88 V';
 dac_set12  = $199A;  dac_str12 = '+ 1,999 92 V';
 dac_set11  = $0CCD;  dac_str11 = '  0,999 96 V';
 dac_set10  = $0000;  dac_str10 = '  0,000 00 V';
 dac_set9   = $F333;  dac_str9  = '- 1,000 00 V';
 dac_set8   = $E666;  dac_str8  = '- 2,000 00 V';
 dac_set7   = $D999;  dac_str7  = '- 3,000 00 V';
 dac_set6   = $CCCC;  dac_str6  = '- 4,000 00 V';
 dac_set5   = $C000;  dac_str5  = '- 5,000 00 V';
 dac_set4   = $B333;  dac_str4  = '- 6,000 00 V';
 dac_set3   = $A666;  dac_str3  = '- 7,000 00 V';
 dac_set2   = $9999;  dac_str2  = '- 8,000 00 V';
 dac_set1   = $8CCC;  dac_str1  = '- 9,000 00 V';
 dac_set0   = $8000;  dac_str0  = '-10,000 00 V';

 VAR
     error_cnt  : LONGINT;
     MilErr : TMilErr;
     Fct    : TFct;
     OnlineErr  : TOnlineErr;
     RetAdr     : Byte;

     dac_lin : ARRAY [0..20] OF WORD;
     dac_text: STRING[13];
     i       : BYTE;
     up      : BOOLEAN;
     SollWert: Word;

  PROCEDURE ini_dac_lin;
   Begin
     dac_lin[0] :=dac_set0;
     dac_lin[1] :=dac_set1;  dac_lin[2] :=dac_set2;  dac_lin[3]:=dac_set3;
     dac_lin[4] :=dac_set4;  dac_lin[5] :=dac_set5;  dac_lin[6]:=dac_set6;
     dac_lin[7] :=dac_set7;  dac_lin[8] :=dac_set8;  dac_lin[9]:=dac_set9;
     dac_lin[10]:=dac_set10; dac_lin[11]:=dac_set11; dac_lin[12]:=dac_set12;
     dac_lin[13]:=dac_set13; dac_lin[14]:=dac_set14; dac_lin[15]:=dac_set15;
     dac_lin[16]:=dac_set16; dac_lin[17]:=dac_set17; dac_lin[18]:=dac_set18;
     dac_lin[19]:=dac_set19; dac_lin[20]:=dac_set20;
   End;

   Begin
    Mil_Ask_Ifc;
    Ini_Text_Win;
    Ini_dac_lin;

    GotoXY(5, 10);
    TextColor(Red);               {Setze Schriftfarbe}
    Write('Beachten: Abgleich erst sinnvoll nach 5 Minuten Warmlauf der Hardware!! ');
    TextColor(Black);               {Setze Schriftfarbe}
    GotoXY(5, 22);
    write ('Welchen Write-Function-Code [06, 07, 08, 09] ??');
    Fct.B.Adr := Ifc_Test_Nr;
    Fct.B.Fct := ask_hex_byte;

    Ini_Text_Win;
    transf_cnt := 0;
    error_cnt  := 0;
    timout_wr  := 0;

    GotoXY(15,05); write ('----- DAC LinearitÑtstest mit Voltmeterkontrolle -----');
    GotoXY(25,08); write ('Function-Word (Fct + Adr): ',hex_word(Fct.W),' [H]');
    GotoXY(55,10); write ('Anzeige Voltmeter: ');
    GotoXY(6, 11); write ('Wr-Data-Cnt:              Write-Data[H]:               ');
    GotoXY(22,12); write ('^  ^');
    GotoXY(62,12); write ('^');

    GotoXY(06,13); write('Timeout:');
    GotoXY(18,13); write(timout_wr:10);
    GotoXY(47,11); write(hex_word(write_data));

    I := 10;
    Mil.Reset;                            { clear fifo }
    Ch := ' ';
    if Ch = ' ' then
      begin
       Ini_Msg_Win;
       Write('Stop/Single Step mit <SPACE>, Loop mit <CR> ,  Ende mit [X]');
       repeat until KeyPressed;
       Ch := ReadKey;
       if  Ch in ['x','X'] then Goto 99;
      end;

     repeat
       repeat
         Set_Text_win;
         Transf_Cnt := Transf_Cnt+ 1;
         GotoXY(18,11); write(transf_cnt:10);
         sollwert := dac_lin[i];

         GotoXY(47,11); write(hex_word(SollWert));
         GotoXY(55,11); Write_Real_10V_Bipol (Sollwert);
         Mil.Ifc_Online (Ifc_Test_Nr, RetAdr, OnlineErr);
         if OnlineErr = NoErr then
          begin
           Mil.Wr (SollWert, Fct, MilErr);
          end
         else
          begin
            timout_wr := timout_wr + 1;
            GotoXY(18, 13); write(timout_wr:10);
          end;

        IF up AND (i = 20)    THEN up := FALSE;
        IF (NOT up) AND (i=0) THEN up := TRUE;
        IF  up    THEN i := i + 1;
        IF NOT up THEN i := i - 1;
      until KeyPressed or (Ch = ' ');

     if Ch = ' ' then
       begin
        Ini_Msg_Win;
        Write('Stop/Single Step mit <SPACE>, Loop mit <CR> ,  Ende mit [X]');
        repeat until KeyPressed;
       end;
     Ch := ReadKey;
    until Ch in ['x','X'];
    99:
end; {Mil_DAC_Lin}


  procedure  Set_Tast_Win;
  begin
   Window(50, 21, 80, 23);
   TextBackground(Green);
   TextColor(Black);               {Setze Schriftfarbe}
  end;

procedure  Mil_DAC_Bitshift;
  LABEL 99;
  const ADC_Wait :LongInt = 50;
   VAR
     error_cnt  : LONGINT;
     MilErr     : TMilErr;
     Fct        : TFct;
     OnlineErr  : TOnlineErr;
     RetAdr     : Byte;
     Left_Shift : Boolean;
     Plus       : Boolean;
     Rd_Fct     : Byte;
     Wr_Fct     : Byte;
     Delta      : Byte;
     Bit16_Str  : Str19 ;
     Sonder_Zeichen : Char;

  procedure DAC_Wr_Data (Wr_Data: Integer);
   begin
    Set_Text_win;
    Transf_Cnt := Transf_Cnt + 1;
    GotoXY(25,10); write(transf_cnt:10);

    GotoXY(22,14); Writeln(hex_word(Wr_Data));
    Hex_Bin_Str (Wr_Data, Bit16_str);
    GotoXY(30,14); Write(Bit16_str);
    GotoXY(28,18); Write_Real_10V_Bipol (Wr_Data);

    Fct.B.Fct := Wr_Fct;;
    Mil.Ifc_Online (Ifc_Test_Nr, RetAdr, OnlineErr);
    if OnlineErr = NoErr then
      begin
       Mil.Wr (Wr_Data, Fct, MilErr);
      end {OnlineErr=NoErr}
    else
      begin
       timout_wr := timout_wr + 1;
       GotoXY(25, 11); write(timout_wr:10);
      end;
   end; {DAC_Wr_Data}

  procedure ADC_Rd_Data (Wr_Data: Integer);
   var ADC_Data : Word;
   begin
    Set_Text_win;
    Mil.Ifc_Online (Ifc_Test_Nr, RetAdr, OnlineErr);
    if OnlineErr = NoErr then
      begin
       Fct.B.Fct := Fct_Start_Conv; {Vor dem Datenlesen: Convert Command senden!!}
       Mil.WrFct (Fct, MilErr);     {290399}

       Mil.Timer2_Wait(ADC_Wait);   {Warten auf ADC}
       Fct.B.Fct := Rd_Fct;
       Mil.Rd (ADC_Data, Fct, MilErr);
       if MilErr = No_Err then
        begin
         GotoXY(22,15); writeln(hex_word(ADC_Data));
         Hex_Bin_Str (ADC_Data, Bit16_str);
         GotoXY(30,15); Write(Bit16_str);
         GotoXY(28,19); Write_Real_10V_Bipol(ADC_Data);

         GotoXY(22,16); Write (Hex_Word (abs(ADC_Data-Wr_Data)));
         GotoXY(28,20); Write_Real_10V_Bipol (ADC_Data-Wr_Data);

{Write_Real_10V_Bipol(IW1-SW_Act);}

        end;
      end {OnlineErr=NoErr}
    else
      begin
       timout_wr := timout_wr + 1;
       GotoXY(25, 11); write(timout_wr:10);
       GotoXY(22,15); Write ('    ');
       GotoXY(30,15); Write ('                    ');
       GotoXY(22,16); Write ('    ');
       GotoXY(28,19); Write ('          ');
       GotoXY(28,20); Write ('                    ');
      end;
     Life_Sign (Norm);
   end; {ADC_Rd_Data}

   Begin
    Mil_Ask_Ifc;
    Ini_Text_Win;
    GotoXY(5, 10);
    TextColor(Red);               {Setze Schriftfarbe}
    Write('Beachten: Abgleich erst sinnvoll nach 5 Minuten Warmlauf der Hardware!! ');
    TextColor(Black);               {Setze Schriftfarbe}

    GotoXY(5, 22);
    write ('Welchen Write-Functions-Code [06, 07, 08, 09] ??');
    Wr_Fct    := ask_hex_byte;
    Ini_Text_Win;

    GotoXY(5, 22);
    write ('Welchen Read-Functions-Code [80, 81, 82, 83] ??');
    Rd_Fct    := ask_hex_byte;
    Ini_Text_Win;

    Fct.B.Adr := Ifc_Test_Nr;
    transf_cnt := 0;
    error_cnt  := 0;
    timout_wr  := 0;
    Write_Data := $0000;
    Plus       := True;    {Testflag: Spannung positiv setzen}

    TextColor (Brown);
    GotoXY(23,03); write('---------- LinearitÑt DAC ----------');
    GotoXY(20,04); write  ('Write Function-Word (Fct + Adr): '); TextColor (Black);
    Write(hex_byte(Wr_Fct), hex_byte(Ifc_Test_Nr));  TextColor(Brown); Write(' [H]');
    GotoXY(20,05); write  ('Read  Function-Word (Fct + Adr): '); TextColor (Black);
    Write (hex_byte(Rd_Fct), hex_byte(Ifc_Test_Nr)); TextColor(Brown); Write(' [H]');

    GotoXY(3,07); Write('ADC wird frÅhestens '); TextColor (Black);
                  Write (ADC_Wait * 10); TextColor (Brown);
                  Write(' [us] nach dem Schreiben des DAC-Sollwertes gelesen!');
    GotoXY(06,10); writeln('Wr-Data-Cnt : ');
    GotoXY(06,11); writeln('Timeout     : ');
    GotoXY(25,11); write(timout_wr:10);

    Sonder_Zeichen := chr(124);  {Absolut Zeichen}
    GotoXY(06,13); writeln('                [Hex]');
    GotoXY(30,13); writeln('MSB_____________LSB');
    GotoXY(06,14); writeln('DAC-Data    : ');
    GotoXY(06,15); writeln('ADC-Data    : ');
    GotoXY(06,16); Write (Sonder_Zeichen);  Write ('Hex-Diffrz');
                   Write (Sonder_Zeichen);  Write (': '); ClrEol;

    GotoXY(06,18); write('DAC    [V]  : ');
    GotoXY(06,19); write('ADC    [V]  : ');
{   GotoXY(06,20); write('Differz[V]  : '); }
    GotoXY(06,20); write('ADC-DAC[V]  : ');
    GotoXY(50,18); write('Belegung Funktionstasten: ');

    Set_Tast_Win;
    TextColor(Yellow);
    GotoXY(01, 01); Write('F1:   + Spannung              ');
    GotoXY(01, 02); Write('F2:   - Spannung              ');
    GotoXY(01, 03); Write('<- -> Bitschieben             ');

    Set_Text_Win;
    Mil.Reset;                            { clear fifo }
    Write_Data := 0;
    Cursor(False);
    Std_Msg;
    Single_Step := False;
    Ch := #13;

    repeat
     if KeyEPressed then Ch := NewReadKey;

     if Ch = ' ' then
      begin
       Std_Msg;
       Single_Step := True;
       DAC_Wr_Data (Write_Data);
       ADC_Rd_Data (Write_Data);
       repeat until KeyEPressed;
       Ch := NewReadKey;
      end;

     if Ch = #13 then Single_Step := False;

     if not Single_Step then
      begin
       ADC_Rd_Data (Write_Data);
      end;

     if Ch = #0 then
      begin
       Ch := NewReadKey;
       case ord (Ch) of
         Taste_F1 : begin
                     Plus  := True;
                     Write_Data := Write_Data and $7FFF;
                     DAC_Wr_Data (Write_Data);
                     Single_Step := False;
                     Ch := #13;
                    end;
         Taste_F2 : begin
                     Plus  := False;
                     Write_Data := Write_Data or $8000;
                     DAC_Wr_Data (Write_Data);
                     Single_Step := False;
                     Ch := #13;
                    end;
         Taste_Pfeil_Links :
           begin
             if Plus then                    {Positive Spannung}
              begin
                if Write_Data = $0000 then
                  Write_Data := 1
                else
                  Write_Data := Write_Data shl 1;
              end
             else                            {Negative Spannung}
              begin
                if Write_Data = $8000 then Write_Data := $8001
                else
                 begin
                   Write_Data := Write_Data and $7FFF;
                   Write_Data := Write_Data shl 1;
                   Write_Data := Write_Data or $8000;
                 end;
              end;
             DAC_Wr_Data (Write_Data);
             Single_Step := False;
             Ch := #13;
           end; {Pfeil_Left}

         Taste_Pfeil_Rechts :
           begin                               {Positive Spannung}
            if Plus then
              begin
               if (Write_Data=$0000) then Write_Data := $8000
               else
                Write_Data := Write_Data shr 1;
              end
            else
             begin                              {Negative Spannung}
              if (Write_Data=$8000) then Write_Data := $C000
              else
                begin
                 Write_Data := Write_Data and $7FFF;
                 Write_Data := Write_Data shr 1;
                 Write_Data := Write_Data or $8000;
                end;
             end;  {if PLus}
            DAC_Wr_Data (Write_Data);
            Single_Step := False;
            Ch := #13;
           end; {Pfeil_Rechts}
      end;  {Case}
     end;
   until Ch in ['x','X'];
 99:  Cursor(True);
end; {Mil_DAC_Bitshift}
procedure  Mil_Auto_Test_Unipolar;
  LABEL 99;
  const Rd_Wait = 200;     {190207 Wartezeit x 10 us}
   VAR
     error_cnt  : LONGINT;
     MilErr     : TMilErr;
     Fct        : TFct;
     OnlineErr  : TOnlineErr;
     RetAdr     : Byte;
     Wr_Fct     : Word;
     Rd_Fct     : Word;
     Delta      : Integer;
     Delta_Max  : Word;
     Rd_Integ   : Integer;
     Wr_Integ   : Integer;
     DAC_Data_Int : Integer;
     ADC_Data_Int : Integer;

   Begin
    Mil_Ask_Ifc;
    Ini_Text_Win;
    GotoXY(5, 10);
    TextColor(Red);               {Setze Schriftfarbe}
    Write('Beachten: Abgleich erst sinnvoll nach 5 Minuten Warmlauf der Hardware!! ');
    TextColor(Black);               {Setze Schriftfarbe}
    GotoXY(5, 22);
    write ('Welchen Write-Functions-Code [06, 07, 08, 09] ??');
    Fct.B.Adr := Ifc_Test_Nr;
    if not Ask_Hex_Break (Wr_Fct, Byt) then
     begin
      Ini_Err_Win;
      Write ('ERROR: Falsche Hex-Eingabe!! Ende mit beliebiger Taste.');
      repeat until KeyEPressed;
      goto 99;
     end;

    Ini_Text_Win;
    GotoXY(5, 22);
    write ('Welchen Read-Functions-Code [80, 81, 82, 83] ??');
    if not Ask_Hex_Break (Rd_Fct, Byt) then
     begin
      Ini_Err_Win;
      Write ('ERROR: Falsche Hex-Eingabe!! Ende mit beliebiger Taste.');
      repeat until KeyEPressed;
      goto 99;
     end;

    Ini_Text_Win;
    GotoXY(5, 22);
    write ('Welche max. Abweichung [Hex]: Soll <> Istwert zulassen (N * 305 uV) ? ');
    if not Ask_Hex_Break (Delta_Max, Byt) then
     begin
      Ini_Err_Win;
      Write ('ERROR: Falsche Hex-Eingabe!! Ende mit beliebiger Taste.');
      repeat until KeyEPressed;
      goto 99;
     end;

    Ini_Text_Win;
    transf_cnt := 0;
    error_cnt  := 0;
    timout_wr  := 0;
    timout_rd  := 0;
    TextColor(Brown);
    GotoXY(12,02); write('---------- Automatischer Test DAC - ADC : Unipolar----------');
    Fct.B.Fct := Wr_Fct;
    GotoXY(23,03); Write('Wr-Function-Word (Fct + Adr): '); TextColor(Black);
                   Write(hex_word(Fct.W));                  TextColor(Brown); Write(' [H]');
    Fct.B.Fct := Rd_Fct;
    GotoXY(23,04); write('Rd-Function-Word (Fct + Adr): '); TextColor(Black);
                   Write(hex_word(Fct.W));                  TextColor(Brown); Write(' [H]');

    GotoXY(6, 07); writeln('Wr-Data-Cnt   : ');
    GotoXY(6, 08); writeln('IFC not online: ');
    GotoXY(6, 09); writeln('ADC Rd-Timeout: ');

    GotoXY(6, 13); writeln('--- DATA ---     [ Hex ]      [ Volt]');
    GotoXY(6, 15); writeln('DAC-Data   : ');
    GotoXY(6, 16); writeln('ADC-Data   : ');
                 {Setze Schriftfarbe}
    GotoXY(48,16); Write('Wartezeit beim Lesen [us]: '); TextColor(Black);
                   Write (Rd_Wait*10);
                   Write (' fÅr +10V/-10V Sprung');
                 {Setze Schriftfarbe}
    TextColor(Brown);
    GotoXY(6, 17); writeln('Abweichnung: ');
    GotoXY(6, 18); writeln('[" LSB:',Hex_Word(Delta_Max),']');
    TextColor(Black);
    Mil.Reset;
    Write_Data  := $0000;
    Fct.B.Fct := Wr_Fct;
    Mil.Wr (Write_Data, Fct, MilErr);
                           { clear fifo }
    Ch := ' ';
    if Ch = ' ' then
      begin
       Ini_Msg_Win;
       Write('Stop/Single Step mit <SPACE>, <A>bweichnung N, Loop mit <CR> ,  Ende mit [X]');
       repeat until KeyPressed;
       Ch := ReadKey;
       if  Ch in ['x','X'] then Goto 99;
      end;

    Ch := ' ';
    repeat
     repeat
       Set_Text_win;
       Transf_Cnt := Transf_Cnt + 1;
       GotoXY(25,07); write(transf_cnt:10);
       GotoXY(25,15); writeln(hex_word(Write_Data));
       GotoXY(33,15); Write_Real_10V_Bipol (Write_Data);

       Mil.Ifc_Online (Ifc_Test_Nr, RetAdr, OnlineErr);
       Fct.B.Fct := Wr_Fct;
       if OnlineErr = NoErr then
         begin
          Mil.Wr (Write_Data, Fct, MilErr);
          Mil.Timer2_Wait(Rd_Wait);

          Fct.B.Fct := Fct_Start_Conv; {Vor dem Datenlesen: Convert Command senden!!}
          Mil.WrFct (Fct, MilErr);

          Mil.Timer2_Wait(20);
          Fct.B.Fct := Rd_Fct;
          Mil.Rd (Read_Data, Fct, MilErr);
          if MilErr = No_Err then
           begin
            {GotoXY(25,16); writeln(hex_word(Read_Data));}

            GotoXY(33,16); Write_Real_10V_Bipol(Read_Data);
            Read_Data := Read_Data and $FFFF; {Vergleich nur mit 14 bit?}

            Delta := (Write_Data - Read_Data);
            GotoXY(25,16); writeln(Delta);

            if Delta > abs (Delta_Max) then
              begin
               GotoXY(25,17); writeln(hex_word(Delta));
               GotoXY(33,17); Write_Real_10V_Bipol (Delta);
               repeat until KeyPressed;
               GotoXY(25,17); writeln('    ');
               GotoXY(33,17); writeln('            ');;
              end;
           end
          else
           begin
             TextColor (Red);
             timout_rd := timout_rd + 1;
             GotoXY(25, 09); write(timout_rd:10);
             TextColor(Black);
             GotoXY(25,16); writeln('    ');
             GotoXY(33,16); Writeln('               ');
           end; {if milerr rd}
          end
       else
         begin
          TextColor (Red);
          timout_wr := timout_wr + 1;
          GotoXY(25, 08); write(timout_wr:10);
          TextColor(Black);
          GotoXY(25,16); writeln('    ');
          GotoXY(33,16); Writeln('               ');
         end; {if online-err}

       Write_Data := Write_Data + 1;
       if Write_Data = $7FFF then Write_Data := 0;
     until KeyPressed or (Ch = ' ');

     if Keypressed then  Ch := ReadKey;
     if Ch = ' ' then
       begin
        Ini_Msg_Win;
        Write('Stop/Single Step mit <SPACE>, <A>bweichnung N, Loop mit <CR> ,  Ende mit [X]');
        repeat until KeyPressed;
       end;

     if Ch in ['a','A'] then
       begin
        Ini_Msg_Win;
        write ('Welche max. Abweichung Soll <> Istwert zulassen (N * 305 uV) ? ');
        Readln (Delta_Max);
        Set_Text_Win;
        TextColor(Brown);
        GotoXY(6, 18); writeln('[ " max.',Delta_Max:3,']');
        Ini_Msg_Win;
        Write('Stop/Single Step mit <SPACE>, <A>bweichnung N, Loop mit <CR> ,  Ende mit [X]');
        repeat until KeyPressed;
       end;
  until Ch in ['x','X'];
   99:
end; {Mil_Auto_Test}

procedure  Mil_Auto_Test_Bipolar(Unipolar:boolean);
  LABEL 99;
  const Rd_Wait = 200;     {150207 Wartezeit x 10 us}
   VAR
     error_cnt  : LONGINT;
     MilErr     : TMilErr;
     Fct        : TFct;
     OnlineErr  : TOnlineErr;
     RetAdr     : Byte;
     Wr_Fct     : Word;
     Rd_Fct     : Word;
     Delta      : Word;
     Delta_Aus  : Word;
     Delta_Max  : Word;
     Rd_Integ   : Integer;
     Wr_Integ   : Integer;
     DAC_Data_Int : Integer;
     ADC_Data_Int : Integer;

   Begin
    Mil_Ask_Ifc;
    Ini_Text_Win;
    GotoXY(5, 10);
    TextColor(Red);               {Setze Schriftfarbe}
    Write('Beachten: Abgleich erst sinnvoll nach 5 Minuten Warmlauf der Hardware!! ');
    TextColor(Black);               {Setze Schriftfarbe}
    GotoXY(5, 22);
    write ('Welchen Write-Functions-Code [06, 07, 08, 09] [def.06]??'); {200104}
    Fct.B.Adr := Ifc_Test_Nr;
    if not Ask_Hex_Break (Wr_Fct, Byt) then
     begin
      Wr_Fct := $06;                        {200104}
     end;

    Ini_Text_Win;
    GotoXY(5, 22);
    write ('Welchen Read-Functions-Code [80, 81, 82, 83] [def.81]??');{200104}
    if not Ask_Hex_Break (Rd_Fct, Byt) then
     begin
      Rd_Fct := $81;                        {200104}
     end;

    Ini_Text_Win;
    GotoXY(5, 22);
    write ('Welche max. Abweichung [Hex]: Soll <> Ist zulassen (N *305 uV) ? [def.06]'); {200104}
    if not Ask_Hex_Break (Delta_Max, Byt) then
     begin
      Delta_Max := $06;  {200104}
     end;

    Ini_Text_Win;
    transf_cnt := 0;
    error_cnt  := 0;
    timout_wr  := 0;
    timout_rd  := 0;
    TextColor(Brown);

    if(Unipolar = false) then
     begin
      GotoXY(12,02); write('---------- Automatischer Test DAC - ADC: Bipolar ----------');
     end
    else
     begin
      GotoXY(11,02); write('---------- Automatischer Test DAC - ADC: Unipolar ----------');
    end;

    Fct.B.Fct := Wr_Fct;
    GotoXY(23,03); Write('Wr-Function-Word (Fct + Adr): '); TextColor(Black);
                   Write(hex_word(Fct.W));                  TextColor(Brown); Write(' [H]');
    Fct.B.Fct := Rd_Fct;
    GotoXY(23,04); write('Rd-Function-Word (Fct + Adr): '); TextColor(Black);
                   Write(hex_word(Fct.W));                  TextColor(Brown); Write(' [H]');

    GotoXY(6, 07); writeln('Wr-Data-Cnt   : ');
    GotoXY(6, 08); writeln('IFC not online: ');
    GotoXY(6, 09); writeln('ADC Rd-Timeout: ');

    GotoXY(6, 13); writeln('--- DATA ---     [ Hex ]      [ Volt]      [Count] ');
    GotoXY(6, 15); writeln('DAC-Data   : ');
    GotoXY(6, 16); writeln('ADC-Data   : ');
                 {Setze Schriftfarbe}
    GotoXY(6,11); Write('Wartezeit beim Lesen [us]: '); TextColor(Black);{210104}
                  Write (Rd_Wait*10);
                  Write (' fÅr +10V/-10V Sprung');
                 {Setze Schriftfarbe}
    TextColor(Brown);
    GotoXY(6, 17); writeln('Abweichnung: ');
    GotoXY(6, 18); writeln('[Hex:|',Hex_Word(Delta_Max),'|]');
    TextColor(Black);
    Mil.Reset;
    Write_Data  := $0000;
    Fct.B.Fct := Wr_Fct;
    Mil.Wr (Write_Data, Fct, MilErr);
                           { clear fifo }
    Ch := ' ';
    if Ch = ' ' then
      begin
       Ini_Msg_Win;
       Write('Stop/Single Step mit <SPACE>, <A>bweichnung N, Loop mit <CR> ,  Ende mit [X]');
       repeat until KeyPressed;
       Ch := ReadKey;
       if  Ch in ['x','X'] then Goto 99;
      end;

    Ch := ' ';
    repeat
     repeat
       Set_Text_win;
       Transf_Cnt := Transf_Cnt + 1;
       GotoXY(25,07); write(transf_cnt:10);
       GotoXY(25,15); writeln(hex_word(Write_Data));
       GotoXY(33,15); Write_Real_10V_Bipol (Write_Data);

       Mil.Ifc_Online (Ifc_Test_Nr, RetAdr, OnlineErr);
       Fct.B.Fct := Wr_Fct;

       if OnlineErr = NoErr then
         begin
          Mil.Wr (Write_Data, Fct, MilErr);
          Mil.Timer2_Wait(Rd_Wait);

          Fct.B.Fct := Fct_Start_Conv; {Vor dem Datenlesen: Convert Command senden!!}
          Mil.WrFct (Fct, MilErr);

          Mil.Timer2_Wait(20);
          Fct.B.Fct := Rd_Fct;
          Mil.Rd (Read_Data, Fct, MilErr);
          if MilErr = No_Err then
           begin
            GotoXY(25,16); writeln(hex_word(Read_Data));
            GotoXY(33,16); Write_Real_10V_Bipol(Read_Data);
            Read_Data := Read_Data and $FFFF; {Vergleich nur mit 14 bit?}

            Delta := (Read_Data - Write_Data);        {200104}
            Delta_Aus := Delta;   {fuer die bildschirausgabe}

            {Delta := (Write_Data - Read_Data);}

            if (delta and $8000) <> 0 then            {200104}
             begin
              Delta := not (Delta);
              Delta := Delta + 1;
             end;

            {Delta := Delta and $7FFF;}                 {200104}

            if Delta > Delta_Max then
             begin
              GotoXY(25,17); writeln(hex_word(Delta));
              GotoXY(33,17); Write_Real_10V_Bipol (Delta_Aus);
              GotoXY(50,17); writeln(Delta:4);
              repeat until KeyPressed;                {200104}
                {GotoXY(25,17); writeln('    ');
               GotoXY(33,17); writeln('            ');; }
             end
             else
              begin
               GotoXY(25,17); writeln('    ');         {200104}
               GotoXY(33,17); writeln('            ');
               GotoXY(49,17); writeln('            ');
              end; { if Delta > Delta_Max}
            end
         else
           begin
             TextColor (Red);
             timout_rd := timout_rd + 1;
             GotoXY(25, 09); write(timout_rd:10);
             TextColor(Black);
             GotoXY(25,16); writeln('    ');
             GotoXY(33,16); Writeln('               ');
           end; {if milerr rd}
          end
       else
         begin
          TextColor (Red);
          timout_wr := timout_wr + 1;
          GotoXY(25, 08); write(timout_wr:10);
          TextColor(Black);
          GotoXY(25,17); writeln('    ');         {210104}
          GotoXY(33,17); writeln('            ');
          GotoXY(49,17); writeln('            ');
       end; {if online-err}

       Write_Data := Write_Data + 1;
       if(Unipolar = true) then
        begin
         if Write_Data = $7FFF then Write_Data := 0;
        end;
     until KeyPressed or (Ch = ' ');

     if Keypressed then  Ch := ReadKey;
     if Ch = ' ' then
       begin
        Ini_Msg_Win;
        Write('Stop/Single Step mit <SPACE>, <A>bweichnung N, Loop mit <CR> ,  Ende mit [X]');
        repeat until KeyPressed;
       end;

      if Ch in ['a','A'] then
       begin
        Ini_Msg_Win;
        write ('Welche max. Abweichung Soll <> Istwert zulassen (N * 305 uV) ? ');
        if not Ask_Hex_Break (Delta_Max, Byt) then      {200104}
          begin
           Ini_Err_Win;
           Write ('ERROR: Falsche Hex-Eingabe!! Ende mit beliebiger Taste.');
          repeat until KeyEPressed;
        end;
        Set_Text_Win;
        TextColor(Brown);
        GotoXY(6, 18); writeln('[Hex:|',Hex_Word(Delta_Max),'|]');
        Ini_Msg_Win;
        Write('Stop/Single Step mit <SPACE>, <A>bweichnung N, Loop mit <CR> ,  Ende mit [X]');
        repeat until KeyPressed;
       end;
  until Ch in ['x','X'];
   99:
end; {Mil_Auto_Test}

procedure  Mil_ADC_Abgleich;
  LABEL 99;
  const
   Z_Status     = 5;
   Z_Delay      = Z_Status+1;
   Z_ConvStart  = Z_Status+2;
   Z_ConvAdr    = Z_Status+3;
   Z_BroadStat  = Z_Status+4;

   S_Conv   = 27;
   Rd_Delay = 20; {entpricht 20 x 10 us = 200 us}

 type
   TConv_Adr = (Ifk, Broad);


   VAR
     error_cnt  : LONGINT;
     MilErr     : TMilErr;
     Fct        : TFct;
     OnlineErr  : TOnlineErr;
     RetAdr     : Byte;
     Bit16_Str  : Str19 ;
     Rd_FctCode : Byte;
     User_Word  : Word;
     RdDelay_Aktiv: Boolean;
     Conv_Start : Boolean;
     Broadcast_Status : Boolean;
     Conv_Adr   : TConv_Adr;

     PROCEDURE Displ_ADC_Abgleich;
      begin
      {Info-Anzeige}
       Ini_Info_Win;
       TextColor(Blue);
       writeln('>Feste Werte fÅr ADC-Abgleich<');
       writeln('       Text            [Volt] ');
       writeln('------------------------------');
       writeln('       OFFSET        -9.99984 ');
       writeln('        Bereich  8000...8001H ');
       writeln;
       writeln('       GAIN          +9.99954 ');
       writeln('        Bereich  7FFF...7FFEH ');
       writeln;
       writeln('       NULLTEST       0.00000 ');
       writeln('        Bereich  0000...0000H ');
       end; {Displ_ADC_Abgleich;}

  procedure Set_TastAdc_Win;
   const Z_Base = 22;
   begin
     Set_Text_Win;
     GotoXY(02, Z_Base-3); TextColor(Brown);
     Write('Belegung Funktions-Tasten: ');
     Window(02, Z_Base, 49, Z_Base+1);
     TextBackground(Green);
     TextColor(Black);
   end;

 procedure Displ_Broad_Stat;
  begin
   Set_Text_Win;
   GotoXY(S_Conv, Z_BroadStat);
   Fct.B.Adr := Ifc_Test_Nr;
   Fct.B.Fct := Fct_Rd_GlobalStat;
   Mil.Rd (User_Word, Fct, MilErr);   {Lese Status}
   if MilErr = No_Err then
     begin
       if BitTst (User_Word, 9) then
        begin
          Write ('Ein');
          TextColor(Yellow+128);
        end
       else
        begin
          Write ('Aus');
          TextColor(Yellow);
        end;
     end
   else
     Write ('???')
  end;

  procedure Read_ADC;       {énderungscode 050199}
   begin
     Mil.Timer2_Wait(500);
     Set_Text_win;
     Transf_Cnt := Transf_Cnt + 1;
     GotoXY(25,11); write(transf_cnt:10);
     Mil.Ifc_Online (Ifc_Test_Nr, RetAdr, OnlineErr);
     if OnlineErr = NoErr then
       begin
         if Conv_Start then
          begin                                               {Adresse festlegen}
            if Conv_Adr = Ifk   then Fct.B.Adr := Ifc_Test_Nr;
            if Conv_Adr = Broad then Fct.B.Adr := $FF;
            {Sende Conversion Command}
            Fct.B.Fct := Fct_Start_Conv;
            Mil.WrFct (Fct, MilErr);
          end;

        if RdDelay_Aktiv then
           Mil.Timer2_Wait (Rd_Delay)    {Warte sicherheitshalber}
        else
          Mil.Timer2_Wait (4);           {290399 : min. 40 us warten}

        Fct.B.Adr := Ifc_Test_Nr;
        Fct.B.Fct := Rd_FctCode;
        Mil.Rd (Read_Data, Fct, MilErr);
        if MilErr = No_Err then
         begin
          Set_Text_Win;  TextColor(Black);
          GotoXY(31,14); writeln(hex_word(read_data));
          GotoXY(25,15); Write_Real_10V_Bipol (Read_Data);
          Hex_Bin_Str (Read_Data, Bit16_str);
          GotoXY(22,16); Write(Bit16_str);
         end
        else
         begin
           Set_Text_Win; TextColor(Black);
           timout_wr := timout_wr + 1;
           GotoXY(25,12); write(timout_wr:10);
           GotoXY(31,14); writeln('    ');
           GotoXY(25,15); writeln('             ');
           GotoXY(22,16); writeln('                   ');
         end;
       end
     else
       begin                          {Online Error}
        timout_wr := timout_wr + 1;
        GotoXY(25,12);  write(timout_wr:10);
        GotoXY(31,14);  writeln('    ');
        GotoXY(25,15);  writeln('             ');
        GotoXY(22,16);  writeln('                   ');
       end;
   end; {Read_Adc}

   Begin
    Mil_Ask_Ifc;
    Ini_Text_Win;
    GotoXY(5, 10);
    TextColor(Red);               {Setze Schriftfarbe}
    Write('Beachten: Abgleich erst sinnvoll nach 5 Minuten Warmlauf der Hardware!! ');
    Ini_Msg_Win;
    Write('Read-Function-Code (80, 81, 82, 83)??      <');    TextColor(Red);
    Write('CR'); TextColor(Yellow); Write('> fÅr 81 bzw. ['); TextColor(Red);
    Write('W'); TextColor(Yellow); WRite(']Ñhlen');
    Ch := NewReadKey;
    if Ch = Taste_Return then
      Rd_FctCode := $81
    else
     begin
       Set_Text_Win;
       TextColor(Blue);
       GotoXY(2, 22);
       Write('Read-Function-Code 80, 81, 82, 83 ??');
       if Ask_Hex_Break (User_Word, Byt) then
        begin
         Rd_FctCode:= Lo(User_Word);
        end
       else
        Exit;
     end;

    Ini_Text_Win;
    Ch := '?';
    Fct.B.Adr  := Ifc_Test_Nr;
    Fct.B.Fct  := Rd_FctCode;
    transf_cnt := 0;
    error_cnt  := 0;
    timout_wr  := 0;
    Read_Data  := $0000;
    RdDelay_Aktiv    := False;
    Conv_Start       := False;
    Broadcast_Status := False;
    Conv_Adr         := Ifk;

    TextColor(Yellow);
    GotoXY(5,02); write('Abgleich ADC  (wahlweise incl. Start-Conversion mit Fct-Code 5F [H])');
    TextColor(Brown);
    GotoXY(25,04); write  ('Function-Word (Fct + Adr): '); TextColor(Blue);
    Write(hex_word(Fct.W)); TextColor(Brown); Write(' [H]');
    GotoXY(2, Z_Delay);      TextColor (Yellow); write('F1  '); TextColor (Brown);  write   ('Read-Delay  (');
    Write(Rd_Delay*10);      Writeln('us): ');
    GotoXY(2, Z_ConvStart ); TextColor (Yellow); write('F2  '); TextColor (Brown);  writeln ('Conv Start     (5F): ');
    GotoXY(2, Z_ConvAdr );   TextColor (Yellow); write('F3  '); TextColor (Brown);  writeln ('Conv Adr Ifk/Broad : ');
    GotoXY(2, Z_BroadStat);  TextColor (Yellow); write('F4  '); TextColor (Brown);  writeln ('Ifk Broad-Stat (CA): ');

    GotoXY(6, 11); writeln('Rd-Data-Cnt  : ');
    GotoXY(6, 12); writeln('Timeout      : ');
    GotoXY(6, 14); writeln('Read-Data [H]: ');
    GotoXY(6, 15); writeln('ADC    [Volt]: ');
    GotoXY(06,16); writeln('    Data[BIN]: ');
    GotoXY(22,17); write('MSB             LSB');

    Set_TastAdc_Win;
    TextColor(Yellow);
    GotoXY(01, 01); Write('F1:Read Delay ein/aus  F3:Conv Adr IFK/Broad  ');
    GotoXY(01, 02); Write('F2:Conv Start ein/aus  F4:IFK Broadcst ein/aus');

    Set_Text_Win;  TextColor(Black);
    GotoXY(25,15); write_Real_10V_Bipol (Read_Data);
    GotoXY(25,12); write(timout_wr:10);
    GotoXY(31,14); write(hex_word(Read_Data));
    GotoXY(S_Conv, Z_Delay);     if RdDelay_Aktiv then Write ('Ein') else Write ('Aus');
    GotoXY(S_Conv, Z_ConvStart); if Conv_Start then Write ('Ein') else Write ('Aus');
    GotoXY(S_Conv, Z_ConvAdr );  if Conv_Adr = Ifk then Write('Ifk  ') else Write('Broad');

    Displ_Broad_Stat;
    Displ_ADC_Abgleich;
    Mil.Reset;                            { clear fifo }

    Cursor(False);
    Std_Msg;
    Ch := NewReadKey;

    repeat
     if Ch = ' ' then
      begin
       Std_Msg;
       Single_Step := True;
       Read_Adc;
       Displ_Broad_Stat;
       repeat until KeyEPressed;
       Ch := NewReadKey;
      end;

     if Ch = #13 then Single_Step := False;

     if not Single_Step then
      begin
       Read_Adc;
       Displ_Broad_Stat;
      end;

     if Ch = #0 then                  {Sonder-Tasten Abfrage}
      begin
       Ch := NewReadKey;
       case ord (Ch) of
        Taste_F1 : begin
                     GotoXY(S_Conv, Z_Delay);
                     TextColor(Black);
                     if RdDelay_Aktiv then
                      begin RdDelay_Aktiv := False; Write ('Aus'); end
                     else
                      begin RdDelay_Aktiv := True;  Write ('Ein'); end
                   end;
        Taste_F2 : begin
                     Set_Text_Win;
                     GotoXY(S_Conv, Z_ConvStart);
                     TextColor(Black);
                     if Conv_Start then
                      begin Conv_Start := False; Write ('Aus'); end
                     else
                      begin Conv_Start := True;  Write ('Ein'); end
                   end;
        Taste_F3 : begin  {wÑhle Adr an die das Conversion-Cmd gesendet wird}
                     if Conv_Adr = Ifk then Conv_Adr := Broad
                     else Conv_Adr := Ifk;
                     GotoXY(S_Conv, Z_ConvAdr );
                     if Conv_Adr = Ifk then Write('Ifk  ') else Write('Broad');
                   end;
        Taste_F4 : begin                               {IFK-Broadcast Ein/Aus}
                     Fct.B.Adr := Ifc_Test_Nr;
                     Fct.B.Fct := Fct_Rd_GlobalStat;
                     Mil.Rd (User_Word, Fct, MilErr);   {Lese Status}
                     if MilErr = No_Err then
                       begin
                         if BitTst (User_Word, 9) then  {aktueller Boadcast-Status}
                           Fct.B.Fct := Fct_Dis_Broad   {Toggle Broadcast von Ein -> Aus}
                         else
                           Fct.B.Fct := Fct_En_Broad;   {von Aus -> Ein}

                         Mil.WrFct (Fct, MilErr);
                         Displ_Broad_Stat;
                       end;

                     Ini_Err_Win;
                     TextColor(Black);
                     Write('IFK Broadcast Ein/Aus');
                     Mil.Timer2_Wait(100000);
                     Std_Msg;
                   end;
        Taste_F12: begin
                   end;
        Taste_Pfeil_Links : begin
                            end;
        Taste_Pfeil_Rechts: begin
                            end;
      end;  {Case}
     end;
    if KeyEPressed then Ch := NewReadKey;
   until Ch in ['x','X'];
 99:  Cursor(True);
end; {Mil_ADC_Abgleich}


BEGIN   { Hauptprogramm }
  Ifc_Test_Nr := 0;
  PCI_MilCardOpen:=false;

  REPEAT
    menue_win;
    User_Input := ReadKey;
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
		  if Check_Ifc_Adr(Ifc_Test_Nr)  then Mil_Wr_Fctcode;
                end;
     'i', 'I' : begin
                  if Check_Ifc_Adr(Ifc_Test_Nr) THEN
                   begin
		     Mil_Wr (Mil_Data);
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
                  Mil_DAC_SetSw;
                end;
     'n', 'N' : begin
                  Mil_DAC_Abgleich;
                end;
     'o', 'O' : begin
                  Mil_DAC_Lin;
                end;
     'p', 'P' : begin
                  Mil_DAC_Bitshift;
                end;
     'q', 'Q' : begin
                  Mil_ADC_Abgleich;
                end;
     'r', 'R' : begin
                  Mil_Auto_Test_Bipolar(true);
                end;
     's', 'S' : begin
                  Mil_Auto_Test_Bipolar(false);
                end;

     't', 'T' : begin

                end;
End; {CASE}
  UNTIL user_input in ['x','X'];
  Window(1, 1, 80, 25);
  TextBackground(Black);

  PCI_DriverClose(PCIMilCardNr);

  ClrScr;

END. {mil_ADAC}


