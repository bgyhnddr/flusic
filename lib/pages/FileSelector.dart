import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import '../services/system.dart';

class FileSelector extends StatefulWidget {
  FileSelector({this.index});
  final int index;
  @override
  FileSelectorState createState() => FileSelectorState();
}

class FileSelectorState extends State<FileSelector> {
  SystemService service = new SystemService();
  Future<List<FileSystemEntity>> listFuture;
  List<FileSystemEntity> list = <FileSystemEntity>[];

  void getFiles({String path}) {
    setState(() {
      listFuture = service.fileService.getEntities(path: path);
    });
  }

  Widget buildLeading(FileSystemEntity file) {
    if (FileSystemEntity.isDirectorySync(file.path)) {
      return Icon(Icons.folder);
    } else {
      return Icon(Icons.insert_drive_file);
    }
  }

  Widget buildPathBar() {
    return new Column(
      children: <Widget>[
        new Container(
          height: 44.0,
          padding: const EdgeInsets.only(left: 14.0),
          child: new Row(
            children: <Widget>[
              new Expanded(
                  child: new Text(
                service.fileService.currentDirectory?.path ?? '',
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                softWrap: false,
              ))
            ],
          ),
        ),
        new Divider(height: 1.0)
      ],
    );
  }

  Widget buildContent() {
    return FutureBuilder(
        future: listFuture,
        builder: (BuildContext context,
            AsyncSnapshot<List<FileSystemEntity>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return new Center(
              child: new Text('waiting...'),
            );
          } else if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData && null != snapshot.data) {
              list = snapshot.data;
              return Column(children: [
                buildPathBar(),
                Expanded(
                    child: ListView.separated(
                  separatorBuilder: (BuildContext context, int index) =>
                      new Divider(),
                  itemBuilder: (BuildContext context, int index) {
                    if (index == 0 && !service.fileService.root) {
                      return ListTile(
                        title: Text('上一级'),
                        onTap: () {
                          getFiles(
                              path: service
                                  .fileService.currentDirectory.parent.path);
                        },
                      );
                    }

                    FileSystemEntity file =
                        list[service.fileService.root ? index : index - 1];

                    return ListTile(
                      leading: buildLeading(file),
                      title: Text(basename(file.path)),
                      onTap: () {
                        if (FileSystemEntity.isDirectorySync(file.path)) {
                          getFiles(path: file.path);
                        } else {
                          service.musicService
                              .saveMusic(index: widget.index, path: file.path);
                          Navigator.pop(context, true);
                        }
                      },
                    );
                  },
                  itemCount:
                      service.fileService.root ? list.length : list.length + 1,
                ))
              ]);
            } else {
              return new Container(
                child: new Center(child: new Text('无结果')),
              );
            }
          } else {
            return new Container(
              child: new Text('异常'),
            );
          }
        });
  }

  @override
  void initState() {
    super.initState();
    listFuture = service.fileService.getEntities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text("打开音频")), body: buildContent());
  }
}
