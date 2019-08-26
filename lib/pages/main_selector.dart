import 'cloud_selector.dart';
import 'file_selector.dart';
import 'package:flutter/material.dart';

class MainSelector extends StatefulWidget {
  MainSelector({this.index});
  final int index;
  @override
  MainSelectorState createState() => MainSelectorState();
}

class MainSelectorState extends State<MainSelector>
    with SingleTickerProviderStateMixin {
  TabController tabcontroller;

  @override
  void initState() {
    super.initState();
    tabcontroller = TabController(
        length: 2, //Tab页的个数
        vsync: this //动画效果的异步处理，默认格式
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: TabBarView(
          physics: new NeverScrollableScrollPhysics(),
          controller: tabcontroller,
          children: <Widget>[
            //创建之前写好的三个页面，万物皆是Widget
            CloudSelector(
              index: widget.index,
            ),
            FileSelector(
              index: widget.index,
            )
          ],
        ),
        bottomNavigationBar: TabBar(
          controller: tabcontroller,
          tabs: <Tab>[
            Tab(text: "网络", icon: Icon(Icons.cloud)),
            Tab(text: "本地", icon: Icon(Icons.folder)),
          ],
        ));
  }
}
