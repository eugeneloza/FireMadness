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

{$IFDEF Windows}{$Apptype GUI}{$ENDIF}

uses  {$IFDEF UNIX}cthreads,{$ENDIF}Classes, SysUtils,
  castle_window, CastleWindow, castle_base,
  CastleGLImages,
  castleVectors, castleImages,
  CastleKeysMouse,
  CastleFreeType, CastleFonts, CastleUnicode, CastleStringUtils,
  Game_controls, general_var, Sound_Music, botsdata,
  map_manager, Translation, GL_button;

const MinWindowWidth=320;
      minWindowHeight=240;


type game_context_type=(gameplay_title,gameplay_play);
     Current_title_type=(currentTitle_title,currentTitle_prologue,currenttitle_bestiary, currentTitle_credits, currentTitle_mapselect);

{---------------------------}

var Window:TCastleWindow;
  startNewGame:boolean;
  firstrender:boolean;
  Current_game_context:game_context_type=gameplay_title;
  //images
  wall,pass: TGLimage;
//  healthBarHorizontal,emptyBarHorizontal,leftCapHorizontal,RightCapHorizontal:TGlImage;
  HealthBarVertical,EmptyBarVertical,TopCapVertical,BottomCapVertical:TGlImage;
  imgControl,imgControlBackground:TGLImage;
  imgControlsFire,imgControlsMove:array[0..3] of TGLImage;
  FIWIhealthempty,FIWIhealthfull:TGlImage;
  imgPause:TGLimage;

  //GUI
  TitleBackground:TGLIMage;
  BlackScreenImg,flamesTextImage:TGLImage;
  BlackScreenIntensity:integer;{0..100}
  CGE_icon:TGLImage;
  Screen_fadeOut,Screen_fadeIn:boolean;
  ShowBestiary:integer=0;
  ShowPrologue:integer=0;
  CurrentTitleDisplay:Current_Title_type=currentTitle_title;

  Story_stage:integer=0;
  Story_rollback:integer;
  VictoryTimer:TDateTime;

  buttons:array of TGLButton;
  buttonIMg:TGLImage;
  MouseMenuPress:boolean=false;

  UserPortraits:Array[0..4] of TGLImage;
  Player1Portrait:integer=0;
  Player2Portrait:integer=2;

  TitleReady:boolean;
  RescaleWindow:boolean;
  LeftInterface:integer=0;
  RightInterface:integer=32;
  //fonts
  BoldFont,NormalFont: TTextureFont;

{$R+}{$Q+}


procedure NextStoryStage(setStoryStage:integer=-1); forward;

{------------------------------------------------------------------------------------}
{====================================================================================}
{------------------------------------------------------------------------------------}


const maxBlackIntensity=120;
      BlackTransparency=0.90;
var blackPhase:integer=0;
procedure doBlackScreen(myAlpha:integer);
var MyShade:TVector4Single;
    blackPhaseScaled:integer;
begin
 MyShade[0]:=1;
 MyShade[1]:=1;
 MyShade[2]:=1;
 MyShade[3]:=BlackTransparency*(MyAlpha+10*sin(2*Pi*blackPhase/BlackScreenImg.width))/(maxBlackIntensity+10);
 if random<0.9 then inc(blackPhase);
 if blackPhase>blackScreenImg.width then blackPhase:=0;
 BlackScreenImg.Color:=MyShade;
 blackPhaseScaled:=round(blackPhase*window.width/blackScreenImg.width);

 blackScreenImg.Draw(0,0,blackPhaseScaled,window.height,
    BlackScreenImg.width-blackPhase,0,blackPhase,blackScreenImg.height);
 blackScreenImg.Draw(blackPhaseScaled,0,window.width-blackPhaseScaled,window.height,
    0,0,BlackScreenImg.width-blackPhase,blackScreenImg.height);
{ blackScreenImg.Draw(0,0,blackPhaseScaled,window.height,0,0,blackPhase,blackScreenImg.height);
 blackScreenImg.Draw(blackPhaseScaled,0,window.width-blackPhaseScaled,window.height,blackPhase,0,BlackScreenImg.width-blackPhase,blackScreenImg.height);}
end;

procedure StartGame(MapIt:TMapType);
var i:integer;
begin
  map:=MapIt;
  Current_Game_context:=gameplay_play;
  startNewGame:=true;
  //stop fire and movement if there were any before
  for i:=low(PlayerControls) to high(PlayerControls) do PlayerControls[i].StopControls;
end;

procedure MenuKeyRelease(Container: TUIContainer; const Event: TInputPressRelease);
var i:integer;
begin
  if (event.key=k_none) and (mouseMenuPress) then begin
    for i:=low(buttons) to high(buttons) do if buttons[i]<>nil then buttons[i].checkClick(round(event.Position[0]),round(event.position[1]));
  end;
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
    k_7:StartGame(map_Crossfire);
    k_9:NextStoryStage(1);
    k_f1: begin
            if Player2Active then begin
              DifficultyLevel.EnemyFirePowerMultiplier/=hotSeatDifficultyMultiplier;
              DifficultyLevel.EnemyHealthMultiplier/=2;
              DifficultyLevel.EnemySpawnRateMultiplier/=hotSeatDifficultyMultiplier;
              DifficultyLevel.simultaneous_active-=1;
            end;
            Player2Active:=false;
            RightInterface:=32;
            LeftInterface:=0;
//            PlayerControls[0].makeControls(controls_cursor,controls_WASD);
          end;
    k_f2: begin
            if not Player2Active then begin
              DifficultyLevel.EnemyFirePowerMultiplier*=hotSeatDifficultyMultiplier;
              DifficultyLevel.EnemyHealthMultiplier*=2;
              DifficultyLevel.EnemySpawnRateMultiplier*=hotSeatDifficultyMultiplier;
              DifficultyLevel.simultaneous_active+=1;
            end;
            Player2Active:=true;
            LeftInterface:=32;
            RightInterface:=32;
//            PlayerControls[0].makeControls(controls_numbers,controls_cursor);
//            PlayerControls[1].makeControls(controls_TFGH,controls_WASD);
          end;
    k_f5:difficultyLevel:=Singleplayer_easy;
    k_f6:difficultyLevel:=Singleplayer_normal;
    k_f7:difficultyLevel:=Singleplayer_hard;
    k_f8:difficultyLevel:=Singleplayer_insane;
    k_none:if event.IsMouseButton(MBLeft) then MouseMenuPress:=true;
  end;
end;


procedure HideAllButtons;
var i:integer;
begin
  for i:=low(buttons) to high(buttons) do if buttons[i]<>nil then buttons[i].hidden:=true;
