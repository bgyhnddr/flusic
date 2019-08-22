import 'dart:async';

import 'package:flutter_downloader/flutter_downloader.dart';

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
    with AutomaticKeepAliveClientMixin {
  SystemService service = new SystemService();
  final GlobalKey<RefreshIndicatorState> refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();

  int year = DateTime.now().year;
  List<int> years = [];
  List<Map<String, dynamic>> list = [];
  Map<String, dynamic> downList = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(() {
      refreshIndicatorKey.currentState.show();

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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        appBar: AppBar(title: Text(year.toString()), actions: [
          IconButton(icon: Icon(Icons.ac_unit), onPressed: () {}),
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
          },
          child: ListView.builder(
            ///保持ListView任何情况都能滚动，解决在RefreshIndicator的兼容问题。
            physics: const AlwaysScrollableScrollPhysics(),

            ///根据状态返回子孔健
            itemBuilder: (context, index) {
              Widget leading;
              if (list[index]["status"] == DownloadTaskStatus.complete) {
                leading = IconButton(
                  icon: Icon(Icons.done),
                  onPressed: () {},
                );
              } else if (list[index]["status"] == DownloadTaskStatus.enqueued ||
                  list[index]["status"] == DownloadTaskStatus.running) {
                var progress = (list[index]["progress"] ?? 0) / 100;

                leading = GestureDetector(
                    onTap: () {
                      showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          // return object of type Dialog
                          return AlertDialog(
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
                          );
                        },
                      ).then((val) async {
                        if (val) {
                          await service.fileService
                              .cancelTask(list[index]["taskId"]);
                        }
                      });
                    },
                    child: Container(
                        width: 48,
                        height: 48,
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: progress == 0 ? null : progress)));
              } else {
                leading = IconButton(
                  icon: Icon(Icons.file_download),
                  onPressed: () async {
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

              return ListTile(
                title: Text(list[index]["title"].toString()),
                subtitle: Text(
                  list[index]["filename"].toString(),
                ),
                leading: AnimatedSwitcher(
                    duration: Duration(milliseconds: 300), child: leading),
                trailing: Icon(Icons.keyboard_arrow_right),
                onTap: () async {
                  await service.musicService.saveMusic(
                      index: widget.index,
                      title: list[index]["filename"].toString(),
                      url: list[index]["url"].toString(),
                      taskId: list[index]["taskId"]?.toString());
                  Navigator.pop(context, true);
                },
              );
            },

            ///根据状态返回数量
            itemCount: list.length,
          ),
        ));
  }
}
