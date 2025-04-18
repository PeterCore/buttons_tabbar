library buttons_tabbar;

import 'package:flutter/material.dart';

// Default values from the Flutter's TabBar.

class CustomBoxDecoration {
  int index;
  BoxDecoration? decoration;

  CustomBoxDecoration({
    required this.index,
    this.decoration,
  });
}

const double _kTabHeight = 46.0;

class ButtonsTabBar extends StatefulWidget implements PreferredSizeWidget {
  ButtonsTabBar(
      {super.key,
      required this.tabs,
      this.controller,
      this.duration = 250,
      this.backgroundColor,
      this.unselectedBackgroundColor,
      this.decoration,
      this.unselectedDecoration,
      this.labelStyle,
      this.unselectedLabelStyle,
      this.splashColor,
      this.borderWidth = 0,
      this.borderColor = Colors.black,
      this.unselectedBorderColor = Colors.black,
      this.physics = const BouncingScrollPhysics(),
      this.contentPadding = const EdgeInsets.symmetric(horizontal: 4),
      this.buttonMargin = const EdgeInsets.all(4),
      this.labelSpacing = 4.0,
      this.radius = 7.0,
      this.elevation = 0,
      this.height = _kTabHeight,
      this.width,
      this.center = false,
      this.contentCenter = false,
      this.onTap,
      // 新增 onTabAdded 回调，当用户点击“+”按钮时触发
      this.icons,
      this.minimumSize,
      this.onIconTap,
      this.onActionTap,
      this.actions,
      this.customBoxDecoration,
      this.addButton,
      this.onAddTab,
      this.unselectCustomBoxDecoration}) {
    assert(backgroundColor == null || decoration == null);
    assert(unselectedBackgroundColor == null || unselectedDecoration == null);
  }

  /// Tab 列表
  final List<Widget> tabs;
  List<Widget>? actions;

  /// TabController，如果不提供，则通过 DefaultTabController 获取
  final TabController? controller;

  /// 切换动画时长（毫秒）
  final int duration;
  final List<Widget>? icons;
  final Color? backgroundColor;
  final Color? unselectedBackgroundColor;
  final Color? splashColor;
  final BoxDecoration? decoration;
  final BoxDecoration? unselectedDecoration;
  final TextStyle? labelStyle;
  final TextStyle? unselectedLabelStyle;
  final double borderWidth;
  final Color borderColor;
  final Color unselectedBorderColor;
  final ScrollPhysics physics;
  final EdgeInsets contentPadding;
  final EdgeInsets buttonMargin;
  final double labelSpacing;
  final double radius;
  final double elevation;
  final double? height;
  final double? width;
  final Size? minimumSize;
  final bool center;
  final bool contentCenter;
  final Widget? addButton;
  final CustomBoxDecoration? customBoxDecoration;
  final CustomBoxDecoration? unselectCustomBoxDecoration;

  final void Function(int)? onTap;
  final void Function()? onAddTab;
  Function(
    int,
    int,
  )? onIconTap;
  Function(int index)? onActionTap;

  @override
  Size get preferredSize {
    return Size.fromHeight(height ??
        (_kTabHeight + contentPadding.vertical + buttonMargin.vertical));
  }

  @override
  State<ButtonsTabBar> createState() => _ButtonsTabBarState();
}