end;

procedure ShowMainButtons;
var i:integer;
begin
  HideAllButtons;
  buttons[0].hidden:=false;
  buttons[3].hidden:=false;
  for i:=14 to 17 do begin
    buttons[i].Alpha:=0.4;
    buttons[i].hidden:=false;
  end;
  case CurrentDifficultyLevel of
     difficulty_easy:   buttons[14].Alpha:=0.9;
     difficulty_normal: buttons[15].Alpha:=0.9;
     difficulty_hard:   buttons[16].Alpha:=0.9;
     difficulty_insane: buttons[17].Alpha:=0.9;
   end;
end;

Procedure ShowTitleScreenButtons;
var i:integer;
begin
 ShowMainButtons;
 for i:=0 to 22 do if buttons[i]<>nil then buttons[i].hidden:=false;

 //player 1 portraits
 if Player1Portrait=0 then buttons[8].Alpha:=0.9 else buttons[8].Alpha:=0.4;
 if Player1Portrait=1 then buttons[9].Alpha:=0.9 else buttons[9].Alpha:=0.4;

 //player 2 and portrait
 if Player2Active then begin
   buttons[5].Alpha:=0.9;
   if Player2Portrait=2 then buttons[6].Alpha:=0.9 else buttons[6].Alpha:=0.4;
   if Player2Portrait=3 then buttons[7].Alpha:=0.9 else buttons[7].Alpha:=0.4;
   buttons[12].Alpha:=0.9;
   buttons[13].Alpha:=0.9;
 end else begin
   buttons[5].Alpha:=0.4;
   buttons[6].Alpha:=0.4;
   buttons[7].Alpha:=0.4;
   buttons[12].Alpha:=0.4;
   buttons[13].Alpha:=0.4;
 end;

 buttons[10].image:=GetControlImage(playercontrols[0].FireStyle);
 buttons[11].image:=GetControlImage(playercontrols[0].MoveStyle);
 buttons[12].image:=GetControlImage(playercontrols[1].FireStyle);
 buttons[13].image:=GetControlImage(playercontrols[1].MoveStyle);

 for i:=18 to 20 do buttons[i].Alpha:=0.4;
 case CurrentLanguage of
    Language_English:   buttons[18].Alpha:=0.9;
    Language_Russian:   buttons[19].Alpha:=0.9;
    Language_Ukrainian: buttons[20].Alpha:=0.9;
  end;

end;

procedure ShowMapSelectionButtons;
var i:integer;
begin
  ShowMainButtons;
  for i:=23 to 32 do if buttons[i]<>nil then
   if buttons[i].ClickMe<>nil then buttons[i].hidden:=false;
end;


procedure ReturnToTitle;
begin
  Screen_fadein:=true;
  currentTitleDisplay:=currentTitle_title;
  MouseMenuPress:=false;
  window.OnPress:=@MenuKeyPress;
  HideAllButtons;
end;

procedure SimpleKeyOfReturn(Container: TUIContainer; const Event: TInputPressRelease);
begin
  ReturnToTitle;
end;

procedure SimpleKeyOfContinue(Container: TUIContainer; const Event: TInputPressRelease);
begin
  NextStoryStage;
end;

{------------------------------------------------------------------------}


const startY=0;
      normalFontSize=16;
      boldFontSize=18;
      FontScaleCoefficient=0.6;
var tmpScale:integer;

procedure StoryButtonClick;
begin
  HideAllButtons;
  NextStoryStage(1);
end;

procedure CreditsButtonClick;
begin
  HideAllButtons;
  CurrentTitleDisplay:=CurrentTitle_credits;
  screen_fadeout:=true;
end;

procedure ExitButtonClick;
begin
  Window.close;
end;

procedure DoShowMainTitle;
var scaledY:integer;
    i:integer;
begin
  Screen_fadeOut:=false;
  Screen_fadein:=true;
  ScaledY:=round(Window.height*FlamesTextImage.height/FlamesTextImage.width);
  flamesTextImage.Draw(20,Window.height-ScaledY,window.width-40,scaledY);
  if CurrentTitleDisplay= currentTitle_mapselect
    then ShowMapSelectionButtons
    else ShowTitleScreenButtons;
  for i:=low(buttons) to high(buttons) do if buttons[i]<>nil then buttons[i].drawMe;
end;

procedure doShowCredits;
var s:string;
  x,y:integer;
begin
  Screen_fadeOut:=true;

  x:=10;
  Y:=Window.height-10-boldFontSize;
  BoldFont.print(window.width div 2 - 100,Y,Vector4Single(1,1,1,1), txt[61]);

  Y-=boldFontSize+30;
  BoldFont.print(x,Y,Vector4Single(0.9,0.9,0.9,1),txt[53]);
  Y-=BoldFontSize*2;
  CGE_icon.Draw(x,Y-64+10,64,64);
  s:=txt[49]+slinebreak+txt[50]+slinebreak+txt[51]+slinebreak+txt[52];
  Y-=NormalFontSize*NormalFont.PrintBrokenString(x+64+10,Y,Vector4Single(0.9,0.9,0.9,1),s,(window.width-X)-10,true,1);

  Y-=NormalFontSize;
  NormalFont.Print(x,y,Vector4Single(0.9,0.9,0.9,1),txt[54]);
  Y-=NormalFontSize*2;
  NormalFont.Print(x,y,Vector4Single(0.9,0.9,0.9,1),txt[55]);
  Y-=NormalFontSize*2;
  NormalFont.Print(x,y,Vector4Single(0.9,0.9,0.9,1),txt[56]);
  Y-=NormalFontSize;
  NormalFont.Print(x,y,Vector4Single(0.9,0.9,0.9,1),txt[57]);
  Y-=NormalFontSize;
  NormalFont.Print(x,y,Vector4Single(0.9,0.9,0.9,1),txt[58]);
  Y-=NormalFontSize*2;
  NormalFont.Print(x,y,Vector4Single(0.9,0.9,0.9,1),txt[59]);
  Y-=NormalFontSize*2;
  NormalFont.Print(x,y,Vector4Single(0.9,0.9,0.9,1),txt[60]);

  NormalFont.print(Window.width-round(FontScaleCoefficient*UTF8length(txt[63])*NormalFontSize),10,Vector4Single(0.9,0.9,0.9,1),txt[63]);
  window.OnPress:=@SimpleKeyOfReturn;
end;

procedure doShowPrologue(PrologueRecord:integer);
var txt_index:integer;
    Y,X:integer;
