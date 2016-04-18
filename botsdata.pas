unit botsdata;

{$mode objfpc}{$H+}

interface

uses SysUtils,
     CastleGLImages,
     CastleOpenAL, CastleSoundEngine, CastleTimeUtils, CastleVectors,
     firemadnesscontrols, general_var,sound_music,map_manager;

const missle_explosion=10;

type TBotType = (botPlayer1,botPlayer2,bot1,bot2,bot3,botBossCrossFire,botBossCarrier,botBossMiner,botmine,botfighter,botshielder,heavybot,bothealer,botTeleporter,botautohealer,botFIWI,botDisabler);

type TBot=class(TObject)
  public
    hp,maxhp:integer;
    x,y,vx,vy:float;
    start_x,start_y:integer;
    lastx,lasty,nextx,nexty:integer;
    BotType:TBotType;
    FireRate:float;
    BotSpeed:float;
    countdown,explosiontype:integer;
    //yeah... those are only for hostile bots, but I don't want to write too much identical copy-code
    isHidden,isMoving:boolean;
    procedure move(dx,dy:shortint);
    function fire(dx,dy:shortint):boolean;
    procedure doMove;
    procedure doDraw;
    procedure hitme(damage:integer);
    constructor create(ThisBotType:TBotType;mx:integer=-1;my:integer=-1);
  private
    LastFireTime,LastActionTimer:TDateTime;
    procedure resetMe;
end;

type TPlayerBot=class(TBot)
  public
    isDisabled:integer;
    procedure PlayerFire(dx,dy:shortint);
    procedure doPlayerFire;
    procedure PlayerMove(dx,dy:shortint);
    procedure doPlayerMove;
    constructor create(ThisBotType:TBotType;mx:integer=-1;my:integer=-1); virtual;
  private
    procedure resetMe; virtual;
end;

type TBossBot=(boss_none,boss_crossfire,boss_carrier,boss_miner);

type THostileBot=class(TBot)
  public
    BornToBeABoss:TBossBot;
    mobility,spawnRate:float;
    isShielded,IsHealing,IAMDEAD:boolean;
    isTeleporting:integer;
    procedure doSpawn(spawn:TBotType);
    procedure doTeleport(OnlyInnerCore:boolean=false);
    procedure doAI;
    function GetPlayerTarget:TPlayerBot;
    constructor create(ThisBotType:TBotType;mx:integer=-1;my:integer=-1); virtual;
  private
    lastSpawnTime:TDateTime;
    procedure EndMyLife;
    procedure SayHi;
    procedure resetMe; virtual;
end;

type TFIWIaction=(f_spawn,f_fire,f_shield,f_teleport);

type TFIWI=class(THostileBot)
  public
    constructor create(mx:integer;my:integer); virtual;
    procedure FIWI_AI;
  private
    FIWI_action_change:float;
    FIWI_lastAction:TFIWIaction;
    FIWI_timer:TDateTime;
    FIWI_Spawn:TBotType;
    FIWI_SpawnTimer:TDateTime;
    SpawnNumber:integer;
    procedure resetMe; virtual;
end;

type TMissle=class(TObject)
  public
    MissleType:TBotType;
    MissleSpeed:float;
    x,y,vx,vy:float;
    IsAlive:boolean;
    countdown:integer;
    constructor create(ThisBot:TBot;dx,dy:shortint);
    procedure doMove;
    procedure doDraw;
  private
    LastActionTimer:TDateTime;
end;

var
    //images
    BotsImg: array [TBotType] of TGLImage;
    playermissle,enemymissle,bossmissle,bigmissle,fightermissle,FIWImissle,DisablerMissle: TGLImage;
    explosionImg:array[1..6] of TGLImage;
    ShieldImg,HealImg,PlayerDisabledImg:array[0..3] of TGLImage;
    teleportimg:TGlImage;
    //general
    bots: array of TBot;
    nenemies:integer;
    missles:array of TMissle;
    nmissles:integer;
    activebots, enemiesalive: integer;
    healerPresent,ShielderPresent: boolean;

procedure doLoadImages;


implementation


procedure doLoadImages;
var i:TBotType;
    j:integer;
