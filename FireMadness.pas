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

program FireMadness;

{$Apptype GUI}

uses  {$IFDEF UNIX}cthreads,{$ENDIF}Classes, SysUtils,
  castle_window, CastleWindow, castle_base,
  CastleGLImages,
  CastleKeysMouse,
  firemadnesscontrols, general_var, Sound_Music, botsdata,
  map_manager;


type game_context_type=(gameplay_title,gameplay_play);

{---------------------------}

var Window:TCastleWindow;
  startNewGame:boolean;
  firstrender:boolean;
  Current_game_context:game_context_type=gameplay_title;
  //images
  wall,pass: TGLimage;
  healthbar,emptybar:TGlImage;

  //GUI
  label1:TGLIMage;
  TitleReady:boolean;

{$R+}{$Q+}

{------------------------------------------------------------------------------------}
{====================================================================================}
{------------------------------------------------------------------------------------}

procedure StartGame(MapIt:TMapType);
begin
  map:=MapIt;
  Current_Game_context:=gameplay_play;
  startNewGame:=true;
end;

procedure MenuKeyPress(Container: TUIContainer; const Event: TInputPressRelease);
begin
  case event.key of
    k_1:StartGame(map_bedRoom);
    k_2:StartGame(map_LivingRoom);
    k_3:StartGame(map_cellar);
    k_4:StartGame(map_kitchen);
    k_5:StartGame(map_FiWi);
    k_6:StartGame(map_test);
    k_f1: begin
            if Player2Active then begin
              DifficultyLevel.EnemyFirePowerMultiplier/=hotSeatDifficultyMultiplier;
              DifficultyLevel.EnemyHealthMultiplier/=2;
              DifficultyLevel.EnemySpawnRateMultiplier/=hotSeatDifficultyMultiplier;
              DifficultyLevel.simultaneous_active-=1;
            end;
            Player2Active:=false;
            PlayerControls[0].makeControls(controls_cursor,controls_WASD);
          end;
    k_f2: begin
            if not Player2Active then begin
              DifficultyLevel.EnemyFirePowerMultiplier*=hotSeatDifficultyMultiplier;
              DifficultyLevel.EnemyHealthMultiplier*=2;
              DifficultyLevel.EnemySpawnRateMultiplier*=hotSeatDifficultyMultiplier;
              DifficultyLevel.simultaneous_active+=1;
            end;
            Player2Active:=true;
            PlayerControls[0].makeControls(controls_numbers,controls_cursor);
            PlayerControls[1].makeControls(controls_TFGH,controls_WASD);
          end;
    k_f5:difficultyLevel:=Singleplayer_easy;
    k_f6:difficultyLevel:=Singleplayer_normal;
    k_f7:difficultyLevel:=Singleplayer_hard;
    k_f8:difficultyLevel:=Singleplayer_insane;
  end;


end;

procedure MakeTitleScreen;
begin
  label1:=TGLImage.Create(TitlescreenFolder+'FireMadness.jpg',false);
  TitleReady:=false;
end;

procedure ShowTitle;
begin
  music_context:=music_easy;
  doStartFadeOut;
  Label1.Draw(0,0);
  TitleReady:=true;
end;

procedure hideTitle;
begin
  //Window.Controls.remove(label1);
  TitleReady:=false;
end;

{------------------------------------------------------------------------------------}
{====================================================================================}
{------------------------------------------------------------------------------------}

procedure GameKeyPress(Container: TUIContainer; const Event: TInputPressRelease);
var dx,dy:float;
    PlayerBot:TPlayerBot;
    i:integer;