begin
  if music_context<>music_TitleScreen then begin
    music_context:=music_TitleScreen;
    if not isMusicCrossfade then doLoadNewMusic;
  end;
  Story_rollback:=Story_stage;

  CurrentTitleDisplay:=currentTitle_prologue;
  ShowPrologue:=PrologueRecord;
  Screen_fadeOut:=true;


  Y:=window.height-startY-10-2*BoldFontSize;
  X:=10+30*4+20;

  UserPortraits[Player1Portrait].Draw(10,Y-10-40*4,30*4,40*4);

  case PrologueRecord of
    1:txt_index:=1;
    2:txt_index:=3;
    3:txt_index:=5;
    4:txt_index:=7;
    5:txt_index:=9;
    6:txt_index:=11;
    7:txt_index:=13;
  end;
  boldFont.Print(x+(Window.width-X) div 4,Y,Vector4Single(1,1,1,1),txt[txt_index]);
  try NormalFont.PrintBrokenString(x,Y-50,Vector4Single(0.9,0.9,0.9,1),txt[txt_index+1],(window.width-X)-10,true,1);
  finally end;

  NormalFont.print(Window.width-round(FontScaleCoefficient*UTF8length(txt[62])*NormalFontSize),10,Vector4Single(0.9,0.9,0.9,1),txt[62]);

  if (player2active) and (PrologueRecord>1) then begin
    case PrologueRecord of
      2:txt_index:=71;
      3:txt_index:=72;
      4:txt_index:=73;
      5:txt_index:=74;
      6:txt_index:=75;
      7:txt_index:=76;
    end;
    UserPortraits[Player2Portrait].Draw(10,Y-10-40*4-40*4-40,30*4,40*4);
    NormalFont.Print(x,Y-10-40*4-40-50,Vector4Single(0.9,0.9,0.9,1),txt[txt_index]);
  end;
end;

function doShowBotInfo(botType:TBotType;y:integer):integer;
var txt_index:integer;
    t_x,t_y:integer;
    y_text:integer;
begin
  BotsImg[bottype].Draw(10,y,tmpscale,tmpscale);
  case bottype of
    bot1             :txt_index:=15;
    bot2             :txt_index:=17;
    bot3             :txt_index:=19;
    botdisabler      :txt_index:=21;
    heavybot         :txt_index:=23;
    botautohealer    :txt_index:=25;
    botshielder      :txt_index:=27;
    bothealer        :txt_index:=29;
    botteleporter    :txt_index:=31;
    botBossCrossFire :txt_index:=33;
    botBossMiner     :txt_index:=35;
    botMine          :txt_index:=37;
    botBossCarrier   :txt_index:=39;
    botfighter       :txt_index:=41;
    botFIWI          :txt_index:=43;
    botplayer1       :txt_index:=45;
    botplayer2       :txt_index:=47;
  end;
  t_x:=tmpscale+10+10;
  t_y:=y+tmpscale-BoldFontSize;
  BoldFont.print(t_x,t_y,Vector4Single(1,1,1,1),txt[txt_index]);
  try y_Text:=BoldFontSize+20+NormalFontSize*NormalFont.PrintBrokenString(t_x,t_y-BoldFontSize,Vector4Single(0.9,0.9,0.9,1),txt[txt_index+1],window.width-10-t_x,true,1);
  finally end;

  if y_text<tmpscale+10 then result:=tmpscale+10 else result:=y_text;

end;

procedure doShowBestiary(BestiaryRecord:integer);
var new_y:integer;
begin
  if music_context<>music_TitleScreen then begin
    music_context:=music_TitleScreen;
    if not isMusicCrossfade then doLoadNewMusic;
  end;

  CurrentTitleDisplay:=currenttitle_bestiary;
  ShowBestiary:=BestiaryRecord;
  Screen_fadeOut:=true;

  if player2Active then tmpScale:= (window.height-20) div 6 -10 else
                        tmpScale:= (window.height-20) div 5 -10;
  new_y:=window.height-startY-10-tmpscale;
  case BestiaryRecord of
    1: begin
         new_y-=doShowBotInfo(bot1,new_y);
         new_y-=doShowBotInfo(bot2,new_y);
         new_y-=doShowBotInfo(bot3,new_y);
         new_y-=doShowBotInfo(botdisabler,new_y);
         new_y-=doShowBotInfo(botplayer1,new_y);
         if player2active then
           new_y-=doShowBotInfo(botplayer2,new_y);
       end;
    2: begin
         new_y-=doShowBotInfo(heavybot,new_y);
         new_y-=doShowBotInfo(botteleporter,new_y);
         new_y-=doShowBotInfo(botbosscrossfire,new_y);
       end;
    3: begin
         new_y-=doShowBotInfo(botshielder,new_y);
         new_y-=doShowBotInfo(botautohealer,new_y);
         new_y-=doShowBotInfo(botbossminer,new_y);
         new_y-=doShowBotInfo(botmine,new_y);
       end;
    4: begin
         new_y-=doShowBotInfo(bothealer,new_y);
         new_y-=doShowBotInfo(botbosscarrier,new_y);
         new_y-=doShowBotInfo(botfighter,new_y);
       end;
    5: begin
         new_y-=doShowBotInfo(botfiwi,new_y);
       end;
  end;
  NormalFont.print(Window.width-round(FontScaleCoefficient*UTF8length(txt[62])*NormalFontSize),10,Vector4Single(0.9,0.9,0.9,1),txt[62]);
end;

{===========================================================}

procedure NextStoryStage(setStoryStage:integer=-1);
begin
 Current_game_context:=gameplay_title;
 window.OnPress:=@SimpleKeyOfContinue;

 if setStoryStage>0 then Story_stage:=SetStoryStage else inc(Story_stage);
 case Story_stage of
     1: doShowPrologue(1);
     2: doShowPrologue(2);
     3: doShowBestiary(1);
     4: StartGame(map_bedroom);
     5: doShowPrologue(3);
     6: doShowBestiary(2);
     7: StartGame(map_LivingRoom);
     8: doShowPrologue(4);
     9: doShowBestiary(3);
    10: StartGame(map_Cellar);
    11: doShowPrologue(5);
    12: doShowBestiary(4);
    13: StartGame(map_Kitchen);
    14: doShowPrologue(6);
    15: doShowBestiary(5);
    16: StartGame(map_FIWI);
    17: doShowPrologue(7);
    else begin CurrentTitleDisplay:=CurrentTitle_title;Current_game_context:=gameplay_title; window.OnPress:=@MenuKeyPress; window.OnRelease:=@MenuKeyRelease end;
 end;
