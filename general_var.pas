unit general_var;

{$mode objfpc}{$H+}

interface

uses SysUtils;

const BotFolder= 'DAT'+pathdelim+'bots'+pathdelim;
      ExpFolder= 'DAT'+pathdelim+'explosions'+pathdelim;
      GuiFolder= 'DAT'+pathdelim+'gui'+pathdelim;
      MapFolder= 'DAT'+pathdelim+'map'+pathdelim;
      MusFolder= 'DAT'+pathdelim+'music'+pathdelim;
      SndFolder= 'DAT'+pathdelim+'sound'+pathdelim;
      VocFolder= 'DAT'+pathdelim+'voice'+pathdelim;
      TitlescreenFolder= 'DAT'+pathdelim+'titlescreen'+pathdelim;

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