begin
  BotsImg[botplayer1]:=TGLImage.create(BotFolder+'Player1.png',true);
  BotsImg[botplayer2]:=TGLImage.create(BotFolder+'Player2.png',true);
  BotsImg[bot1]:=TGLImage.create(BotFolder+'01.png',true);
  BotsImg[bot2]:=TGLImage.create(BotFolder+'02.png',true);
  BotsImg[bot3]:=TGLImage.create(BotFolder+'03.png',true);
  BotsImg[botBossCrossFire]:=TGLImage.create(BotFolder+'BossCrossFire.png',true);
  BotsImg[botBossCarrier]:=TGLImage.create(BotFolder+'BossCarrier.png',true);
  BotsImg[botBossMiner]:=TGLImage.create(BotFolder+'BotBossMiner.png',true);
  BotsImg[botmine]:=TGLImage.create(BotFolder+'BotMine.png',true);
  BotsImg[botfighter]:=TGLImage.create(BotFolder+'BotFighter.png',true);
  BotsImg[botshielder]:=TGLImage.create(BotFolder+'BotShielder.png',true);
  BotsImg[bothealer]:=TGLImage.create(BotFolder+'Healer.png',true);
  BotsImg[botteleporter]:=TGLImage.create(BotFolder+'Teleporter.png',true);
  BotsImg[heavybot]:=TGLImage.create(BotFolder+'HeavyBot.png',true);
  BotsImg[botautohealer]:=TGLImage.create(BotFolder+'AutoHealer.png',true);
  BotsImg[botDisabler]:=TGLImage.create(BotFolder+'BotDisabler.png',true);
  BotsImg[botFIWI]:=TGLImage.create(BotFolder+'FI-WI.png',true);

  PlayerMissle:=TGLImage.create(BotFolder+'playermissle.png',true);
  EnemyMissle:=TGLImage.create(BotFolder+'enemymissle.png',true);
  BossMissle:=TGLImage.create(BotFolder+'bossmissle.png',true);
  BigMissle:=TGLImage.create(BotFolder+'BigMissle.png',true);
  FIWIMissle:=TGLImage.create(BotFolder+'FIWI_missle.png',true);
  FighterMissle:=TGLImage.create(BotFolder+'FighterMissle.png',true);
  DisablerMissle:=TGLImage.create(BotFolder+'DisablerMissle.png',true);

  explosionImg[1]:=TGlImage.create(ExpFolder+'explosion3_CC0_by_StumpyStrust.png',true);
  explosionImg[2]:=TGlImage.create(ExpFolder+'explosion6a_CC0_by_StumpyStrust.png',true);
  explosionImg[3]:=TGlImage.create(ExpFolder+'explosion6b_CC0_by_StumpyStrust.png',true);
  explosionImg[4]:=TGlImage.create(ExpFolder+'explosion6c_CC0_by_StumpyStrust.png',true);
  explosionImg[5]:=TGlImage.create(ExpFolder+'explosion9_CC0_by_StumpyStrust.png',true);
  explosionImg[6]:=TGlImage.create(ExpFolder+'explosion10_CC0_by_StumpyStrust.png',true);

  ShieldImg[0]:=TGLImage.create(BotFolder+'shield1.png',true);
  ShieldImg[1]:=TGLImage.create(BotFolder+'shield2.png',true);
  ShieldImg[2]:=TGLImage.create(BotFolder+'shield3.png',true);
  ShieldImg[3]:=TGLImage.create(BotFolder+'shield4.png',true);
  HealImg[0]:=TGLImage.create(BotFolder+'Healing1.png',true);
  HealImg[1]:=TGLImage.create(BotFolder+'Healing2.png',true);
  HealImg[2]:=TGLImage.create(BotFolder+'Healing3.png',true);
  HealImg[3]:=TGLImage.create(BotFolder+'Healing4.png',true);
  PlayerDisabledImg[0]:=TGLImage.create(BotFolder+'PlayerDisabled1.png',true);
  PlayerDisabledImg[1]:=TGLImage.create(BotFolder+'PlayerDisabled2.png',true);
  PlayerDisabledImg[2]:=TGLImage.create(BotFolder+'PlayerDisabled3.png',true);
  PlayerDisabledImg[3]:=TGLImage.create(BotFolder+'PlayerDisabled4.png',true);


  TeleportImg:=TGLImage.create(BotFolder+'teleporting2.png',true);
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
  if missleType=HeavyBot then MissleSpeed:=4.5 else MissleSpeed:=5;
  if missleType=botFIWI then missleSpeed:=5.5;
  if MissleType=botDisabler then missleSpeed:=6;
  LastActionTimer:=now;
  IsAlive:=true;
end;

procedure TMissle.doDraw;
var thisscale:integer;
    mx,my:integer;
begin
  if isalive then thisscale:=round(scale*24/128) else begin
    thisscale:=round(24/128*scale*(8*(missle_explosion-countdown)/missle_explosion+1));
    if missletype=heavybot then thisscale*=2;
    dec(countdown);
  end;
  if missletype=heavybot then thisscale*=2;
  mx:=GameScreenStartX+round((x-12/128*thisscale/round(scale*24/128))*scale);
  my:=GameScreenStartY+round((y-12/128*thisscale/round(scale*24/128))*scale);
  //doesn't accessing 128th x of the 12x image cause memory failure???
  case MissleType of
    botplayer1,botplayer2: playermissle.draw(mx,my,thisscale,thisscale,0,0,24,24);
    bot1,bot2,bot3,botshielder{botmine},bothealer,botteleporter,botautohealer: enemymissle.draw(mx,my,thisscale,thisscale,0,0,24,24);
    botBossCrossFire,botBossCarrier,botBossMiner: bossmissle.draw(mx,my,thisscale,thisscale,0,0,24,24);
    heavybot: bigmissle.draw(mx,my,thisscale,thisscale,0,0,50,50);
    botfighter: FighterMissle.draw(mx,my,thisscale,thisscale,0,0,50,50);
    botDisabler: DisablerMissle.draw(mx,my,thisscale,thisscale,0,0,50,50);
    botFIWI: FIWImissle.draw(mx,my,thisscale,thisscale,0,0,50,50);
  end;
end;

function hostile(bot1,bot2:TBotType):boolean;
var b1,b2:boolean;
begin
  if (bot1=botplayer1) or (bot1=botplayer2) then b1:=true else b1:=false;
  if (bot2=botplayer1) or (bot2=botplayer2) then b2:=true else b2:=false;
  if (b1 and not b2) or (b2 and not b1) then result:=true else result:=false;
end;


procedure TMissle.doMove;
var newx,newy:float;
    missle_lives:boolean;
    i:integer;
begin
  newx:=x+vx*MissleSpeed*(now-LastActionTimer)*60*60*24;
  newy:=y+vy*MissleSpeed*(now-LastActionTimer)*60*60*24;
  LastActionTimer:=now;
 if not pauseMode then begin
  missle_lives:=true;
  if (newx<0) or (newx>maxx+1) or (newy<0) or (newy>maxy+1) then missle_lives:=false;
  //check target hit
  for i:=low(bots) to high(bots) do if bots[i].hp>0 then
    if (newx>bots[i].x) and (newy>bots[i].y) and (newx<bots[i].x+1) and (newy<bots[i].y+1) then begin
      if hostile(bots[i].bottype,missletype) then begin
        if missletype<>HeavyBot then bots[i].hitme(1) else bots[i].hitme(30);
        if missletype=botDisabler then if bots[i] is TPlayerBot {this is redundant} then (bots[i] as TPlayerBot).isDisabled:=round(300*difficultyLevel.EnemyRangeMultiplier);
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
end;

