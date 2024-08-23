import 'package:flutter/material.dart';
import 'package:flutter_client/utils/request.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/responsive.dart';

class AppsPage extends StatefulWidget {
  const AppsPage({super.key, required this.callback});

  final Function callback;

  @override
  State<AppsPage> createState() => _AppsPageState();
}

class _AppsPageState extends State<AppsPage> {
  bool isLoading = false;
  late SharedPreferences prefs;

  List<Map> apps = [];

  @override
  void initState() {
    super.initState();
    setPrefs();
  }

  void setPrefs() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      prefs = pref;
    });

    fetchApps();
  }

  void addApps() async {
    showDialog(context: context, builder: (ctx) {
      TextEditingController appName = TextEditingController();
      TextEditingController appCWD = TextEditingController();
      TextEditingController appCommand = TextEditingController();
      bool startOnStartup = true;
      bool processing = false;

      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text("New Application"),
          content: SingleChildScrollView(
            child: SizedBox(
              height: 300,
              width: 400,
              child: Column(
                children: [
                  TextFormField(
                    controller: appName,
                    decoration: const InputDecoration(
                      labelText: "Application Name"
                    ),
                  ),
                  TextFormField(
                    controller: appCWD,
                    decoration: const InputDecoration(
                        labelText: "Application Directory"
                    ),
                  ),
                  TextFormField(
                    controller: appCommand,
                    decoration: const InputDecoration(
                        labelText: "Application Command"
                    ),
                  ),
                  DropdownButtonFormField<bool>(value: startOnStartup,items: const [
                    DropdownMenuItem(value: true,child: Text("Enable")),
                    DropdownMenuItem(value: false,child: Text("Disable"))
                  ], onChanged: (bool? enable) {
                    setState(() {
                      startOnStartup = enable!;
                    });
                  })
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
            FilledButton(onPressed: processing ? null : () async {
              setState(() { processing = true; });

              Map<String, dynamic> response = await makeRequest(
                  prefs: prefs,
                  method: "POST",
                  data: {
                    "directory" : appCWD.text,
                    "startup": startOnStartup ? "on" : "off",
                    "name" : appName.text,
                    "command" : appCommand.text
                  },
                  endpoint: "v1/auth/app/new"
              );

              setState(() { processing = false; });

              if(response['status'] == true){
                Navigator.of(context).pop();
                fetchApps();
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(response['message']),behavior: SnackBarBehavior.floating,width: 280,)
                );
              }else{
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(response['message']),behavior: SnackBarBehavior.floating,width: 280,)
                );
              }
            }, child: const Text("New"))
          ],
        );
      });
    });
  }

  void fetchApps() async {
    setState(() {
      isLoading = true;
    });

    Map<String, dynamic> response = await makeRequest(
        prefs: prefs,
        method: "GET",
        data: {},
        endpoint: "v1/auth/app/list"
    );

    if(!context.mounted) return;

    setState(() {
      isLoading = false;
    });

    if(response['status'] == true){
      if(context.mounted){
        setState(() {
          apps = List.from(response['data']);
        });
      }
    }else{
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message']),behavior: SnackBarBehavior.floating,width: 280,)
      );
    }
  }

  Widget colOrRow({ required List<Widget> children }) {
    return isMobile(context) ? Column(
      children: children,
    ) : Row(
      children: children,
    );
  }

  void deleteApp(int id){
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Are you sure?"),
      content: const Text("Are you sure you want to delete this application make sure all of it's resources are backed up!"),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
        FilledButton(onPressed: () async {
          Navigator.of(context).pop();

          setState(() {
            isLoading = true;
          });

          Map<String, dynamic> response = await makeRequest(
              prefs: prefs,
              method: "POST",
              data: {
                "id" : id.toString(),
              },
              endpoint: "v1/auth/app/delete"
          );

          setState(() {
            isLoading = false;
          });

          if(response['status'] == true){
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(response['message']),behavior: SnackBarBehavior.floating,width: 280,)
            );

            fetchApps();
          }else{
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(response['message']),behavior: SnackBarBehavior.floating,width: 280,)
            );
          }

        }, child: const Text("Delete"))
      ],
    ));
  }

  void doAction(String action,int id){
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Are you sure?"),
      content: Text("Are you sure you want to $action this application."),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
        FilledButton(onPressed: () async {
          Navigator.of(context).pop();

          setState(() {
            isLoading = true;
          });

          Map<String, dynamic> response = await makeRequest(
              prefs: prefs,
              method: "POST",
              data: {
                "id" : id.toString(),
              },
              endpoint: "v1/auth/app/$action"
          );

          setState(() {
            isLoading = false;
          });

          if(response['status'] == true){
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(response['message']),behavior: SnackBarBehavior.floating,width: 280,)
            );

            fetchApps();
          }else{
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(response['message']),behavior: SnackBarBehavior.floating,width: 280,)
            );
          }

        }, child: const Text("Proceed"))
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton(onPressed: () => addApps(), child: const Text("Add +"))
              ],
            ),
            const Divider(),
            for(var app in apps) Container(
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.black)
              ),
              child: ListTile(
                leading: app['application_running'] == false ? Icon(Icons.apps_outage,color: app['application_enabled'] ? Colors.red : null,) :  Icon(Icons.apps, color: app['application_enabled'] == false ? Colors.pinkAccent : Colors.blue),
                title: Text(app['application_name']),
                subtitle: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app['application_runtime']),
                    Text(app['application_run_dir']),
                    Row(
                      children: [
                        app['application_running'] ?
                          IconButton(onPressed: () {
                            doAction("stop", app['application_id']);
                          }, icon: const Icon(Icons.pause))
                            : IconButton(onPressed: () {
                          doAction("start", app['application_id']);
                        }, icon: const Icon(Icons.play_arrow)),

                        IconButton(onPressed: () => deleteApp(app['application_id']), icon: const Icon(Icons.delete))
                      ],
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
      floatingActionButton: isLoading ? const Card(
        child: Padding(
          padding: EdgeInsets.all(18.0),
          child: CircularProgressIndicator(),
        ),
      ) : FilledButton(onPressed: () => fetchApps(), child: const Icon(Icons.refresh)),
    );
  }
}