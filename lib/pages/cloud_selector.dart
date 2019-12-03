import 'dart:async';

import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:slide_bar/slide_bar.dart';

import '../services/system.dart';
import 'package:flusic/utils/request.dart';
import 'package:flutter/material.dart';

class CloudSelector extends StatefulWidget {
  CloudSelector({this.index});
  final int index;
  @override
  CloudSelectorState createState() => CloudSelectorState();
}

class CloudSelectorState extends State<CloudSelector>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  SystemService service = new SystemService();
  final GlobalKey<RefreshIndicatorState> refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();

  int year = DateTime.now().year;
  List<int> years = [];
  List<Map<String, dynamic>> list = [];
  Map<String, dynamic> downList = {};
  ScrollController controller = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    int musicYear = (service.musicService.musicList.length >
                service.musicService.listening &&
            service.musicService.listening >= 0)
        ? service.musicService.musicList[service.musicService.listening]['year']
        : DateTime.now().year;
    if (musicYear != null && musicYear > 0) {
      year = musicYear;
    }
    super.initState();
    scheduleMicrotask(() {
      Request.getCacheList(year, service).then((cacheList) {
        if (cacheList.length == 0) {
          refreshIndicatorKey.currentState.show();
        } else {
          if (mounted) {
            setState(() {
              list = cacheList;
              scrollToListing();
            });
          }
        }
      });

      service.fileService.registerDownloadCallback(
          (String id, DownloadTaskStatus status, int progress) async {
        var task = list.where((o) {
          return o["taskId"] == id;
        }).toList();
        if (task.length > 0) {
          if (status == DownloadTaskStatus.enqueued ||
              status == DownloadTaskStatus.running ||
              status == DownloadTaskStatus.complete) {
            task.first["status"] = status;
            task.first["progress"] = progress;
          } else {
            await service.fileService
                .removeTask(task.first["taskId"].toString());
            task.first.remove("taskId");
            task.first.remove("status");
            task.first.remove("progress");
          }
        }
        setState(() {});
      });
    });

    Request.getYears().then((val) {
      setState(() {
        years = val;
      });
    });
  }

  bool isActive(int index) {
    return service.musicService.musicList
            .where((o) => o["title"] == list[index]["filename"])
            .length >
        0;
  }

  bool isPlaying(int index) {
    if (service.musicService.listening < 0) {
      return false;
    }

    return service.musicService.musicList[service.musicService.listening]
            ["title"] ==
        list[index]["filename"];
  }

  void scrollToListing() {
    if (service.musicService.listening >= 0) {
      double index = list
          .indexWhere((o) =>
              service.musicService.musicList[service.musicService.listening]
                  ["title"] ==
              o["filename"])
          .toDouble();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.animateTo(
          85.0 * (index >= 0 ? index : 0),
          curve: Curves.ease,
          duration: Duration(milliseconds: 300),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        appBar: AppBar(title: Text(year.toString()), actions: [
          PopupMenuButton<int>(
              icon: Icon(Icons.filter_list),
              itemBuilder: (context) {
                return years.asMap().keys.map((i) {
                  return PopupMenuItem(
                      value: i, child: Text(years[i].toString()));
                }).toList();
              },
              onSelected: (int value) async {
                refreshIndicatorKey.currentState.show();
                year = years[value];
              },
              onCanceled: () {})
        ]),
        body: RefreshIndicator(
          key: refreshIndicatorKey,
          onRefresh: () async {
            list = await Request.getList(year, service);
            setState(() {});
            scrollToListing();
          },
          child: ListView.separated(
            ///保持ListView任何情况都能滚动，解决在RefreshIndicator的兼容问题。
            physics: const AlwaysScrollableScrollPhysics(),
            controller: controller,
            itemBuilder: (context, index) {
              Widget leading;
              ActionItems action;
              ListTile listTile;
              if (list[index]["status"] == DownloadTaskStatus.complete) {
                leading = AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: IconButton(icon: Icon(Icons.done), onPressed: () {}),
                );
                action = ActionItems(
                    backgroudColor: Theme.of(context).dialogBackgroundColor,
                    icon: Icon(Icons.delete),
                    onPress: () async {
                      if (await showGeneralDialog<bool>(
                          barrierColor: Colors.black.withOpacity(0.5),
                          transitionBuilder: (context, a1, a2, widget) {
                            return Transform.scale(
                              scale: a1.value,
                              child: Opacity(
                                opacity: a1.value,
                                child: AlertDialog(
                                  title: new Text("是否删除"),
                                  content: new Text(
                                      "将会删除下载的${list[index]["filename"].toString()}"),
                                  actions: <Widget>[
                                    // usually buttons at the bottom of the dialog
                                    FlatButton(
                                      child: new Text("取消"),
                                      onPressed: () {
                                        Navigator.of(context).pop(false);
                                      },
                                    ),
                                    FlatButton(
                                      child: new Text("确认"),
                                      onPressed: () {
                                        Navigator.of(context).pop(true);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          transitionDuration: Duration(milliseconds: 200),
                          barrierDismissible: true,
                          barrierLabel: '',
                          context: context,
                          pageBuilder: (context, a1, a2) {
                            return;
                          })) {
                        await service.fileService
                            .cleanTask(list[index]["filename"]);
                        list[index].remove("taskId");
                        list[index].remove("status");
                        list[index].remove("progress");
                        setState(() {});
                      }
                    });
              } else if (list[index]["status"] == DownloadTaskStatus.enqueued ||
                  list[index]["status"] == DownloadTaskStatus.running) {
                var progress = (list[index]["progress"] ?? 0) / 100;
                leading = AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    child: GestureDetector(
                        onTap: () async {
                          if (await showGeneralDialog<bool>(
                              barrierColor: Colors.black.withOpacity(0.5),
                              transitionBuilder: (context, a1, a2, widget) {
                                return Transform.scale(
                                  scale: a1.value,
                                  child: Opacity(
                                    opacity: a1.value,
                                    child: AlertDialog(
                                      title: Text("取消任务"),
                                      content: Text(
                                          "是否取消${list[index]["filename"].toString()}下载"),
                                      actions: <Widget>[
                                        // usually buttons at the bottom of the dialog
                                        FlatButton(
                                          child: Text("否"),
                                          onPressed: () {
                                            Navigator.of(context).pop(false);
                                          },
                                        ),
                                        FlatButton(
                                          child: Text("是"),
                                          onPressed: () {
                                            Navigator.of(context).pop(true);
                                          },
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                              transitionDuration: Duration(milliseconds: 200),
                              barrierDismissible: true,
                              barrierLabel: '',
                              context: context,
                              pageBuilder: (context, a1, a2) {
                                return;
                              })) {
                            await service.fileService
                                .cancelTask(list[index]["taskId"]);
                          }
                        },
                        child: Stack(
                          alignment: AlignmentDirectional.center,
                          children: <Widget>[
                            Container(
                                width: 48,
                                height: 48,
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value: progress == 0 ? null : progress)),
                            Icon(Icons.stop)
                          ],
                        )));
              } else {
                leading = null;
                action = ActionItems(
                  backgroudColor: Theme.of(context).dialogBackgroundColor,
                  icon: Icon(Icons.file_download),
                  onPress: () async {
                    var taskId = await service.fileService.download(
                        list[index]["url"].toString(),
                        list[index]["filename"].toString());

                    setState(() {
                      list[index]["taskId"] = taskId;
                      list[index]["progress"] = 0;
                      list[index]["status"] = DownloadTaskStatus.running;
                    });
                  },
                );
              }

              List<Widget> title = [Text(list[index]["title"].toString())];
              if (isActive(index)) {
                title.add(Icon(Icons.flag));
              }
              if (isPlaying(index)) {
                title.add(Icon(Icons.play_arrow));
              }

              listTile = ListTile(
                  title: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: title,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        list[index]["filename"].toString(),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text("下载${list[index]["downloads"]?.toString()}次")
                    ],
                  ),
                  leading: leading,
                  trailing: Icon(Icons.keyboard_arrow_right),
                  onTap: () async {
                    await service.musicService.saveMusic(
                        index: widget.index,
                        year: year,
                        title: list[index]["filename"].toString(),
                        url: list[index]["url"].toString(),
                        taskId: list[index]["taskId"]?.toString());
                    Navigator.pop(context, true);
                  });
              if (list[index]["status"] == DownloadTaskStatus.enqueued ||
                  list[index]["status"] == DownloadTaskStatus.running) {
                return listTile;
              } else {
                return SlideBar(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    items: [action],
                    child: listTile);
              }
            },

            ///根据状态返回数量
            itemCount: list.length,
            separatorBuilder: (BuildContext context, int index) {
              return LayoutBuilder(builder: (context, constraints) {
                return Divider(
                  color: Colors.white,
                  indent: 12,
                  endIndent: 12,
                );
              });
            },
          ),
        ));
  }
}
