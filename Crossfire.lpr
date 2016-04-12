{Copyright (C) 2015-2016 Yevhen Loza

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.}

program Crossfire;

{$Apptype GUI}

uses Classes, SysUtils,
  castle_window, CastleWindow, castle_base,

  CastleGLImages,

  CastleKeysMouse;

const maxx=2*6; {not odd}
      maxy=maxx;
      nenemies=maxx*4 div 2;
      scale=48; {square image size}
      simultaneous_active=3;//round(sqrt(nenemies));
      missle_explosion=10;

const DatFolder= 'DAT'+pathdelim;

type TBotType = (botplayer,bot1,bot2,bot3,botboss);

type TBot=class(TObject)
  public
  hp,maxhp:integer;
  x,y,vx,vy:single;
  start_x,start_y:integer;
  lastx,lasty,nextx,nexty:integer;
  BotType:TBotType;
  LastFireTime:TDateTime;
  FireRate:double;
  mobility:double;
  BotSpeed:double;
  isHidden,isMoving:boolean;
  procedure move(dx,dy:shortint);
  procedure fire(dx,dy:shortint);
  procedure doMove;
  procedure doDraw;
  procedure doAI;
  procedure hitme;
  procedure resetMe;
  constructor create(ThisBotType:TBotType);
end;

type TMissle=class(TObject)
  public
    MissleType:TBotType;
    MissleSpeed:double;
    x,y,vx,vy:single;
    IsAlive:boolean;
    countdown:integer;
    constructor create(ThisBot:TBot;dx,dy:shortint);
    procedure doMove;
    procedure doDraw;
end;


{---------------------------}

var Window:TCastleWindow;
  firstrender:boolean;
  BotsImg: array [TBotType] of TGLImage;
  wall,pass: TGLimage;
  playermissle,enemymissle,bossmissle: TGLImage;
  healthbar,emptybar:TGlImage;
  bots: array of TBot;
  missles:array of TMissle;
  nmissles:integer;
  activebots, enemiesalive: integer;
  lastframe:TDateTime;
  timePassed:double;

{------------------------------------------------------------------------------------}
{====================================================================================}
{------------------------------------------------------------------------------------}
function sgn(value:single):shortint;
begin
  if value>0 then result:=1 else
  if value<0 then result:=-1 else result:=0;
end;


procedure KeyPress(Container: TUIContainer; const Event: TInputPressRelease);
begin
  if bots[0].hp>0 then
  case Event.Key of
    k_up:    bots[0].move(0,+1);
    k_down:  bots[0].move(0,-1);
    k_right: bots[0].move(+1,0);
    k_left:  bots[0].move(-1,0);
    k_w:     bots[0].fire(0,+1);
    k_s:     bots[0].fire(0,-1);
    k_d:     bots[0].fire(+1,0);
    k_a:     bots[0].fire(-1,0);
  end;
end;

{------------------------------------------------------------------------------------}
{====================================================================================}
{------------------------------------------------------------------------------------}

constructor TMissle.create(thisBot:TBot;dx,dy:shortint);
begin
  vx:=dx;
  vy:=dy;
  x:=thisbot.x+0.5+random*0.2-0.1;
  y:=thisbot.y+0.5+random*0.2-0.1;
  MissleType:=ThisBot.BotType;
  MissleSpeed:=5;
  IsAlive:=true;
end;

procedure TMissle.doDraw;
var thisscale:integer;
    mx,my:integer;
begin
  if isalive then thisscale:=round(scale*24/128) else begin
    thisscale:=round(24/128*scale*(8*(missle_explosion-countdown)/missle_explosion+1));
    dec(countdown);
  end;
  mx:=round((x-12/128*thisscale/round(scale*24/128))*scale);
  my:=round((y-12/128*thisscale/round(scale*24/128))*scale);
  //doesn't accessing 128th x of the 12x image cause memory failure???
  case MissleType of
    botplayer: playermissle.draw(mx,my,thisscale,thisscale,0,0,24,24);
    bot1,bot2,bot3: enemymissle.draw(mx,my,thisscale,thisscale,0,0,24,24);
    botboss: bossmissle.draw(mx,my,thisscale,thisscale,0,0,24,24);
  end;
end;

procedure TMissle.doMove;
var newx,newy:single;
    missle_lives:boolean;
    i:integer;

    function hostile(bot1,bot2:TBotType):boolean;
    begin
      if ((bot1=botplayer) and (bot2<>botplayer)) or
         ((bot2=botplayer) and (bot1<>botplayer)) then result:=true else result:=false;
    end;
