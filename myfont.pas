unit MyFont;

{$mode objfpc}{$H+}

interface

uses CastleFonts,CastleFilesUtils, CastleUnicode, CastleStringUtils,
  general_var{$ifdef Android},
  castletexturefont_linbiolinumrbg_16,
  castletexturefont_linbiolinumrbg_22,
  castletexturefont_linbiolinumrbg_30,
  castletexturefont_linbiolinumrbg_38,
  castletexturefont_linbiolinumrbg_48,
  castletexturefont_linbiolinumrg_16
  {$endif};

type TFont_type=(font_bold,font_normal);

var MyCharSet:TUnicodeCharList;

function GetFireFont(font_type:TFont_type;font_size:integer):TTextureFont;
procedure InitCharSet;

implementation

procedure InitCharSet;
begin
  if MyCharSet=nil then begin
      MyCharSet:=TUnicodeCharList.Create;
      MyCharSet.add(SimpleAsciiCharacters);
      MyCharSet.add('śЁЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮёйцукенгшщзхъфывапролджэячсмитьбюІЇЄіїє');
    end;//else FreeAndNil(CharSet);
end;

function GetFireFont(font_type:TFont_type;font_size:integer):TTextureFont;
begin
 {$ifdef Android}
   if font_type=font_normal then
     result:=TTextureFont.Create(TextureFont_LinBiolinumRG_16)
   else begin
     case font_size of
        0..20: result:=TTextureFont.Create(TextureFont_LinBiolinumRBG_16);
       21..28: result:=TTextureFont.Create(TextureFont_LinBiolinumRBG_22);
       29..36: result:=TTextureFont.Create(TextureFont_LinBiolinumRBG_30);
       37..46: result:=TTextureFont.Create(TextureFont_LinBiolinumRBG_38);
       else result:=TTextureFont.Create(TextureFont_LinBiolinumRBG_48);
     end;
   end;
 {$else}
   if font_type=font_normal then
     result:=TTextureFont.Create(ApplicationData(NormalFontFile),Font_Size,true,MyCharSet)
   else
     result:=TTextureFont.Create(ApplicationData(BoldFontFile),Font_Size,true,MyCharSet);
 {$endif}
end;

end.