class _ButtonsTabBarState extends State<ButtonsTabBar>
    with TickerProviderStateMixin {
  TabController? _controller;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late List<GlobalKey> _tabKeys;
  final GlobalKey _tabsContainerKey = GlobalKey();
  final GlobalKey _tabsParentKey = GlobalKey();
  int _currentIndex = 0;
  int _prevIndex = -1;
  int _aniIndex = 0;
  double _prevAniValue = 0;
  late bool _textLTR;
  EdgeInsets _centerPadding = EdgeInsets.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _getCenterPadding(context));
    _tabKeys = widget.tabs.map((Widget tab) => GlobalKey()).toList();
    _animationController = AnimationController(
        vsync: this, duration: Duration(milliseconds: widget.duration));
    _animationController.value = 1.0;
    _animationController.addListener(() {
      setState(() {});
    });
  }

  void _updateTabController() {
    final TabController newController =
        widget.controller ?? DefaultTabController.of(context);
    assert(() {
      if (newController == null) {
        throw FlutterError('No TabController for ${widget.runtimeType}.\n'
            'You must provide a TabController via the "controller" property, or ensure a DefaultTabController exists.');
      }
      return true;
    }());

    if (newController == _controller) return;
    if (_controllerIsValid) {
      _controller?.animation!.removeListener(_handleTabAnimation);
      _controller?.removeListener(_handleController);
    }
    _controller = newController;
    _controller?.animation!.addListener(_handleTabAnimation);
    _controller?.addListener(_handleController);
    _currentIndex = _controller!.index;
    Future.delayed(Duration.zero, () {
      _scrollTo(_currentIndex);
    });
  }

  bool get _controllerIsValid => _controller?.animation != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    assert(debugCheckHasMaterial(context));
    _updateTabController();
  }

  @override
  void didUpdateWidget(ButtonsTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _tabKeys.add(GlobalKey());
      _updateTabController();
    }
    if (widget.tabs.length > oldWidget.tabs.length) {
      final int delta = widget.tabs.length - oldWidget.tabs.length;
      _tabKeys.addAll(List<GlobalKey>.generate(delta, (int n) => GlobalKey()));
    } else if (widget.tabs.length < oldWidget.tabs.length) {
      _tabKeys.removeRange(widget.tabs.length, oldWidget.tabs.length);
    }
  }

  @override
  void dispose() {
    if (_controllerIsValid) {
      _controller!.animation!.removeListener(_handleTabAnimation);
      _controller!.removeListener(_handleController);
    }
    _controller = null;
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  _getCenterPadding(BuildContext context) {
    final RenderBox tabsParent =
        _tabsParentKey.currentContext!.findRenderObject() as RenderBox;
    final double screenWidth = tabsParent.size.width;
    RenderBox renderBox =
        _tabKeys.first.currentContext?.findRenderObject() as RenderBox;
    double size = renderBox.size.width;
    final double left = (screenWidth - size) / 2;
    renderBox = _tabKeys.last.currentContext?.findRenderObject() as RenderBox;
    size = renderBox.size.width;
    final double right = (screenWidth - size) / 2;
    _centerPadding = EdgeInsets.only(left: left, right: right);
  }

  BorderRadiusGeometry? _buildBoxDecoration(int index) {
    final boxDecoration = widget.customBoxDecoration;
    if (boxDecoration != null) {
      if (boxDecoration.index == index) {
        return boxDecoration.decoration?.borderRadius;
      } else {
        return widget.decoration?.borderRadius ??
            BorderRadius.circular(widget.radius);
      }
    }
    final borderRadius =
        widget.decoration?.borderRadius ?? BorderRadius.circular(widget.radius);
    return borderRadius;
  }

  BorderRadiusGeometry? _buildUnSelectedBoxDecoration(int index) {
    final boxDecoration = widget.unselectCustomBoxDecoration;
    if (boxDecoration != null) {
      if (boxDecoration.index == index) {
        return boxDecoration.decoration?.borderRadius;
      } else {
        return widget.decoration?.borderRadius ??
            BorderRadius.circular(widget.radius);
      }
    }
    final borderRadius =
        widget.decoration?.borderRadius ?? BorderRadius.circular(widget.radius);
    return borderRadius;
  }

  Widget _buildButton(int index, Tab tab) {
    final double animationValue;
    if (index == _currentIndex) {
      animationValue = _animationController.value;
    } else if (index == _prevIndex) {
      animationValue = 1 - _animationController.value;
    } else {
      animationValue = 0;
    }
    final TextStyle? textStyle = TextStyle.lerp(
        widget.unselectedLabelStyle ?? const TextStyle(color: Colors.black),
        widget.labelStyle ?? const TextStyle(color: Colors.white),
        animationValue);
    final Color? borderColor = Color.lerp(
        widget.unselectedBorderColor, widget.borderColor, animationValue);
    final Color foregroundColor = textStyle?.color ?? Colors.black;
    final BoxDecoration? boxDecoration = BoxDecoration.lerp(
        BoxDecoration(
            color: widget.unselectedDecoration?.color ??
                widget.unselectedBackgroundColor ??
                Colors.grey[300],
            boxShadow: widget.unselectedDecoration?.boxShadow,
            gradient: widget.unselectedDecoration?.gradient,
            borderRadius: _buildUnSelectedBoxDecoration(index)),
        BoxDecoration(
            color: widget.decoration?.color ??
                widget.backgroundColor ??
                Theme.of(context).colorScheme.secondary,
            boxShadow: widget.decoration?.boxShadow,
            gradient: widget.decoration?.gradient,
            borderRadius: _buildBoxDecoration(index)),
        animationValue);
    EdgeInsets margin;
    if (index == 0) {
      margin = EdgeInsets.only(
        top: widget.buttonMargin.top,
        bottom: widget.buttonMargin.bottom,
        left: widget.buttonMargin.left,
        right: widget.buttonMargin.right / 2,
      );
    } else if (index == widget.tabs.length - 1) {
      margin = EdgeInsets.only(
        top: widget.buttonMargin.top,
        bottom: widget.buttonMargin.bottom,
        right: widget.buttonMargin.right,
        left: widget.buttonMargin.left / 2,
      );
    } else {
      margin = EdgeInsets.only(
        top: widget.buttonMargin.top,
        bottom: widget.buttonMargin.bottom,
        left: widget.buttonMargin.left / 2,
        right: widget.buttonMargin.right / 2,
      );
    }
    return Padding(
      key: _tabKeys[index],
      padding: margin,
      child: ElevatedButton(
        onPressed: () {
          _controller?.animateTo(index);
          if (widget.onTap != null) widget.onTap!(index);
        },
        style: ElevatedButton.styleFrom(
          elevation: widget.elevation,
          minimumSize: const Size(40, 30),
          padding: EdgeInsets
              .zero, //const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          textStyle: textStyle,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
              side: (widget.borderWidth == 0)
                  ? BorderSide.none
                  : BorderSide(
                      color: borderColor ?? Colors.black,
                      width: widget.borderWidth,
                      style: BorderStyle.solid,
                    ),
              borderRadius: _buildBoxDecoration(index) ??
                  BorderRadius.circular(widget.radius)),
          backgroundColor: Colors.transparent,
          overlayColor: widget.splashColor,
        ),
        child: Ink(
          decoration: boxDecoration,
          child: Container(
            padding: widget.contentPadding,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: !widget.contentCenter
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: <Widget>[
                tab.text != null
                    ? Text(
                        tab.text!,
                        style: textStyle,
                      )
                    : (tab.child ?? Container()),
                SizedBox(
                  width: (tab.text == null && tab.child == null)
                      ? 0
                      : widget.labelSpacing,
                ),
                ...buildIcons(index),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(() {
      if (_controller!.length != widget.tabs.length) {
        throw FlutterError(
            "Controller's length property (${_controller!.length}) does not match the "
            "number of tabs (${widget.tabs.length}) present in TabBar's tabs property.");
      }
      return true;
    }());
    if (_controller!.length == 0) return Container(height: widget.height);
    _textLTR = Directionality.of(context).index == 1;
    return Opacity(
      opacity: (!widget.center || _centerPadding != EdgeInsets.zero) ? 1 : 0,
      child: AnimatedBuilder(
        animation: _animationController,
        key: _tabsParentKey,
        builder: (context, child) => SizedBox(
          key: _tabsContainerKey,
          height: widget.preferredSize.height,
          child: Row(
            children: [
              Expanded(
                flex: 8,
                child: SingleChildScrollView(
                  physics: widget.physics,
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: widget.center ? _centerPadding : EdgeInsets.zero,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...List.generate(
                        widget.tabs.length,
                        (int index) => SizedBox(
                          width: widget.width,
                          child: _buildButton(index, widget.tabs[index] as Tab),
                        ),
                      ),
                      GestureDetector(
                          onTap: () {
                            widget.onAddTab?.call();
                          },
                          child: widget.addButton ?? Container())
                    ],
                  ),
                ),
              ),
              ...buildActions()
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> buildActions() {
    List<Widget> icons = [];
    final actions = widget.actions;
    if (actions != null) {
      for (int i = 0; i < widget.actions!.length; i++) {
        icons.add(GestureDetector(
          onTap: () => widget.onActionTap?.call(i),
          child: widget.actions![i],
        ));
      }
    }
    return icons;
  }

  List<Widget> buildIcons(int index) {
    List<Widget> icons = [];
    if (widget.icons != null) {
      if (index == widget.unselectCustomBoxDecoration?.index) {
        return icons;
      }
      for (int i = 0; i < widget.icons!.length; i++) {
        icons.add(GestureDetector(
          onTap: () => widget.onIconTap?.call(index, i),
          child: widget.icons![i],
        ));
      }
    }

    final results = _currentIndex == index ? icons : [Container()];
    return results;
  }

  _handleTabAnimation() {
    _aniIndex = ((_controller!.animation!.value > _prevAniValue)
            ? _controller!.animation!.value
            : _prevAniValue)
        .round();
    if (!_controller!.indexIsChanging && _aniIndex != _currentIndex) {
      _setCurrentIndex(_aniIndex);
    }
    _prevAniValue = _controller!.animation!.value;
  }

  _handleController() {
    if (_controller!.indexIsChanging) {
      _goToIndex(_controller!.index);
    }
  }

  _goToIndex(int index) {
    if (index != _currentIndex) {
      _setCurrentIndex(index);
      _controller?.animateTo(index);
    }
  }

  _setCurrentIndex(int index) {
    setState(() {
      _prevIndex = _currentIndex;
      _currentIndex = index;
    });
    _scrollTo(index);
    _triggerAnimation();
  }

  _triggerAnimation() {
    _animationController.reset();
    _animationController.forward();
  }

  _scrollTo(int index) {
    final RenderBox tabsContainer =
        _tabsContainerKey.currentContext!.findRenderObject() as RenderBox;
    double screenWidth = tabsContainer.size.width;
    final tabsContainerPosition = tabsContainer.localToGlobal(Offset.zero).dx;
    final tabsContainerOffset = Offset(-tabsContainerPosition, 0);
    RenderBox renderBox =
        _tabKeys[index].currentContext?.findRenderObject() as RenderBox;
    double size = renderBox.size.width;
    double position = renderBox.localToGlobal(tabsContainerOffset).dx;
    double offset = (position + size / 2) - screenWidth / 2;
    if (offset < 0) {
      renderBox = (_textLTR ? _tabKeys.first : _tabKeys.last)
          .currentContext
          ?.findRenderObject() as RenderBox;
      position = renderBox.localToGlobal(tabsContainerOffset).dx;
      if (!widget.center && position > offset) offset = position;
    } else {
      renderBox = (_textLTR ? _tabKeys.last : _tabKeys.first)
          .currentContext
          ?.findRenderObject() as RenderBox;
      position = renderBox.localToGlobal(tabsContainerOffset).dx;
      size = renderBox.size.width;
      if (position + size < screenWidth) screenWidth = position + size;
      if (!widget.center && position + size - offset < screenWidth) {
        offset = position + size - screenWidth;
      }
    }
    offset *= (_textLTR ? 1 : -1);
    _scrollController.animateTo(offset + _scrollController.offset,
        duration: Duration(milliseconds: widget.duration),
        curve: Curves.easeInOut);
  }
}