{------------------------------------------------------------------------------------}
{====================================================================================}
{------------------------------------------------------------------------------------}

procedure TFIWI.ResetMe;
begin
  maxHP:=round(1000*difficultyLevel.EnemyHealthMultiplier);

  BotSpeed:=0;
  Mobility:=-1;
  FireRate:=0.0/24/60/60;
  spawnRate:=-1;

  lastSpawnTime:=now;
  isMoving:=false;
  isShielded:=false;
  isHealing:=false;
  IAMDEAD:=false;
  isTeleporting:=0;

  LastActionTimer:=-1;
  lastFireTime:=now;
  vx:=0;vy:=0;
  hp:=maxHp;
  x:=start_x;
  y:=start_y;
  lastx:=round(x);
  lasty:=round(y);
  nextx:=lastx;
  nexty:=lasty;

  FIWI_lastAction:=f_shield{f_spawn};
  FIWI_timer:=now;
  FIWI_spawn:={botfighter}BotTeleporter;
  FIWI_SpawnTimer:=now;
  isHidden:=FALSE;
  SpawnNumber:=0;
  FIWI_action_change:=5.5/DifficultyLevel.EnemyFirePowerMultiplier;
end;

constructor TFIWI.create(mx:integer;my:integer);
begin
  bottype:=botFIWI;
  start_x:=mx;
  start_y:=my;
  resetMe;
end;

procedure TFIWI.FIWI_AI;
var foe:TPlayerBot;
    FIWI_nextAction:TFIWIAction;
    SpawnsPerSecond:float;
    FIWI_nextSpawn:TBotType;
    ReadyToSpawn,randomSpawn:boolean;
    i,ValidHealerTargets,activeFriends:integer;
begin
  foe:=getPlayerTarget;
  if foe.hp<=0 then exit;
  if FIWI_LastAction=f_spawn then begin
    case FIWI_spawn of
      botFighter: SpawnsPerSecond:=12/FIWI_action_change;
      botMine: SpawnsPerSecond:=10/FIWI_action_change;
      else SpawnsPerSecond:=1.5/FIWI_action_change;
    end;
    ReadyToSpawn:= (now-FIWI_SpawnTimer)*60*60*24>=1/SpawnsPerSecond;
    if ReadyToSpawn then FIWI_SpawnTimer:=now;
  end;
  case FIWI_lastAction of
    f_fire: begin fire(-1,0);fire(1,0);fire(0,-1);fire(0,1) end;
    f_shield: IsShielded:=true;
    f_teleport: if isTeleporting=50 then doTeleport(true) else
                if isteleporting=0 then
                  case random(3) of
                    0:FIWI_lastAction:=f_fire;
                    1:FIWI_lastAction:=f_shield;
                    2:begin
                        FIWI_LastAction:=f_spawn;
                        FIWI_spawn:=botmine;
                      end;
                  end;
    f_spawn: if readyToSpawn then begin
      doSpawn(FIWI_spawn);
    end;
  end;
  if now-FIWI_timer>Fiwi_Action_Change/60/60/24 then begin
    FIWI_Timer:=now;
    repeat
      case random(4) of
        0:FIWI_nextAction:=f_fire;
        1:FIWI_nextAction:=f_shield;
        2:FIWI_nextAction:=f_spawn;
        3:FIWI_nextAction:=f_teleport;
      end;
    until FIWI_nextAction<>FIWI_lastAction;
    activeFriends:=0;
    for i:=low(bots) to high(bots) do if (bots[i].hp>0) and (bots[i] is THostileBot) and (bots[i].bottype<>botmine)  then begin
       if bots[i].bottype=botfighter then inc(activeFriends) else inc(activeFriends,5);
    end;
    if activeFriends<20 then FIWI_nextAction:=f_spawn;

    FIWI_lastAction:=FIWI_nextAction;

    if FIWI_lastAction=f_teleport then begin
      isTeleporting:=100;
    end;

    if FIWI_LastAction=f_spawn then begin
      FIWI_SpawnTimer:=now;
      repeat
        ReadyToSpawn:=true;
        if (Random<0.9) or (SpawnNumber<4) then RandomSpawn:=false else randomSpawn:=true;
        case SpawnNumber of
           0:FIWI_nextSpawn:=botFighter;
           1:FIWI_nextSpawn:=HeavyBot;
           2:FIWI_nextSpawn:=botAutoHealer;
           3:FIWI_nextSpawn:=botFighter;
           4:FIWI_nextSpawn:=HeavyBot;
           5:FIWI_nextSpawn:=botDisabler;
           6:FIWI_nextSpawn:=HeavyBot;
           7:FIWI_nextSpawn:=botFighter;
           8:FIWI_nextSpawn:=HeavyBot;
           9:FIWI_nextSpawn:=BotTeleporter;
          10:FIWI_nextSpawn:=HeavyBot;
          else randomSpawn:=true;
        end;
        if RandomSpawn then
          case random(9) of
            0:FIWI_nextSpawn:=botFighter;
            1:FIWI_nextSpawn:=botMine;
            2:FIWI_nextSpawn:=HeavyBot;
            3:FIWI_nextSpawn:=bot3;
            4:FIWI_nextSpawn:=botHealer;
            5:FIWI_nextSpawn:=botShielder;
            6:FIWI_nextSpawn:=botAutoHealer;
            7:FIWI_nextSpawn:=botTeleporter;
            8:FIWI_nextSpawn:=botDisabler;
          end;
        if FIWI_nextSpawn=FIWI_spawn then readyToSpawn:=false;
        if (FIWI_nextSpawn=botHealer) or (FIWI_nextSpawn=botShielder) or (FIWI_nextSpawn=botDisabler) then begin
          ValidHealerTargets:=0;
          for i:=low(bots) to high(bots) do if bots[i].hp>0 then begin
            if (bots[i].bottype=bot3) or (bots[i].bottype=HeavyBot) then inc(ValidHealerTargets,2);
            if (bots[i].bottype=botAutoHealer) or (bots[i].bottype=botTeleporter) then inc(ValidHealerTargets);
          end;
          if ValidHealerTargets<4 then ReadyToSpawn:=false;
        end;
      until ReadyToSpawn;
      if not RandomSpawn then inc(SpawnNumber);
      FIWI_Spawn:=FIWI_nextSpawn;
    end;
  end;
