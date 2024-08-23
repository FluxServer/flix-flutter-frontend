import 'package:flutter/material.dart';
import 'package:flutter_client/mainfold/dashboard.dart';
import 'package:flutter_client/utils/request.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/responsive.dart';

class ServerSelectionPage extends StatefulWidget {
  const ServerSelectionPage({super.key});

  @override
  State<ServerSelectionPage> createState() => _ServerSelectionPageState();
}

class _ServerSelectionPageState extends State<ServerSelectionPage> {
  List<Map> servers = [];
  late SharedPreferences prefs;
  bool isLoading = false;
  bool isButtonLoading = false;

  TextEditingController serverName = TextEditingController();
  TextEditingController serverAPI = TextEditingController();

  TextEditingController userName = TextEditingController();
  TextEditingController userPassword = TextEditingController();
  TextEditingController displayName = TextEditingController();

  @override
  void initState() {
    super.initState();
    initSharedPrefs();
  }

  void initSharedPrefs () async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      prefs = pref;
    });
    fetchServers();
  }

  void fetchServers () async {
    Set<String> keys = prefs.getKeys();
    List<Map> tempMapBuild = [];

    for(var key in keys) {
      if(key.startsWith("!server:")) {
        tempMapBuild.add({
          'name': key.replaceFirst("!server:", ""),
          'api': prefs.get(key),
        });
      }
    }

    setState(() {
      servers = tempMapBuild;
    });
  }

  void processAddServer() async {
    Navigator.of(context).pop();

    prefs.setString("!server:${serverName.value.text}", serverAPI.value.text);

    fetchServers();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Sucessfully added"),behavior: SnackBarBehavior.floating,width: 200,)
    );
  }

  void setServer(String id) async {
    setState(() {
      isLoading = true;
    });

    prefs.setString("currentServer", id);

    if(prefs.containsKey("login_token")){
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (ctx) => const DashboardPage()
          )
      );

      return;
    }

    Map<String, dynamic> data = await makeRequest(
        prefs: prefs,
        method: "GET",
        data: {},
        endpoint: "v1/_uscnt"
    );


    setState(() {
      isLoading = false;
    });

    if(data['status'] == true){
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Server Ping Sucessfully done."),behavior: SnackBarBehavior.floating,width: 280,)
      );

      if(data['count'] == 0) {

      }else {
        showDialog(context: context, builder: (ctx) => AlertDialog(
          title: const Text("Login to your Flix Server"),
          content: SizedBox(
            height: 200,
            width: isMobile(context) ? MediaQuery.of(context).size.width - 200 : 300,
            child: Column(
              children: [
                TextFormField(
                  controller: userName,
                  decoration: const InputDecoration(
                    labelText: "Username"
                  ),
                ),
                TextFormField(
                  controller: userPassword,
                  decoration: const InputDecoration(
                      labelText: "Password"
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
            FilledButton(onPressed: () async {
              setState(() {
                isButtonLoading = true;
              });

              Map<String, dynamic> data = await makeRequest(
                  prefs: prefs,
                  method: "POST",
                  data: {
                    'username' : userName.value.text,
                    'password': userPassword.value.text
                  },
                  endpoint: "v1/login"
              );

              setState(() {
                isButtonLoading = false;
              });

              if(data['status'] == true){
                Navigator.of(context).pop();
                prefs.setString("login_token", data['token']);
                prefs.setString("login_displayName", data['displayName']);
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (ctx) => const DashboardPage()
                    )
                );
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(data['message']),behavior: SnackBarBehavior.floating,width: 280,)
                );
              }else{
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(data['message']),behavior: SnackBarBehavior.floating,width: 280,)
                );
              }
            }, child: Text(isButtonLoading ? "Logging in" : "Login"))
          ],
        ));
      }

    }else{
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Something went wrong"),behavior: SnackBarBehavior.floating,width: 280,)
      );
    }
  }

  void newServer() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("New Server"),
      content: SingleChildScrollView(
        child: SizedBox(
          width: isMobile(context) ? null : MediaQuery.of(context).size.width - 600,
          height: isMobile(context) ? null : MediaQuery.of(context).size.height - 400,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const ListTile(
                leading: Icon(Icons.info),
                title: Text("Some Examples are \"aqua-server\" or \"production or staging servers\""),
              ),
              TextFormField(
                controller: serverName,
                decoration: const InputDecoration(
                  labelText: "Server Name/Label"
                ),
              ),
              const ListTile(
                  leading: Icon(Icons.info),
                  title: Text("The API Must Point to FLix Backend URI with PORT HTTP/HTTPS should be provided by the user as of now."),
              ),
              TextFormField(
                controller: serverAPI,
                decoration: const InputDecoration(
                    labelText: "Server URL/API"
                ),
              )
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
        FilledButton(onPressed: () => processAddServer(), child: const Text("Add"))
      ],
    ));
  }

  Widget serverLists() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            isMobile(context) ? const SizedBox() : FilledButton(onPressed: () => newServer(), child: const Text("New Server")),
          ],
        ),
        const Divider(),
        for(var server in servers) ListTile(
          leading: const Icon(Icons.computer),
          title: Text(server['name']),
          onTap: () => setServer(server['name']),
          subtitle: Text(server['api']),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Flix Web Host Panel"),
        centerTitle: true,
      ),
      floatingActionButton: isLoading ? const Card(
        child: Padding(
          padding: EdgeInsets.all(18.0),
          child: CircularProgressIndicator(),
        ),
      ) : null,
      body: isMobile(context) ? const Text("Meow") : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: SizedBox(
              width: 800,
              height: MediaQuery.of(context).size.height - 320,
              child: Card(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: serverLists(),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}