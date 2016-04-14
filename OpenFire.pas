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

program OpenFire;

{$Apptype GUI}

uses {$IFDEF UNIX}cthreads,{$ENDIF} Classes, SysUtils,
  castle_window, CastleWindow, castle_base,
  CastleGLImages,
  CastleOpenAL, CastleSoundEngine, CastleTimeUtils, CastleVectors,
  CastleKeysMouse;

const maxx=2*6; {not odd}
      maxy=2*5;
      nenemies=maxx+maxy;
      scale=48; {square image size}
      simultaneous_active=3;//round(sqrt(nenemies));
      missle_explosion=10;

const BotFolder= 'DAT'+pathdelim+'bots'+pathdelim;
      ExpFolder= 'DAT'+pathdelim+'explosions'+pathdelim;
      GuiFolder= 'DAT'+pathdelim+'gui'+pathdelim;
      MapFolder= 'DAT'+pathdelim+'map'+pathdelim;
      MusFolder= 'DAT'+pathdelim+'music'+pathdelim;
      SndFolder= 'DAT'+pathdelim+'sound'+pathdelim;
      VocFolder= 'DAT'+pathdelim+'voice'+pathdelim;

type TBotType = (botplayer,bot1,bot2,bot3,botboss);

type TBot=class(TObject)
  public
  hp,maxhp:integer;
  x,y,vx,vy:single;
  start_x,start_y:integer;
  lastx,lasty,nextx,nexty:integer;
  BotType:TBotType;
  BornToBeABoss:integer;
  LastFireTime:TDateTime;
  FireRate:double;
  mobility:double;
  BotSpeed:double;
  isHidden,isMoving:boolean;

  countdown,explosiontype:integer;
  procedure move(dx,dy:shortint);
  procedure fire(dx,dy:shortint);
  procedure PlayerFire(dx,dy:shortint);
  procedure doPlayerFire;
  procedure doMove;
  procedure doDraw;
  procedure doAI;
  procedure SayHi;
  procedure hitme;
  procedure EndMyLife;
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

type TMusic_context=(music_easy,music_mid,music_hard,music_boss);
type TMusicLoadThread = class(TThread)
  private
  protected
    procedure Execute; override;
end;
{---------------------------}

var Window:TCastleWindow;
  firstrender:boolean;
  //images
  BotsImg: array [TBotType] of TGLImage;
  wall,pass: TGLimage;
  playermissle,enemymissle,bossmissle: TGLImage;
  explosionImg:array[1..6] of TGLImage;
  healthbar,emptybar:TGlImage;
  //sounds
  SndPlayerShot,sndBotShot1,sndBotShot2:TSoundBuffer;
  sndPlayerHit:array[1..6] of TSoundBuffer;
  sndBotHit:array[1..9] of TSoundBuffer;
  sndExplosion:TSoundBuffer;
  nvoices:integer;
  sndVoice:array of TSoundBuffer;
  voiceDuration:array of TFloatTime;
  MyVoiceTimer:TDateTime;
  LastVoice:integer=-1;
  //music
  music: TSoundBuffer;
  music_duration: TFloatTime;
  oldmusic:integer;
  MusicLoadThread:TMusicLoadThread; //thread to load music in background to avoid lags
  MyMusicTimer:TDateTime;
  MusicReady:boolean;
  music_context:TMusic_context;
  AverageEnemyPower:single=0;
  //general
  bots: array of TBot;
  missles:array of TMissle;
  nmissles:integer;
  activebots, enemiesalive: integer;
  lastframe:TDateTime;
  timePassed:double;
  //gui
  GameScreenStartX,GameScreenEndX:integer;
  FirePressed{,mousefire}:boolean;
  LastFireKeyPress:TKey;
  FireX,FireY:shortint;

{$R+}{$Q+}

{------------------------------------------------------------------------------------}
{====================================================================================}
{------------------------------------------------------------------------------------}
function sgn(value:single):shortint;
begin
  if value>0 then result:=1 else
  if value<0 then result:=-1 else result:=0;
end;


