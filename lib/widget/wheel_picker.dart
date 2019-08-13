import 'package:flutter/material.dart';

class WheelPicker<T> extends StatefulWidget {
  WheelPicker(
      {@required this.children,
      this.index = 0,
      this.isScrolable = true,
      @required this.onDragStart,
      @required this.onDragUpdate,
      @required this.onDragEnd});

  final int index;
  final Function(int) onDragStart;
  final Function(int) onDragUpdate;
  final Function(int) onDragEnd;
  final List<T> children;
  final bool isScrolable;
  @override
  WheelPickerState createState() => WheelPickerState();
}

class WheelPickerState extends State<WheelPicker> {
  FixedExtentScrollController controller;

  int currentIndex;
  bool dragStart = false;

  int childrenLength;
  Widget wheelScroll;

  Widget renderWheelScroll() {
    return Stack(alignment: Alignment.center, children: [
      NotificationListener(
        onNotification: (ScrollNotification scrollNotification) {
          if (widget.children.length > 0) {
            if (scrollNotification is ScrollStartNotification) {
              if (scrollNotification.dragDetails is DragStartDetails) {
                dragStart = true;
              }
            } else if (scrollNotification is ScrollUpdateNotification) {
              if (scrollNotification.dragDetails is DragUpdateDetails) {
                widget.onDragUpdate(currentIndex);
              }
            } else if (scrollNotification is ScrollEndNotification) {
              if (dragStart) {
                dragStart = false;
                widget.onDragEnd(currentIndex);
              }
            }
          }
          return true;
        },
        child: ListWheelScrollView.useDelegate(
            onSelectedItemChanged: (int index) {
              currentIndex = index;
            },
            childDelegate: ListWheelChildBuilderDelegate(
                childCount: childrenLength,
                builder: (BuildContext context, int index) {
                  return Text(
                    index.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: "LED",
                        fontSize: 32,
                        color: Color.fromARGB(
                            widget.index == index ? 255 : 200, 255, 255, 255)),
                  );
                }),
            perspective: 0.01,
            controller: controller,
            physics: widget.isScrolable
                ? const AlwaysScrollableScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            itemExtent: 40,
            clipToSize: false),
      ),
      IgnorePointer(
        child: Wrap(
          children: <Widget>[
            Container(
                width: 38,
                height: 32,
                decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(width: 1, color: Colors.white70)))),
          ],
        ),
      )
    ]);
  }

  @override
  void initState() {
    controller = FixedExtentScrollController(initialItem: widget.index);
    currentIndex = widget.index;
    childrenLength = widget.children.length;
    wheelScroll = new Container(width: 0.0, height: 0.0);
    super.initState();
  }

  @override
  void didUpdateWidget(Widget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!dragStart) {
      currentIndex = widget.index;
      childrenLength = widget.children.length;
      wheelScroll = renderWheelScroll();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.animateToItem(
          widget.index,
          curve: Curves.ease,
          duration: Duration(milliseconds: 300),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return wheelScroll;
  }
}