end;

{------------------------------------------------------------------------------------}
{====================================================================================}
{------------------------------------------------------------------------------------}

procedure THostileBot.ResetMe;
begin
  case botType of
    bot1:                  maxHp:=20;
    bot2:                  maxHp:=40;
    bot3:                  maxHp:=60;
    botBossCrossFire:      MaxHp:=250;
    botBossCarrier:        MaxHp:=250;
    botBossMiner:          MaxHp:=200;
    botmine:               MaxHp:=10;
    botfighter:            MaxHp:=10;
    botshielder:           MaxHp:=100;
    bothealer:             MaxHp:=100;
    botteleporter:         MaxHp:=70;
    heavybot:              MaxHp:=80;
    botautohealer:         MaxHp:=50;
    botDisabler:           MaxHp:=90;
  end;
  maxHP:=round(maxHP*DifficultyLevel.EnemyHealthMultiplier);
  case botType of
    bot1:                  BotSpeed:= 3;
    bot2:                  BotSpeed:= 2;
    bot3:                  BotSpeed:= 2.1;
    botBossCrossFire:      BotSpeed:= 1.9;
    botBossCarrier:        BotSpeed:= 1.5;
    botBossMiner:          BotSpeed:= 1.4;
    botmine:               BotSpeed:= 1.5;
    botfighter:            BotSpeed:= 2.5;
    botshielder:           BotSpeed:= 1.7;
    bothealer:             BotSpeed:= 1.8;
    botteleporter:         BotSpeed:= 1.9;
    heavybot:              BotSpeed:= 1.2;
    botautohealer:         BotSpeed:= 2.25;
    botDisabler:           BotSpeed:= 1.3;
  end;
  case botType of
    bot1:                  Mobility:=0.05;
    bot2:                  Mobility:=0.1;
    bot3:                  Mobility:=0.2;
    botBossCrossFire:      Mobility:=0.075;
    botBossCarrier:        Mobility:=0.03;
    botBossMiner:          Mobility:=0.04;
    botmine:               Mobility:=0.5;
    botfighter:            Mobility:=0.5;
    botshielder:           Mobility:=0.01;
    bothealer:             Mobility:=0.01;
    botteleporter:         Mobility:=0.5;
    heavybot:              Mobility:=0.06;
    botautohealer:         Mobility:=0.09;
    botDisabler:           Mobility:=0.01;
  end;
  case BotType of
    bot1:                  FireRate:= 1   /24/60/60;
    bot2:                  FireRate:= 0.7 /24/60/60;
    bot3:                  FireRate:= 0.5 /24/60/60;
    botBossCrossFire:      FireRate:= 0.02/24/60/60;
    botBossCarrier:        FireRate:= 1   /24/60/60;
    botBossMiner:          FireRate:= 1   /24/60/60;
    botmine:               FireRate:= -1;
    botfighter:            FireRate:= 0.3 /24/60/60;
    botshielder:           FireRate:= 2   /24/60/60;
    bothealer:             FireRate:= 2   /24/60/60;
    botteleporter:         FireRate:= 0.5 /24/60/60;
    heavybot:              FireRate:= 1.5 /24/60/60;
    botautohealer:         FireRate:= 0.6 /24/60/60;
    botDisabler:           FireRate:= 1.7 /24/60/60;
  end;
  FireRate:=FireRate/DifficultyLevel.EnemyFirePowerMultiplier;
  case BotType of
    botBossCarrier:        spawnRate:= 3   /24/60/60;
    botBossMiner:          spawnRate:= 1.1 /24/60/60;
    else                   spawnRate:=-1;
  end;
  spawnRate:=spawnRate/DifficultyLevel.EnemySpawnRateMultiplier;

  lastSpawnTime:=now;
  isHidden:=true;
  isMoving:=false;
  isShielded:=false;
  isHealing:=false;
  IAMDEAD:=false;
  isTeleporting:=0;

  LastActionTimer:=-1;
  lastFireTime:=now;
  vx:=0;vy:=0;
  hp:=maxHp;
  x:=start_x;
  y:=start_y;
  lastx:=round(x);
  lasty:=round(y);
  nextx:=lastx;
  nexty:=lasty;
end;

procedure TPlayerBot.ResetMe;
begin
  maxHp:=DifficultyLevel.PlayerHealth;
  BotSpeed:= 2;
  FireRate:= 0.03/24/60/60;{30 shots/sec}

  LastActionTimer:=-1;
  lastFireTime:=now;
  vx:=0;vy:=0;
  hp:=maxHp;
  x:=start_x;
  y:=start_y;
  lastx:=round(x);
  lasty:=round(y);
  nextx:=lastx;
  nexty:=lasty;
end;

procedure TBot.resetMe;
begin
 //why isn't it accessed through inherited???
end;

constructor THostileBot.create(ThisBotType:TBotType;mx:integer=-1;my:integer=-1);
var flg:boolean;
    tryx,tryy:integer;
    i:integer;
begin
  bottype:=ThisBotType;
  BornToBeABoss:=boss_none;
  if mx<0 then begin
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
      for i:=low(bots) to high(bots) do if (bots[i]<>nil) then
        if (bots[i].start_x=tryx) and (bots[i].start_y=tryy) then flg:=false;
     until flg;
   start_x:=tryx;
   start_y:=tryy;
  end else begin
    start_x:=mx;
    start_y:=my;
  end;
  ResetMe;
end;