begin
  newx:=x+vx*MissleSpeed*TimePassed;
  newy:=y+vy*MissleSpeed*TimePassed;
  missle_lives:=true;
  if (newx<0) or (newx>maxx+1) or (newy<0) or (newy>maxy+1) then missle_lives:=false;
  //check target hit
  for i:=low(bots) to high(bots) do if bots[i].hp>0 then
    if (newx>bots[i].x) and (newy>bots[i].y) and (newx<bots[i].x+1) and (newy<bots[i].y+1) then begin
      if hostile(bots[i].bottype,missletype) then begin
        bots[i].hitme;
        missle_lives:=false;
      end;
    end;
  //finally
  if Missle_lives then begin
    x:=newx;
    y:=newy;
  end else begin
    //missle dies
    isAlive:=false;
    countdown:=missle_explosion;
  end;
end;

{------------------------------------------------------------------------------------}
{====================================================================================}
{------------------------------------------------------------------------------------}

procedure TBot.resetMe;
begin
  lastFireTime:=now;
  BotSpeed:= 2;
  vx:=0;vy:=0;
  if BotType=botplayer then isHidden:=false else isHidden:=true;
  case botType of
    botplayer: maxHp:=200;
    bot1:      maxHp:=20;
    bot2:      maxHp:=40;
    bot3:      maxHp:=100;
    botBoss:   MaxHp:=300;
  end;
  case botType of
    bot1:      Mobility:=0.05;
    bot2:      Mobility:=0.1;
    bot3:      Mobility:=0.2;
    botBoss:   Mobility:=0.9;
  end;
  isMoving:=false;
  hp:=maxHp;
  x:=start_x;
  y:=start_y;
  lastx:=round(x);
  lasty:=round(y);
  nextx:=lastx;
  nexty:=lasty;
end;

constructor TBot.create(ThisBotType:TBotType);
var i:integer;
  flg:boolean;
  tryx,tryy:integer;
begin
  inherited create;
  bottype:=ThisBotType;
  if ThisBotType=botplayer then begin
    FireRate:= 0.03/24/60/60;{3 shots/sec}
    start_x:=maxx div 2; if odd((start_x)) then start_x-=1;
    start_y:=maxy div 2; if odd((start_y)) then start_y-=1;
  end
  else begin
    FireRate:= 0.9/24/60/60;
    start_x:=-1;
    start_y:=-1;
    repeat
      flg:=true;
      tryx:=round(random*(maxx-2)/2)*2+1;
      tryy:=round(random*(maxy-2)/2)*2+1;
      case random(4) of
        0: tryx:=0;
        1: tryx:=maxx;
        2: tryy:=0;
        3: tryy:=maxy;
      end;
      for i:=1 to nenemies do if (bots[i]<>nil) then
        if (bots[i].start_x=tryx) and (bots[i].start_y=tryy) then flg:=false;
    until flg;
    start_x:=tryx;
    start_y:=tryy;
  end;
  resetMe;
end;

procedure TBot.move(dx,dy:shortint);
var moveAllowed:boolean;
    tryNextX,tryNextY,tryLastX,tryLastY,tryNewVX,tryNewVY:integer;
    i:integer;
begin
  moveAllowed:=true;
  if (dx<>0) and (vy<>0) then MoveAllowed:=false;
  if (dy<>0) and (vx<>0) then MoveAllowed:=false;
  if (sgn(vx)=sgn(dx)) and (sgn(vy)=sgn(dy)) then MoveAllowed:=false; //bug

  tryNewVX:=dx;
  tryNewVY:=dy;
  tryLastX:=nextX;
  tryLastY:=nextY;
  if not IsHidden then begin
    //normal movement
    tryNextX:=tryLastX+2*tryNewVX;
    tryNextY:=tryLastY+2*tryNewVY;
    if (tryNextX<1) or (tryNextY<1) or (tryNextX>maxx-1) or (TryNextY>maxy-1) then MoveAllowed:=false;
  end else begin
    //leaving bunker
    tryNextX:=tryLastX+tryNewVX;
    tryNextY:=tryLastY+tryNewVY;
    if (tryNextX<0) or (tryNextY<0) or (tryNextX>maxx) or (TryNextY>maxy) then MoveAllowed:=false;
    if (tryNextX=0) and (tryNextY=0) then MoveAllowed:=false;
    if (tryNextX=maxx) and (tryNextY=0) then MoveAllowed:=false;
    if (tryNextX=maxx) and (tryNextY=maxy) then MoveAllowed:=false;
    if (tryNextX=0) and (tryNextY=maxy) then MoveAllowed:=false;
  end;
  //check simple collisions
  for i:=low(bots) to high(bots) do if (bots[i].hp>0) and (bots[i].nextX=tryNextX) and (bots[i].nextY=tryNextY) then MoveAllowed:=false;
  //BUG - might overlap sometimes  on excessive back-forward manuvering
  //this fix does bad job, need to improve, maybe
