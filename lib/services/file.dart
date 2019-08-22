import 'dart:io';
import 'dart:async';
import 'package:flusic/utils/constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_ex/path_provider_ex.dart';
import 'package:flutter/foundation.dart' show required;
import 'package:simple_permissions/simple_permissions.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'system.dart';
import 'package:path/path.dart';

enum DirType { all, loveq, flusic }

class FileService {
  static FileService _cache;

  factory FileService({SystemService systemService}) {
    if (null == _cache) {
      _cache = new FileService._internal(systemService: systemService);
    }
    return _cache;
  }

  FileService._internal({@required SystemService systemService});

  final SystemService service = new SystemService();

  bool _havePermission = false;
  Directory currentDirectory;

  /// check directory permission
  Future<bool> checkPermission() async {
    if (service.isAndroid) {
      /// on android
      print('on android');
      print('check external directory permission');

      if (true == _havePermission) {
        print('have permission: $_havePermission');
        return _havePermission;
      }

      /// check write permission
      bool havePermission = await SimplePermissions.checkPermission(
          Permission.WriteExternalStorage);

      if (true == havePermission) {
        // have write permission
        print('have write permission');
        _havePermission = true;
      } else {
        /// have not wirte permission, request it
        print('have not write permission, request it');
        PermissionStatus requestPermission =
            await SimplePermissions.requestPermission(
                Permission.WriteExternalStorage);
        if (PermissionStatus.authorized == requestPermission) {
          print('request external directroy permission successful.');
          _havePermission = true;
        } else {
          print('request external directroy permission failed.');
        }
      }
    } else if (service.isIOS) {
      /// TODO: check permission on iOS
      print('something need to be done on iOS');
    } else if (service.isFuchsia) {
      /// TODO: check permission on fuchsia
      print('something need to be done on Fuchsia');
    }
    return _havePermission;
  }

  Directory rootDirectory;

  /// valid only after checkAppDirectory has been called.
  bool canUp(FileSystemEntity currentEntity) {
    return null != currentEntity && currentEntity.path != rootDirectory.path;
  }

  /// get FileSystemEntities from directory
  Future<List<FileSystemEntity>> getEntities(
      {String path, DirType type = DirType.flusic}) async {
    print('getEntities');
    if (!await checkPermission()) {
      print('get entities failed');
      return null;
    }

    if (type == DirType.flusic) {
      rootDirectory = await getApplicationSupportDirectory();
    } else {
      List<StorageInfo> info = await PathProviderEx.getStorageInfo();
      rootDirectory = Directory(info?.first?.rootDir);
    }

    if (path == null) {
      path = service.getString(current_path);
      if (path == null) {
        path = rootDirectory.path;
      }
    }

    if (path.indexOf(rootDirectory.path) < 0) {
      path = rootDirectory.path;
    }

    currentDirectory = Directory(path);

    service.setString(current_path, currentDirectory.path);

    if (null != currentDirectory &&
        currentDirectory.existsSync() &&
        FileSystemEntity.isDirectorySync(currentDirectory.path)) {
      /// signle directory

      var fileList = currentDirectory.listSync();
      if (currentDirectory.path == rootDirectory.path &&
          type == DirType.loveq) {
        int loveqIndex = fileList.indexWhere((item) {
          return basename(item.path).toLowerCase() == "loveq";
        });
        fileList = [fileList[loveqIndex]];
      }
      return fileList;
    }

    return null;
  }

  bool get root {
    return rootDirectory.path == currentDirectory.path;
  }

  /// download
  static Map<String, dynamic> downList = {};

  void registerDownloadCallback(callback) {
    FlutterDownloader.registerCallback(
        (String id, DownloadTaskStatus status, int progress) {
      callback(id, status, progress);
    });
  }

  Future<String> download(String url, String filename) async {
    var dir = await getApplicationSupportDirectory();
    var path = Directory("${dir.path}/download");
    if (!await checkPermission()) {
      print('get entities failed');
      return null;
    }
    if (!path.existsSync()) {
      path.createSync();
    }

    var existsTask = await getTaskByFilename('$filename');
    if (existsTask.length > 0) {
      for (var i = 0; i < existsTask.length; i++) {
        await FlutterDownloader.remove(taskId: existsTask[i].taskId);
      }
    }

    final taskId = await FlutterDownloader.enqueue(
      url: url,
      savedDir: path.path,
      fileName: '$filename',
      showNotification:
          true, // show download progress in status bar (for Android)
      openFileFromNotification:
          false, // click on notification to open downloaded file (for Android)
    );
    return taskId;
  }

  Future<List<DownloadTask>> getTaskByTaskId(String taskId) async {
    final tasks = await FlutterDownloader.loadTasksWithRawQuery(
        query: 'SELECT * FROM task where task_id="$taskId"');
    return tasks;
  }

  Future<List<DownloadTask>> getTaskByFilename(String filename) async {
    final tasks = await FlutterDownloader.loadTasksWithRawQuery(
        query: 'SELECT * FROM task where file_name="$filename"');
    return tasks;
  }

  cancelTask(String taskId) async {
    await FlutterDownloader.cancel(taskId: taskId);
  }

  removeTask(String taskId) async {
    await FlutterDownloader.remove(taskId: taskId);
  }

  cleanTask(String filename) async {
    await FlutterDownloader.loadTasksWithRawQuery(
        query: 'delete FROM task where file_name="$filename"');
  }
}