begin
 PauseMode:=false;
 if event.key=K_Pause then pauseMode:=not PauseMode;
 if event.key=K_f10 then begin Current_game_context:=gameplay_title; window.OnPress:=@MenuKeyPress; window.OnRelease:=nil end;
 for i:=0 to nplayers-1 do begin
   PlayerBot:=bots[i] as TPlayerBot;
   if not firstrender then begin
  {  mouseFire:=false;}
    if PlayerBot.hp>0 then with PlayerControls[i] do begin
      if event.key=MoveKeys.up then    begin PlayerBot.PlayerMove(0,+1); lastMoveKeyPress:=Event.Key; end;
      if event.key=MoveKeys.down then  begin PlayerBot.PlayerMove(0,-1); lastMoveKeyPress:=Event.Key; end;
      if event.key=MoveKeys.right then begin PlayerBot.PlayerMove(+1,0); lastMoveKeyPress:=Event.Key; end;
      if event.key=MoveKeys.left then  begin PlayerBot.PlayerMove(-1,0); lastMoveKeyPress:=Event.Key; end;
      if event.key=FireKeys.up then    begin PlayerBot.PlayerFire(0,+1); lastFireKeyPress:=Event.Key; end;
      if event.key=FireKeys.down then  begin PlayerBot.PlayerFire(0,-1); lastFireKeyPress:=Event.Key; end;
      if event.key=FireKeys.right then begin PlayerBot.PlayerFire(+1,0); lastFireKeyPress:=Event.Key; end;
      if event.key=FireKeys.left then  begin PlayerBot.PlayerFire(-1,0); lastFireKeyPress:=Event.Key; end;
      if event.key=k_f5 then doStartFadeOut;
    {  if event.key=K_None then
        if event.MouseButton=mbLeft then begin
            if (Event.Position[0]>GameScreenStartX) and (Event.Position[0]<GameScreenEndX) then begin
              //do game
      {        mousefire:=true;}
              dx:=(Event.Position[0]-GameScreenStartX)-(PlayerBot.x+0.5)*scale;
              dy:=(Event.Position[1])-(PlayerBot.y+0.5)*scale;
              if abs(dx)>abs(dy) then begin
                if (dx<0) then PlayerBot.Move(-1,0) else PlayerBot.Move(+1,0);
              end else begin
                if (dy<0) then PlayerBot.Move(0,-1) else PlayerBot.Move(0,+1);
              end;
            end else begin
              //do side menu
            end;
        end; {mouse @key_none}}

    end;
   end;
 end;{for i 0 to nplayers}
end;

procedure GameKeyRelease(Container: TUIContainer; const Event: TInputPressRelease);
var playerBot:TPlayerBot;
    i:integer;
begin
 for i:=0 to nplayers-1 do begin
   PlayerBot:=bots[i] as TPlayerBot;
   if PlayerBot.hp>0 then with PlayerControls[i] do begin
     if (Event.Key=moveKeys.up) or(Event.Key=moveKeys.down) or (Event.Key=moveKeys.left) or (Event.Key=moveKeys.right) then
        if event.key=lastMoveKeyPress then MovePressed:=false;
     if (Event.Key=FireKeys.up) or(Event.Key=FireKeys.down) or (Event.Key=FireKeys.left) or (Event.Key=FireKeys.right) then
        if event.Key=LastFireKeyPress then FirePressed:=false;
   end;
 end;
end;

{procedure GameKeyMotion(Container: TUIContainer; const Event: TInputMotion);
var dx,dy:float;
begin
 if mousefire then begin
   dx:=(Event.Position[0]-GameScreenStartX)-(PlayerBot.x-0.5)*scale;
   dy:=(Event.Position[1])-(PlayerBot.y-0.5)*scale;
   if abs(dx)>abs(dy) then begin
     if (dx<0) then PlayerBot.PlayerFire(-1,0) else PlayerBot.PlayerFire(+1,0);
   end else begin
     if (dy<0) then PlayerBot.PlayerFire(0,-1) else PlayerBot.PlayerFire(0,+1);
   end;

 end;
end;            }



{------------------------------------------------------------------------------------}
{====================================================================================}
{------------------------------------------------------------------------------------}

procedure doStartGame;
var i:integer;
    bosses:integer;
    b_shielder,b_heavy,b_healer,b_Teleporter,b_autohealer,b_disabler:integer;
    MapSpanX,MapSpanY,gameAreaWidth,gameAreaHeight:integer;
    tryInverseScale,tmp:integer;

    TileSelect:integer;