constructor TPlayerBot.create(ThisBotType:TBotType;mx:integer=-1;my:integer=-1);
begin
 bottype:=ThisBotType;

 if mx<0 then begin
   if (ThisBotType=botplayer1) then begin
     start_x:=maxx div 2; if odd((start_x)) then start_x-=1;
     start_y:=maxy div 2; if odd((start_y)) then start_y-=1;
   end else
   if (ThisBotType=botplayer2) then begin
     start_x:=maxx div 2+2; if odd((start_x)) then start_x-=1;
     start_y:=maxy div 2+2; if odd((start_y)) then start_y-=1;
   end;
 end else begin
   start_x:=mx;
   start_y:=my;
 end;

 resetMe;
end;

constructor TBot.create(ThisBotType:TBotType;mx:integer=-1;my:integer=-1);
begin
 //why isn't it accessed through inherited???
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
  if (bottype<>botmine) and (bottype<>botfighter) then
  for i:=low(bots) to high(bots) do if (bots[i].hp>0) and (bots[i].bottype<>botFighter) and (bots[i].bottype<>botmine) and (bots[i].nextX=tryNextX) and (bots[i].nextY=tryNextY) then MoveAllowed:=false;
  //BUG - might overlap sometimes  on excessive back-forward manuvering
  //this fix does bad job, need to improve, maybe
//  for i:=low(bots) to high(bots) do if (bots[i].lastX=tryNextX) and (bots[i].lastY=tryNextY) then MoveAllowed:=false;
  //finally if move is allowed
  if MoveAllowed then begin
    if isHidden then (self as THostileBot).SayHi;
//    LastActionTimer:=now;
    isHidden:=false; {for enemy bots - if they can move they leave the cover}
    vx:=tryNewVX;
    vy:=tryNewVY;
    nextX:=tryNextX;
    nextY:=tryNextY;
    lastX:=tryLastX;
    lastY:=tryLastY;
  end;
end;

procedure THostileBot.doSpawn(spawn:TBotType);
begin
  if PauseMode then LastSpawnTime:=now+(now-LastSpawnTime);
//  if (x>=2) and (y>=2) and (x<=maxx-2) and (y<=maxy-2) then
  if (not odd(round(x))) and (not odd(round(y))) then
  if (now-LastSpawnTime)>=SpawnRate then begin
    LastSpawnTime:=now;
    setlength(bots,length(bots)+1);
    bots[length(bots)-1]:=THostileBot.create(spawn,round(x),round(y));
    bots[length(bots)-1].isHidden:=false;
  end;
end;

procedure THostileBot.SayHi;
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

procedure TPlayerBot.PlayerMove(dx,dy:shortint);
var playerControlsRef:^TPlayerControls;
begin
 if self.BotType=botplayer1 then playerControlsRef:=@playercontrols[0];
 if self.BotType=botplayer2 then playerControlsRef:=@playercontrols[1];
 playerControlsRef^.moveX:=dx;
 playerControlsRef^.moveY:=dy;
 playerControlsRef^.movePressed:=true;
end;

procedure TPlayerBot.DoPlayerMove;
var playerControlsRef:^TPlayerControls;
begin
 if self.BotType=botplayer1 then playerControlsRef:=@playercontrols[0];
 if self.BotType=botplayer2 then playerControlsRef:=@playercontrols[1];
 if playerControlsRef^.MovePressed then move(playerControlsRef^.moveX,playerControlsRef^.moveY);
end;


procedure TPlayerBot.PlayerFire(dx,dy:shortint);
var playerControlsRef:^TPlayerControls;
begin
 if self.BotType=botplayer1 then playerControlsRef:=@playercontrols[0];
 if self.BotType=botplayer2 then playerControlsRef:=@playercontrols[1];
 playerControlsRef^.FireX:=dx;
 playerControlsRef^.FireY:=dy;
 playerControlsRef^.FirePressed:=true;
end;

procedure TPlayerBot.DoPlayerFire;
var playerControlsRef:^TPlayerControls;
begin
 if self.BotType=botplayer1 then playerControlsRef:=@playercontrols[0];
 if self.BotType=botplayer2 then playerControlsRef:=@playercontrols[1];
 if playerControlsRef^.FirePressed then fire(playerControlsRef^.FireX,playerControlsRef^.FireY);
end;


function TBot.fire(dx,dy:shortint):boolean;
var FireAllowed:boolean;
begin
  if bottype=botmine then exit;
  FireAllowed:=true;
  if PauseMode then LastFireTime:=now+(now-lastFireTime);
  if (now-lastFireTime)>=FireRate then begin
    if (dx<>0) and ((vy<>0) and ((abs(round(y)-y)>0.3) or odd(round(y))) ) then FireAllowed:=false;
    if (dy<>0) and ((vx<>0) and ((abs(round(x)-x)>0.3) or odd(round(x))) ) then FireAllowed:=false;
    {bot specific tweaks}
    if (x<2) and (dx<>1) then FireAllowed:=false;
    if (y<2) and (dy<>1) then FireAllowed:=false;
    if (x>maxx-2) and (dx<>-1) then FireAllowed:=false;
    if (y>maxy-2) and (dy<>-1) then FireAllowed:=false;
    if FireAllowed then begin
      if (bottype=botplayer1) or (bottype=botplayer2) then
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
  Result:=FireAllowed;
end;

procedure THostileBot.EndMyLife;
var i:integer;
begin
  if bottype=bot1 then begin
    bottype:=bot2;
    ResetMe;
  end else
  if bottype=bot2 then begin
    bottype:=bot3;
    ResetMe;
  end else if (BornToBeABoss<>boss_none) then begin
    //todo: select boss based on BornToBeABoss
    case BornToBeABoss of
      boss_crossfire: bottype:=botBossCrossFire;
      boss_carrier: bottype:=botBossCarrier;
      boss_miner: bottype:=botBossMiner;
    end;
    ResetMe;
    bornToBeABoss:=boss_none;
  end;
  if bottype=botFIWI then begin
    for i:=low(bots) to high(bots) do if (bots[i].hp>0) and (bots[i] is THostileBot) then bots[i].hitMe(bots[i].maxhp);
  end;
  //if no reanimation - this is the end;
  if hp=0 then IAMDEAD:=true;
