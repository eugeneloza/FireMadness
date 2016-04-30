unit Translation;

{$mode objfpc}{$H+}

interface

uses Sysutils,
     CastleUnicode,CastleStringUtils,
     general_var;

type TLanguage=(language_english,language_russian,language_ukrainian);

var TXT:array of string;
    f1:Text;
    MyCharSet:TUnicodeCharList;
    CurrentLanguage:TLanguage;

procedure loadTranslation(language:TLanguage);
procedure InitCharSet;

implementation

{$Q+}{$R+}

procedure InitCharSet;
begin
  if MyCharSet=nil then begin
      MyCharSet:=TUnicodeCharList.Create;
      MyCharSet.add(SimpleAsciiCharacters);
      MyCharSet.add('ЁЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮёйцукенгшщзхъфывапролджэячсмитьбюІЇЄіїє');
    end;//else FreeAndNil(CharSet);
end;

procedure loadTranslation(language:TLanguage);
var filename:string;
    s:string;
    line_n,errorcode:integer;
begin
  InitCharSet;
  currentLanguage:=language;

  setlength(TXT,92+1);
  case language of
    language_english:filename:='English.txt';
    language_russian:filename:='Russian.txt';
    language_ukrainian:filename:='Ukrainian.txt';
  end;
  Assign(f1,TranslationFolder+filename);
  reset(f1);
  repeat
    readln(f1,s);
    val(copy(trim(s),1,3),line_n,errorcode);
    if errorcode=0 then begin
      TXT[line_n]:=trim(copy(trim(s),6,length(s)-5));
    end;
  until eof(f1);
  closefile(f1);
end;



end.