begin
  if isMusicPlaying and not isMusicFading then doStartFadeOut;
  hideTitle;

  if wall<>nil then freeandnil(wall);
  if map.WallTile<0 then TileSelect:=random(5) else TileSelect:=map.WallTile;
  case TileSelect of
    0:Wall:=TGLImage.create(MapFolder+'walls'+pathdelim+'Pattern_002_CC0_by_Nobiax_diffuse.png',true);
    1:Wall:=TGLImage.create(MapFolder+'walls'+pathdelim+'Pattern_003_CC0_by_Nobiax_diffuse.png',true);
    2:Wall:=TGLImage.create(MapFolder+'walls'+pathdelim+'Pattern_015_CC0_by_Nobiax_specular.png',true);
    3:Wall:=TGLImage.create(MapFolder+'walls'+pathdelim+'Pattern_026_CC0_by_Nobiax_specular.png',true);
    4:Wall:=TGLImage.create(MapFolder+'walls'+pathdelim+'Pattern_144_CC0_by_Nobiax_diffuse.png',true);
  end;

  if pass<>nil then freeandnil(pass);
  if map.FloorTile<0 then TileSelect:=random(13) else TileSelect:=map.FloorTile;
  case TileSelect of
    0:Pass:=TGLImage.create(MapFolder+'floors'+pathdelim+'Pattern_009_CC0_by_Nobiax_specular.png',true);
    1:Pass:=TGLImage.create(MapFolder+'floors'+pathdelim+'Pattern_023_CC0_by_Nobiax_diffuse.png',true);
    2:Pass:=TGLImage.create(MapFolder+'floors'+pathdelim+'Pattern_024_CC0_by_Nobiax_specular.png',true);
    3:Pass:=TGLImage.create(MapFolder+'floors'+pathdelim+'Pattern_027_CC0_by_Nobiax_specular.png',true);
    4:Pass:=TGLImage.create(MapFolder+'floors'+pathdelim+'Pattern_033_CC0_by_Nobiax_specular.png',true);
    5:Pass:=TGLImage.create(MapFolder+'floors'+pathdelim+'Pattern_037_CC0_by_Nobiax_specular.png',true);
    6:Pass:=TGLImage.create(MapFolder+'floors'+pathdelim+'Pattern_039_CC0_by_Nobiax_specular.png',true);
    7:Pass:=TGLImage.create(MapFolder+'floors'+pathdelim+'Pattern_040_CC0_by_Nobiax_specular.png',true);
    8:Pass:=TGLImage.create(MapFolder+'floors'+pathdelim+'Pattern_040_CC0_by_Nobiax_specular_full.png',true);
    9:Pass:=TGLImage.create(MapFolder+'floors'+pathdelim+'Pattern_041_CC0_by_Nobiax_specular.png',true);
   10:Pass:=TGLImage.create(MapFolder+'floors'+pathdelim+'Pattern_241_CC0_by_Nobiax_diffuse.png',true);
   11:Pass:=TGLImage.create(MapFolder+'floors'+pathdelim+'Pattern_244_CC0_by_Nobiax_diffuse.png',true);
   12:Pass:=TGLImage.create(MapFolder+'floors'+pathdelim+'Pattern_274_CC0_by_Nobiax_specular.png',true);
  end;

  maxx:=map.maxX;
  maxY:=map.MaxY;
  GameAreaWidth:=window.width;
  GameAreaHeight:=window.height-32;
  if GameAreaWidth/(maxx+1) < GameAreaHeight/(maxy+1) then scale := GameAreaWidth div (maxx+1) else scale:= GameAreaHeight div (maxy+1);
  if GameAreaWidth/(maxy+1) < GameAreaHeight/(maxx+1) then tryInverseScale := GameAreaWidth div (maxy+1) else tryInverseScale:= GameAreaHeight div (maxx+1);
  if tryInverseScale>scale then begin
    scale:=tryInverseScale;
    tmp:=maxX;maxX:=maxY;MaxY:=tmp;
  end;
  mapSpanX:=(maxx+1)*scale;
  mapSpanY:=(maxy+1)*scale;
  GameScreenStartX:=(GameAreaWidth-mapSpanX) div 2;
  GameScreenEndX:=GameScreenStartX+(maxx+1)*scale;
  GameScreenStartY:=(GameAreaHeight-mapSpanY) div 2;
  GameScreenEndY:=GameScreenStartY+(maxy+1)*scale;

  randomize;
  old_music_context:=music_context;
  nmissles:=0;
  setlength(missles,nmissles);

  setlength(bots,1);
  bots[0]:=TPlayerBot.create(botplayer1);
  if Player2Active then begin
    setlength(bots,2);
    bots[1]:=TPlayerBot.create(botplayer2);
    nplayers:=2;
  end else nplayers:=1;

  nenemies:=map.nenemies;
  if nenemies>0 then begin
    setlength(bots,nenemies+nplayers);

    b_heavy:=map.bots_heavy;
    b_shielder:=map.bots_shielder;
    b_healer:=map.bots_healer;
    b_Teleporter:=map.bots_Teleporter;
    b_autohealer:=map.bots_autohealer;
    b_disabler:=map.bots_disabler;
    for i:=high(bots) downto low(bots)+nplayers do begin
      if b_heavy>0      then begin bots[i]:=THostileBot.create(heavyBot);      dec(b_heavy) end else
      if b_shielder>0   then begin bots[i]:=THostileBot.create(botShielder);   dec(b_shielder) end else
      if b_healer>0     then begin bots[i]:=THostileBot.create(botHealer);     dec(b_healer) end else
      if b_Teleporter>0 then begin bots[i]:=THostileBot.create(botTeleporter); dec(b_Teleporter) end else
      if b_autohealer>0 then begin bots[i]:=THostileBot.create(botAutoHealer); dec(b_autohealer) end else
      if b_disabler>0   then begin bots[i]:=THostileBot.create(botDisabler);   dec(b_disabler) end else
                                   bots[i]:=THostileBot.create(bot1);
    end;
    bosses:=map.Crossfire_Bosses;
    if bosses>0 then
    repeat
      i:=nplayers+random(nenemies-nplayers);
      if (bots[i] as THostileBot).BornToBeABoss=boss_none then begin
        (bots[i] as THostileBot).BornToBeABoss:=boss_crossfire;
        dec(bosses);
      end;
    until bosses=0;
    bosses:=map.Carrier_bosses;
    if bosses>0 then
    repeat
      i:=nplayers+random(nenemies-nplayers);
      if (bots[i] as THostileBot).BornToBeABoss=boss_none then begin
        (bots[i] as THostileBot).BornToBeABoss:=boss_carrier;
        dec(bosses);
      end;
    until bosses=0;
    bosses:=map.Miner_bosses;
    if bosses>0 then
    repeat
      i:=nplayers+random(nenemies-nplayers);
      if (bots[i] as THostileBot).BornToBeABoss=boss_none then begin
        (bots[i] as THostileBot).BornToBeABoss:=boss_miner;
        dec(bosses);
      end;
    until bosses=0;
  end;
  //FIWI
  if map.fiwi then begin
    setlength(bots,length(bots)+1);
    bots[length(bots)-1]:=TFIWI.create(6,6);
  end;
  startNewGame:=false;
  window.OnPress:=@GameKeyPress;
  window.onRelease:=@GameKeyRelease;
  //window.OnMotion:=@GameKeyMotion;
