import 'dart:io';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:toonfu/const/path.dart';
import 'package:yaml/yaml.dart';
import '../../common/log.dart';
import '../../const/general_const.dart';
import '../../const/lua_const.dart';
import '../../models/db/extensions.dart' as model_extensions;
import '../../types/manager/actions.dart';
import '../../types/provider/extension_provider.dart';
import '../../types/provider/setting_provider.dart';
import '../../utils/utils_general.dart';

class ExtensionsTab extends StatefulWidget {
  const ExtensionsTab({super.key});

  @override
  State<ExtensionsTab> createState() => _ExtensionsTabState();
}

class _ExtensionsTabState extends State<ExtensionsTab> {
  final List<model_extensions.Extension> _remoteExtensions = [];
  bool _isInitContext = false;
  bool _isLoadingRemote = false;
  bool _isInstalling = false; // 添加加载状态变量
  BuildContext? _buildCtx;

  @override
  void initState() {
    super.initState();
    _isLoadingRemote = true;
  }

  Future<void> _initWithContext(BuildContext context) async {
    if (_isInitContext) {
      return;
    }

    _isInitContext = true;
    List<String> sources = context.read<SettingProvider>().sources;
    await _loadRemoteExtensions(sources);
    _isLoadingRemote = false;
  }

  Future<void> _onRefresh() async {
    if (_isLoadingRemote) {
      return;
    }

    setState(() {
      _isLoadingRemote = true;
    });
    await _loadRemoteExtensions(context.read<SettingProvider>().sources);
    setState(() {
      _isLoadingRemote = false;
    });
  }

  Future<void> _loadRemoteExtensionsFromNet(String source) async {
    Dio dio = Dio();
    await dio.download(source, tempSrcDownloadPath);
    final srcFileContent = await File(tempSrcDownloadPath).readAsString();
    var doc = loadYaml(srcFileContent);
    for (var ext in doc[yamlExtensionKey]) {
      _remoteExtensions.add(model_extensions.Extension.fromYaml(ext));
    }
  }

  Future<void> _loadRemoteExtensionsFromFile(String path) async {
    final srcFileContent = await File(path).readAsString();
    var doc = loadYaml(srcFileContent);
    for (var ext in doc[yamlExtensionKey]) {
      _remoteExtensions.add(model_extensions.Extension.fromYaml(ext));
    }
  }

  Future<void> _loadRemoteExtensions(List<String> sources) async {
    for (var src in sources) {
      try {
        if (src.startsWith('http')) {
          await _loadRemoteExtensionsFromNet(src);
        } else {
          await _loadRemoteExtensionsFromFile(src);
        }
      } catch (e) {
        Log.instance.e('_loadRemoteExtensions error $src: $e');
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _downloadExtension(model_extensions.Extension extension) async {
    Dio dio = Dio();
    await dio.download(extension.url, tempExtDownloadPath);
    final bytes = await File(tempExtDownloadPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive) {
      String filename = file.name;
      if (filename.contains('/')) {
        filename = filename.substring(filename.indexOf('/') + 1);
      }
      print(filename);
      if (file.isFile) {
        final data = file.content as List<int>;
        File('$pluginDir/${extension.name}/$filename')
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      }
    }
  }

  Future<void> _copyLocalExtension(model_extensions.Extension extension) async {
    await copyDir(extension.url, '$pluginDir/${extension.name}');
  }

  Future<void> _installExtension(
      model_extensions.Extension extension, BuildContext buildContext) async {
    setState(() {
      _isInstalling = true; // 开始安装时设置为 true
    });

    try {
      if (extension.url.startsWith("http")) {
        await _downloadExtension(extension);
      } else {
        await _copyLocalExtension(extension);
      }
    } catch (e) {
      Log.instance.e('_installExtension error $extension: $e');
      setState(() {
        _isInstalling = false; // 安装完成后设置为 false
      });
      return;
    }

    var clone = extension.clone();
    clone.status = extensionStatusInstalled;

    if (_buildCtx != null) {
      print('updateExtension');
      _buildCtx!.read<ExtensionProvider>().updateExtension(clone);
    }
    actionsManager.resetMainLua();
    setState(() {
      _isInstalling = false; // 安装完成后设置为 false
    });
  }

  Future<bool?> _showInstallConfirmDialog(
      model_extensions.Extension extension) async {
    return await showCupertinoDialog<bool>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text('Install ${extension.name}?'),
          actions: [
            CupertinoButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel')),
            CupertinoButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Install')),
          ],
        );
      },
    );
  }

  Widget buildExtensionItem(model_extensions.Extension ext, bool isInstalled,
      BuildContext buildContext) {
    return GestureDetector(
      onTap: () async {
        if (isInstalled) {
          // TODO: show extension detail
        } else {
          if (await _showInstallConfirmDialog(ext) ?? false) {
            _installExtension(ext, buildContext);
          }
        }
      },
      child: Row(
        children: [
          Column(
            children: [
              Text(ext.name),
              Text(ext.version),
            ],
          ),
          Text(isInstalled ? 'status' : ''),
        ],
      ),
    );
  }

  Widget buildExtensionList(BuildContext context, String title,
      List<model_extensions.Extension>? exts, bool isInstalled) {
    return Expanded(
      child: Column(
        children: [
          Expanded(flex: 1, child: Text(title)),
          Expanded(
            flex: 9,
            child: EasyRefresh(
              onRefresh: _onRefresh,
              child: ListView.builder(
                itemCount: exts?.length ?? 0,
                itemBuilder: (context, index) {
                  return buildExtensionItem(exts![index], isInstalled, context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _buildCtx = context;
    _initWithContext(context);

    if (_isInstalling) {
      return const Center(child: CupertinoActivityIndicator()); // 显示加载指示器
    }

    return Row(
      children: [
        buildExtensionList(context, 'Installed',
            context.read<ExtensionProvider>().extensions, true),
        if (_isLoadingRemote)
          const CupertinoActivityIndicator()
        else
          buildExtensionList(context, 'Remote', _remoteExtensions, false),
      ],
    );
  }
}
