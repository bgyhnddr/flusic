import 'dart:io';
import 'dart:async';
import 'package:flusic/utils/constants.dart';
import 'package:path_provider_ex/path_provider_ex.dart';
import 'package:flutter/foundation.dart' show required;
import 'package:simple_permissions/simple_permissions.dart';
import 'system.dart';

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

      /// check read permission
      bool havePermission = await SimplePermissions.checkPermission(
          Permission.ReadExternalStorage);

      if (true == havePermission) {
        // have read permission
        print('have read permission');
        _havePermission = true;
      } else {
        /// have not wirte permission, request it
        print('have not read permission, request it');
        PermissionStatus requestPermission =
            await SimplePermissions.requestPermission(
                Permission.ReadExternalStorage);
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
  Future<List<FileSystemEntity>> getEntities({String path}) async {
    print('getEntities');
    if (!await checkPermission()) {
      print('get entities failed');
      return null;
    }

    if (null == rootDirectory) {
      List<StorageInfo> info = await PathProviderEx.getStorageInfo();
      rootDirectory = Directory(info?.first?.rootDir);
    }

    if (path == null) {
      path = service.getString(current_path);
    }

    currentDirectory = path == null ? rootDirectory : Directory(path);

    service.setString(current_path, currentDirectory.path);

    if (null != currentDirectory &&
        currentDirectory.existsSync() &&
        FileSystemEntity.isDirectorySync(currentDirectory.path)) {
      /// signle directory
      return currentDirectory.listSync();
    }

    return null;
  }

  bool get root {
    return rootDirectory.path == currentDirectory.path;
  }
}