end;

{------------------------------------------------------------------------------------}

procedure doLoadGameData;
begin
  MakeTitleScreen;
  //load TGLImages
  doLoadImages;

  EmptyBar:=TGLImage.create(GuiFolder+'SleekBars_CC0_by_Jannax(opengameart)_empty.png');
  HealthBar:=TGLImage.create(GuiFolder+'SleekBars_CC0_by_Jannax(opengameart)_full.png');

  //load sounds as TSoundBuffer
  doLoadSound;
  StartNewGame:=true;
  //and launch music
  oldMusic:=-1;
  MyVoiceTimer:=now;
  MyMusicTimer:=now+1/60/60/24;
  Music_duration:=0;  {a few seconds of silence}
end;

{------------------------------------------------------------------------------------}

procedure DoDrawMap;
var ix,iy:integer;
begin
for ix:=0 to maxx do
 for iy:=0 to maxy do if odd(ix) and odd(iy) then begin
     //draw wall
     wall.Draw(GameScreenStartX+ix*scale,GameScreenStartY+iy*scale,scale,scale,0,0,128,128);
   end else begin
     //draw pass
     pass.Draw(GameScreenStartX+ix*scale,GameScreenStartY+iy*scale,scale,scale,0,0,128,128);
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
    PlayerBot:TPlayerBot;
begin
  PlayerBot:=bots[0] as TPlayerBot;
  medianW:=round((GameScreenEndX-GameScreenStartX)*PlayerBot.hp / PlayerBot.maxHp);
  median128:=round(118*PlayerBot.hp / PlayerBot.maxHp);
  HealthBar.Draw(GameScreenStartX+0,window.height-32,medianW,32,0,0,median128,32);
  emptyBar.Draw(GameScreenStartX+medianW,window.height-32,(GameScreenEndX-GameScreenStartX)-medianW,32,median128,0,118,32);
end;

procedure doDisplayImages;
begin
  doDrawMap;
  doDrawBots;
  doDrawInterface;
end;

const music_averaging=100;
procedure doGame;
var i,nm:integer;
    enemyPower:integer;