end;

procedure TBot.doDraw;
var thisscale:integer;
begin
  if hp>0 then begin
    botsImg[bottype].draw(GameScreenStartX+round(x*scale),GameScreenStartY+round(y*scale),scale,scale,0,0,128,128);
    if self is THostileBot then begin
      if (self as THostileBot).isShielded then
        ShieldImg[random(4)].draw(GameScreenStartX+round(x*scale),GameScreenStartY+round(y*scale),scale,scale,0,0,128,128);
      if (self as THostileBot).isHealing then
        HealImg[random(4)].draw(GameScreenStartX+round(x*scale),GameScreenStartY+round(y*scale),scale,scale,0,0,128,128);
      if (self as THostileBot).isTeleporting>0 then begin
        thisscale:=round(3*scale*abs(50-(self as THostileBot).isteleporting)/50);
        TeleportImg.draw(GameScreenStartX+round(x*scale-thisscale/2+scale/2),GameScreenStartY+round(y*scale-thisscale/2+scale/2),thisscale,thisscale,0,0,128,128);
      end;
    end else if self is TPlayerBot then begin
      if (self as TPlayerBot).isDisabled>0 then
        PlayerDisabledImg[random(4)].draw(GameScreenStartX+round(x*scale),GameScreenStartY+round(y*scale),scale,scale,0,0,128,128);
    end;
  end
  else if countdown>0 then begin
    dec(countdown);
    vx:=vx/1.01;
    vy:=vy/1.01;
    explosionImg[explosionType].draw(GameScreenStartX+round((x-1.5)*scale),GameScreenStartY+round((y-1.5)*scale),scale*4,scale*4,100*((100-countdown) mod 10),1024-100-100*((100-countdown) div 10),100,100);
    if (countdown=0) and (self is THostileBot) then (self as THostileBot).endMyLife;
  end;
end;

procedure TBot.hitme(damage:integer);
begin
  if self is TPlayerBot then begin
    if (self as TPlayerBot).isDisabled=0 then dec(hp,damage) else dec(hp,damage+1)
  end else if self is THostileBot then if not (self as THostileBot).isShielded then dec(hp,damage);

  if hp<=0 then begin
    hp:=0;
    SoundEngine.PlaySound(sndExplosion, false, false, 2, 1, 0, 1, ZeroVector3Single);
    if (damage>5) and ((bottype=botplayer1) or (bottype=botplayer2)) then SoundEngine.PlaySound(sndPlayerHitHard, false, false, 3, 1, 0, 1, ZeroVector3Single);
    countdown:=100;
    //prepare explosion
    case bottype of
      botplayer1,botplayer2,botBossCrossFire,botBossCarrier,botBossMiner: explosionType:=5+round(random);
      botFIWI: explosionType:=6;
      botfighter: explosionType:=1;
      bot1: explosionType:=1+round(random*4);
      bot2,bot3,botshielder,heavybot,botautohealer,bothealer,botteleporter,botmine,botDisabler: explosionType:=2+random(5);
    end;
  end else begin
    if (bottype=botplayer1) or (bottype=botplayer2) then begin
      SoundEngine.PlaySound(sndPlayerHit[Random(6)+1], false, false, 1, 0.5, 0, 1, ZeroVector3Single);
      if damage>5 then SoundEngine.PlaySound(sndPlayerHitHard, false, false, 3, 1, 0, 1, ZeroVector3Single)
    end else
      SoundEngine.PlaySound(sndBotHit[Random(9)+1], false, false, 0, 0.4, 0, 1, ZeroVector3Single)
  end;
end;

procedure TBot.doMove;
var newx,newy:float;
    currentSpeed:float;
begin
if lastActionTimer=-1 then LastActionTimer:=now;
  currentSpeed:=botSpeed;
  if self is TPlayerBot then if (self as TPlayerBot).isDisabled>0 then currentSpeed/=2;
  newx:=x+vx*currentSpeed*(now-LastActionTimer)*60*60*24;
  newy:=y+vy*currentSpeed*(now-LastActionTimer)*60*60*24;
  LastActionTimer:=now;

if not PauseMode then begin
 if (vx<>0) or (vy<>0) then begin
   isMoving:=true;
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
end;

{------------------------------------------------------------------------------------}

function THostileBot.GetPlayerTarget:TPlayerBot;
var foe1closer,foe2closer,foe1direct,foe2direct:boolean;
    foe_target1,foe_target2,foe_closer_target,foe_final_target:integer;
    this_r,min_r:float;
    i:integer;
begin
{find both players and find a closer player}
min_r:=9999999999;
foe_closer_target:=-10; foe_target1:=-10; foe_target2:=-10;
for i:=low(bots)to high(bots) do if (bots[i].hp>0) and (bots[i] is TPlayerBot) then begin
  this_R:=sqr(x-bots[i].x)+sqr(y-bots[i].y);
  if foe_target1<0 then foe_target1:=i else foe_target2:=i;
  if min_r>this_r then begin
    min_r:=this_r;
    foe_closer_target:=i;
  end;