//  for i:=low(bots) to high(bots) do if (bots[i].lastX=tryNextX) and (bots[i].lastY=tryNextY) then MoveAllowed:=false;
  //finally if move is allowed
  if MoveAllowed then begin
    isHidden:=false; {for enemy bots - if they can move they leave the cover}
    vx:=tryNewVX;
    vy:=tryNewVY;
    nextX:=tryNextX;
    nextY:=tryNextY;
    lastX:=tryLastX;
    lastY:=tryLastY;
  end;
end;

procedure TBot.fire(dx,dy:shortint);
var FireAllowed:boolean;
begin
  if (now-lastFireTime)>=FireRate then begin
    FireAllowed:=true;
    if (dx<>0) and (vy<>0) then FireAllowed:=false;
    if (dy<>0) and (vx<>0) then FireAllowed:=false;
    if FireAllowed then begin
      //create a missle
      inc(nmissles);
      setlength(missles,nmissles);
      missles[nmissles-1]:=TMissle.create(self,dx,dy);
      lastFireTime:=now;
    end;
  end;
end;

procedure TBot.doDraw;
begin
  if hp>0 then
    botsImg[bottype].draw(round(x*scale),round(y*scale),scale,scale,0,0,128,128);
end;

procedure TBot.hitme;
begin
  dec(hp);
  if hp=0 then begin
    //draw explosion
    if bottype=bot1 then begin
      bottype:=bot2;
      fireRate:=fireRate/3;
      ResetMe;
    end else
    if bottype=bot2 then begin
      bottype:=bot3;
      fireRate:=fireRate/3;
      ResetMe;
    end else if random<0.1 then begin
      bottype:=botboss;
      fireRate:=fireRate/10;
      ResetMe;
    end;
    //this is the end;
  end;
end;

procedure TBot.doMove;
var newx,newy:single;
begin
 if (vx<>0) or (vy<>0) then begin
  isMoving:=true;
  newx:=x+vx*botSpeed*TimePassed;
  newy:=y+vy*botSpeed*TimePassed;
  if sgn(x-nextx)<>sgn(newx-nextx) then begin newx:=round(newx); vx:=0; end;
  if sgn(y-nexty)<>sgn(newy-nexty) then begin newy:=round(newy); vy:=0; end;
  x:=newx;
  y:=newy;
  if (vx=0) and (vy=0) then begin
    //arrived at destination
    isMoving:=false;
    lastx:=nextx;
    lasty:=nexty;
  end;
 end;
end;

{------------------------------------------------------------------------------------}

procedure TBot.doAI;
var dx,dy:shortint;
begin
  if isHidden then begin
    //try leave the cover
    if ((simultaneous_active>activebots) and (random<1/60/(enemiesalive+1))) or (random<1/60*1e-3) then begin
      dx:=0;dy:=0;
      if (x=0) or (x=maxx) then dy:=round((random-0.5)*2);
      if (y=0) or (y=maxy) then dx:=round((random-0.5)*2);
      if (dx<>0) or (dy<>0) then move(dx,dy);
    end;
  end else begin
    case random(8) of
      0: if not isMoving and (random<Mobility) then move(0,+1);
      1: if not isMoving and (random<Mobility) then move(0,-1);
      2: if not isMoving and (random<Mobility) then move(+1,0);
      3: if not isMoving and (random<Mobility) then move(-1,0);
      4: fire(0,+1);
      5: fire(0,-1);
      6: fire(+1,0);
      7: fire(-1,0);
    end;
  end;
end;

{------------------------------------------------------------------------------------}
{====================================================================================}
{------------------------------------------------------------------------------------}

procedure doStartGame;
var i:integer;
begin
  randomize;
  nmissles:=0;
  setlength(bots,nenemies+1);
  bots[0]:=TBot.create(botplayer);
  for i:=1 to high(bots) do bots[i]:=TBot.create(bot1);
end;

{------------------------------------------------------------------------------------}