procedure KeyPress(Container: TUIContainer; const Event: TInputPressRelease);
var dx,dy:single;
begin
{  mouseFire:=false;}
  if bots[0].hp>0 then
  case Event.Key of
    k_up:    bots[0].move(0,+1);
    k_down:  bots[0].move(0,-1);
    k_right: bots[0].move(+1,0);
    k_left:  bots[0].move(-1,0);
    k_w:     begin bots[0].PlayerFire(0,+1); lastFireKeyPress:=Event.Key; end;
    k_s:     begin bots[0].PlayerFire(0,-1); lastFireKeyPress:=Event.Key; end;
    k_d:     begin bots[0].PlayerFire(+1,0); lastFireKeyPress:=Event.Key; end;
    k_a:     begin bots[0].PlayerFire(-1,0); lastFireKeyPress:=Event.Key; end;
    K_None:
      if event.MouseButton=mbLeft then begin
          if (Event.Position[0]>GameScreenStartX) and (Event.Position[0]<GameScreenEndX) then begin
            //do game
    {        mousefire:=true;}
            dx:=(Event.Position[0]-GameScreenStartX)-(bots[0].x+0.5)*scale;
            dy:=(Event.Position[1])-(bots[0].y+0.5)*scale;
            if abs(dx)>abs(dy) then begin
              if (dx<0) then bots[0].Move(-1,0) else bots[0].Move(+1,0);
            end else begin
              if (dy<0) then bots[0].Move(0,-1) else bots[0].Move(0,+1);
            end;
          end else begin
            //do side menu
          end;
      end;
  end;
end;

procedure KeyRelease(Container: TUIContainer; const Event: TInputPressRelease);
begin
  //if (bots[0].hp>0) and (FirePressed) then
  case Event.Key of
    k_w,k_s,k_d,k_a: {begin   } if event.Key=LastFireKeyPress then FirePressed:=false;{mousefire:=false; end; }
  end;
 { if event.MouseButton = mbLeft then begin
    FirePressed:=false;
    mousefire:=false;
  end;   }
end;

{procedure KeyMotion(Container: TUIContainer; const Event: TInputMotion);
var dx,dy:single;
begin
 if mousefire then begin
   dx:=(Event.Position[0]-GameScreenStartX)-(bots[0].x-0.5)*scale;
   dy:=(Event.Position[1])-(bots[0].y-0.5)*scale;
   if abs(dx)>abs(dy) then begin
     if (dx<0) then bots[0].PlayerFire(-1,0) else bots[0].PlayerFire(+1,0);
   end else begin
     if (dy<0) then bots[0].PlayerFire(0,-1) else bots[0].PlayerFire(0,+1);
   end;

 end;
end;            }

{------------------------------------------------------------------------------------}
{====================================================================================}
{------------------------------------------------------------------------------------}

procedure doLoadMusic;
begin
 MusicReady:=false;
 MyMusicTimer:=now;
 Music_duration:=10000;
 //launching music through a thread to avoid lags both in music and gameplay
 MusicLoadThread:=TMusicLoadThread.Create(true);
 MusicLoadThread.FreeOnTerminate:=true;
 MusicLoadThread.Priority:=tpLower;
 MusicLoadThread.Start;
end;

procedure TMusicLoadThread.execute;
var nextmusic:integer;
    music_name:string;
