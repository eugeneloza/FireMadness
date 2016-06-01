{$mode objfpc}{$H+}
program MouseTrack_Desktop;
Uses {$IFDEF UNIX}cthreads,{$ENDIF} CastleWindow, FireMadness, MyFont;
begin
  window.openandrun;
end.

