import 'package:audioplayers/audioplayers.dart';

import '../services/system.dart';
import '../widget/time_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'FileSelector.dart';

class Play extends StatefulWidget {
  Play({this.index});
  final int index;
  @override
  PlayState createState() => PlayState();
}

class PlayState extends State<Play> {
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

  Map<String, dynamic> music;

  String formatTime(int milliseconds) {
    return DateFormat.Hms()
        .format(DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true));
  }

  Widget controlButton() {
    return RawMaterialButton(
        onPressed: () {
          if (duration.inSeconds > 0) {
            AudioPlayerState.PLAYING == playerState
                ? audioPlayer.pause()
                : audioPlayer.resume();
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

  void loadMusic() {
    music = service.musicService.getMusic(widget.index);
    path = music["path"].toString();
    _currentFile = music["title"].toString();
    time = int.tryParse(music['time'].toString()) ?? 0;
    position = Duration(seconds: time);

    audioPlayer.setUrl(path, isLocal: true);
    audioPlayer.seek(position).then((v) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _progress = position.inSeconds;
        });
      });
    });
  }

  Future setPosition(int pos) async {
    position = Duration(seconds: pos);
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
        });
      }
    });
    audioPlayer.onDurationChanged.listen((Duration d) {
      if (mounted) {
        setState(() {
          duration = d;
          _progress = position.inSeconds;
        });
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
    loadMusic();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('音频播放'), actions: <Widget>[
          new IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(context,
                    new MaterialPageRoute(builder: (BuildContext context) {
                  return FileSelector(index: widget.index);
                })).then((change) {
                  if (change) {
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
                          child: new Slider(
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
  }
}
