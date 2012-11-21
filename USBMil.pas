unit USBMil;

interface
uses SysUtils, D2XXUnit, forms, windows;

const
USB_STX      =char($02);
USB_ETX      =char($03);
USB_Daten    ='011';
USB_CMD      ='010';
USB_RD       ='RD';
USB_WR       ='WR';
MaxSendBuff  =16;
MaxResBuff   =16;

Read_TimeOut =0;
Write_TimeOut=0;


var USB_Device_Online: Boolean;
    Status           : FT_Result;

   SendString: RECORD CASE BYTE OF
                1:(SendS: String[MaxSendBuff]);
                2:(SendB: array[0..MaxSendBuff]of Byte);
                end;

   DatenRec:   RECORD CASE BYTE OF
                1:(DatenW:_Word);
                2:(DatenB: array[0..1]of Byte);
                end;

Function  USB_MIl_Open ():Boolean;
Function  USB_Mil_Reset():Boolean;
Function  USB_MIL_Close():Boolean;

Function  USB_IfkWrite(IFKAdr:_BYTE; IFKFktCode:_BYTE; Data:_Word)    :Boolean;
Function  USB_IfkRead (IFKAdr:_BYTE; IFKFktCode:_BYTE; var Data:_Word):Boolean;

Function  USB_WriteData(data:Word):Boolean;
Function  USB_WriteCMD (IFKAdr:_BYTE; IFKFktCode:_BYTE):Boolean;
Function  USB_Read(var data:word):Boolean;

Function  ReadQueue(var Data:Word):Boolean;


implementation

//USB Box oeffnen
Function  USB_MIl_Open ():Boolean;

begin
     if(USB_Device_Online = false) then begin
        GetFTDeviceCount();
        if(FT_Device_Count > 0) then begin
          if(Open_USB_Device_By_Device_Description('USBTOMIL') <> FT_OK) then  begin
            Application.MessageBox('Open USB Device: ERROR','Hello ?',16);
            USB_MIl_Open:=false;
          end else USB_MIl_Open:=true;
        end else begin
            Application.MessageBox('Keine USB Kiste gefunden','Shit',16);
            USB_MIl_Open:=false;
        end;
     end else USB_MIl_Open:= false;
end;

//USB_FTDI reseten
Function  USB_Mil_Reset():Boolean;
begin
     if (USB_Device_Online = true) then begin
        if (Reset_USB_Device()= FT_OK)then USB_Mil_Reset:=true
        else USB_Mil_Reset:=false;
     end else USB_Mil_Reset:= false;
end;

//USB Box schliessen
Function USB_MIL_Close():Boolean;
begin
     if (USB_Device_Online = true) then begin
        Reset_USB_Device();
        if(Close_USB_Device()= FT_OK) then begin;
           USB_MIL_Close:=true;
           USB_Device_Online := false;
        end else USB_MIL_Close:=false;
     end else USB_MIL_Close:= false ;
end;

//Daten an eine IFK schreiben
Function  USB_IfkWrite(IFKAdr:_BYTE; IFKFktCode:_BYTE; Data:_Word):Boolean;

var SendString:String;
    BytesWritten:DWord;

begin
     if (USB_Device_Online = true) then begin
        if(USB_WriteData(data)= true) then
           if(USB_WriteCMD(IFKAdr, IFKFktCode)=true) then USB_IfkWrite := true
           else USB_IfkWrite := false
        else USB_IfkWrite := false
     end else USB_IfkWrite := false;

{     DatenRec.DatenB[0]:= IFKAdr;
     DatenRec.DatenB[1]:= IFKFktCode;

     status:= USB_WriteData(Data);
     if(status=true) then status:= USB_WriteCMD(DatenRec.DatenW);

     USB_IfkWrite:= status;   }
end;

//Daten von einer IFK lesen
Function  USB_IfkRead (IFKAdr:_BYTE; IFKFktCode:_BYTE; var Data:_Word):Boolean;

var SendString:String;
    BytesWritten:DWord;

begin
     if (USB_Device_Online = true) then begin
       SendString:= USB_STX + USB_WR + USB_CMD + IntToHex(IFKFktCode,2)+ IntToHex(IFKAdr,2)+ USB_ETX;
       if (FT_Write(FT_Handle, @SendString[1], 11, @BytesWritten)<> FT_OK) then USB_IfkRead:= false
       else begin
 //           Sleep(5);
            if (ReadQueue(Data) = true) then USB_IfkRead:= true
            else USB_IfkRead:= false;
       end;
     end else USB_IfkRead:=false;

{     DatenRec.DatenB[0]:= IFKAdr;
     DatenRec.DatenB[1]:= IFKFktCode;

     status:= USB_WriteCMD(DatenRec.DatenW);
     if(status = true) then status:= USB_Read(Data);

     USB_IfkRead:= status;  }
end;

//Schreibt daten an die USB Box
Function  USB_WriteData(data:Word):Boolean;

var SendString:String;
    BytesWritten:DWord;

