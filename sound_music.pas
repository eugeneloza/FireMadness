unit Sound_Music;

{$mode objfpc}{$H+}

interface

uses {$IFDEF UNIX}cthreads,{$ENDIF}sysUtils,Classes,
  CastleOpenAL, CastleSoundEngine, CastleTimeUtils, CastleVectors,
  general_var;

type TMusic_context=(music_easy,music_mid,music_hard,music_boss);
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
    nvoices:integer;
    sndVoice:array of TSoundBuffer;
    voiceDuration:array of TFloatTime;
    MyVoiceTimer:TDateTime;
    LastVoice:integer=-1;
    //music
    nowPlaying: TSound;
    musicGain,fadeGain: single;
    isMusicFading:boolean=false;
    isMusicPlaying:boolean=false;
    fadeDuration:float;
    FadeStart:TDateTime;
    music: TSoundBuffer;
    music_duration: TFloatTime;
    oldmusic:integer;
    MusicLoadThread:TMusicLoadThread; //thread to load music in background to avoid lags
    MyMusicTimer:TDateTime;
    MusicReady:boolean;
    music_context,old_music_context:TMusic_context;
    AverageEnemyPower:single=0;

procedure doLoadMusic;
procedure doPlayMusic;
procedure doLoadSound;

procedure doStartFadeOut;
procedure doFadeOut;

implementation

procedure doStartFadeOut;
begin
 if IsMusicPlaying then begin
   MyMusicTimer:=now+5/60/60/24;
   FadeStart:=now;
   isMusicFading:=true;
   fadeDuration:=2;
   fadeGain:=0; {actually,fade-out}
 end;
end;

procedure doFadeOut;
var tmp:single;
begin
 tmp:=musicGain+(fadeGain-musicGain)*((now-FadeStart)*60*60*24/fadeDuration);
 if (now-MyMusicTimer)*60*60*24>fadeDuration then begin
    tmp:=fadeGain;
    isMusicFading:=false;
    myMusicTimer:=now{+1/60/60/24};
 end;
 if tmp<0 then tmp:=0;
 nowPlaying.Gain:=tmp;
end;

procedure TMusicLoadThread.execute;
var nextmusic:integer;
    music_name:string;
begin
 isMusicFading:=false;
 old_music_context:=music_context;
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

{ {if music<>nil then }soundEngine.FreeBuffer(music);
 if nowPlaying<>nil then freeandnil(nowPlaying); }

 //start music
 music:=soundengine.loadbuffer(MusFolder+music_name,music_duration);
 //and finish
 oldmusic:=nextmusic;
 MyMusicTimer:=now+(music_duration)/60/60/24;
 MusicReady:=true;
end;

procedure doLoadMusic;
begin
 MusicReady:=false;
 //avoid simultaneously loading a few tracks
 MyMusicTimer:=now+1;
 Music_duration:=10000;
 //launching music through a thread to avoid lags both in music and gameplay
 MusicLoadThread:=TMusicLoadThread.Create(true);
 MusicLoadThread.FreeOnTerminate:=true;
 MusicLoadThread.Priority:=tpLower;
 MusicLoadThread.Start;
end;

procedure doPlayMusic;
begin
 musicGain:=1.0;
 isMusicPlaying:=true;
 nowPlaying:=SoundEngine.PlaySound(music, false, false, 10, musicGain, 0, 1, ZeroVector3Single);
 //nowPlaying.Gain:=0;
 //soundEngine.Sounds.*****;
 //soundEngine.Volume:=;
end;

procedure doLoadSound;
begin
 SndPlayerShot:= SoundEngine.LoadBuffer(SndFolder+'bookOpen_CC0_by_Kenney.nl.ogg');
 SndBotShot1:= SoundEngine.LoadBuffer(SndFolder+'beltHandle1_CC0_by_Kenney.nl.ogg');
 SndBotShot2:= SoundEngine.LoadBuffer(SndFolder+'beltHandle2_CC0_by_Kenney.nl.ogg');
 sndPlayerHit[1]:= SoundEngine.LoadBuffer(SndFolder+'hit21_CC0_by_Independent.nu.ogg');
 sndPlayerHit[2]:= SoundEngine.LoadBuffer(SndFolder+'hit23_CC0_by_Independent.nu.ogg');
 sndPlayerHit[3]:= SoundEngine.LoadBuffer(SndFolder+'hit24_CC0_by_Independent.nu.ogg');
 sndPlayerHit[4]:= SoundEngine.LoadBuffer(SndFolder+'hit25_CC0_by_Independent.nu.ogg');
 sndPlayerHit[5]:= SoundEngine.LoadBuffer(SndFolder+'hit31_CC0_by_Independent.nu.ogg');
 sndPlayerHit[6]:= SoundEngine.LoadBuffer(SndFolder+'hit35_CC0_by_Independent.nu.ogg');
 sndPlayerHitHard:= SoundEngine.LoadBuffer(SndFolder+'hit34+hit37_CC0_by_Independent.nu.ogg');
 sndBotHit[1]:= SoundEngine.LoadBuffer(SndFolder+'footstep01_CC0_by_Kenney.nl.ogg');
 sndBotHit[2]:= SoundEngine.LoadBuffer(SndFolder+'footstep02_CC0_by_Kenney.nl.ogg');
 sndBotHit[3]:= SoundEngine.LoadBuffer(SndFolder+'footstep03_CC0_by_Kenney.nl.ogg');
 sndBotHit[4]:= SoundEngine.LoadBuffer(SndFolder+'footstep04_CC0_by_Kenney.nl.ogg');
 sndBotHit[5]:= SoundEngine.LoadBuffer(SndFolder+'footstep05_CC0_by_Kenney.nl.ogg');
 sndBotHit[6]:= SoundEngine.LoadBuffer(SndFolder+'footstep06_CC0_by_Kenney.nl.ogg');
 sndBotHit[7]:= SoundEngine.LoadBuffer(SndFolder+'footstep07_CC0_by_Kenney.nl.ogg');
 sndBotHit[8]:= SoundEngine.LoadBuffer(SndFolder+'footstep08_CC0_by_Kenney.nl.ogg');
 sndBotHit[9]:= SoundEngine.LoadBuffer(SndFolder+'footstep09_CC0_by_Kenney.nl.ogg');
 sndExplosion:=  SoundEngine.LoadBuffer(SndFolder+'Hit_explosion_CC0_by_Independent.nu.ogg');
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
end;


end.