begin
 if (music_context=music_boss) and (oldmusic=7) then music_context:=music_hard;
 repeat
   case music_context of
     music_easy: nextmusic:=random(3);
     music_mid: nextmusic:=3+random(2);
     music_hard: nextmusic:=5+random(2);
     music_boss: if oldmusic<>7 then nextmusic:=7 else nextmusic:=6;
   end;
 until nextmusic<>oldmusic;
 //load the track
 case nextmusic of
     0: music_name:='1_cannontube_CC-BY_by_Gundatsch.ogg';
     1: music_name:='1_Isthissupposedtobehere_CC-BY_by_Gundatsch.ogg';
     2: music_name:='1_misanthropy-low_CC-BY_by_Gundatsch.ogg';
     3: music_name:='2_cannontube_loop_medium_CC-BY_by_Gundatsch.ogg';
     4: music_name:='2_InnerCore_Low_CC-BY_by_Gundatsch.ogg';
     5: music_name:='3_destoroya_CC-BY_by_Gundatsch.ogg';
     6: music_name:='3_Magerbruchstand_CC-BY_by_Gundatsch.ogg';
     else music_name:='4_ABoarInTheBushesFull_CC-BY_by_Gundatsch_01.ogg';
 end;
 //start music
 music:=soundengine.loadbuffer(MusFolder+music_name,music_duration);
 //and finish
 oldmusic:=nextmusic;
 MyMusicTimer:=now;
 MusicReady:=true;
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
    botplayer: playermissle.draw(GameScreenStartX+mx,my,thisscale,thisscale,0,0,24,24);
    bot1,bot2,bot3: enemymissle.draw(GameScreenStartX+mx,my,thisscale,thisscale,0,0,24,24);
    botboss: bossmissle.draw(GameScreenStartX+mx,my,thisscale,thisscale,0,0,24,24);
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
  vx:=0;vy:=0;
  if BotType=botplayer then isHidden:=false else isHidden:=true;

  case botType of
    botplayer: maxHp:=200;
    bot1:      maxHp:=20;
    bot2:      maxHp:=40;
    bot3:      maxHp:=70;
    botBoss:   MaxHp:=250;
  end;
  case botType of
    botplayer: BotSpeed:= 2;
    bot1:      BotSpeed:= 3;
    bot2:      BotSpeed:= 2;
    bot3:      BotSpeed:= 2.1;
    botBoss:   BotSpeed:= 1.9;
  end;
  case botType of
    bot1:      Mobility:=0.05;
    bot2:      Mobility:=0.1;
    bot3:      Mobility:=0.2;
    botBoss:   Mobility:=0.075;
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
  BornToBeABoss:=0;
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
    if isHidden then SayHi;
    isHidden:=false; {for enemy bots - if they can move they leave the cover}
    vx:=tryNewVX;
    vy:=tryNewVY;
    nextX:=tryNextX;
    nextY:=tryNextY;
    lastX:=tryLastX;
    lastY:=tryLastY;
  end;
end;

procedure TBot.SayHi;
var PlayVoice:integer;
begin
  if (Now>MyVoiceTimer) then begin
    Repeat
      PlayVoice:=random(nVoices);
    until (PlayVoice<>lastVoice) or (nVoices=1);
    SoundEngine.PlaySound(sndVoice[PlayVoice], false, false, 1, 0.7, 0, 1, ZeroVector3Single);
    MyVoiceTimer:=now+VoiceDuration[PlayVoice]/60/60/24;
    LastVoice:=PlayVoice;
  end;
end;

procedure TBot.PlayerFire(dx,dy:shortint);
begin
 FireX:=dx;
 FireY:=dy;
 FirePressed:=true;
end;

procedure TBot.DoPlayerFire;
begin
  if FirePressed then fire(FireX,FireY);
end;


procedure TBot.fire(dx,dy:shortint);
var FireAllowed:boolean;
begin
  if (now-lastFireTime)>=FireRate then begin
    FireAllowed:=true;
    if (dx<>0) and (vy<>0) then FireAllowed:=false;
    if (dy<>0) and (vx<>0) then FireAllowed:=false;
    {bot specific tweaks}
    if (x<2) and (dx<>1) then FireAllowed:=false;
    if (y<2) and (dy<>1) then FireAllowed:=false;
    if (x>maxx-2) and (dx<>-1) then FireAllowed:=false;
    if (y>maxy-2) and (dy<>-1) then FireAllowed:=false;
    if FireAllowed then begin
      if bottype=botplayer then
        SoundEngine.PlaySound(sndPlayerShot, false, false, 0, 0.5, 0, 1, ZeroVector3Single)
      else
        case random(2) of
          0: SoundEngine.PlaySound(sndBotShot1, false, false, 0, 0.3, 0, 1, ZeroVector3Single);
          else SoundEngine.PlaySound(sndBotShot2, false, false, 0, 0.3, 0, 1, ZeroVector3Single);
        end;
      //create a missle
      inc(nmissles);
      setlength(missles,nmissles);
      missles[nmissles-1]:=TMissle.create(self,dx,dy);
      lastFireTime:=now;
    end;
  end;
end;

procedure TBot.EndMyLife;
begin
  if bottype=bot1 then begin
    bottype:=bot2;
    fireRate:=fireRate/3;
    ResetMe;
  end else
  if bottype=bot2 then begin
    bottype:=bot3;
    fireRate:=fireRate/3;
    ResetMe;
  end else if (bottype=bot3) and (BornToBeABoss>0) then begin
    //todo: select boss based on BornToBeABoss
    bottype:=botboss;
    fireRate:=fireRate/10;
    ResetMe;
  end;
  //if no reanimation - this is the end;
