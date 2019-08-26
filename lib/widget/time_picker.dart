import 'package:flutter/material.dart';

import 'wheel_picker.dart';

class TimePicker<T> extends StatefulWidget {
  TimePicker(
      {this.time = 0,
      this.max = 0,
      @required this.onDragStart,
      @required this.onDragUpdate,
      @required this.onDragEnd});
  final int time;
  final int max;
  final Function(int) onDragStart;
  final Function(int) onDragUpdate;
  final Function(int) onDragEnd;
  @override
  TimePickerState createState() => TimePickerState();
}

class TimePickerState extends State<TimePicker> {
  int hour = 0;
  int minute = 0;
  int second = 0;
  List<int> hourList;
  List<int> minuteList;
  List<int> secondList;

  LocalKey key = UniqueKey();

  Widget hourWidget;
  Widget minuteWidget;
  Widget secondWidget;

  bool hourPhysics = true;
  bool minutePhysics = true;
  bool secondPhysics = true;

  void setTime(int current, int max) {
    DateTime currentTime =
        DateTime.fromMillisecondsSinceEpoch(current * 1000, isUtc: true);
    hour = currentTime.hour;
    minute = currentTime.minute;
    second = currentTime.second;
    DateTime maxTime =
        DateTime.fromMillisecondsSinceEpoch(max * 1000, isUtc: true);
    hourList = List<int>.filled(maxTime.hour + 1, 0);
    minuteList = List<int>.filled(
        ((max - hour * 60 * 60) >= 60 * 60) ? 60 : (maxTime.minute + 1), 0);
    secondList = List<int>.filled(
        (max - hour * 60 * 60 - minute * 60) > 60 ? 60 : (maxTime.second + 1),
        0);

    hourWidget = hourChild(hour, hourList);
    minuteWidget = minuteChild(minute, minuteList);
    secondWidget = secondChild(second, secondList);
  }

  Widget hourChild(int index, List<int> list) {
    void justify(int index) {
      DateTime maxTime =
          DateTime.fromMillisecondsSinceEpoch(widget.max * 1000, isUtc: true);
      if (maxTime.hour == index) {
        minuteList = List<int>.filled(maxTime.minute, 0);
        minute = 0;
        second = 0;
      }
      hourWidget = hourChild(hour, hourList);
      minuteWidget = minuteChild(minute, minuteList);
      secondWidget = secondChild(second, secondList);
      setState(() {});
    }

    return WheelPicker<int>(
      index: index,
      children: list,
      onDragStart: (int index) {
        widget.onDragStart(index * 60 * 60 + minute * 60 + second);
      },
      onDragUpdate: (int index) {
        hourPhysics = true;
        minutePhysics = false;
        secondPhysics = false;
        justify(index);
        widget.onDragUpdate(index * 60 * 60 + minute * 60 + second);
      },
      onDragEnd: (int index) {
        hourPhysics = true;
        minutePhysics = true;
        secondPhysics = true;
        justify(index);
        widget.onDragEnd(index * 60 * 60 + minute * 60 + second);
      },
      isScrolable: hourPhysics,
    );
  }

  Widget minuteChild(int index, List<int> list) {
    void justify(int index) {
      DateTime maxTime =
          DateTime.fromMillisecondsSinceEpoch(widget.max * 1000, isUtc: true);
      if (maxTime.hour == hour && maxTime.minute == index) {
        secondList = List<int>.filled(maxTime.second, 0);
        second = 0;
      }
      hourWidget = hourChild(hour, hourList);
      minuteWidget = minuteChild(minute, minuteList);
      secondWidget = secondChild(second, secondList);
      setState(() {});
    }

    return WheelPicker<int>(
      index: index,
      children: list,
      onDragStart: (int index) {
        widget.onDragStart(hour * 60 * 60 + index * 60 + second);
      },
      onDragUpdate: (int index) {
        hourPhysics = false;
        minutePhysics = true;
        secondPhysics = false;
        justify(index);
        widget.onDragUpdate(hour * 60 * 60 + index * 60 + second);
        setState(() {});
      },
      onDragEnd: (int index) {
        hourPhysics = true;
        minutePhysics = true;
        secondPhysics = true;
        justify(index);
        widget.onDragEnd(hour * 60 * 60 + index * 60 + second);
      },
      isScrolable: minutePhysics,
    );
  }

  Widget secondChild(int index, List<int> list) {
    return WheelPicker<int>(
      index: index,
      children: list,
      onDragStart: (int index) {
        widget.onDragStart(hour * 60 * 60 + minute * 60 + index);
      },
      onDragUpdate: (int index) {
        hourPhysics = false;
        minutePhysics = false;
        secondPhysics = true;
        hourWidget = hourChild(hour, hourList);
        minuteWidget = minuteChild(minute, minuteList);
        secondWidget = secondChild(second, secondList);
        setState(() {});
        widget.onDragUpdate(hour * 60 * 60 + minute * 60 + index);
      },
      onDragEnd: (int index) {
        hourPhysics = true;
        minutePhysics = true;
        secondPhysics = true;
        hourWidget = hourChild(hour, hourList);
        minuteWidget = minuteChild(minute, minuteList);
        secondWidget = secondChild(second, secondList);
        setState(() {});
        widget.onDragEnd(hour * 60 * 60 + minute * 60 + index);
      },
      isScrolable: secondPhysics,
    );
  }

  @override
  void initState() {
    super.initState();
    setTime(widget.time, widget.max);
  }

  @override
  void didUpdateWidget(TimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    setTime(widget.time, widget.max);
    if (oldWidget.max != widget.max) {
      key = UniqueKey();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      key: key,
      children: <Widget>[
        Expanded(
          child: hourWidget,
        ),
        Expanded(
          child: minuteWidget,
        ),
        Expanded(
          child: secondWidget,
        )
      ],
    );
  }
}