end;

{---------------------------------------------------------------------------}

procedure SetPlayerPortrait0;
begin
 Player1Portrait:=0;
end;
procedure SetPlayerPortrait1;
begin
 Player1Portrait:=1;
end;
procedure SetPlayerPortrait2;
begin
 Player2Portrait:=2;
end;
procedure SetPlayerPortrait3;
begin
 Player2Portrait:=3;
end;
procedure TogglePlayer1;
begin
 {   DifficultyLevel.EnemyFirePowerMultiplier/=hotSeatDifficultyMultiplier;
    DifficultyLevel.EnemyHealthMultiplier/=2;
    DifficultyLevel.EnemySpawnRateMultiplier/=hotSeatDifficultyMultiplier;
    DifficultyLevel.simultaneous_active-=1;}
    case CurrentDifficultyLevel of
      difficulty_easy:   difficultyLevel:=Singleplayer_easy;
      difficulty_normal: difficultyLevel:=Singleplayer_normal;
      difficulty_hard:   difficultyLevel:=Singleplayer_hard;
      difficulty_insane: difficultyLevel:=Singleplayer_insane;
    end;
    Player2Active:=false;
    RightInterface:=32;
    LeftInterface:=0;
    PlayerControls[0]:=PlayerControls[2];
end;
procedure TogglePlayer2;
begin
 if Player2Active then begin
   TogglePlayer1
 end else begin
   DifficultyLevel.EnemyFirePowerMultiplier*=hotSeatDifficultyMultiplier;
   DifficultyLevel.EnemyHealthMultiplier*=2;
   DifficultyLevel.EnemySpawnRateMultiplier*=hotSeatDifficultyMultiplier;
   DifficultyLevel.simultaneous_active+=1;
   Player2Active:=true;
   LeftInterface:=32;
   RightInterface:=32;
   PlayerControls[0]:=PlayerControls[3];
 end;
end;
procedure SetDifficultyLevelEasy;
begin
  difficultyLevel:=Singleplayer_easy;
  currentDifficultyLevel:=DifficultyLevel.DifficultyStyle;
end;
procedure SetDifficultyLevelNormal;
begin
  difficultyLevel:=Singleplayer_Normal;
  currentDifficultyLevel:=DifficultyLevel.DifficultyStyle;
end;
procedure SetDifficultyLevelHard;
begin
  difficultyLevel:=Singleplayer_Hard;
  currentDifficultyLevel:=DifficultyLevel.DifficultyStyle;
end;
procedure SetDifficultyLevelInsane;
begin
  difficultyLevel:=Singleplayer_Insane;
  currentDifficultyLevel:=DifficultyLevel.DifficultyStyle;
end;



procedure ResizeButtons;
var StartY,EndY,spanY,startX,EndX,SpanX:integer;
    Span74,spanL:integer;
    NewFontSize:integer;
    i:integer;
begin
 NewFontSize:=round(30*Window.width/800);
 for i:=low(buttons) to high(buttons) do if buttons[i]<>nil then
   if buttons[i].fontSize<>newFontSize then buttons[i].setFontSize(newFontSize);

 startY:=10;
 EndY:= Window.height-round(Window.height*FlamesTextImage.height/FlamesTextImage.width)-10;
 SpanY:=(EndY-StartY) div 6-10;

 startX:=10;
 EndX:=window.Width-10;
 SpanX:=(EndX-StartX) div 10-10;

 if SpanY<30 then begin inc(SpanY,8-SpanY div 4); inc(SpanX,8-SpanY div 4) end;

 buttons[0].ResizeMe(StartX,EndY-SpanY,5*SpanX,spanY);
 buttons[1].ResizeMe(StartX,StartY,3*SpanX,spanY);
 buttons[2].ResizeMe(endX-SpanX*3,StartY,3*SpanX,spanY);
 buttons[3].ResizeMe(endX-SpanX*5,EndY-SpanY,5*SpanX,spanY);

 //Player1
 buttons[4].ResizeMe(StartX,EndY-4*SpanY,3*SpanX,2*spanY);
 buttons[8].ResizeMe(StartX+3*spanX,EndY-4*SpanY,2*SpanX,2*spanY);
 buttons[9].ResizeMe(StartX+5*spanX,EndY-4*SpanY,2*SpanX,2*spanY);
 buttons[10].ResizeMe(StartX+7*spanX,EndY-4*SpanY,2*SpanX,2*spanY);
 buttons[11].ResizeMe(StartX+9*spanX,EndY-4*SpanY,2*SpanX,2*spanY);
 //Player2
 buttons[5].ResizeMe(StartX,EndY-6*SpanY,3*SpanX,2*spanY);
 buttons[6].ResizeMe(StartX+3*spanX,EndY-6*SpanY,2*SpanX,2*spanY);
 buttons[7].ResizeMe(StartX+5*spanX,EndY-6*SpanY,2*SpanX,2*spanY);
 buttons[12].ResizeMe(StartX+7*spanX,EndY-6*SpanY,2*SpanX,2*spanY);
 buttons[13].ResizeMe(StartX+9*spanX,EndY-6*SpanY,2*SpanX,2*spanY);
 //difficulty
 Span74:=round(SpanX*7/4);
 buttons[14].ResizeMe(StartX        ,EndY-SpanY*2,Span74,spanY);
 buttons[15].ResizeMe(StartX+Span74  ,EndY-SpanY*2,Span74,spanY);
 buttons[16].ResizeMe(StartX+Span74*2,EndY-SpanY*2,Span74,spanY);
 buttons[17].ResizeMe(StartX+Span74*3,EndY-SpanY*2,Span74,spanY);
 for i:=14 to 17 do buttons[i].setFontSize(2*NewFontSize div 3);
 //language
 spanL:=3*SpanX div 2;
 buttons[18].ResizeMe(StartX+(EndX-StartX-spanL) div 2-SpanL,StartY,SpanL,spanY div 2);
 buttons[19].ResizeMe(StartX+(EndX-StartX-spanL) div 2,StartY,SpanL,spanY div 2);
 buttons[20].ResizeMe(StartX+(EndX-StartX-spanL) div 2+SpanL,StartY,SpanL,spanY div 2);
 for i:=18 to 20 do buttons[i].setFontSize(NewFontSize div 2);
 buttons[21].ResizeMe(StartX+7*spanX,EndY-4*SpanY+9*SpanY div 5,2*SpanX,spanY div 2);
 buttons[22].ResizeMe(StartX+9*spanX,EndY-4*SpanY+9*SpanY div 5,2*SpanX,spanY div 2);
 for i:=21 to 22 do buttons[i].setFontSize(NewFontSize div 2);
 //maps
 for i:=0 to 4 do buttons[23+i].resizeMe(StartX,EndY-SpanY*(i+3),5*SpanX,spanY);
 for i:=0 to 4 do buttons[28+i].resizeMe(EndX-5*SpanX,EndY-SpanY*(i+3),5*SpanX,spanY);