begin
     if (USB_Device_Online = true) then begin
       SendString:= USB_STX + USB_WR + USB_Daten + IntToHex(data,4)+ USB_ETX;
       if (FT_Write(FT_Handle, @SendString[1], 11, @BytesWritten)<> FT_OK) then USB_WriteData:= false
       else USB_WriteData:= true;
     end else USB_WriteData:= false;

{
     SendString.SendS:= USB_STX + USB_WR + USB_Daten + IntToHex(data,4)+ USB_ETX;

     for i:= 0 to MaxSendBuff do begin
       FT_Out_Buffer[i]:=SendString.SendB[i];
     end;

     SendData:= Write_USB_Device_Buffer(MaxSendBuff);
     Purge_USB_Device_In;

     if (SendData <> MaxSendBuff)  then USB_WriteData:=false
     else USB_WriteData:= true;      }
end;

//Schreibt kommandos an den die USB Box
Function  USB_WriteCMD (IFKAdr:_BYTE; IFKFktCode:_BYTE):Boolean;

var SendString:String;
    BytesWritten:DWord;

begin
     if (USB_Device_Online = true) then begin
       SendString:= USB_STX + USB_WR + USB_CMD + IntToHex(IFKFktCode,2)+ IntToHex(IFKAdr,2)+ USB_ETX;
       if (FT_Write(FT_Handle, @SendString[1], 11, @BytesWritten)<> FT_OK) then USB_WriteCMD:= false
       else USB_WriteCMD:= true;
     end else USB_WriteCMD:= false;

     {
     for i:= 0 to MaxSendBuff do begin
       FT_Out_Buffer[i]:=SendString.SendB[i];
     end;

     SendData:= Write_USB_Device_Buffer(MaxSendBuff);

     if (SendData <> MaxSendBuff)  then USB_WriteCMD:=false
     else USB_WriteCMD:= true;   }
end;

//Liest daten von der USB Box
Function  USB_Read(var data:word):Boolean;

begin
     if (USB_Device_Online = true) then begin
       data:=0;
       if ReadQueue(Data) = true then USB_Read:= true
       else USB_Read:= false;
     end else USB_Read:=false;

{     ResvCnt:= Read_USB_Device_Buffer(MaxResBuff);
     if(ResvCnt <> 0) then begin
       for i:= 0 to ResvCnt do begin
           ResStr:=ResStr + (char(FT_In_Buffer[i]))
       end;

       index:=Pos('M', ResStr);
       if(index<>0) then begin
         ResStr:= char(FT_In_Buffer[index+3])+char(FT_In_Buffer[index+4])+char(FT_In_Buffer[index+5])+char(FT_In_Buffer[index+6]);
         data:= StrToInt('$'+ResStr);
         USB_Read:=true;
       end else USB_Read:= false;
     end else USB_Read:= false; }
end;

function ReadQueue(var Data:Word):Boolean;

var i:dword;
    index:word;

    RxString :string;
    ResultString:string;

    FT_RxQ_Bytes:DWORD;
    BytesRead:DWORD;
    StringPos:word;
    RxChar:Array[0..50] of char;

begin
     index:=0;
     FT_RxQ_Bytes:=0;

     // Buffer lehren
     for i:= 0 to 50 do RxChar[i]:='0';

     // FTDI-Queue abfragen on daten zum abholen da sind
     while (index < 50) and (FT_RxQ_Bytes = 0) do begin
           if(FT_GetQueueStatus(FT_Handle, @FT_RxQ_Bytes) <> FT_OK) then ReadQueue:=false;
           index:=index+1;
     end;

    if(index >= 50) then ReadQueue:=false // Zeit-limit abgelaufen
     else if (FT_RxQ_Bytes > 0) and (FT_RxQ_Bytes < 50) then begin  // Sind mehr wie 0 Zeichen aber max 50 zeichen
        if(FT_Read(FT_Handle, @RxChar, FT_RxQ_Bytes, @BytesRead) <> FT_OK) then ReadQueue:=false // FTDI auslesen
         else begin
          if(BytesRead < 15)  then begin  // sind es weniger wie der erforderlichen zeichen ->bye
            ReadQueue:=false;
            exit;
          end;

          // Zeichen in string kopieren
          for i:=1 to BytesRead do
             if not (RxChar[i] in [#1..#6]) then RxString:=RxString+RxChar[i];
          end;

          // position von kennung suchen & danach zeichen kopieren
          StringPos:= pos('MIL', RxString);
          while StringPos <> 0 do begin
              ResultString:=copy (RxString, StringPos+4, 4);
              try
               Data:= StrToInt('$'+ResultString);
              except
                ReadQueue:=false;
                exit;
              end;
              RxString:=copy (RxString, StringPos+8, Length(RxString));
              StringPos:= pos('MIL', RxString);
              ReadQueue:=true;
          end;
     end else if(FT_RxQ_Bytes > 50) then begin
        FT_Purge(FT_Handle, FT_PURGE_RX and FT_PURGE_TX);
        ReadQueue:=false;
    end else ReadQueue:=true;
end;



end.
