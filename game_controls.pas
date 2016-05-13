unit Game_controls;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  CastleGLImages,
  CastleKeysMouse,
  general_var;

type TControlsVariant=(controls_WASD,controls_TFGH,controls_IJKL,controls_cursor,{controls_numpad,}controls_numbers);

type FourKeys=record
  up,down,left,right:TKey;
end;

type TPlayerControls=class(TObject)
  public
    MoveKeys,FireKeys:FourKeys;
    MoveStyle,FireStyle:TControlsVariant;
    FirePressed,MovePressed:boolean;
    LastFireKeyPress,LastMoveKeyPress:TKey;
    FireX,FireY,moveX,moveY:shortint;
    constructor create;
    procedure makeMoveControls(MoveControlsType:TControlsVariant);
    procedure makeFireControls(FireControlsType:TControlsVariant);
    procedure StopControls;
end;


var GameScreenStartX,GameScreenEndX,GameScreenStartY,GameScreenEndY:integer;
    frameskip:integer=1;
    PauseMode:boolean=false;
    PlayerControls:array[0..3] of TPlayerControls; {2 and 3 are default controls for the Player1 and 0 is a mere link to those}

    ControlsPic:array [TControlsVariant] of TGLImage;

procedure LoadControlsImages;
function GetControlImage(InputKeys:TControlsVariant):TGLImage;
function IncControlsStyle(inputControls:TControlsVariant):TcontrolsVariant;

Procedure cyclePlayer1Fire;
Procedure cyclePlayer1Move;
Procedure cyclePlayer2Fire;
Procedure cyclePlayer2move;

implementation

function IncControlsStyle(inputControls:TControlsVariant):TcontrolsVariant;
begin
  case inputControls of
    controls_WASD:   result:=controls_TFGH;
    controls_TFGH:   result:=controls_IJKL;
    controls_IJKL:   result:=controls_cursor;
    controls_cursor: result:=controls_numbers;
    controls_numbers:result:=controls_WASD;
  end;
end;


procedure LoadControlsImages;
begin
  ControlsPic[controls_WASD]:=TGLImage.Create(keyFolder+'WASD.png',true);
  ControlsPic[controls_TFGH]:=TGLImage.Create(keyFolder+'TFGH.png',true);
  ControlsPic[controls_IJKL]:=TGLImage.Create(keyFolder+'IJKL.png',true);
  ControlsPic[controls_cursor]:=TGLImage.Create(keyFolder+'cursor.png',true);
  ControlsPic[controls_numbers]:=TGLImage.Create(keyFolder+'numpad.png',true);
end;

constructor TPlayerControls.create;
begin
  FirePressed:=false;
  MovePressed:=false;
  LastFireKeyPress:=k_none;
  LastMoveKeyPress:=k_none;
  FireX:=0;
  FireY:=0;
  MoveX:=0;
  MoveY:=0;
end;

const WASD_keys:FourKeys=(
  up:k_w;
  down:k_s;
  left:k_a;
  right:k_d);
const TFGH_keys:FourKeys=(
    up:k_t;
    down:k_g;
    left:k_f;
    right:k_h);
const IJKL_keys:FourKeys=(
    up:k_i;
    down:k_k;
    left:k_j;
    right:k_l);
const cursor_keys:fourKeys=(
  up:k_up;
  down:k_down;
  left:k_left;
  right:k_right);
const numbers_keys:FourKeys=(
  up:k_numpad_8;
  down:k_numpad_2;
  left:k_numpad_4;
  right:k_numpad_6);
{//numpad keys identical to cursor keys!!!
with numpad_keys do begin
  up:=k_numpad_up;
  down:=k_numpad_down;
  left:=k_numpad_left;
  right:=k_numpad_right;
end;}

procedure TPlayerControls.makeMoveControls(MoveControlsType:TControlsVariant);
begin
  MoveStyle:=MoveControlsType;
  case MoveControlsType of
    controls_WASD:   MoveKeys:=WASD_keys;
    controls_TFGH:   MoveKeys:=TFGH_keys;
    controls_IJKL:   MoveKeys:=IJKL_keys;
    controls_cursor: MoveKeys:=cursor_keys;
    {controls_numpad: MoveKeys:=numpad_keys;}
    controls_numbers:MoveKeys:=numbers_keys;
  end;
end;
procedure TPlayerControls.makeFireControls(FireControlsType:TControlsVariant);
begin
  FireStyle:=FireControlsType;
  case FireControlsType of
    controls_WASD:   FireKeys:=WASD_keys;
    controls_TFGH:   FireKeys:=TFGH_keys;
    controls_IJKL:   FireKeys:=IJKL_keys;
    controls_cursor: FireKeys:=cursor_keys;
    {controls_numpad: FireKeys:=numpad_keys;}
    controls_numbers:FireKeys:=numbers_keys;
  end;
end;

procedure TPlayerControls.stopControls;
begin
  FirePressed:=false;
  MovePressed:=false;
end;

function GetControlImage(InputKeys:TControlsVariant):TGLImage;
begin
  result:=ControlsPic[InputKeys];
{  if inputKeys=controls_WASD then result:=ControlsPic[controls_WASD] else
  if inputKeys=controls_TFGH then result:=ControlsPic[controls_TFGH] else
  if inputKeys=controls_IJKL then result:=ControlsPic[controls_IJKL] else
  if inputKeys=controls_cursor then result:=ControlsPic[controls_cursor] else
  if inputKeys=controls_numbers then result:=ControlsPic[controls_numbers];}
end;


function DoControlsCollision(controlsStyle:TControlsVariant):TControlsVariant;
var tmpControls:TControlsVariant;
  function checkControllsCollision(controlsStyle:TControlsVariant):boolean;
  begin
   if (controlsStyle<>playerControls[0].MoveStyle) and
      (controlsStyle<>playerControls[0].FireStyle) and ((not player2Active) or (
      (controlsStyle<>playerControls[1].MoveStyle) and
      (controlsStyle<>playerControls[1].FireStyle))) then
             result:=true else result:=false;
  end;
begin
  tmpControls:=ControlsStyle;
  repeat
    tmpControls:=IncControlsStyle(tmpControls);
  until checkControllsCollision(tmpControls);
  result:=tmpcontrols;
end;
Procedure cyclePlayer1Fire;
begin
  playerControls[0].makeFireControls(DoControlsCollision(playerControls[0].FireStyle));
end;
Procedure cyclePlayer1Move;
begin
  playerControls[0].makeMoveControls(DoControlsCollision(playerControls[0].MoveStyle));
end;
Procedure cyclePlayer2Fire;
begin
  if Player2Active then playerControls[1].makeFireControls(DoControlsCollision(playerControls[1].FireStyle));
end;
Procedure cyclePlayer2move;
begin
  if Player2Active then playerControls[1].makeMoveControls(DoControlsCollision(playerControls[1].MoveStyle));
end;

end.

