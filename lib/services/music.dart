import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';

import 'system.dart';
import 'package:flutter/foundation.dart' show required;
import '../utils/constants.dart';

class MusicService {
  static MusicService _cache;

  factory MusicService({SystemService systemService}) {
    if (null == _cache) {
      _cache = new MusicService._internal(systemService: systemService);
    }
    return _cache;
  }

  MusicService._internal({@required SystemService systemService});

  final SystemService service = new SystemService();

  static List<Map<String, dynamic>> _musicList;

  Future saveMusic(
      {int index, String title, String path, String taskId, String url}) async {
    Map<String, dynamic> music = {
      "title": title ?? basename(path),
      "path": path,
      "taskId": taskId,
      "url": url,
      'time': 0
    };

    if (index == null) {
      musicList.add(music);
    } else {
      musicList[index] = music;
    }

    service.setString(music_key, json.encode(musicList).toString());
  }

  List<Map<String, dynamic>> get musicList {
    if (_musicList == null) {
      String musicJson = service.getString(music_key);
      if (musicJson == null) {
        _musicList = List<Map<String, dynamic>>();
      } else {
        List<dynamic> list = json.decode(musicJson);

        _musicList = list.map((o) {
          return Map<String, dynamic>.from(o);
        }).toList();
      }
    }
    return _musicList;
  }

  Map<String, dynamic> getMusic(int index) {
    if (index < musicList.length) {
      return musicList[index];
    }
    return null;
  }

  void removeMusic(int index) {
    musicList.removeAt(index);
    service.setString(music_key, json.encode(musicList).toString());
  }

  void setMusicList() {
    service.setString(music_key, json.encode(musicList).toString());
  }

  int getPos(int index) {
    return int.tryParse(musicList[index]['time']) ?? 0;
  }

  void setPos(int index, int pos) {
    musicList[index]['time'] = pos;
    service.setString(music_key, json.encode(musicList).toString());
  }

  set musicList(List<Map<String, dynamic>> list) {
    _musicList = list;
  }

  static int _listining;

  int get listening {
    if (_listining == null) {
      _listining = service.getInt(music_listening) ?? -1;
    }
    return _listining;
  }

  set listening(int value) {
    _listining = value;
    service.setInt(music_listening, value);
  }
}