end;

procedure TBot.doDraw;
begin
  if hp>0 then
    botsImg[bottype].draw(GameScreenStartX+round(x*scale),round(y*scale),scale,scale,0,0,128,128)
  else if countdown>0 then begin
    dec(countdown);
    vx:=vx/1.01;
    vy:=vy/1.01;
    explosionImg[explosionType].draw(GameScreenStartX+round((x-1.5)*scale),round((y-1.5)*scale),scale*4,scale*4,100*((100-countdown) mod 10),1024-100-100*((100-countdown) div 10),100,100);
    if countdown=0 then endMyLife;
  end;
end;

procedure TBot.hitme;
begin
  dec(hp);
  if hp<=0 then begin
    hp:=0;
    SoundEngine.PlaySound(sndExplosion, false, false, 2, 1, 0, 1, ZeroVector3Single);
    countdown:=100;
    //prepare explosion
    case bottype of
      botplayer,botboss: explosionType:=5+round(random);
      bot1: explosionType:=1+round(random*4);
      bot2,bot3: explosionType:=2+random(5);
    end;
  end else begin
    if bottype=botplayer then
      SoundEngine.PlaySound(sndPlayerHit[Random(6)+1], false, false, 1, 0.5, 0, 1, ZeroVector3Single)
    else
      SoundEngine.PlaySound(sndBotHit[Random(9)+1], false, false, 0, 0.4, 0, 1, ZeroVector3Single)
  end;
end;

procedure TBot.doMove;
var newx,newy:single;
begin
 if (vx<>0) or (vy<>0) then begin
  isMoving:=true;
  newx:=x+vx*botSpeed*TimePassed;
  newy:=y+vy*botSpeed*TimePassed;
  if hp>0 then begin // add some inertia if the bot explodes onmove
    if sgn(x-nextx)<>sgn(newx-nextx) then begin newx:=round(newx); vx:=0; end;
    if sgn(y-nexty)<>sgn(newy-nexty) then begin newy:=round(newy); vy:=0; end;
  end;
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
      4: if bots[0].y-y>0 then fire(0,+1);
      5: if bots[0].y-y<0 then fire(0,-1);
      6: if bots[0].x-x>0 then fire(+1,0);
      7: if bots[0].x-x<0 then fire(-1,0);
    end;
  end;
end;

{------------------------------------------------------------------------------------}
{====================================================================================}
{------------------------------------------------------------------------------------}

procedure doStartGame;
var i:integer;
    bosses:integer;
begin
  randomize;
  nmissles:=0;
  setlength(bots,nenemies+1);
  bots[0]:=TBot.create(botplayer);
  for i:=1 to high(bots) do bots[i]:=TBot.create(bot1);
  bosses:=2;
  repeat
    i:=1+random(nenemies-1);
    if bots[i].BornToBeABoss=0 then begin
      bots[i].BornToBeABoss:=1;
      dec(bosses);
    end;
  until bosses=0;
  FirePressed:=false;
  LastFireKeyPress:=k_none;
  //MouseFire:=false;
end;

{------------------------------------------------------------------------------------}

procedure doLoadGameData;
var i:TBotType;
    j:integer;
