import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:slide_bar/slide_bar.dart';

import 'main_selector.dart';
import 'play.dart';
import '../services/system.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, dynamic>> musicList = List<Map<String, dynamic>>();
  SystemService service = new SystemService();

  String formatTime(int second) {
    if (null != second) {
      return DateFormat.Hms().format(
          DateTime.fromMillisecondsSinceEpoch(second * 1000, isUtc: true));
    }
    return '00:00:00';
  }

  void goPlay(BuildContext context, int index) {
    service.musicService.listening = index;
    Navigator.push(context,
        new MaterialPageRoute(builder: (BuildContext context) {
      return Play(index: index);
    })).then((val) {
      service.musicService.listening = -1;
      getData();
    });
  }

  Widget buildBody() {
    if (musicList.length == 0) {
      return Center(child: Text('无节目'));
    } else {
      return ReorderableListView(
        children: musicList.asMap().keys.map((index) {
          var item = musicList[index];
          return SlideBar(
            key: UniqueKey(),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            child: ListTile(
              title: Text(item["title"].toString()),
              subtitle: Text(formatTime(int.tryParse(item["time"].toString()))),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                goPlay(context, index);
              },
            ),
            items: [
              ActionItems(
                  backgroudColor: Theme.of(context).dialogBackgroundColor,
                  icon: Icon(Icons.delete),
                  onPress: () async {
                    if (await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        // return object of type Dialog
                        return AlertDialog(
                          title: new Text("是否删除"),
                          content: new Text(
                              "将会删除${musicList[index]["title"].toString()}"),
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
                        );
                      },
                    )) {
                      setState(() {
                        service.musicService.removeMusic(index);
                      });
                    }
                  })
            ],
          );
        }).toList(),
        onReorder: (int oldIndex, int newIndex) {
          setState(() {
            if (newIndex == musicList.length) {
              newIndex = musicList.length - 1;
            }
            var item = musicList.removeAt(oldIndex);
            musicList.insert(newIndex, item);
            service.musicService.setMusicList();
          });
        },
      );
    }
  }

  void getData() {
    setState(() {
      musicList = service.musicService.musicList;
    });
  }

  @override
  void initState() {
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('flusic'), actions: <Widget>[
          IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push<bool>(context,
                    MaterialPageRoute(builder: (BuildContext context) {
                  return MainSelector();
                })).then((bool val) {
                  if (val == true) {
                    getData();
                  }
                });
              }),
        ]),
        body: Center(
          child: buildBody(),
        ));
  }
}
