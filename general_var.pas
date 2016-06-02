unit general_var;

{$mode objfpc}{$H+}

interface

uses SysUtils;

const BotFolder= 'bots'+pathdelim;
      ExpFolder= 'explosions'+pathdelim;
      GuiFolder= 'gui'+pathdelim;
      KeyFolder= GuiFolder+'keys'+pathdelim;
      MapFolder= 'map'+pathdelim;
      {$ifdef Android}
        MusFolder= 'WAV'+pathdelim+'music'+pathdelim;
        SndFolder= 'WAV'+pathdelim+'sound'+pathdelim;
        VocFolder= 'WAV'+pathdelim+'voice'+pathdelim;
      {$else}
        MusFolder= 'music'+pathdelim;
        SndFolder= 'sound'+pathdelim;
        VocFolder= 'voice'+pathdelim;
      {$endif}
      TitlescreenFolder= 'titlescreen'+pathdelim;
      TranslationFolder= 'translation'+pathdelim;
      PortraitFolder= 'portrait'+pathdelim;
      fntFolder= 'font'+pathdelim;
      NormalFontFile=fntFolder+'LinBiolinum_R_G';
      BoldFontFile=fntFolder+'LinBiolinum_RB_G';


type float=single;

var scale:integer=48; {square image size}
    Player2Active:boolean=false;

function sgn(value:float):shortint;

implementation

function sgn(value:float):shortint;
begin
  if value>0 then result:=1 else
  if value<0 then result:=-1 else result:=0;
end;


end.