end;

procedure MakeButtonsText;
var i:integer;
begin
  buttons[0].caption:=txt[68]; //play story
  buttons[1].caption:=txt[69]; //show credits
  buttons[2].caption:=txt[70]; //exit
  buttons[3].caption:=txt[77]; //custom map
  //Players
  buttons[4].caption:=txt[45];
  buttons[5].caption:=txt[47];
  //Difficulty
  buttons[14].Caption:=txt[64];
  buttons[15].Caption:=txt[65];
  buttons[16].Caption:=txt[66];
  buttons[17].Caption:=txt[67];
  //language
  buttons[18].Caption:=txt[78];
  buttons[19].Caption:=txt[79];
  buttons[20].Caption:=txt[80];
  //move&fire
  buttons[21].frame:=nil;
  buttons[21].caption:=txt[81];
  buttons[22].frame:=nil;
  buttons[22].caption:=txt[82];
  //custom map titles
  for i:=23 to 32 do buttons[i].caption:=txt[i+83-23];
end;

procedure SetTranslationEnglish;
begin
  loadTranslation(Language_English);
  MakeButtonsText;
end;
Procedure SetTranslationRussian;
begin
  loadTranslation(Language_Russian);
  MakeButtonsText;
end;
Procedure SetTranslationUkrainian;
begin
  loadTranslation(Language_Ukrainian);
  MakeButtonsText;
end;
Procedure playMap_1;
begin
  NextStoryStage(1)
end;
Procedure playMap_2;
begin
  NextStoryStage(5)
end;
Procedure playMap_3;
begin
  NextStoryStage(8)
end;
Procedure playMap_4;
begin
  NextStoryStage(11)
end;
Procedure playMap_5;
begin
  NextStoryStage(14)
end;
Procedure PlayMap_crossfire;
begin
  StartGame(map_Crossfire);
end;
Procedure playMap_narrow;
begin
  StartGame(map_NarrowCellar)
end;
procedure CustomMap;
begin
 currentTitleDisplay:=CurrentTitle_mapSelect;
end;
procedure ClickToTitle;
begin
 currentTitleDisplay:=CurrentTitle_title;
end;

procedure MakeButtons;
var i:integer;
begin
  //create buttons
  setLength(buttons,32+1);
  for i:=0 to 32 do begin
     buttons[i]:=TGLButton.create;
     buttons[i].Frame:=ButtonImg;
  end;

  SetTranslationEnglish;

  buttons[0].ClickMe:=@StoryButtonClick;
  buttons[1].ClickMe:=@CreditsButtonClick;
  buttons[2].ClickMe:=@ExitButtonClick;
  buttons[3].ClickMe:=@CustomMap;
  //player 1
  buttons[4].ClickMe:=@TogglePlayer1;
  buttons[8].Image:=UserPortraits[0];
  buttons[8].content:=button_img;
  buttons[8].ClickMe:=@SetPlayerPortrait0;
  buttons[9].Image:=UserPortraits[1];
  buttons[9].content:=button_img;
  buttons[9].ClickMe:=@SetPlayerPortrait1;
  buttons[10].content:=button_img;
  buttons[10].ClickMe:=@cyclePlayer1Fire;
  buttons[11].content:=button_img;
  buttons[11].ClickMe:=@cyclePlayer1Move;
  //player 2
  buttons[5].ClickMe:=@TogglePlayer2;
  buttons[6].Image:=UserPortraits[2];
  buttons[6].content:=button_img;
  buttons[6].ClickMe:=@SetPlayerPortrait2;
  buttons[7].Image:=UserPortraits[3];
  buttons[7].content:=button_img;
  buttons[7].ClickMe:=@SetPlayerPortrait3;
  buttons[12].content:=button_img;
  buttons[12].ClickMe:=@CyclePlayer2Fire;
  buttons[13].content:=button_img;
  buttons[13].ClickMe:=@CyclePlayer2Move;
  //difficulty
  buttons[14].clickMe:=@SetDifficultyLevelEasy;
  buttons[15].clickMe:=@SetDifficultyLevelNormal;
  buttons[16].clickMe:=@SetDifficultyLevelHard;
  buttons[17].clickMe:=@SetDifficultyLevelInsane;
  //language
  buttons[18].clickMe:=@SetTranslationEnglish;
  buttons[19].clickMe:=@SetTranslationRussian;
  buttons[20].clickMe:=@SetTranslationUkrainian;
  //CustomMap
  buttons[23].clickMe:=@playMap_1;
  buttons[24].clickMe:=@playMap_2;
  buttons[25].clickMe:=@playMap_3;
  buttons[26].clickMe:=@playMap_4;
  buttons[27].clickMe:=@playMap_5;
  buttons[28].clickMe:=@PlayMap_crossfire;
  buttons[29].clickMe:=@playMap_narrow;
  buttons[30].ClickMe:=nil;
  buttons[31].ClickMe:=nil;
  buttons[32].clickMe:=@ClickToTitle;
  ResizeButtons;
end;


procedure MakeTitleScreen;
begin
  showBestiary:=0;
  ShowPrologue:=0;
  TitleBackground:=TGLImage.Create(TitlescreenFolder+'FireMadness.jpg',true);
  BlackScreenImg:=TGLImage.Create(TitlescreenFolder+'Black.jpg',true);
  BlackScreenImg.Alpha:=acFullRange;
  CGE_icon:=TGLImage.Create(TitlescreenFolder+'castle_game_engine_icon_transparent.png',true);
  FlamesTextImage:=TGLImage.Create(TitlescreenFolder+'flames.png',true);
  buttonIMg:=TGLImage.create(TitlescreenFolder+'button.png',true);

  makeButtons;

  TitleReady:=false;
end;

procedure ShowTitle;
begin
  music_context:=music_TitleScreen;
//  CurrentTitleDisplay:=currentTitle_title;
  ShowTitleScreenButtons;
  BlackScreenIntensity:=0;
  doLoadNewMusic;
  TitleReady:=true;
  mouseMenuPress:=false;
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
 if event.key=K_f10 then begin Current_game_context:=gameplay_title; CurrentTitleDisplay:=currentTitle_title; window.OnPress:=@MenuKeyPress; window.OnRelease:=@MenuKeyRelease end;
 if event.key=K_f9 then for i:= low(bots) to high(bots) do if bots[i] is THostileBot then bots[i].hitme(bots[i].maxhp);
 if event.key=k_f5 then doLoadNewMusic;
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