end;
{now define the current target}
if foe_closer_target>=0 then begin
  if foe_target1=foe_closer_target then foe1closer:=true else foe1closer:=false;
  if foe_target2=foe_closer_target then foe2closer:=true else foe2closer:=false;
  foe1direct:=false;
  if foe_target1>=0 then
    if (abs(x-bots[foe_target1].x)<1) or (abs(y-bots[foe_target1].y)<1) then foe1direct:=true;
  foe2direct:=false;
  if foe_target2>=0 then
    if (abs(x-bots[foe_target2].x)<1) or (abs(y-bots[foe_target2].y)<1) then foe2direct:=true;
  //first check obvious - if target is closer and direct fire possible, choose it
  if foe1closer and foe1direct then foe_final_target:=foe_target1 else
  if foe2closer and foe2direct then foe_final_target:=foe_target2 else
  //else check any target capable of direct fire;
  if foe1direct then foe_final_target:=foe_target1 else
  if foe2direct then foe_final_target:=foe_target2 else
  //and if everything else fails just assign a closer target
                     foe_final_target:=foe_closer_target;
  //and "bake" this decision as current foe
  result:=bots[foe_final_target] as TPlayerBot;
end else result:=bots[0] as TPlayerBot;  //to be SIGSEGV-safe let's define something even if nothing is found. And yes, I'm cheating. I know bots[0] is always a TPlayerBot;

end;

procedure THostileBot.doTeleport(OnlyInnerCore:boolean=false);
var teleportallowed:boolean;
    i:integer;
    tryx,tryy:integer;
begin
  repeat
    teleportallowed:=true;
    if onlyInnerCore then begin
      tryx:=round(random*(maxx-8)/2)*2+4;
      tryy:=round(random*(maxy-8)/2)*2+4;
    end else begin
      tryx:=round(random*(maxx)/2)*2;
      tryy:=round(random*(maxy)/2)*2;
    end;
    if (tryx=0) and (tryy=0) then teleportallowed:=false;
    if (tryx=maxx) and (tryy=0) then teleportallowed:=false;
    if (tryx=0) and (tryy=maxy) then teleportallowed:=false;
    if (tryx=maxx) and (tryy=maxy) then teleportallowed:=false;
    for i:=low(bots) to high(bots) do if (bots[i].hp>0) and (bots[i].BotType<>botmine) and (bots[i].bottype<>botfighter) then
     if ((bots[i].nextx=tryx) and (bots[i].nexty=tryy)) or ((bots[i].lastx=tryx) and (bots[i].lasty=tryy)) then teleportallowed:=false;
  until (teleportallowed) or (random<0.01);
  if teleportallowed then begin
    if hp<maxHp-4 then inc(hp,5);
    ismoving:=false;
    vx:=0;vy:=0;
    nextx:=tryx;nexty:=tryy;
    lastx:=tryx;lasty:=tryy;
    x:=tryx;y:=tryy;
  end;
end;

procedure THostileBot.doAI;
const ColumnFireScale=1.7;
var dx,dy:shortint;
    fireAndForget:boolean;
    i:integer;
    ExitHideoutProbability:float;
    this_R,min_R:float;
    shieldertarget,healertarget:integer;
    friend:THostileBot;
    foe:TPlayerBot;