procedure doLoadImages;
var i:TBotType;
begin
  lastFrame:=now;
  BotsImg[botplayer]:=TGLImage.create(DatFolder+'p.png');
  BotsImg[bot1]:=TGLImage.create(DatFolder+'01.png');
  BotsImg[bot2]:=TGLImage.create(DatFolder+'02.png');
  BotsImg[bot3]:=TGLImage.create(DatFolder+'03.png');
  BotsImg[botboss]:=TGLImage.create(DatFolder+'boss.png');
  for i in TBotType do botsImg[i].SmoothScaling:=true;
  Wall:=TGLImage.create(datFolder+'Pattern_002_CC0_by_Nobiax_diffuse.png');
  wall.smoothscaling:=true;
  Pass:=TGLImage.create(datFolder+'Pattern_197_CC0_by_Nobiax_diffuse.png');
  pass.SmoothScaling:=true;
  PlayerMissle:=TGLImage.create(datFolder+'playermissle.png');
  EnemyMissle:=TGLImage.create(datFolder+'enemymissle.png');
  BossMissle:=TGLImage.create(datFolder+'bossmissle.png');
  EmptyBar:=TGLImage.create(datFolder+'SleekBars_CC0_by_Janna(opengameart)_empty.png');
  HealthBar:=TGLImage.create(datFolder+'SleekBars_CC0_by_Janna(opengameart)_full.png');
  doStartGame;
end;

{------------------------------------------------------------------------------------}

procedure DoDrawMap;
var ix,iy:integer;
begin
for ix:=0 to maxx do
 for iy:=0 to maxy do if odd(ix) and odd(iy) then begin
     //draw wall
     wall.Draw(ix*scale,iy*scale,scale,scale,0,0,128,128);
   end else begin
     //draw pass
     pass.Draw(ix*scale,iy*scale,scale,scale,0,0,128,128);
   end;
end;

procedure doDrawBots;
var i:integer;
begin
  for i:=low(bots) to high(bots) do bots[i].doDraw;
  for i:=low(missles) to high(missles) do missles[i].doDraw;
end;

procedure doDrawInterface;
var medianW,median128:integer;
begin
  medianW:=round(window.width*bots[0].hp / bots[0].maxHp);
  median128:=round(118*bots[0].hp / bots[0].maxHp);
  HealthBar.Draw(0,window.height-32,medianW,32,0,0,median128,32);
  emptyBar.Draw(medianW,window.height-32,window.width-medianW,32,median128,0,118,32);
end;

procedure doDisplayImages;
begin
  doDrawMap;
  doDrawBots;
  doDrawInterface;
end;

procedure doGame;
var i,nm:integer;
begin
  activebots:=0;enemiesalive:=0;
  for i:=1 to high(bots) do if (bots[i].hp>0) then begin
    inc(enemiesalive);
    if not bots[i].isHidden then inc(activebots);
  end;
  // do enemy AI
  for i:=1 to high(bots) do if bots[i].hp>0 then bots[i].doAI;
  // move missles
  for i:=low(missles) to high(missles) do if missles[i].isAlive then missles[i].domove;
  //if missles are not alive then die them
  nm:=-1;
  for i:=low(missles) to high(missles) do begin
    if (not missles[i].isAlive) and (missles[i].countdown<=0) then freeandnil(missles[i]) else begin
      inc(nm);
      if nm<>i then missles[nm]:=missles[i]
    end;
  end;
  if nm<>nmissles-1 then begin
    nmissles:=nm+1;
    setlength(missles,nmissles);
  end;
  // and move bots
  for i:=low(bots) to high(bots) do bots[i].domove;
end;

{------------------------------------------------------------------------------------}
{====================================================================================}
{------------------------------------------------------------------------------------}

procedure doRender(Container: TUIContainer);
begin
  if firstrender then doLoadImages;
  timePassed:=(now-lastFrame)*24*60*60; {sec}
  doGame;

  doDisplayImages;

  lastFrame:=now;
  firstrender:=false;
end;

procedure doTimer;
begin
  window.DoRender;
end;

{------------------------------------------------------------------------------------}
{====================================================================================}
{------------------------------------------------------------------------------------}

begin
firstrender:=true;
Window:=TCastleWindow.create(Application);
window.DoubleBuffer:=true;
window.OnPress:=@KeyPress;
window.OnRender:=@doRender;
window.Width:=(maxx+1)*scale;
window.height:=(maxy+1)*scale+32;
application.TimerMilisec:=1000 div 60; //60 fps
application.OnTimer:=@dotimer;
{=== this will start the game ===}
Window.Open;
Application.Run;
{=== ........................ ===}

end.

