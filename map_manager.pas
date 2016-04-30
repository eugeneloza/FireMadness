unit map_manager;

{$mode objfpc}{$H+}

interface

uses general_var;

type TDifficultyStyle=(difficulty_easy,difficulty_normal,difficulty_hard,difficulty_insane);

type TDifficulty=record
  DifficultyStyle:TDifficultyStyle;
  simultaneous_active:integer;
  EnemyFirePowerMultiplier,EnemySpawnRateMultiplier,EnemyHealingMultiplier,EnemyRangeMultiplier,EnemyHealthMultiplier:float;
  PlayerHealthMultiplier:float;
end;

const Singleplayer_insane:TDifficulty=
 (DifficultyStyle:difficulty_insane;
  simultaneous_active:4;
  EnemyFirepowerMultiplier:1.1;
  EnemySpawnRateMultiplier:1.1;
  EnemyHealingMultiplier:1.3;
  EnemyRangeMultiplier:2;
  EnemyHealthMultiplier:1.5;
  PlayerHealthMultiplier:1.3);

const Singleplayer_hard:TDifficulty=
 (DifficultyStyle:difficulty_hard;
  simultaneous_active:3;
  EnemyFirepowerMultiplier:1.0;
  EnemySpawnRateMultiplier:1.0;
  EnemyHealingMultiplier:1.0;
  EnemyRangeMultiplier:1.5;
  EnemyHealthMultiplier:1.0;
  PlayerHealthMultiplier:1);

const Singleplayer_normal:TDifficulty=
 (DifficultyStyle:difficulty_normal;
  simultaneous_active:3;
  EnemyFirepowerMultiplier:0.9;
  EnemySpawnRateMultiplier:0.9;
  EnemyHealingMultiplier:1.0;
  EnemyRangeMultiplier:1.2;
  EnemyHealthMultiplier:1.0;
  PlayerHealthMultiplier:1);

const Singleplayer_easy:TDifficulty=
 (DifficultyStyle:difficulty_easy;
  simultaneous_active:2;
  EnemyFirepowerMultiplier:0.8;
  EnemySpawnRateMultiplier:0.8;
  EnemyHealingMultiplier:0.9;
  EnemyRangeMultiplier:1.0;
  EnemyHealthMultiplier:0.8;
  PlayerHealthMultiplier:1);

const hotSeatDifficultyMultiplier=1.5;

{maxx=2*(5+1); {not odd}
maxy=2*(4+1);}
type TMapType=record
  maxx,maxy:integer;
  PlayerHealth:integer;
  floorTile,WallTile:integer;
  nenemies:integer;
  bots_shielder,bots_heavy,bots_healer,bots_Teleporter,bots_autohealer,bots_disabler:integer;
  Crossfire_bosses,Carrier_bosses,Miner_bosses:integer;
  fiwi:boolean;
end;

const map_FIWI:TMapType=
 (maxx:2*(5+1);
  maxy:2*(4+1);
  playerHealth:300;
  floorTile:0;
  WallTile:2;
  nenemies:0;
  bots_shielder   :0;
  bots_heavy      :0;
  bots_healer     :0;
  bots_Teleporter :0;
  bots_autohealer :0;
  bots_disabler   :0;
  crossfire_bosses:0;
  carrier_bosses  :0;
  Miner_bosses    :0;
  fiwi:true);

const map_bedroom:TMapType=
 (maxx:2*(4+1);
  maxy:2*(4+1);
  playerHealth:300;
  floorTile:10;
  WallTile:4;
  nenemies:2*(4+1)+2*(4+1);
  bots_shielder   :0;
  bots_heavy      :0;
  bots_healer     :0;
  bots_Teleporter :0;
  bots_autohealer :0;
  bots_disabler   :2;
  crossfire_bosses:0;
  carrier_bosses  :0;
  Miner_bosses    :0;
  fiwi:false);

const map_LivingRoom:TMapType=
 (maxx:2*(5+1);
  maxy:2*(4+1);
  playerHealth:300;
  floorTile:11;
  WallTile:3;
  nenemies:2*(5+1)+2*(4+1);
  bots_shielder   :0;
  bots_heavy      :3;
  bots_healer     :0;
  bots_Teleporter :3;
  bots_autohealer :0;
  bots_disabler   :0;
  crossfire_bosses:2;
  carrier_bosses  :0;
  Miner_bosses    :0;
  fiwi:false);

const map_Cellar:TMapType=
 (maxx:2*(5+1);
  maxy:2*(4+1);
  playerHealth:300;
  floorTile:7;
  WallTile:1;
  nenemies:2*(5+1)+2*(3+1)-8;
  bots_shielder   :3;
  bots_heavy      :3;
  bots_healer     :0;
  bots_Teleporter :0;
  bots_autohealer :2;
  bots_disabler   :0;
  crossfire_bosses:0;
  carrier_bosses  :0;
  Miner_bosses    :1;
  fiwi:false);

const map_Kitchen:TMapType=
 (maxx:2*(5+1);
  maxy:2*(4+1);
  playerHealth:300;
  floorTile:6;
  WallTile:0;
  nenemies:2*(5+1)+2*(4+1)-8;
  bots_shielder   :0;
  bots_heavy      :1;
  bots_healer     :3;
  bots_Teleporter :0;
  bots_autohealer :0;
  bots_disabler   :1;
  crossfire_bosses:0;
  carrier_bosses  :1;
  Miner_bosses    :0;
  fiwi:false);

const map_NarrowCellar:TMapType=
 (maxx:2*(5+1);
  maxy:2*(3+1);
  playerHealth:400;
  floorTile:7;
  WallTile:1;
  nenemies:2*(5+1)+2*(3+1);
  bots_shielder   :3;
  bots_heavy      :3;
  bots_healer     :0;
  bots_Teleporter :0;
  bots_autohealer :2;
  bots_disabler   :0;
  crossfire_bosses:1;
  carrier_bosses  :0;
  Miner_bosses    :1;
  fiwi:false);

const map_Crossfire:TMapType=
 (maxx:2*(6+1);
  maxy:2*(5+1);
  playerHealth:200;
  floorTile:-1;
  WallTile:-1;
  nenemies:2*(6+1)+2*(5+1);
  bots_shielder   :0;
  bots_heavy      :0;
  bots_healer     :0;
  bots_Teleporter :0;
  bots_autohealer :0;
  bots_disabler   :0;
  crossfire_bosses:2;
  carrier_bosses  :0;
  Miner_bosses    :0;
  fiwi:false);

const map_Test:TMapType=
 (maxx:2*(5+1);
  maxy:2*(4+1);
  playerHealth:300;
  floorTile:-1;
  WallTile:-1;
  nenemies:12;
  bots_shielder   :1;
  bots_heavy      :1;
  bots_healer     :1;
  bots_Teleporter :1;
  bots_autohealer :1;
  bots_disabler   :1;
  crossfire_bosses:1;
  carrier_bosses  :1;
  Miner_bosses    :1;
  fiwi:false);

var DifficultyLevel:TDifficulty;
    currentDifficultyLevel:TDifficultyStyle;
    Map:TMapType;
    maxx,maxy:integer;
    NPlayers:integer;


implementation

end.

