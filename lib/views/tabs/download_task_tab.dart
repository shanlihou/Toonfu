import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../const/assets_const.dart';
import '../../const/general_const.dart';
import '../../models/db/comic_model.dart';
import '../../types/context/extension_comic_reader_context.dart';
import '../../types/provider/comic_provider.dart';
import '../../types/provider/task_provider.dart';
import '../../types/task/task_download.dart';
import '../../utils/utils_general.dart';
import '../pages/reader_page.dart';

class DownloadTaskTab extends StatefulWidget {
  const DownloadTaskTab({super.key});

  @override
  State<DownloadTaskTab> createState() => _DownloadTaskTabState();
}

void _gotoReaderPage(BuildContext context, TaskDownload task) {
  ComicProvider p = context.read<ComicProvider>();
  String uniqueId = getComicUniqueId(task.comicId, task.extensionName);
  ComicModel? comicModel = p.getComicModel(uniqueId);
  if (comicModel == null) {
    return;
  }

  Navigator.push(
    context,
    CupertinoPageRoute(
        builder: (context) => ReaderPage(
            readerContext: ExtensionComicReaderContext(task.extensionName,
                task.comicId, task.chapterId, null, comicModel.extra))),
  );
}

class _DownloadTaskTabState extends State<DownloadTaskTab> {
  Widget _buildTaskStatus(TaskDownload task) {
    if (task.status == TaskStatus.running) {
      return Text(
        style: TextStyle(color: const Color.fromARGB(255, 18, 148, 199)),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        '${task.currentCount}/${task.imageCount}',
      );
    } else if (task.status == TaskStatus.finished) {
      return GestureDetector(
        onTap: () => _gotoReaderPage(context, task),
        child: Image.asset(goToRead),
      );
    } else if (task.status == TaskStatus.failed) {
      return const Icon(CupertinoIcons.xmark_circle,
          color: CupertinoColors.systemRed);
    }

    return Text(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      task.status.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        var tasks = provider.getTasks();
        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            var task = tasks[index];
            return GestureDetector(
              onLongPress: () {
                provider.removeTask(task.id);
              },
              child: Container(
                width: double.infinity,
                color: CupertinoColors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (index != 0)
                      Container(
                        height: 1,
                        margin: EdgeInsets.only(left: 40.w, right: 40.w),
                        color: CupertinoColors.separator,
                      ),
                    Container(
                      margin: EdgeInsets.only(
                          left: 80.w, right: 80.w, top: 20.h, bottom: 20.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                              width: 400.w,
                              child: Text(
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  task.displayText())),
                          SizedBox(
                              width: 200.w,
                              height: 80.h,
                              child: _buildTaskStatus(task)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}