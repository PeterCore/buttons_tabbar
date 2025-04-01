import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:flutter/material.dart';

const Color pinkColor = Color(0xFFFA82BF);
const Color pinkBgColor = Color(0xFFFFF1F8);
const Color greyF8F8F8 = Color(0xFFF8F8F8);
const Color blackColorO4 = Color.fromRGBO(0, 0, 0, 0.4);

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dynamic ButtonsTabBar Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  // 初始两个 Tab
  List<Tab> _tabs = [
    Tab(text: 'Tab 1', icon: Icon(Icons.looks_one)),
    Tab(text: 'Tab 2', icon: Icon(Icons.looks_two)),
  ];
  List<Widget> _tabViews = [
    Center(child: Text('内容 1')),
    Center(child: Text('内容 2')),
  ];
  late TabController _tabController;
  int _tabCount = 2;

  @override
  void initState() {
    super.initState();
    // 初始化 TabController，长度与 _tabs 数量一致
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  /// 处理 ButtonsTabBar 中“+”按钮的回调，动态添加新 Tab
  void _handleTabAdded(Widget newTab) {
    final int currentIndex = _tabController.index;
    setState(() {
      _tabCount++;
      _tabs.add(Tab(text: 'Tab ${_tabCount}', icon: Icon(Icons.looks_one)));
      _tabViews.add(Center(child: Text('内容 $_tabCount')));
      // 重新创建 TabController，并保持当前选中索引
      _tabController.dispose();
      _tabController = TabController(
          length: _tabs.length, vsync: this, initialIndex: currentIndex);
      if (currentIndex < _tabs.length) {
        _tabController.index = currentIndex;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('动态添加 Tab 示例'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ButtonsTabBar(
              tabs: _tabs,
              radius: 24,
              labelStyle: const TextStyle(
                  color: pinkColor, fontWeight: FontWeight.w400, fontSize: 14),
              unselectedLabelStyle: const TextStyle(
                  color: blackColorO4,
                  fontWeight: FontWeight.w400,
                  fontSize: 14),
              unselectedBackgroundColor: greyF8F8F8,
              backgroundColor: pinkBgColor,
              onIconTap: (index, idex) {},
              icons: [
                Image.asset(
                  'assets/edit_icon.png',
                  width: 24,
                  height: 24,
                ),
                Image.asset(
                  'assets/trash_icon.png',
                  width: 24,
                  height: 24,
                )
              ],
              buttonMargin:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              controller: _tabController,
            ),
          ),
        ),
      ),
      body: TabBarView(
        key: Key("${_tabs.length}"),
        controller: _tabController,
        children: _tabViews,
      ),
    );
  }
}
