unit GL_button;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  CastleGLImages, CastleFilesUtils,
  castleVectors, {castleImages,}
  CastleFreeType, CastleFonts, MyFont, CastleUnicode, CastleStringUtils,
  Translation, general_var;

type TSimpleProcedure=procedure;

type TButtonContent = (button_text, button_img);

const ButtonBorderSize=7;
type TGLButton=class(TObject)
  public
    Caption:string;
    Image:TGLImage;
    content:TButtonContent;
    Alpha:single;
    Font:TTextureFont;
    frame:TGLImage;
    ClickMe:TSimpleProcedure;
    hidden:boolean;
    fontSize:integer;
    procedure SetFontSize(fs:integer);
    procedure ResizeMe(cx,cy,cw,ch:integer);
    procedure DrawMe;
    function OverMe(cx,cy:integer):boolean;
    procedure checkClick(cx,cy:integer);
    constructor Create{(cx,cy,cw,ch:integer)};
  private
    x,y,w,h:integer;
end;

implementation

constructor TGLButton.create{(cx,cy,cw,ch:integer)};
begin
  {x:=cx;
  y:=cy;
  w:=cw;
  h:=ch;}
  x:=0;
  y:=0;
  w:=0;
  h:=0;
  Alpha:=0.9;
  content:= button_text;
  Caption:='';
  Hidden:=true;
  setFontSize(30);
end;

procedure TGLButton.SetFontSize(fs:integer);
begin
  fontSize:=fs;
  if font<>nil then freeandnil(font);
  Font:=GetFireFont(font_bold, fs)
end;

procedure TGLButton.ResizeMe(cx,cy,cw,ch:integer);
begin
  x:=cx;
  y:=cy;
  w:=cw;
  h:=ch;
end;

procedure TGLButton.drawMe;
var shade:TVector4single;
    scale:single;
begin
 if not hidden then begin
    shade:=Vector4Single(1,1,1,Alpha);
    if frame<>nil then begin
      frame.Color:=shade;
      frame.Draw3x3(x,y,w,h,ButtonBorderSize,ButtonBorderSize,ButtonBorderSize,ButtonBorderSize);
    end;
    if Content=Button_text then
      Font.print(x+w div 2 - UTF8length(Caption)*fontSize div 4,y+h div 2-fontSize div 4,shade, Caption)
    else if image<>nil then begin
      Image.color:=shade;
      if (w-2*buttonBorderSize)/image.Width<(h-2*buttonBorderSize)/image.height then
        scale:=(w-2*buttonBorderSize)/image.Width
      else
        scale:=(h-2*buttonBorderSize)/image.height;
      Image.draw(x+w/2 - image.Width*scale/2,y+h/2-image.height*scale/2,image.Width*scale,image.height*scale);
    end;
 end;
end;

function TGLButton.OverMe(cx,cy:integer):boolean;
begin
  if (not hidden) and (cx>=x) and (cy>=y) and (cx<=x+w) and (cy<=y+h) then result:=true else result:=false;
end;

procedure TGLButton.checkClick(cx,cy:integer);
begin
  if (clickMe<>nil) and (not hidden) then
    if overMe(cx,cy) then ClickMe;
end;

end.


