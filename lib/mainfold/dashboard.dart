import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_client/routes/applications.dart';
import 'package:flutter_client/routes/dashboard.dart';
import 'package:flutter_client/routes/docker.dart';
import 'package:flutter_client/routes/files.dart';
import 'package:flutter_client/routes/users.dart';
import 'package:flutter_client/routes/xterm.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../routes/websites.dart';
import '../utils/responsive.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  double currentIndex = 0;

  Widget returnSidebar() {
    return NavigationDrawer(
      selectedIndex: currentIndex.round(),
      onDestinationSelected: (int index) {
        setState(() {
          currentIndex = index.toDouble();
        });
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Image.asset("assets/icon.png", width: 45,height: 45,),
              const Text("Flix Web Host",style: TextStyle(
                fontSize: 20
              ),)
            ],
          ),
        ),
        const Divider(),
        const NavigationDrawerDestination(
          label: Text("Dashboard"),
          icon: Icon(Icons.dashboard),
          selectedIcon: Icon(Icons.dashboard_outlined),
        ),
        const NavigationDrawerDestination(
          label: Text("User Accounts"),
          icon: Icon(Icons.person),
          selectedIcon: Icon(Icons.person_outline),
        ),
        const NavigationDrawerDestination(
          label: Text("Websites"),
          icon: Icon(Icons.web),
          selectedIcon: Icon(Icons.web_outlined),
        ),
        const NavigationDrawerDestination(
          label: Text("Applications"),
          icon: Icon(Icons.apps),
          selectedIcon: Icon(Icons.apps_outlined),
        ),
        const NavigationDrawerDestination(
          label: Text("Files"),
          icon: Icon(Icons.folder_copy),
          selectedIcon: Icon(Icons.folder_copy_outlined),
        ),
        const NavigationDrawerDestination(
          label: Text("Terminal"),
          icon: Icon(Icons.terminal),
          selectedIcon: Icon(Icons.terminal_outlined),
        ),
        const NavigationDrawerDestination(
          label: Text("Docker"),
          icon: FaIcon(FontAwesomeIcons.docker),
          selectedIcon: FaIcon(FontAwesomeIcons.docker),
        ),
      ],
    );
  }

  void subMethods(double index) {
    print(index);
  }

  Widget routeByIndex() {
    // Dashboard
    if(currentIndex == 0) {
      return DashPage(callback: (double index) => subMethods(index));
    }

    if(currentIndex == 1) {
      return UserPage(callback: (double index) => subMethods(index));
    }

    if(currentIndex == 2) {
      return WebPage(callback: (double index) => subMethods(index));
    }

    if(currentIndex == 3) {
      return AppsPage(callback: (double index) => subMethods(index));
    }

    if(currentIndex == 4) {
      return FilesPage(callback: (double index) => subMethods(index));
    }

    if(currentIndex == 5) {
      return const XtermPage(host: 'auto', username: 'auto', password: 'auto', port: 22,);
    }

    if(currentIndex == 6) {
      return DockerPage(callback: (double index) => subMethods(index));
    }

    return const Center(
      child: SizedBox(
        width: 300,
        height: 200,
        child: Icon(Icons.error,size: 169,),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: isMobile(context) ? AppBar(
        title: const Text("Flix"),
        centerTitle: true,
      ) : null,
      drawer: isMobile(context) ? returnSidebar() : null,
      body: isMobile(context) ? routeByIndex() : Center(
        child: Row(
          children: [
            SizedBox(width: 250,height: MediaQuery.of(context).size.height,child: returnSidebar(),),
            SizedBox(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width - 250,
              child: Column(
                children: [
                  AppBar(
                    title: const Text("Flix Web Panel"),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height - 56,
                    child: Card(
                      child: routeByIndex(),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}