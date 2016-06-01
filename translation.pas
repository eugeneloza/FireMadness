unit Translation;

{$mode objfpc}{$H+}

interface

uses Sysutils,
     CastleDownload, classes,
     castleFilesUtils,
     general_var, MyFont;

type TLanguage=(language_english,language_russian,language_ukrainian);

var TXT:array of string;
    f1:Text;
    CurrentLanguage:TLanguage;

procedure loadTranslation(language:TLanguage);


implementation

{$Q+}{$R+}


procedure loadTranslation(language:TLanguage);
var filename:string;
    s:string;
    line_n,errorcode:integer;

    MyStream:TStream;
    MyStrings:TStringList;
    i:integer;
begin
  InitCharSet;
  currentLanguage:=language;

  setlength(TXT,95+1);
  case language of
    language_english:filename:='English.txt';
    language_russian:filename:='Russian.txt';
    language_ukrainian:filename:='Ukrainian.txt';
  end;
//  AssignFile(f1,ApplicationData(TranslationFolder+filename){copy(ApplicationData(TranslationFolder+filename),8,length(ApplicationData(TranslationFolder+filename)))});
  MyStream:=Download(ApplicationData(TranslationFolder+filename));
  MyStrings:=TStringList.create;
  MyStrings.LoadFromStream(MyStream);

  i:=0;
  repeat
    s:=MyStrings.Strings[i];
    val(copy(trim(s),1,3),line_n,errorcode);
    if errorcode=0 then begin
      TXT[line_n]:=trim(copy(trim(s),6,length(s)-5));
    end;
    inc(i);
  until i>=MyStrings.Count;

  freeandnil(MyStream);
  FreeAndNil(MyStrings);
end;



end.

