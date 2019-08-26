import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:audio_notification/audio_notification.dart';
import 'package:flusic/pages/main_selector.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

import 'home.dart';
import '../services/system.dart';
import '../widget/time_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Play extends StatefulWidget {
  Play({this.index});
  final int index;
  @override
  PlayState createState() => PlayState();
}

class PlayState extends State<Play> {
  final GlobalKey key = GlobalKey();
  int _progress = 0;
  String _currentFile = '未选择';
  SystemService service = new SystemService();
  AudioPlayer audioPlayer;

  AudioPlayerState playerState;
  Duration duration = Duration(seconds: 0);
  Duration position = Duration(seconds: 0);
  String path;
  String title;
  int time;

  bool disposed = false;

  bool draging = false;
  bool changingPosition = false;

  bool initPos = false;

  Map<String, dynamic> music;

  String formatTime(int milliseconds) {
    return DateFormat.Hms()
        .format(DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true));
  }

  Widget controlButton() {
    return RawMaterialButton(
        onPressed: () {
          if (duration.inSeconds > 0) {
            if (AudioPlayerState.PLAYING == playerState) {
              audioPlayer.pause();
            } else {
              audioPlayer.resume();
            }
          }
        },
        child: new Icon(
            AudioPlayerState.PLAYING == playerState
                ? Icons.pause_circle_outline
                : Icons.play_circle_outline,
            size: 32,
            color: duration.inSeconds > 0 ? Colors.white : Colors.black38),
        shape: new CircleBorder(),
        padding: EdgeInsets.all(0),
        constraints: BoxConstraints(),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap);
  }

  loadMusic() async {
    music = service.musicService.getMusic(widget.index);
    bool isLocal = false;
    if (music["path"] != null) {
      path = music["path"].toString();
      isLocal = true;
    } else {
      path = music["url"];
      if (music["taskId"] != null) {
        var tasks = await service.fileService
            .getTaskByTaskId(music["taskId"].toString());
        if (tasks.length > 0) {
          if (tasks.first.status == DownloadTaskStatus.complete) {
            path = "${tasks.first.savedDir}/${tasks.first.filename}";
            isLocal = true;
          }
        }
      }
    }

    _currentFile = music["title"].toString();
    time = int.tryParse(music['time'].toString()) ?? 0;
    position = Duration(seconds: time);

    duration = Duration.zero;
    await audioPlayer.setUrl(path, isLocal: isLocal);
    AudioNotification.show(title: _currentFile, content: "loveq");
    AudioNotification.setPlayState(false);
  }

  Future setPosition(int pos) async {
    position = Duration(seconds: pos);
    service.musicService.setPos(widget.index, position.inSeconds);
    changingPosition = true;
    await audioPlayer.seek(position);
    changingPosition = false;
  }

  @override
  void initState() {
    super.initState();
    if (audioPlayer == null) {
      audioPlayer = AudioPlayer();
    }
    audioPlayer.onPlayerStateChanged.listen((AudioPlayerState s) {
      if (mounted) {
        setState(() {
          playerState = s;
          AudioNotification.setPlayState(
              playerState == AudioPlayerState.PLAYING);
        });
      }
    });
    audioPlayer.onDurationChanged.listen((Duration d) {
      if (!initPos) {
        initPos = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          audioPlayer.seek(position).then((v) {
            setState(() {
              _progress = position.inSeconds;
            });
          });
        });
      }
      if (mounted) {
        if (!(duration == d)) {
          duration = d;
          setState(() {});
        }
      }
    });
    audioPlayer.onAudioPositionChanged.listen((Duration d) {
      if (mounted) {
        setState(() {
          if (!changingPosition) {
            position = d;
            service.musicService.setPos(widget.index, position.inSeconds);
          }
          if (!draging && duration.inSeconds != 0) {
            _progress = position.inSeconds;
          }
        });
      }
    });
    AudioNotification.setMethodCallHandler((method) {
      if (method == "noisy") {
        audioPlayer.pause();
      } else {
        if (playerState == AudioPlayerState.PLAYING) {
          audioPlayer.pause();
        } else {
          audioPlayer.resume();
        }
      }
    });
    loadMusic();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text('音频播放'),
            automaticallyImplyLeading: false,
            leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    service.musicService.listening = -1;
                    Navigator.of(context).pushReplacement(
                        new MaterialPageRoute(builder: (BuildContext context) {
                      return MyHomePage();
                    }));
                  }
                }),
            actions: <Widget>[
              IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(context,
                        new MaterialPageRoute(builder: (BuildContext context) {
                      return MainSelector(index: widget.index);
                    })).then((change) {
                      if (change ?? false) {
                        initPos = false;
                        _progress = 0;
                        loadMusic();
                      }
                    });
                  }),
            ]),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                  flex: 1,
                  child: Center(
                      child: Text('$_currentFile',
                          style: TextStyle(fontSize: 28)))),
              Expanded(
                  flex: 4,
                  child: TimePicker(
                    time: _progress,
                    max: duration.inSeconds,
                    onDragStart: (int index) {
                      draging = true;
                    },
                    onDragUpdate: (index) {},
                    onDragEnd: (index) {
                      if (duration.inSeconds > 0) {
                        if (index <= duration.inSeconds) {
                          _progress = index;
                          setState(() {
                            setPosition(index).then((val) {
                              draging = false;
                              return;
                            });
                          });
                        }
                      }
                    },
                  ))
            ],
          ),
        ),
        bottomNavigationBar: BottomAppBar(
            child: Container(
                child: Wrap(children: [
          Container(
              alignment: FractionalOffset.center,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                    activeTickMarkColor: Colors.white,
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white12,
                    valueIndicatorColor: Colors.white,
                    valueIndicatorTextStyle: TextStyle(
                      color: Colors.black,
                    ),
                    thumbColor: Colors.white),
                child: Container(
                    padding: EdgeInsets.fromLTRB(12, 0, 12, 0),
                    child: Row(
                      children: [
                        Text(formatTime(position.inMilliseconds)),
                        Expanded(
                          child: Slider(
                            key: key,
                            value: _progress.toDouble(),
                            label: formatTime(_progress * 1000),
                            min: 0,
                            max: duration.inSeconds == 0
                                ? 1
                                : duration.inSeconds.toDouble(),
                            divisions: duration.inSeconds == 0
                                ? 1
                                : duration.inSeconds,
                            onChanged: (val) {
                              if (duration.inSeconds > 0) {
                                draging = true;
                                setState(() {
                                  _progress = val.round();
                                });
                              }
                            },
                            onChangeEnd: (val) {
                              if (duration.inSeconds > 0) {
                                draging = false;
                                setState(() {
                                  setPosition(val.round());
                                });
                              }
                            },
                          ),
                        ),
                        Text(formatTime(duration.inMilliseconds)),
                        Padding(
                            padding: EdgeInsets.only(left: 12),
                            child: controlButton())
                      ],
                    )),
              ))
        ]))));
  }

  @override
  void dispose() {
    disposed = true;
    audioPlayer.stop().then((val) {
      audioPlayer.dispose();
      audioPlayer = null;
    });
    super.dispose();
    AudioNotification.hide();
  }
}
