import 'package:flutter/widgets.dart';

class PageKeepAlive extends StatefulWidget {
  final Widget child;

  const PageKeepAlive({Key? key, required this.child}) : super(key: key);

  @override
  State<PageKeepAlive> createState() => _PageKeepAliveState();
}

class _PageKeepAliveState extends State<PageKeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}