begin
  lastFrame:=now;
  //load TGLImages
  BotsImg[botplayer]:=TGLImage.create(BotFolder+'p.png');
  BotsImg[bot1]:=TGLImage.create(BotFolder+'01.png');
  BotsImg[bot2]:=TGLImage.create(BotFolder+'02.png');
  BotsImg[bot3]:=TGLImage.create(BotFolder+'03.png');
  BotsImg[botboss]:=TGLImage.create(BotFolder+'boss.png');
  for i in TBotType do botsImg[i].SmoothScaling:=true;
  Wall:=TGLImage.create(MapFolder+'Pattern_002_CC0_by_Nobiax_diffuse.png');
  wall.smoothscaling:=true;
  Pass:=TGLImage.create(MapFolder+'Pattern_027_CC0_by_Nobiax_specular.png');
  pass.SmoothScaling:=true;
  PlayerMissle:=TGLImage.create(BotFolder+'playermissle.png');
  EnemyMissle:=TGLImage.create(BotFolder+'enemymissle.png');
  BossMissle:=TGLImage.create(BotFolder+'bossmissle.png');
  EmptyBar:=TGLImage.create(GuiFolder+'SleekBars_CC0_by_Jannax(opengameart)_empty.png');
  HealthBar:=TGLImage.create(GuiFolder+'SleekBars_CC0_by_Jannax(opengameart)_full.png');
  explosionImg[1]:=TGlImage.create(ExpFolder+'explosion3_CC0_by_StumpyStrust.png');
  explosionImg[2]:=TGlImage.create(ExpFolder+'explosion6a_CC0_by_StumpyStrust.png');
  explosionImg[3]:=TGlImage.create(ExpFolder+'explosion6b_CC0_by_StumpyStrust.png');
  explosionImg[4]:=TGlImage.create(ExpFolder+'explosion6c_CC0_by_StumpyStrust.png');
  explosionImg[5]:=TGlImage.create(ExpFolder+'explosion9_CC0_by_StumpyStrust.png');
  explosionImg[6]:=TGlImage.create(ExpFolder+'explosion10_CC0_by_StumpyStrust.png');
  //load sounds as TSoundBuffer
  SndPlayerShot:= SoundEngine.LoadBuffer(SndFolder+'bookOpen_CC0_by_Kenney.nl.ogg');
  SndBotShot1:= SoundEngine.LoadBuffer(SndFolder+'beltHandle1_CC0_by_Kenney.nl.ogg');
  SndBotShot2:= SoundEngine.LoadBuffer(SndFolder+'beltHandle2_CC0_by_Kenney.nl.ogg');
  sndPlayerHit[1]:= SoundEngine.LoadBuffer(SndFolder+'hit21_CC0_by_Independent.nu.ogg');
  sndPlayerHit[2]:= SoundEngine.LoadBuffer(SndFolder+'hit23_CC0_by_Independent.nu.ogg');
  sndPlayerHit[3]:= SoundEngine.LoadBuffer(SndFolder+'hit24_CC0_by_Independent.nu.ogg');
  sndPlayerHit[4]:= SoundEngine.LoadBuffer(SndFolder+'hit25_CC0_by_Independent.nu.ogg');
  sndPlayerHit[5]:= SoundEngine.LoadBuffer(SndFolder+'hit31_CC0_by_Independent.nu.ogg');
  sndPlayerHit[6]:= SoundEngine.LoadBuffer(SndFolder+'hit35_CC0_by_Independent.nu.ogg');
  sndBotHit[1]:= SoundEngine.LoadBuffer(SndFolder+'footstep01_CC0_by_Kenney.nl.ogg');
  sndBotHit[2]:= SoundEngine.LoadBuffer(SndFolder+'footstep02_CC0_by_Kenney.nl.ogg');
  sndBotHit[3]:= SoundEngine.LoadBuffer(SndFolder+'footstep03_CC0_by_Kenney.nl.ogg');
  sndBotHit[4]:= SoundEngine.LoadBuffer(SndFolder+'footstep04_CC0_by_Kenney.nl.ogg');
  sndBotHit[5]:= SoundEngine.LoadBuffer(SndFolder+'footstep05_CC0_by_Kenney.nl.ogg');
  sndBotHit[6]:= SoundEngine.LoadBuffer(SndFolder+'footstep06_CC0_by_Kenney.nl.ogg');
  sndBotHit[7]:= SoundEngine.LoadBuffer(SndFolder+'footstep07_CC0_by_Kenney.nl.ogg');
  sndBotHit[8]:= SoundEngine.LoadBuffer(SndFolder+'footstep08_CC0_by_Kenney.nl.ogg');
  sndBotHit[9]:= SoundEngine.LoadBuffer(SndFolder+'footstep09_CC0_by_Kenney.nl.ogg');
  sndExplosion:=  SoundEngine.LoadBuffer(SndFolder+'explosion_CC0_by_Independent.nu.ogg');
  //load voice file
{  nVoices:=12;
  setlength(sndVoice,nVoices);
  setlength(VoiceDuration,nVoices);
  for j:=0 to nVoices-1 do
    sndVoice[j]:=  SoundEngine.LoadBuffer(VocFolder+'phrase1-'+inttostr(j+1)+'.ogg',VoiceDuration[j]);}
{  nVoices:=16;
  setlength(sndVoice,nVoices);
  setlength(VoiceDuration,nVoices);
  for j:=0 to nVoices-1 do
    sndVoice[j]:=  SoundEngine.LoadBuffer(VocFolder+'phrase2-'+inttostr(j+1)+'.ogg',VoiceDuration[j]);}
  nVoices:=1;
  setlength(sndVoice,nVoices);
  setlength(VoiceDuration,nVoices);
 sndVoice[0]:=  SoundEngine.LoadBuffer(VocFolder+'anchor_action_CC0_by_legoluft.ogg',VoiceDuration[0]);
  //initialize Sound Engine
  SoundEngine.ParseParameters;
  SoundEngine.MinAllocatedSources := 1;
  //eventually start the game (set up initial parameters and create bots)
  doStartGame;
  //and launch music
  oldMusic:=-1;
  MyVoiceTimer:=now;
  MyMusicTimer:=Now;
  Music_duration:=0;  {a few seconds of silence}
