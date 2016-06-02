unit Sound_Music;

{$mode objfpc}{$H+}

interface

uses {$IFDEF UNIX}cthreads,{$ENDIF}sysUtils,Classes, castleFilesUtils,
  CastleOpenAL, CastleSoundEngine, CastleTimeUtils, CastleVectors,
  general_var;

const SoundExtension={$ifdef Android}'.wav'{$else}'.ogg'{$endif};

type TMusic_context=(music_easy,music_mid,music_hard,music_boss,music_TitleScreen);
type TMusicLoadThread = class(TThread)
  private
  protected
    procedure Execute; override;
end;

var
    //sounds
    SndPlayerShot,sndBotShot1,sndBotShot2:TSoundBuffer;
    sndPlayerHit:array[1..6] of TSoundBuffer;
    sndPlayerHitHard:TSoundBuffer;
    sndBotHit:array[1..9] of TSoundBuffer;
    sndExplosion:TSoundBuffer;
    sndPlayerDies:TSoundBuffer;
    sndDisabled:TSoundBuffer;
    nvoices:integer;
    sndVoice:array of TSoundBuffer;
    voiceDuration:array of TFloatTime;
    MyVoiceTimer:TDateTime;
    LastVoice:integer=-1;
    //music
    MusicLoadThread:TMusicLoadThread; //thread to load music in background to avoid lags
{
    musicGain,fadeGain: single;
    isMusicFading:boolean=false;
    isMusicPlaying:boolean=false;
    fadeDuration:float;
    FadeStart:TDateTime;
    music_duration: TFloatTime;
    aMusicTimer:TDateTime;
    MusicReady:boolean;  }
    nowPlaying: array[0..1] of TSound;
    music: array[0..1] of TSoundBuffer;
    old_music:integer=-1;
    new_music_array_index:integer=-1;
    old_music_array_index:integer=-1;
    isMusicStart:boolean=false;
    isMusicLoading:Boolean=false;
    isMusicCrossfade:Boolean=false;
    MUSIC_IS_LOADING_DONT_TOUCH_IT:boolean=false;
    MusicTimer,crossfade_timer:TDateTime;
    music_context,old_music_context:TMusic_context;
    AverageEnemyPower:single=0;

procedure doLoadNewMusic;
procedure doFadeOutMusic;
procedure doStartMusic;
procedure doLoadSound;

implementation
const musicGain=1.0;
      fadeGain=0.0;
var crossfadeDuration:float;

procedure doFadeOutMusic;
var gain_old:float;
    Curve:float;
begin
  {if (not isMusicLoading) and (old_music_array_index>=0) then} begin
  isMusicLoading:=false;
  isMusicStart:=false;
  isMusicCrossfade:=true;
  MUSIC_IS_LOADING_DONT_TOUCH_IT:=true;

    if not isMusicCrossfade then begin
      old_music_array_index:=new_music_array_index;
      new_music_array_index:=-1;
      isMusicCrossfade:=true;
      CrossFade_Timer:=now;
      CrossFadeDuration:=0.5;
    end;
    Curve:=(now-CrossFade_Timer)*60*60*24/crossfadeDuration;
    gain_old:=musicGain-(musicGain-fadeGain)*curve;
    if (curve>1) or (old_music_array_index=-1) then begin
       gain_old:=fadeGain;
       isMusicCrossfade:=false;
       MUSIC_IS_LOADING_DONT_TOUCH_IT:=false;
    end;
    if gain_old<0 then gain_old:=0;
    if (old_music_array_index>=0) then
      nowPlaying[old_music_array_index].Gain:=gain_old;
//     if curve>1 then old_music_array_index:=-1;
  end;

end;

procedure doStartMusic;
begin
 if (not isMusicLoading) and (not isMusicCrossfade){ and (not MUSIC_IS_LOADING_DONT_TOUCH_IT)} then begin
  nowPlaying[new_music_array_index]:=SoundEngine.PlaySound(music[new_music_array_index], false, false, 10, musicGain, 0, 1, ZeroVector3Single);

  isMusicLoading:=false;
  isMusicStart:=false;
  isMusicCrossfade:=true;
  MUSIC_IS_LOADING_DONT_TOUCH_IT:=true;

  CrossFadeDuration:=1;
  CrossFade_Timer:=now;
 end;
end;


procedure doLoadNewMusic;
begin
 if (not MUSIC_IS_LOADING_DONT_TOUCH_IT) and (not isMusicLoading) and (not isMusicCrossfade) then begin
   //launching music through a thread to avoid lags both in music and gameplay

   isMusicLoading:=true;
   isMusicStart:=false;
   isMusicCrossfade:=false;
   MUSIC_IS_LOADING_DONT_TOUCH_IT:=true;

   MusicLoadThread:=TMusicLoadThread.Create(true);
   MusicLoadThread.FreeOnTerminate:=true;
   MusicLoadThread.Priority:=tpLower;
   MusicLoadThread.Start;
 end;
end;

var music_duration:TFloatTime;
procedure TMusicLoadThread.execute;
var next_music:integer;
   music_name:string;
