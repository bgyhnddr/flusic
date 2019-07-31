import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'FileSelector.dart';
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

  Widget buildBody() {
    if (musicList.length == 0) {
      return Center(child: Text('无节目'));
    } else {
      return ListView.separated(
        separatorBuilder: (BuildContext context, int index) => new Divider(),
        itemBuilder: (BuildContext context, int index) {
          var item = musicList[index];
          return Dismissible(
            key: Key(UniqueKey().toString()),
            confirmDismiss: (direction) async {
              bool result = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  // return object of type Dialog
                  return AlertDialog(
                    title: new Text("是否删除"),
                    content:
                        new Text("将会删除${musicList[index]["title"].toString()}"),
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
              );
              return result;
            },
            onDismissed: (direction) {
              setState(() {
                service.musicService.removeMusic(index);
              });
            },
            background: Align(
                alignment: FractionalOffset.centerRight,
                child: Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(Icons.delete))),
            child: ListTile(
              title: Text(item["title"].toString()),
              subtitle: Text(formatTime(int.tryParse(item["time"].toString()))),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(context,
                    new MaterialPageRoute(builder: (BuildContext context) {
                  return Play(index: index);
                })).then((val) {
                  getData();
                });
              },
            ),
          );
        },
        itemCount: musicList.length,
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
                  return FileSelector();
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
