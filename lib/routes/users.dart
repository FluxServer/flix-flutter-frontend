import 'package:flutter/material.dart';
import 'package:flutter_client/utils/request.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/responsive.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key, required this.callback});

  final Function callback;

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  bool isLoading = false;
  late SharedPreferences prefs;

  TextEditingController userDisplayName = TextEditingController();
  TextEditingController userName = TextEditingController();
  TextEditingController userPassword = TextEditingController();

  List<Map> users = [];

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

    fetchUsers();
  }

  void addUsers() async {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Add Users"),
      content: SizedBox(
        width: 200,
        height: 300,
        child: Column(
          children: [
            TextFormField(
              controller: userDisplayName,
              decoration: const InputDecoration(
                labelText: "User Display Name"
              ),
            ),
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
          Navigator.of(context).pop();

          setState(() {
            isLoading = true;
          });

          Map<String, dynamic> response = await makeRequest(
              prefs: prefs,
              method: "POST",
              data: {
                "username" : userName.value.text,
                "displayName" : userDisplayName.value.text,
                "password": userPassword.value.text
              },
              endpoint: "v1/auth/users/new"
          );

          setState(() {
            isLoading = false;
          });

          if(response['status'] == true){
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(response['message']),behavior: SnackBarBehavior.floating,width: 280,)
            );

            fetchUsers();
          }else{
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(response['message']),behavior: SnackBarBehavior.floating,width: 280,)
            );
          }
        }, child: const Text("Add"))
      ],
    ));
  }

  void fetchUsers() async {
    setState(() {
      isLoading = true;
    });

    Map<String, dynamic> response = await makeRequest(
        prefs: prefs,
        method: "GET",
        data: {},
        endpoint: "v1/auth/users/list"
    );

    if(!context.mounted) return;

    setState(() {
      isLoading = false;
    });

    if(response['status'] == true){
      if(context.mounted){
        setState(() {
          users = List.from(response['data']);
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

  void editUser(int id,var data){
    TextEditingController eUserDisplayName = TextEditingController(text: data['displayName']);
    TextEditingController eUserName = TextEditingController(text: data['username']);
    TextEditingController eUserPassword = TextEditingController(text: data['password']);

    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Add Users"),
      content: SizedBox(
        width: 200,
        height: 300,
        child: Column(
          children: [
            TextFormField(
              controller: eUserDisplayName,
              decoration: const InputDecoration(
                  labelText: "User Display Name"
              ),
            ),
            TextFormField(
              controller: eUserName,
              decoration: const InputDecoration(
                  labelText: "Username"
              ),
            ),
            TextFormField(
              controller: eUserPassword,
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
          Navigator.of(context).pop();

          setState(() {
            isLoading = true;
          });

          Map<String, dynamic> response = await makeRequest(
              prefs: prefs,
              method: "POST",
              data: {
                "id" : id,
                "username" : eUserName.value.text,
                "displayName" : eUserDisplayName.value.text,
                "password": eUserPassword.value.text
              },
              endpoint: "v1/auth/users/edit"
          );

          setState(() {
            isLoading = false;
          });

          if(response['status'] == true){
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(response['message']),behavior: SnackBarBehavior.floating,width: 280,)
            );

            fetchUsers();
          }else{
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(response['message']),behavior: SnackBarBehavior.floating,width: 280,)
            );
          }
        }, child: const Text("Edit"))
      ],
    ));
  }

  void deleteUser(int id){
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Are you sure?"),
      content: const Text("Are you sure you want to delete this user make sure all of it's resources are deleted too!"),
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
              endpoint: "v1/auth/users/delete"
          );

          setState(() {
            isLoading = false;
          });

          if(response['status'] == true){
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(response['message']),behavior: SnackBarBehavior.floating,width: 280,)
            );

            fetchUsers();
          }else{
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(response['message']),behavior: SnackBarBehavior.floating,width: 280,)
            );
          }

        }, child: const Text("Delete"))
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
                FilledButton(onPressed: () => addUsers(), child: const Text("Add +"))
              ],
            ),
            const Divider(),
            for(var user in users) Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black)
              ),
              child: ListTile(
                leading: Icon(user['user_type'] == 0 ? Icons.settings : Icons.person),
                title: Text(user['displayName']),
                subtitle: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    user['user_type'] == 0 ? const SizedBox() : IconButton(onPressed: () => deleteUser(user['id']), icon: const Icon(Icons.delete)),
                    IconButton(onPressed: () => editUser(user['id'] , user), icon: const Icon(Icons.edit))
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
      ) : FilledButton(onPressed: () => fetchUsers(), child: const Icon(Icons.refresh)),
    );
  }
}