begin
  for i:=low(bots) to high(bots) do if (bots[i] is TPlayerBot) and (bots[i].hp>0) then begin
    if (bots[i] as TPlayerBot).isDisabled>0 then
      dec((bots[i] as TPlayerBot).isDisabled)
    else
      (bots[i] as TPlayerBot).DoPlayerFire;

    (bots[i] as TPlayerBot).DoPlayerMove;
  end;

  activebots:=0;enemiesalive:=0;enemyPower:=0;
  shielderPresent:=false;HealerPresent:=false;
  for i:=low(bots) to high(bots) do if (bots[i].hp>0) and (bots[i] is THostileBot) then if (bots[i].bottype<>botFighter) and (bots[i].bottype<>botMine) then begin
    inc(enemiesalive);
    if not bots[i].isHidden then begin
      if (bots[i].bottype<>botShielder) and (bots[i].bottype<>botHealer) and (bots[i].bottype<>botDisabler) and (bots[i].bottype<>botFIWI) then inc(activebots);
      if bots[i].bottype=botShielder then ShielderPresent:=true;
      if bots[i].bottype=botHealer then HealerPresent:=true;
      case bots[i].botType of
        bot1:inc(EnemyPower);
        bot2,botshielder,bothealer:inc(enemyPower,2);
        bot3,botteleporter,botDisabler:inc(enemyPower,4);
        HeavyBot,botautohealer:inc(enemyPower,5);
        BotBossCrossFire,botBossCarrier,botBossMiner,botFIWI:inc(enemyPower,100);
        //botfighter,botmine
      end;
    end;
  end;
  averageEnemyPower:=(AverageEnemyPower*music_averaging+EnemyPower)/(music_averaging+1);   //~averaged by 3 seconds
  case round(AverageEnemyPower) of
    -1..5:music_context:=music_easy;
    6..10:music_context:=music_mid;
    else music_context:=music_hard;
  end;
  if EnemyPower>99 then music_context:=music_boss;

  //if situation changed significantly, reload music based on current context
  if not isMusicFading then begin
    if (music_context=music_easy) and (old_music_context=music_hard) then doStartFadeOut;
    if (music_context=music_hard) and (old_music_context=music_easy) then doStartFadeOut;
    if (old_music_context<>music_hard) and (old_music_context<>music_boss) and (averageEnemyPower>25) then doStartFadeOut;
    if (old_music_context=music_boss) and (music_context<>music_boss) then doStartFadeOut;
    if (music_context=music_boss) and (old_music_context<>music_boss) then doStartFadeOut;
  end;

  if not pauseMode then begin
    //dispose of dead bots (especially fighters and mines)
    nm:=-1;
    for i:=low(bots) to high(bots) do if bots[i] is THostileBot then begin
      if (not (bots[i] as THostileBot).IAMDEAD) then begin
        inc(nm);
        if nm<>i then bots[nm]:=bots[i];
      end else begin
        freeandnil(bots[i]);
      end;
    end else inc(nm);
    if nm+1<>length(bots) then begin
      setlength(bots,nm+1);
    end;

    // do enemy AI
    for i:=low(bots) to high(bots) do if (bots[i].hp>0) and (bots[i] is THostileBot) then begin
      (bots[i] as THostileBot).isShielded:=false;
      (bots[i] as THostileBot).isHealing:=false;
       if (bots[i] as THostileBot).isteleporting>0 then dec((bots[i] as THostileBot).isteleporting);
    end;
    for i:=low(bots) to high(bots) do if (bots[i].hp>0) and (bots[i] is THostileBot) then begin
      if bots[i] is TFIWI then (bots[i] as TFIWI).FIWI_AI else (bots[i] as THostileBot).doAI;
    end;
  end;

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
  if current_game_context = gameplay_play then begin
    if startNewGame then doStartGame;

    if not RenderingBuisy then begin
      frameskip:=1;
      RenderingBuisy:=true;
      doGame;

      doDisplayImages;

      RenderingBuisy:=false;
    end else inc(frameskip);
  end else if current_game_context = gameplay_title then begin
    if not TitleReady then ShowTitle;
    Label1.Draw(0,0);
  end;
  firstrender:=false;
end;

procedure doTimer;
begin
  window.DoRender;
  if (Now>MyMusicTimer{(Now-MyMusicTimer)*60*60*24>Music_duration+1}) then doLoadMusic;
  if MusicReady then begin
    doPlayMusic;
    MusicReady:=false;
  end;
  if isMusicFading and isMusicPlaying then doFadeOut;

end;

{------------------------------------------------------------------------------------}
{====================================================================================}
{------------------------------------------------------------------------------------}

begin
firstrender:=true;
music_context:=music_easy;
Window:=TCastleWindow.create(Application);
window.DoubleBuffer:=true;
window.OnRender:=@doRender;

window.OnPress:=@MenuKeyPress;
window.onRelease:=nil;
window.OnMotion:=nil;

map:=map_bedRoom;

window.Width:=800{(maxx+1)*scale};
window.height:=600{(maxy+1)*scale+32};

difficultyLevel:=Singleplayer_hard;

PlayerControls[0]:=TPlayerControls.create;
PlayerControls[1]:=TPlayerControls.create;

player2Active:=false;
PlayerControls[0].makeControls(controls_cursor,controls_WASD);

application.TimerMilisec:=1000 div 60; //60 fps
application.OnTimer:=@dotimer;
{=== this will start the game ===}
Window.Open;
Application.Run;
{=== ........................ ===}

end.