procedure doGetMapScale(CanInvert:boolean);
var MapSpanX,MapSpanY,gameAreaWidth,gameAreaHeight:integer;
    tryInverseScale,tmp:integer;
begin
  GameAreaWidth:=window.width-RightInterface-LeftInterface;
  GameAreaHeight:=window.height;
  if GameAreaWidth/(maxx+1) < GameAreaHeight/(maxy+1) then scale := GameAreaWidth div (maxx+1) else scale:= GameAreaHeight div (maxy+1);
  if canInvert then begin
    if GameAreaWidth/(maxy+1) < GameAreaHeight/(maxx+1) then tryInverseScale := GameAreaWidth div (maxy+1) else tryInverseScale:= GameAreaHeight div (maxx+1);
    if tryInverseScale>scale then begin
      scale:=tryInverseScale;
      tmp:=maxX;maxX:=maxY;MaxY:=tmp;
    end;
  end;
  mapSpanX:=(maxx+1)*scale;
  mapSpanY:=(maxy+1)*scale;
  GameScreenStartX:=LeftInterface+(GameAreaWidth-mapSpanX) div 2;
  GameScreenEndX:=GameScreenStartX+(maxx+1)*scale;
  GameScreenStartY:=(GameAreaHeight-mapSpanY) div 2;
  GameScreenEndY:=GameScreenStartY+(maxy+1)*scale;
end;

procedure doStartGame;
var i:integer;
    bosses:integer;
    b_shielder,b_heavy,b_healer,b_Teleporter,b_autohealer,b_disabler:integer;

    TileSelect:integer;
begin
  VictoryTimer:=-1;
  doFadeOutMusic;
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
  doGetMapScale(true);

  randomize;
  old_music_context:=music_context;
  nmissles:=0;
  if length(missles)>0 then for i:=low(missles) to high(missles) do freeandnil(missles[i]);
  setlength(missles,0);
  if length(bots)>0 then for i:=low(bots) to high(bots) do freeandnil(bots[i]);

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
  PauseMode:=false;
  window.OnPress:=@GameKeyPress;
  window.onRelease:=@GameKeyRelease;
  //window.OnMotion:=@GameKeyMotion;
end;

{------------------------------------------------------------------------------------}

procedure doLoadFonts;
begin
  normalFont:= TTextureFont.Create(NormalFontFile,16,true,MyCharSet);
  boldFont:= TTextureFont.Create(BoldFontFile,22,true,MyCharSet);
end;

procedure doLoadGameData;
begin
  doLoadFonts;
  //load TGLImages
  doLoadImages;

{  EmptyBarHorizontal:=TGLImage.create(GuiFolder+'SleekBars_CC0_by_Jannax(opengameart)_empty.png',true);
  HealthBarHorizontal:=TGLImage.create(GuiFolder+'SleekBars_CC0_by_Jannax(opengameart)_full.png',true);
  LeftCapHorizontal:=TGLImage.create(GuiFolder+'SleekBars_CC0_by_Jannax(opengameart)_leftcap.png',true);
  RightCapHorizontal:=TGLImage.create(GuiFolder+'SleekBars_CC0_by_Jannax(opengameart)_rightcap.png',true);}

  EmptyBarVertical:=TGLImage.create(GuiFolder+'SleekBars_CC0_by_Jannax(opengameart)_vertical_empty.png',true);
  HealthBarVertical:=TGLImage.create(GuiFolder+'SleekBars_CC0_by_Jannax(opengameart)_vertical_full.png',true);
  TopCapVertical:=TGLImage.create(GuiFolder+'SleekBars_CC0_by_Jannax(opengameart)_vertical_topCap.png',true);
  BottomCapVertical:=TGLImage.create(GuiFolder+'SleekBars_CC0_by_Jannax(opengameart)_vertical_bottomCap.png',true);

  imgControlBackground:=TGLImage.create(GuiFolder+'Pattern_005_CC0_by_Nobiax_specular.png',true);
  imgControl:=TGLImage.create(GuiFolder+'Controls_none_(Pattern_001_CC0_by_Nobiax_diffuse).png',true);
  imgControlsFire[0]:=TGLImage.create(GuiFolder+'Fire_left_(Pattern_001_CC0_by_Nobiax_diffuse).png',true);
  imgControlsFire[1]:=TGLImage.create(GuiFolder+'Fire_up_(Pattern_001_CC0_by_Nobiax_diffuse).png',true);
  imgControlsFire[2]:=TGLImage.create(GuiFolder+'Fire_right_(Pattern_001_CC0_by_Nobiax_diffuse).png',true);
  imgControlsFire[3]:=TGLImage.create(GuiFolder+'Fire_down_(Pattern_001_CC0_by_Nobiax_diffuse).png',true);
  imgControlsMove[0]:=TGLImage.create(GuiFolder+'Move_left_(Pattern_001_CC0_by_Nobiax_diffuse).png',true);
  imgControlsMove[1]:=TGLImage.create(GuiFolder+'Move_up_(Pattern_001_CC0_by_Nobiax_diffuse).png',true);
  imgControlsMove[2]:=TGLImage.create(GuiFolder+'Move_right_(Pattern_001_CC0_by_Nobiax_diffuse).png',true);
  imgControlsMove[3]:=TGLImage.create(GuiFolder+'Move_down_(Pattern_001_CC0_by_Nobiax_diffuse).png',true);

  FIWIHealthEmpty:=TGLImage.create(GuiFolder+'FiwiHealth_empty.png',true);
  FIWIHealthFull:=TGLImage.create(GuiFolder+'FiwiHealth_full.png',true);

  imgPause:=TGLImage.create(GuiFolder+'pause.png',true);

  UserPortraits[0]:=TGLImage.create(PortraitFolder+'m_CC_BY_by_noblemaster.png',true);
  UserPortraits[1]:=TGLImage.create(PortraitFolder+'f_CC_BY_by_noblemaster.png',true);
  UserPortraits[2]:=TGLImage.create(PortraitFolder+'cute_cat_03_CC0_by_frugalhappyfamilies.com.png',true);
  UserPortraits[3]:=TGLImage.create(PortraitFolder+'cute_cat_05_CC0_by_frugalhappyfamilies.com.png',true);
  UserPortraits[4]:=TGLImage.create(PortraitFolder+'none.png',true);

  LoadControlsImages;
  MakeTitleScreen;

  //load sounds as TSoundBuffer
  doLoadSound;
  StartNewGame:=true;
  //and launch music
  //old_Music:=-1;
  MyVoiceTimer:=now;
  //aMusicTimer:=now+1/60/60/24;
  //Music_duration:=0;  {a few seconds of silence}
