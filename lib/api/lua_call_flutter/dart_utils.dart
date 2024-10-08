import 'package:lua_dardo_co/lua.dart';
import 'dart:io';

import 'package:toonfu/const/lua_const.dart';

class UtilsLib {
  static const Map<String, DartFunction> _utilsFuncs = {
    "cwd": _cwd,
    "main_dir": _mainDir,
    "plugin_dir": _pluginDir,
  };

  static int openUtilsLib(LuaState ls) {
    ls.newLib(_utilsFuncs);
    return 1;
  }

  static int _cwd(LuaState ls) {
    ls.pushString(Directory.current.path);
    return 1;
  }

  static int _mainDir(LuaState ls) {
    ls.pushString(mainDir);
    return 1;
  }

  static int _pluginDir(LuaState ls) {
    ls.pushString(pluginDir);
    return 1;
  }
}