begin
 foe:=GetPlayerTarget;

 if bottype<>botmine then begin
  if isHidden then begin
    //try leave the cover
    If activebots=0 then ExitHideoutProbability:=0.5 else
    If (DifficultyLevel.simultaneous_active>activebots) then ExitHideoutProbability:=frameskip/60/(enemiesalive+1) else
      ExitHideoutProbability:=frameskip/60/(enemiesalive+1)*1e-2;
    if (BornToBeABoss<>boss_none) or (bottype=botshielder) or (bottype=bothealer) or (bottype=botDisabler) then ExitHideoutProbability/=1.1;
    if (bottype=botShielder) and (ShielderPresent) then ExitHideoutProbability/=2;
    if (bottype=botHealer) and (HealerPresent) then ExitHideoutProbability/=2;
    if random<ExitHideoutProbability then begin
      dx:=0;dy:=0;
      if (x=0) or (x=maxx) then dy:=round((random-0.5)*2);
      if (y=0) or (y=maxy) then dx:=round((random-0.5)*2);
      if (dx<>0) or (dy<>0) then move(dx,dy);
      inc(activebots)
    end;
  end else begin
    if (bottype<>botshielder) and (bottype<>bothealer) and (bottype<>botbossminer) and (bottype<>botbosscarrier) then {these have different movement logic}
    case random(4) of
      0: if not isMoving and (random<Mobility) then move(0,+1);
      1: if not isMoving and (random<Mobility) then move(0,-1);
      2: if not isMoving and (random<Mobility) then move(+1,0);
      3: if not isMoving and (random<Mobility) then move(-1,0);
    end;
    if (foe.hp>0) and (bottype<>botmine) then
      begin
        FireAndForget:=false; //demand a fire if possible to max out possible FireRate
        repeat
          case random(4) of
            0: if (foe.y-y>ColumnFireScale) then if fire(0,+1) then FireAndForget:=true;
            1: if (foe.y-y<-ColumnFireScale) then if fire(0,-1) then FireAndForget:=true;
            2: if (foe.x-x>ColumnFireScale) then if fire(+1,0) then FireAndForget:=true;
            3: if (foe.x-x<-ColumnFireScale) then if fire(-1,0) then FireAndForget:=true;
          end;
          if (random<0.1) and (not FireAndForget) then begin
           //to be freeze-safe
           case random(4) of
             0: if (foe.y-y>0) then if fire(0,+1) then FireAndForget:=true;
             1: if (foe.y-y<-0) then if fire(0,-1) then FireAndForget:=true;
             2: if (foe.x-x>0) then if fire(+1,0) then FireAndForget:=true;
             3: if (foe.x-x<-0) then if fire(-1,0) then FireAndForget:=true;
           end;
           if (x=0) or (x=maxx) or (y=0) or (y=maxy) then FireAndForget:=true;
           if (random<0.1) and (not FireAndForget) then begin
            //to be veeery freeze-safe
            case random(4) of
              0: if fire(0,+1) then FireAndForget:=true;
              1: if fire(0,-1) then FireAndForget:=true;
              2: if fire(+1,0) then FireAndForget:=true;
              3: if fire(-1,0) then FireAndForget:=true;
            end;
           end;
          end;
        Until FireAndForget;
      end;
    if foe.hp>0 then begin
     if bottype=botBossCarrier then dospawn(botfighter);
     if bottype=botBossMiner then dospawn(botmine);
     if ((bottype=botBossMiner) or (bottype=botBossCarrier)) and not isMoving then begin
       //run away from player
       dx:=sgn(x-foe.x);
       dy:=sgn(y-foe.y);
       //not to make i completely invulnerable let's add 40% chance of random movement
       if random<0.1 then move( 0,+1);
       if random<0.1 then move( 0,-1);
       if random<0.1 then move(+1, 0);
       if random<0.1 then move(-1, 0);
       if (dx<>0) and (dy<>0) then begin
         if random<0.5 then move(dx,0) else move(0,dy);
       end else
       if dx=0 then begin
          if random<0.5 then dx:=1 else dx:=-1;
          move(dx,0);
       end else
       if dy=0 then begin
          if random<0.5 then dy:=1 else dy:=-1;
          move(0,dy);
       end;
       //but still move out from initial position
       if x<2 then move(1,0);
       if y<2 then move(0,1);
       if x>maxx-2 then move(-1,0);
       if y>maxy-2 then move(0,-1);
     end;
     if (bottype=botautohealer) and (hp<maxhp) then begin
       isHealing:=true;
       if random<3*frameskip/60*DifficultyLevel.EnemyHealingMultiplier then inc(hp);
     end;
     if (bottype=botTeleporter) then begin
       if isteleporting=0 then begin
         if (random<frameskip/60/3) then isteleporting:=100;
       end else begin
         if isteleporting=50 then doTeleport;

       end;
     end;
     if (bottype=botShielder) or (bottype=botHealer) then begin
        min_R:=99999999;shieldertarget:=-10;
        for i:=low(bots) to high(bots) do if (bots[i].hp>0) and (not bots[i].isHidden) and (bots[i].bottype<>bottype) and (bots[i].bottype<>botmine) and (bots[i].bottype<>botfighter) and (bots[i].bottype<>botFIWI) and (bots[i] is THostileBot) then begin
         friend:=bots[i] as THostileBot;
         this_R:=sqr(x-friend.x)+sqr(y-friend.y);
         if (min_R>this_R) and (friend.x>0) and (friend.y>0) and (friend.x<maxx) and (friend.y<maxy) then begin
           min_R:=this_R;
           shieldertarget:=i;
         end;
         if this_R<8.9*DifficultyLevel.EnemyRangeMultiplier then begin
           if bottype=botShielder then friend.IsShielded:=true else
           if (bottype=botHealer) and (friend.hp<friend.maxHp) then begin
             friend.isHealing:=true;
             if random<5*frameskip/60*DifficultyLevel.EnemyHealingMultiplier then inc(friend.hp);
           end;
         end;
        end;
        if bottype=bothealer then begin
          min_R:=99999999;HealerTarget:=-10;
          for i:=low(bots) to high(bots) do if (bots[i].hp>0) and (bots[i].hp<bots[i].MaxHp) and (not bots[i].isHidden) and (bots[i].bottype<>bottype) and (bots[i].bottype<>botmine) and (bots[i].bottype<>botfighter) and not hostile(bots[i].bottype,bottype) then begin
           this_R:=sqr(x-bots[i].x)+sqr(y-bots[i].y);
           if (min_R>this_R) and (bots[i].x>0) and (bots[i].y>0) and (bots[i].x<maxx) and (bots[i].y<maxy) then begin
             min_R:=this_R;
             healerTarget:=i;
           end;
          end;
          if HealerTarget>=0 then shielderTarget:=HealerTarget;
        end;

        if shieldertarget>=0 then begin
          dx:=sgn(bots[shieldertarget].x-x);
          dy:=sgn(bots[shieldertarget].y-y);
          if dy=0 then move(dx,0) else
          if dx=0 then move(0,dy) else begin
            if random<0.5 then move(dx,0) else move(0,dy);
          end;
        end;
        if x<2 then move(1,0);
        if y<2 then move(0,1);
        if x>maxx-2 then move(-1,0);
        if y>maxy-2 then move(0,-1);
     end; {shielder}
    end;
  end;
 end else if {(bottype=botmine) and} (hp>0) then begin
   //homing at player;
  if foe.hp>0 then begin
   dx:=sgn(foe.x-x);
   dy:=sgn(foe.y-y);
   if dx=0 then move(0,dy) else
   if dy=0 then move(dx,0) else begin
     if random<0.5 then move(dx,0) else move(0,dy);
   end;
{   if abs(x-foe.x)<=abs(y-foe.y) then move(0,sgn(foe.y-y)) else move(sgn(foe.x-x),0);}
{   if x=foe.x then move(0,sgn(foe.y-y));
   if y=foe.y then move(sgn(foe.x-x),0);}
   if x<2 then move(1,0);
   if y<2 then move(0,1);
   if x>maxx-2 then move(-1,0);
   if y>maxy-2 then move(0,-1);
   //check collision
   for i:=low(bots) to high(bots) do if bots[i].hp>0 then
    if (abs(x-bots[i].x)<1) and (abs(y-bots[i].y)<1) then
       if hostile(bots[i].bottype,botmine) then begin
         bots[i].hitme(40);
         hitme(maxHp);
       end;
  end;
 end;
 if bottype=botShielder then
  for i:=low(bots) to high(bots) do if (bots[i].hp>0) and (bots[i].bottype<>botshielder) and (bots[i].bottype<>botmine) and (bots[i].bottype<>botfighter) then
   if (sqr(x-bots[i].x)+sqr(y-bots[i].y)<6) and ((bots[i].x=0) or (bots[i].y=0) or (bots[i].x=maxx) or (bots[i].y=maxy))then
    if bots[i] is THostileBot then (bots[i] as THostileBot).IsShielded:=true;


end;

end.

