{$mode objfpc}{$H+}
library FireMadness_Android;
uses CastleAndroidNativeAppGlue, FireMadness, CastleMessaging;
exports
  Java_net_sourceforge_castleengine_MainActivity_jniMessage,
  ANativeActivity_onCreate;
end.
