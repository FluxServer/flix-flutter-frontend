import 'package:flutter/material.dart';
import 'package:flutter_client/utils/request.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/responsive.dart';

class DockerPage extends StatefulWidget {
  const DockerPage({super.key, required this.callback});

  final Function callback;

  @override
  State<DockerPage> createState() => _DockerPageState();
}

class _DockerPageState extends State<DockerPage> with SingleTickerProviderStateMixin {
  late SharedPreferences prefs;
  late TabController _tabController;

  bool isLoading = false;
  bool isDockerRunning = false;

  List<Map> containers = [];
  List<Map> images = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    setPrefs();
  }

  void setPrefs() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      prefs = pref;
    });

    fetchSystemInfo();
  }

  void fetchSystemInfo() async {
    setState(() {
      isLoading = true;
    });

    Map<String, dynamic> response = await makeRequest(
        prefs: prefs,
        method: "GET",
        data: {},
        endpoint: "v1/auth/services/list"
    );

    if (!context.mounted) return;

    setState(() {
      isLoading = false;
    });

    if (response['status'] == true) {
      if (context.mounted) {
        setState(() {
          isLoading = false;
          isDockerRunning = response['services']['docker'] == "active" ? true : false;
        });

        if (isDockerRunning) {
          fetchContainers();
          fetchImages();
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message']), behavior: SnackBarBehavior.floating, width: 280,)
      );
    }
  }

  void fetchContainers() async {
    setState(() {
      isLoading = true;
    });

    Map<String, dynamic> response = await makeRequest(
        prefs: prefs,
        method: "GET",
        data: {},
        endpoint: "v1/auth/docker/containers/list"
    );

    if (context.mounted) {
      setState(() {
        isLoading = false;
        containers = List.from(response['containers']);
      });
    }
  }

  void fetchImages() async {
    setState(() {
      isLoading = true;
    });

    Map<String, dynamic> response = await makeRequest(
        prefs: prefs,
        method: "GET",
        data: {},
        endpoint: "v1/auth/docker/images/list"
    );

    if (context.mounted) {
      setState(() {
        isLoading = false;
        images = List.from(response['images']);
      });
    }
  }

  void startStopContainer(action, id) async {
    setState(() {
      isLoading = true;
    });

    Map<String, dynamic> response = await makeRequest(
        prefs: prefs,
        method: "POST",
        data: {
          "id": id,
          "action": action
        },
        endpoint: "v1/auth/docker/containers/action"
    );

    if (context.mounted) {
      setState(() {
        isLoading = false;
      });

      fetchContainers();
    }
  }

  Widget buildContainersTab() {
    return isDockerRunning ? Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const Divider(),
        const Text("Containers List", style: TextStyle(fontSize: 21),),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var container in containers) Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Name
                    Row(
                      children: [
                        for (String name in List.from(container['Names'])) Text(name, style: const TextStyle(
                            fontSize: 21
                        ),),
                      ],
                    ),
                    Text("Image Used : ${container['Image'] ?? 'No Image'}"),
                    const Divider(),
                    Text("Created On : ${DateTime.fromMillisecondsSinceEpoch(container['Created'] * 1000).toString()}"),
                    for (var port in List.from(container['Ports'])) Text("IP : ${port['IP'] ?? 'Default'}\nPrivatePort : ${port['PrivatePort']}\nPublic Port : ${port['PublicPort'] ?? 'None'}\nType: ${port['Type']}"),
                    Text("State : ${container['State']}"),
                    // End Name
                    Row(
                      children: [
                        IconButton(onPressed: () {
                          startStopContainer(container['State'] == "running" ? "stop" : "start",
                              container['Id']
                          );
                        }, icon: Icon(container['State'] == "running" ? Icons.stop : Icons.play_arrow),)
                      ],
                    )
                  ],
                ),
              ),
            )
          ],
        )
      ],
    ) : const Center(
      child: Text("Docker Service is not running."),
    );
  }

  Widget buildImagesTab() {
    return isDockerRunning ? Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const Divider(),
        const Text("Images List", style: TextStyle(fontSize: 21),),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var image in images) Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text("Repository : ${image['RepoTags']?.first ?? 'No Repository'}"),
                    Text("Size : ${image['Size'] ?? 'No Size'}"),
                    const Divider(),
                    Text("Created On : ${DateTime.fromMillisecondsSinceEpoch(image['Created'] * 1000).toString()}"),
                  ],
                ),
              ),
            )
          ],
        )
      ],
    ) : const Center(
      child: Text("Docker Service is not running."),
    );
  }

  Widget buildDockerHubTab() {
    return Center(
      child: Text("Docker Hub Integration Coming Soon"),
    );
  }

  Widget buildSettingsTab() {
    return Center(
      child: Text("Settings Coming Soon"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Docker Manager'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Containers', icon: Icon(Icons.storage)),
            Tab(text: 'Images', icon: Icon(Icons.image)),
            Tab(text: 'Docker Hub', icon: Icon(Icons.cloud)),
            Tab(text: 'Settings', icon: Icon(Icons.settings)),
          ],
        ),
      ),
      body: isLoading ? const Center(
        child: CircularProgressIndicator(),
      ) : TabBarView(
        controller: _tabController,
        children: [
          buildContainersTab(),
          buildImagesTab(),
          buildDockerHubTab(),
          buildSettingsTab(),
        ],
      ),
    );
  }
}