end;

{------------------------------------------------------------------------------------}

procedure DoDrawMap;
var ix,iy:integer;
begin
for ix:=0 to maxx do
 for iy:=0 to maxy do if odd(ix) and odd(iy) then begin
     //draw wall
     wall.Draw(GameScreenStartX+ix*scale,GameScreenStartY+iy*scale,scale,scale);
   end else begin
     //draw pass
     pass.Draw(GameScreenStartX+ix*scale,GameScreenStartY+iy*scale,scale,scale);
   end;
end;

procedure doDrawBots;
var i:integer;
begin
  for i:=low(bots) to high(bots) do bots[i].doDraw;
  for i:=low(missles) to high(missles) do missles[i].doDraw;
end;


procedure doDrawInterface;
var PlayerBot:TPlayerBot;
    PlayerControlsIndex:integer;

  procedure DrawHealthBar32(bar_x,from_y,to_y:integer);
  var FullRange:integer;
      Median:integer;
      ScaledMedian:single;
  begin
    topCapVertical.draw(bar_x,to_y-5);
    bottomCapVertical.draw(bar_x,from_y);
    FullRange:=(to_y-from_y-10);
    Median:=round(FullRange*PlayerBot.hp/PlayerBot.MaxHp);
    ScaledMedian:=(HealthBarVertical.Height*PlayerBot.hp/PlayerBot.MaxHp);
    EmptyBarVertical.draw(bar_x,from_y+5+Median,32,FullRange-Median,0,ScaledMedian,32,EmptyBarVertical.height-ScaledMedian);
    HealthBarVertical.draw(bar_x,from_y+5,32,Median,0,0,32,ScaledMedian);
  end;

  procedure DrawInterface128(bar_x:integer);
  const FullRange=118;
        PadControlSize=128;
  var i:integer;
      Median:integer;
      ScaledMedian:single;
  begin
    imgControl.Draw(bar_x,0);
    with PlayerControls[playercontrolsindex] do begin
      if FirePressed then begin
        if FireX=-1 then imgControlsFire[0].draw(bar_x,0);
        if FireY= 1 then imgControlsFire[1].draw(bar_x,0);
        if FireX= 1 then imgControlsFire[2].draw(bar_x,0);
        if FireY=-1 then imgControlsFire[3].draw(bar_x,0);
      end;
    end;
    i:=0;
    repeat
       inc(i,128);
       imgControlBackground.draw(bar_x,i);
    until i>window.height-128;
    imgControl.Draw(bar_x,window.height-PadControlSize);
    with PlayerControls[playercontrolsindex] do begin
      if MovePressed then begin
        if MoveX=-1 then imgControlsMove[0].draw(bar_x,window.height-PadControlSize);
        if MoveY= 1 then imgControlsMove[1].draw(bar_x,window.height-PadControlSize);
        if MoveX= 1 then imgControlsMove[2].draw(bar_x,window.height-PadControlSize);
        if MoveY=-1 then imgControlsMove[3].draw(bar_x,window.height-PadControlSize);
      end;
    end;
    if bar_x=0 then
      DrawHealthBar32(128-32,PadControlSize,window.height-PadControlSize)
    else
      DrawHealthBar32(bar_x,PadControlSize,window.height-PadControlSize);

{    LeftCapHorizontal.draw(bar_x,GameScreenEndY-PadControlSize-64);
    RightCapHorizontal.draw(bar_x+FullRange+5,GameScreenEndY-PadControlSize-64);
    Median:=round(FullRange*PlayerBot.hp/PlayerBot.MaxHp);
    ScaledMedian:=(HealthBarHorizontal.width*PlayerBot.hp/PlayerBot.MaxHp);
    HealthBarHorizontal.Draw(bar_x+5,GameScreenEndY-PadControlSize-64,median,32,0,0,scaledMedian,32);
    EmptyBarHorizontal.Draw(bar_x+5+median,GameScreenEndY-PadControlSize-64,fullrange-median,32,ScaledMedian,0,EmptyBarHorizontal.width-scaledMedian,32);}
  end;

  procedure DrawFIWIhealth;
  var FullRange:integer;
      Median:integer;
      scaledMedian:single;
  begin
    FullRange:=GameScreenEndX-GameScreenStartX-Scale*3;
    Median:=round(FullRange*FIWI_health/FIWI_maxHealth);
    ScaledMedian:=FIWIHealthEmpty.width*FIWI_health/FIWI_maxHealth;
    FIWIHealthEmpty.draw(GameScreenStartX+Scale*3 div 2+Median,GameScreenEndY-Scale div 2,FullRange-median,20,ScaledMedian,0,FIWIHealthEmpty.width-scaledMedian,20);
    FIWIHealthFull.draw(GameScreenStartX+Scale*3 div 2,GameScreenEndY-Scale div 2,Median,20,0,0,scaledMedian,20);
    //    FIWIHealthEmpty.draw(GameScreenStartX+Scale*3 div 2+round(median),GameScreenEndY-Scale div 2,Fullrange-round(median),20,0,0,20,FIWIHealthEmpty.width-round(ScaledMedian));
  end;

begin
  if map.fiwi then drawFIWIhealth;
  if RightInterface>0 then begin
    PlayerBot:=bots[0] as TPlayerBot;
    PlayerControlsIndex:=0;
    if RightInterface=32 then DrawHealthBar32(GameScreenEndX,gameScreenStartY,GameScreenEndY) else
    if RightInterface=128 then DrawInterface128(Window.width-128);
  end;
  if LeftInterface>0 then begin
    //if 2 players, left interface is for player2 else - only player
    if Player2Active then begin
      PlayerBot:=bots[1] as TPlayerBot;
      PlayerControlsIndex:=1;
    end else begin
      PlayerBot:=bots[0] as TPlayerBot;
      PlayerControlsIndex:=0;
    end;
    if RightInterface=32 then DrawHealthBar32(GameScreenStartX-32,gameScreenStartY,GameScreenEndY) else
    if RightInterface=128 then DrawInterface128(0);
  end;
{  PlayerBot:=bots[0] as TPlayerBot;
  medianW:=round((GameScreenEndX-GameScreenStartX)*PlayerBot.hp / PlayerBot.maxHp);
  median128:=round(118*PlayerBot.hp / PlayerBot.maxHp);
  HealthBar.Draw(GameScreenStartX+0,window.height-32,medianW,32,0,0,median128,32);
  emptyBar.Draw(GameScreenStartX+medianW,window.height-32,(GameScreenEndX-GameScreenStartX)-medianW,32,median128,0,118,32);}