begin
  old_music_context:=music_context;
  if (music_context=music_boss) and (old_music=7) then music_context:=music_hard;
  if (music_context=music_TitleScreen) then next_music:=9 {else
  if (music_context=music_briefing) then next_music:=9  }
  else
  repeat
    case music_context of
      music_easy: next_music:=random(3);
      music_mid: next_music:=3+random(2);
      music_hard: next_music:=5+random(2);
      music_boss: if old_music<>7 then next_music:=7 else next_music:=6;
    end;
  until (next_music<>old_music);
  //load the track
  case next_music of
      0: music_name:='1_cannontube_CC-BY_by_Gundatsch';
      1: music_name:='1_Isthissupposedtobehere_CC-BY_by_Gundatsch';
      2: music_name:='1_misanthropy-low_CC-BY_by_Gundatsch';
      3: music_name:='2_cannontube_loop_medium_CC-BY_by_Gundatsch';
      4: music_name:='2_InnerCore_Low_CC-BY_by_Gundatsch';
      5: music_name:='3_destoroya_CC-BY_by_Gundatsch';
      6: music_name:='3_Magerbruchstand_CC-BY_by_Gundatsch';
      7: music_name:='4_ABoarInTheBushesFull_CC-BY_by_Gundatsch_01';
      9: music_name:='FragileCeiling-LQ_CC-BY_by_Gundatsch';
  end;
  music_name+=SoundExtension;

  //start music
  old_music_array_index:=new_music_array_index;
  if new_music_array_index=0 then new_music_array_index:=1 else new_music_array_index:=0;
  if old_Music<>next_music then begin
     { if nowPlaying<>nil then freeandnil(nowPlaying); }
     //soundEngine.FreeBuffer(music);
     music[new_music_array_index]:=soundengine.loadbuffer(ApplicationData(MusFolder+music_name),music_duration);
     old_music:=next_music;
  end else begin
     music[new_music_array_index]:=music[old_music_array_index];
     old_music_array_index:=-1;
  end;
  //and finish
  MusicTimer:=now+(music_duration)/60/60/24;

  isMusicLoading:=false;
  isMusicStart:=true;
  isMusicCrossfade:=false;
end;

{---------------------------------------------------------------------------------}

function GetSound(const SoundString:string):TSoundBuffer;
begin
  result:=SoundEngine.LoadBuffer(ApplicationData(sndFolder+SoundString+SoundExtension));
end;

function GetVoice(const VoiceString:string; var DurationVoc:TFloatTime ):TSoundBuffer;
begin
 result:=SoundEngine.LoadBuffer(ApplicationData(VocFolder+VoiceString+SoundExtension),DurationVoc);
end;

procedure doLoadSound;
begin
 SndPlayerShot:= GetSound('bookOpen_CC0_by_Kenney.nl');
 SndBotShot1:= GetSound('beltHandle1_CC0_by_Kenney.nl');
 SndBotShot2:= GetSound('beltHandle2_CC0_by_Kenney.nl');
 sndPlayerHit[1]:= GetSound('hit21_CC0_by_Independent.nu');
 sndPlayerHit[2]:= GetSound('hit23_CC0_by_Independent.nu');
 sndPlayerHit[3]:= GetSound('hit24_CC0_by_Independent.nu');
 sndPlayerHit[4]:= GetSound('hit25_CC0_by_Independent.nu');
 sndPlayerHit[5]:= GetSound('hit31_CC0_by_Independent.nu');
 sndPlayerHit[6]:= GetSound('hit35_CC0_by_Independent.nu');
 sndPlayerHitHard:= GetSound('hit34+hit37_CC0_by_Independent.nu');
 sndBotHit[1]:= GetSound('footstep01_CC0_by_Kenney.nl');
 sndBotHit[2]:= GetSound('footstep02_CC0_by_Kenney.nl');
 sndBotHit[3]:= GetSound('footstep03_CC0_by_Kenney.nl');
 sndBotHit[4]:= GetSound('footstep04_CC0_by_Kenney.nl');
 sndBotHit[5]:= GetSound('footstep05_CC0_by_Kenney.nl');
 sndBotHit[6]:= GetSound('footstep06_CC0_by_Kenney.nl');
 sndBotHit[7]:= GetSound('footstep07_CC0_by_Kenney.nl');
 sndBotHit[8]:= GetSound('footstep08_CC0_by_Kenney.nl');
 sndBotHit[9]:= GetSound('footstep09_CC0_by_Kenney.nl');
 sndExplosion:= GetSound('Hit_explosion_CC0_by_Independent.nu');
 sndDisabled:=GetSound('magnet_action_flangerplus_CC0_by_legoluft');

 nVoices:=6;
 setlength(sndVoice,nVoices);
 setlength(VoiceDuration,nVoices);
 sndPlayerDies:=GetVoice('PlayerDie_by_EugeneLoza+Independent.nu',VoiceDuration[0]{dummy});
 //load voice file
 sndVoice[0]:= GetVoice('anchor_action_CC0_by_legoluft',VoiceDuration[0]);
 sndVoice[1]:= GetVoice('anchor_action_chorus_CC0_by_legoluft',VoiceDuration[1]);
 sndVoice[2]:= GetVoice('anchor_action_flanger_CC0_by_legoluft',VoiceDuration[2]);
 sndVoice[3]:= GetVoice('anchor_action_industry_CC0_by_legoluft',VoiceDuration[3]);
 sndVoice[4]:= GetVoice('exit__CC0_by_legoluft',VoiceDuration[4]);
 sndVoice[5]:= GetVoice('magnet_action_industry_CC0_by_legoluft',VoiceDuration[5]);
 //initialize Sound Engine
 SoundEngine.ParseParameters;
 SoundEngine.MinAllocatedSources := 1;
end;


end.

