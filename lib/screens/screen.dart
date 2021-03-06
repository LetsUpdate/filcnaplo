import 'package:flutter/material.dart';
import 'package:filcnaplo/globals.dart' as globals;
import 'package:filcnaplo/global_drawer.dart';

class Screen extends StatelessWidget {
  final Widget title;
  final Widget body;
  final String returnPage;
  final actions;
  final bool showDrawer;
  Screen(this.title, this.body, this.returnPage, this.actions, {this.showDrawer = true});
  Widget build(BuildContext context) {
    globals.context = context;
    return WillPopScope(
        onWillPop: () {
          globals.screen = 0;
          Navigator.pushReplacementNamed(context, returnPage);
        },
        child: Scaffold(
            drawer: showDrawer ? GlobalDrawer() : null,
            appBar: AppBar(
              title: title,
              actions: actions,
            ),
            body: this.body));
  }
}
