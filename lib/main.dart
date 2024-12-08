// import 'dart:isolate';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:toonfu/const/general_const.dart';
import 'package:toonfu/types/provider/extension_provider.dart';
import 'package:provider/provider.dart';
import 'package:toonfu/types/provider/setting_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:toonfu/models/db/settings.dart';
import 'package:toonfu/models/db/extensions.dart';
import 'package:toonfu/models/db/comic_model.dart';
import 'package:toonfu/types/provider/comic_provider.dart';
import 'package:toonfu/views/pages/splash.dart';

import 'common/log.dart';
import 'const/assets_const.dart';
import 'const/color_const.dart';
import 'const/db_const.dart';
import 'models/db/read_history_model.dart';
import 'types/provider/local_provider.dart';
import 'types/provider/task_provider.dart';
import 'utils/utils_general.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _main();
}

Future<void> _main() async {
  // Isolate.spawn<void>(luaLoop, null);
  try {
    await initDirectory();
    Hive.init(Directory.current.path);
    await Hive.initFlutter();
    await Hive.openBox(taskHiveKey);
    Hive.registerAdapter(SettingsAdapter());
    Hive.registerAdapter(ExtensionAdapter());
    Hive.registerAdapter(ExtensionsAdapter());
    Hive.registerAdapter(ComicModelAdapter());
    Hive.registerAdapter(ChapterModelAdapter());
    Hive.registerAdapter(ReadHistoryModelAdapter());

    String targetPath = '';
    if (Platform.isWindows) {
      targetPath = '$cbzDir\\tutorial.zip';
    } else {
      targetPath = '$cbzDir/tutorial.zip';
    }

    if (File(targetPath).existsSync()) {
      Log.instance.i('tutorial zip already exists');
    } else {
      // create dir cbz
      await Directory(cbzDir).create(recursive: true);
      await assetToFile(tutorialZip, targetPath);
    }
  } catch (e, s) {
    Log.instance.e('Hive init error e:$e, s:$s');
  }

  Log.instance.i('ready to run app');

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => SettingProvider()),
      ChangeNotifierProvider(create: (_) => ExtensionProvider()),
      ChangeNotifierProvider(create: (_) => ComicProvider()),
      ChangeNotifierProvider(create: (_) => TaskProvider()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // call provider
    return ScreenUtilInit(
      designSize: const Size(1179, 2556),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return ChangeNotifierProvider(
          create: (context) => LocalProvider(),
          child: Consumer<LocalProvider>(
            builder: (context, localProvider, child) {
              return CupertinoApp(
                locale: localProvider.locale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('en'),
                  Locale('zh'),
                ],
                title: 'ToonFu',
                theme: const CupertinoThemeData(
                  primaryColor: primaryTextColor,
                  primaryContrastingColor: CupertinoColors.systemYellow,
                  barBackgroundColor: CupertinoColors.white,
                  scaffoldBackgroundColor: CupertinoColors.white,
                  brightness: Brightness.light,
                ),
                home: const SplashScreen(),
              );
            },
          ),
        );
      },
    );
  }
}