end;

{------------------------------------------------------------------------------------}

procedure DoDrawMap;
var ix,iy:integer;
begin
for ix:=0 to maxx do
 for iy:=0 to maxy do if odd(ix) and odd(iy) then begin
     //draw wall
     wall.Draw(GameScreenStartX+ix*scale,iy*scale,scale,scale,0,0,128,128);
   end else begin
     //draw pass
     pass.Draw(GameScreenStartX+ix*scale,iy*scale,scale,scale,0,0,128,128);
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
  medianW:=round((GameScreenEndX-GameScreenStartX)*bots[0].hp / bots[0].maxHp);
  median128:=round(118*bots[0].hp / bots[0].maxHp);
  HealthBar.Draw(GameScreenStartX+0,window.height-32,medianW,32,0,0,median128,32);
  emptyBar.Draw(GameScreenStartX+medianW,window.height-32,window.width-medianW,32,median128,0,118,32);
end;

procedure doDisplayImages;
begin
  doDrawMap;
  doDrawBots;
  doDrawInterface;
end;

procedure doGame;
var i,nm:integer;
    enemyPower:integer;
begin
  activebots:=0;enemiesalive:=0;enemyPower:=0;
  bots[0].DoPlayerFire;

  for i:=1 to high(bots) do if (bots[i].hp>0) then begin
    inc(enemiesalive);
    if not bots[i].isHidden then begin
      inc(activebots);
      case bots[i].botType of
        bot1:inc(EnemyPower);
        bot2:inc(enemyPower,2);
        bot3:inc(enemyPower,4);
        botboss:enemyPower:=1000;
      end;
    end;
  end;
  averageEnemyPower:=(AverageEnemyPower*10+EnemyPower)/11;
  case round(AverageEnemyPower) of
    -1..5:music_context:=music_easy;
    6..10:music_context:=music_mid;
    else music_context:=music_hard;
  end;
  if EnemyPower>999 then music_context:=music_boss;
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

var RenderingBuisy:boolean=false;
procedure doRender(Container: TUIContainer);
begin
  if firstrender then doLoadGameData;
  timePassed:=(now-lastFrame)*24*60*60; {sec}
  doGame;

  if not RenderingBuisy then begin
    RenderingBuisy:=true;
    doDisplayImages;

    RenderingBuisy:=false;
  end {else increase frameskip};
  lastFrame:=now;
  firstrender:=false;
end;

procedure doTimer;
begin
  window.DoRender;
  if (MyMusicTimer=-1) or ((Now-MyMusicTimer)*60*60*24>Music_duration+1) then doLoadMusic;
  if MusicReady then begin
    SoundEngine.PlaySound(music, false, false, 1, 1, 0, 1, ZeroVector3Single);
    MusicReady:=false;
  end;

end;

{------------------------------------------------------------------------------------}
{====================================================================================}
{------------------------------------------------------------------------------------}

begin
firstrender:=true;
music_context:=music_easy;
Window:=TCastleWindow.create(Application);
window.DoubleBuffer:=true;
window.OnPress:=@KeyPress;
window.onRelease:=@KeyRelease;
//window.OnMotion:=@KeyMotion;
window.OnRender:=@doRender;
window.Width:=(maxx+1)*scale;
window.height:=(maxy+1)*scale+32;
GameScreenStartX:=0;
GameScreenEndX:=(maxx+1)*scale;

application.TimerMilisec:=1000 div 60; //60 fps
application.OnTimer:=@dotimer;
{=== this will start the game ===}
Window.Open;
Application.Run;
{=== ........................ ===}

end.