end;

procedure doDisplayImages;
begin
  doDrawMap;
  doDrawBots;
  doDrawInterface;
end;

const music_averaging=600;
procedure doGame;
var i,nm:integer;
    enemyPower:integer;
    boss_present:boolean;
    EnemyHp,PlayerHp:integer;
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
  boss_present:=false;
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
        BotBossCrossFire,botBossCarrier,botBossMiner,botFIWI:boss_present:=true;
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
  if boss_present then music_context:=music_boss;

  //calculate total Hp of players and bots
  EnemyHP:=0; PlayerHP:=0;
  for i:=low(bots) to high(bots) do begin
    if bots[i] is TPlayerbot then inc(PlayerHp,bots[i].hp) else begin
      if bots[i].bottype=bot1 then inc(EnemyHp,bots[i].maxhp*2); //a tiny cheat to account for polymorphs
      if bots[i].bottype=bot2 then inc(EnemyHp,bots[i].maxhp);
      if (bots[i] as THostileBot).BornToBeABoss<>boss_none then inc(enemyHp,250);
      inc(EnemyHp,bots[i].hp)
    end;
  end;
  if (VictoryTimer<0) and ((PlayerHp=0) or (enemyHp=0)) then begin
    if (EnemyHp=0) then VictoryTimer:=now+3/60/60/24 else VictoryTimer:=now+6/60/60/24;
    doFadeOutMusic;
    //Music_context:=music_briefing;
    //then doLoadNewMusic;
  end;
  if (victoryTimer>0) and (victoryTimer<now) then begin
    Current_game_context:=gameplay_title;
    if Story_Stage>0 then begin
      if PlayerHP>0 then NextStoryStage else NextStoryStage(Story_rollback);
    end else
      begin NextStoryStage(999); end;
  end;
  //if situation changed significantly, reload music based on current context
  if victoryTimer<0 then begin
    if (old_music_context=music_titlescreen) {or (old_music_context=music_briefing)} then doLoadNewMusic else begin

      if (music_context=music_easy) and (old_music_context=music_hard) then doLoadNewMusic;
      if (music_context=music_hard) and (old_music_context=music_easy) then doLoadNewMusic;
      if (old_music_context<>music_hard) and (old_music_context<>music_boss) and (averageEnemyPower>25) then doLoadNewMusic;
      if (old_music_context=music_boss) and (music_context<>music_boss) then doLoadNewMusic;
      if (music_context=music_boss) and (old_music_context<>music_boss) then doLoadNewMusic;
    end;
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


procedure doWindowResize(Container: TUIContainer);
begin
 if Window.width<MinWindowWidth then window.Width:=MinWindowWidth;
 if Window.Height<MinWindowHeight then Window.Height:=MinWindowHeight;
 RescaleWindow:=true;
 PauseMode:=true;
 window.doRender;
end;

var RenderingBuisy:boolean=false;
procedure doWindowRender(Container: TUIContainer);
begin
  if firstrender then doLoadGameData;
  if current_game_context = gameplay_play then begin
    if startNewGame then doStartGame;

    if not RenderingBuisy then begin
      frameskip:=1;
      RenderingBuisy:=true;
      doGame;

      if RescaleWindow then begin
        doGetMapScale(false);
        ResizeButtons;
        RescaleWindow:=false;
      end;
      doDisplayImages;
      if PauseMode then imgPause.draw((window.width - imgPause.width) div 2,(window.height - imgPause.height) div 2);

      RenderingBuisy:=false;
    end else inc(frameskip);
  end else if current_game_context = gameplay_title then begin
    if not TitleReady then ShowTitle;
    TitleBackground.Draw(0,0,window.width,window.height);
    if RescaleWindow then begin
       ResizeButtons;
       RescaleWindow:=false;
    end;
    if screen_fadeout and (blackScreenIntensity<maxBlackIntensity) then inc(blackScreenIntensity) else screen_fadeOut:=false;
    if not screen_fadeout then
    if screen_fadein and (blackScreenIntensity>0) then dec(blackScreenIntensity) else screen_fadein:=false;
    if blackScreenIntensity>0 then doBlackScreen(blackScreenIntensity);
    case CurrentTitleDisplay of
      CurrentTitle_bestiary: doShowBestiary(ShowBestiary);
      CurrentTitle_prologue: doShowPrologue(showPrologue);
      CurrentTitle_credits: doShowCredits;
      CurrentTitle_title,currentTitle_mapSelect: doShowMainTitle;
    end;
  end;
  firstrender:=false;
end;

procedure doTimer;
begin
  window.DoRender;

  if (musicTimer<now) then doLoadNewMusic;
  if isMusicStart then doStartMusic;
  if isMusicCrossfade then doFadeOutMusic;

end;

{------------------------------------------------------------------------------------}
{====================================================================================}
{------------------------------------------------------------------------------------}

begin
MusicTimer:=now-1;
firstrender:=true;

InitCharSet;

//music_context:=music_easy;
Window:=TCastleWindow.create(Application);
window.DoubleBuffer:=true;
window.OnRender:=@doWindowRender;
window.OnResize:=@doWindowResize;

window.OnPress:=@MenuKeyPress;
window.onRelease:=@MenuKeyRelease;
window.OnMotion:=nil;

//map:=map_bedRoom;

window.Width:=800;
window.height:=600;

SetDifficultyLevelHard;

PlayerControls[2]:=TPlayerControls.create;
PlayerControls[3]:=TPlayerControls.create;
PlayerControls[0]:=PlayerControls[2];
PlayerControls[1]:=TPlayerControls.create;
PlayerControls[1].makeMoveControls(controls_TFGH);
PlayerControls[1].makeFireControls(controls_WASD);
PlayerControls[2].makeMoveControls(controls_cursor);
PlayerControls[2].makeFireControls(controls_WASD);
PlayerControls[3].makeMoveControls(controls_numbers);
PlayerControls[3].makeFireControls(controls_cursor);


player2Active:=false;

application.TimerMilisec:=1000 div 60; //60 fps
application.OnTimer:=@dotimer;
{=== this will start the game ===}
Window.Open;
Application.Run;
{=== ........................ ===}

end.

