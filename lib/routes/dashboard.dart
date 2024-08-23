import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_client/utils/request.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/responsive.dart';

class DashPage extends StatefulWidget {
  const DashPage({super.key, required this.callback});

  final Function callback;

  @override
  State<DashPage> createState() => _DashPageState();
}

class _DashPageState extends State<DashPage> {
  bool isLoading = false;
  late SharedPreferences prefs;

  String flixPlatform = "none";

  Map<String, dynamic> networkInterfaces = {};
  List<Map> storageDevices = [];

  String processor = "Catenium Meowore meow7 mWW003 ";

  Map<String,dynamic> memory = {};

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
        endpoint: "v1/auth/sysinfo"
    );

    if(!context.mounted) return;

    setState(() {
      isLoading = false;
    });

    if(response['status'] == true){
      if(context.mounted){
        setState(() {
          flixPlatform = response['platform'];
          networkInterfaces = Map.from(response['network']['interfaces']);
          storageDevices = List.from(response['storage']['devices']);
          processor = "${response['processor']['model']} (${response['processor']['speed']})";
          memory = Map.from(response['memory']);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.settings_applications_rounded),
                title: const Text("Flix Platform"),
                subtitle: Text(flixPlatform),
              ),
              ListTile(
                leading: const Icon(Icons.computer),
                title: const Text("Processor"),
                subtitle: Text(processor),
              ),
              const Divider(),
              colOrRow(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black)
                    ),
                    child: SizedBox(
                      width: 290,
                      height: 130,
                      child: memory.isEmpty ? const SizedBox() : Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.memory),
                                Text("Memory",style: TextStyle(
                                    fontSize: 30
                                ),),
                              ],
                            ),
                            Text("Total : ${memory['total']}\nUsed : ${memory['used']}\n Free : ${memory['free']}")
                          ],
                        ),
                      ),
                    ),
                  ),
                  isMobile(context) ? const Divider() : const VerticalDivider(),
                  Container(
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.black)
                    ),
                    child: memory.isNotEmpty ? SizedBox(
                      width: 290,
                      height: 130,
                      child: memory['swap'].isEmpty ? const SizedBox() : Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.memory),
                                Text("Swap Memory",style: TextStyle(
                                    fontSize: 30
                                ),),
                              ],
                            ),
                            Text("Total : ${memory['swap']['total']}\nUsed : ${memory['swap']['used']}\n Free : ${memory['swap']['free']}")
                          ],
                        ),
                      ),
                    ) : const SizedBox(),
                  ),
                ]
              ),
              const Divider(),
              Flex(direction: Axis.horizontal,children: [SizedBox(
                width: MediaQuery.of(context).size.width - 284,
                height: networkInterfaces.length * 120,
                child: GridView(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                  children: [
                    for(var interface in networkInterfaces.keys) Card(
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Column(
                          children: [
                            Column(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.network_cell),
                                  title: Text(interface)
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    for(var ip in List.from(networkInterfaces[interface])) ListTile(
                                      leading: IconButton(
                                        icon: const Icon(Icons.copy),
                                        onPressed: () {
                                          Clipboard.setData(
                                              ClipboardData(text: ip['address'])
                                          );
                                        },
                                      ),
                                      title: Text(ip['address']),
                                      subtitle: Text(ip['family']),
                                    )
                                  ],
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              )],)
            ],
          ),
        ),
      ),
      floatingActionButton: isLoading ? const Card(
        child: Padding(
          padding: EdgeInsets.all(18.0),
          child: CircularProgressIndicator(),
        ),
      ) : FilledButton(onPressed: () => fetchSystemInfo(), child: const Icon(Icons.refresh)),
    );
  }
}