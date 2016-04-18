unit firemadnesscontrols;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  CastleKeysMouse;

type TControlsVariant=(controls_WASD,controls_TFGH,controls_IJKL,controls_cursor,{controls_numpad,}controls_numbers);

type FourKeys=record
  up,down,left,right:TKey;
end;

type TPlayerControls=class(TObject)
  public
    MoveKeys,FireKeys:FourKeys;
    FirePressed,MovePressed:boolean;
    LastFireKeyPress,LastMoveKeyPress:TKey;
    FireX,FireY,moveX,moveY:shortint;
    constructor create;
    procedure makeControls(MoveControlsType,FireControlsType:TControlsVariant);
end;


var GameScreenStartX,GameScreenEndX,GameScreenStartY,GameScreenEndY:integer;
    frameskip:integer=1;
    PauseMode:boolean=false;
    PlayerControls:array[0..1] of TPlayerControls;

implementation

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

procedure TPlayerControls.makeControls(MoveControlsType,FireControlsType:TControlsVariant);
begin
  case MoveControlsType of
    controls_WASD:   MoveKeys:=WASD_keys;
    controls_TFGH:   MoveKeys:=TFGH_keys;
    controls_IJKL:   MoveKeys:=IJKL_keys;
    controls_cursor: MoveKeys:=cursor_keys;
    {controls_numpad: MoveKeys:=numpad_keys;}
    controls_numbers:MoveKeys:=numbers_keys;
  end;
  case FireControlsType of
    controls_WASD:   FireKeys:=WASD_keys;
    controls_TFGH:   FireKeys:=TFGH_keys;
    controls_IJKL:   FireKeys:=IJKL_keys;
    controls_cursor: FireKeys:=cursor_keys;
    {controls_numpad: FireKeys:=numpad_keys;}
    controls_numbers:FireKeys:=numbers_keys;
  end;
end;



end.

