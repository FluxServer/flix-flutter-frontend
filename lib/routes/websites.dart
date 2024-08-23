import 'package:flutter/material.dart';
import 'package:flutter_client/utils/request.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:highlight/languages/nginx.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import '../utils/responsive.dart';

class WebPage extends StatefulWidget {
  const WebPage({super.key, required this.callback});

  final Function callback;

  @override
  State<WebPage> createState() => _WebPageState();
}

class _WebPageState extends State<WebPage> {
  bool isLoading = false;
  late SharedPreferences prefs;

  List<Map> sitesList = [];
  List<Map> applList = [];

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

    fetchWebsites();
    fetchApplications();
  }

  void addNewWebsite() async {
    showDialog(
        context: context,
        builder: (ctx) {
          TextEditingController webDomain = TextEditingController();
          TextEditingController webProxy = TextEditingController();
          bool webPHPEnabled = false;
          int applicationId = 0;
          String webPHPVersion = "8.1";
          bool webProxyEnabled = false;
          bool processing = false;

          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: const Text("New Website"),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  height: 260,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: webDomain,
                        decoration:
                            const InputDecoration(labelText: "Web Domain"),
                      ),
                      const SizedBox(
                        height: 6,
                      ),
                      DropdownButtonFormField<bool>(
                          value: webProxyEnabled,
                          items: const [
                            DropdownMenuItem(
                              value: true,
                              child: Text("Enable Proxy"),
                            ),
                            DropdownMenuItem(
                              value: false,
                              child: Text("Disable Proxy"),
                            ),
                          ],
                          onChanged: webPHPEnabled
                              ? null
                              : (bool? status) async {
                                  setState(() {
                                    webProxyEnabled = status!;
                                    webPHPEnabled = false;
                                  });
                                }),
                      webProxyEnabled
                          ? TextFormField(
                              controller: webProxy,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: false),
                              decoration: const InputDecoration(
                                  labelText: "Web Proxy Port"),
                            )
                          : const SizedBox(),
                      webProxyEnabled
                          ? DropdownButtonFormField<int>(
                              value: applicationId,
                              items: [
                                const DropdownMenuItem(
                                    value: 0, child: Text("none")),
                                for (var app in applList)
                                  DropdownMenuItem(
                                      value: app['application_id'],
                                      child: Text(app['application_name']))
                              ],
                              onChanged: (int? value) async {
                                setState(() {
                                  applicationId = value!;
                                });
                              })
                          : const SizedBox(),
                      DropdownButtonFormField<bool>(
                          value: webPHPEnabled,
                          items: const [
                            DropdownMenuItem(
                              value: true,
                              child: Text("Enable PHP"),
                            ),
                            DropdownMenuItem(
                              value: false,
                              child: Text("Disable PHP"),
                            ),
                          ],
                          onChanged: webProxyEnabled
                              ? null
                              : (bool? status) async {
                                  setState(() {
                                    webPHPEnabled = status!;
                                    webProxyEnabled = false;
                                  });
                                }),
                      webPHPEnabled
                          ? DropdownButtonFormField<String>(
                              value: webPHPVersion,
                              items: const [
                                DropdownMenuItem(
                                    value: "8.1", child: Text("PHP 8.1")),
                                DropdownMenuItem(
                                    value: "8.2", child: Text("PHP 8.2")),
                              ],
                              onChanged: (String? value) async {
                                setState(() {
                                  webPHPVersion = value!;
                                });
                              })
                          : const SizedBox(),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Cancel")),
                FilledButton(
                    onPressed: processing
                        ? null
                        : () async {
                            setState(() {
                              processing = true;
                            });

                            Map<String, dynamic> response = await makeRequest(
                                prefs: prefs,
                                method: "POST",
                                data: {
                                  "domain" : webDomain.text,
                                  "enable_php" : webPHPEnabled ? "on" : "off",
                                  "php" : webPHPVersion,
                                  "app_link" : webProxyEnabled ? applicationId : "none",
                                  "port": webProxyEnabled ? int.parse(webProxy.text) : 0
                                },
                                endpoint: "v1/auth/sites/new");

                            if(response['status'] == true){
                              setState(() {
                                processing = false;
                              });

                              Navigator.of(context).pop();
                              fetchWebsites();

                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(response['message']),
                                behavior: SnackBarBehavior.floating,
                                width: 280,
                              ));
                            }else{
                              setState(() {
                                processing = false;
                              });

                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(response['message']),
                                behavior: SnackBarBehavior.floating,
                                width: 280,
                              ));
                            }
                          },
                    child: const Text("New"))
              ],
            );
          });
        });
  }

  void fetchApplications() async {
    setState(() {
      isLoading = true;
    });

    Map<String, dynamic> applications = await makeRequest(
        prefs: prefs, method: "GET", data: {}, endpoint: "v1/auth/app/list");

    if (!context.mounted) return;

    setState(() {
      isLoading = false;
    });

    if (applications['status'] == true) {
      setState(() {
        applList = List.from(applications['data']);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(applications['message']),
        behavior: SnackBarBehavior.floating,
        width: 280,
      ));
    }
  }

  void fetchWebsites() async {
    setState(() {
      isLoading = true;
    });

    Map<String, dynamic> sites = await makeRequest(
        prefs: prefs, method: "GET", data: {}, endpoint: "v1/auth/sites/list");

    if (!context.mounted) return;

    setState(() {
      isLoading = false;
    });

    if (sites['status'] == true) {
      setState(() {
        sitesList = List.from(sites['data']);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(sites['message']),
        behavior: SnackBarBehavior.floating,
        width: 280,
      ));
    }
  }

  Widget colOrRow({required List<Widget> children}) {
    return isMobile(context)
        ? Column(
            children: children,
          )
        : Row(
            children: children,
          );
  }

  void saveNginxConfig(siteId, config) async {
    setState(() {
      isLoading = true;
    });

    Map<String, dynamic> response = await makeRequest(
        prefs: prefs,
        method: "POST",
        data: {'site_id': siteId, 'config': config},
        endpoint: "v1/auth/sites/config");

    if (response['status'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(response['message']),
        behavior: SnackBarBehavior.floating,
        width: 280,
      ));
      setState(() {
        isLoading = false;
      });

      fetchWebsites();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(response['message']),
        behavior: SnackBarBehavior.floating,
        width: 280,
      ));
    }
  }

  void assignSSL(siteId, domain) async {
    setState(() {
      isLoading = true;
    });

    Map<String, dynamic> response = await makeRequest(
        prefs: prefs,
        method: "POST",
        data: {'site_id': siteId, 'domain': domain},
        endpoint: "v1/auth/sites/ssl-new");

    if (response['status'] == true) {
      Navigator.of(context).pop();
      fetchWebsites();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(response['message']),
        behavior: SnackBarBehavior.floating,
        width: 280,
      ));
      setState(() {
        isLoading = false;
      });

      fetchWebsites();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(response['message']),
        behavior: SnackBarBehavior.floating,
        width: 280,
      ));
    }
  }

  void deleteSite(siteId) async {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Are you sure"),
      content: const Text("All the contents would be lost forever are you sure?"),
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
              data: {'site_id': siteId},
              endpoint: "v1/auth/sites/delete");

          if (response['status'] == true) {
            fetchWebsites();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(response['message']),
              behavior: SnackBarBehavior.floating,
              width: 280,
            ));
            setState(() {
              isLoading = false;
            });

            fetchWebsites();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(response['message']),
              behavior: SnackBarBehavior.floating,
              width: 280,
            ));
          }
        }, child: const Text("Sure"))
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
                FilledButton(
                    onPressed: () => addNewWebsite(), child: const Text("Add"))
              ],
            ),
            const Divider(),
            Column(
              children: [
                for (var site in sitesList)
                  Card(
                    child: SizedBox(
                      width: 1000,
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  IconButton(onPressed: ()=>deleteSite(site['site_id']), icon: const Icon(Icons.delete)),
                                  Icon(
                                    site['site_ssl_enabled']
                                        ? Icons.lock_outline
                                        : Icons.lock_open_outlined,
                                    color: site['site_ssl_enabled']
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  Text(
                                    site['site_domain_1'],
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ],
                              ),
                              const Divider(),
                              colOrRow(children: [
                                SizedBox(
                                  width: 200,
                                  height: 80,
                                  child: Container(
                                    decoration: BoxDecoration(
                                        border: Border.all(color: Colors.black),
                                        borderRadius: BorderRadius.circular(2)),
                                    child: ListTile(
                                      titleAlignment:
                                          ListTileTitleAlignment.top,
                                      onTap: () async {
                                        assignSSL(site['site_id'],
                                            site['site_domain_1']);
                                      },
                                      leading: Icon(
                                        site['certificate']['expired']
                                            ? Icons.broken_image
                                            : site['site_ssl_enabled']
                                                ? Icons.lock_outline
                                                : Icons.lock_open_outlined,
                                        color: site['site_ssl_enabled']
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      title: const Text("SSL Certificate"),
                                      subtitle: site['site_ssl_enabled']
                                          ? Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    "${site['certificate']['daysLeft']} Days Left")
                                              ],
                                            )
                                          : const Text("Click to assign SSL"),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 200,
                                  height: 80,
                                  child: Container(
                                    decoration: BoxDecoration(
                                        border: Border.all(color: Colors.black),
                                        borderRadius: BorderRadius.circular(2)),
                                    child: ListTile(
                                      titleAlignment:
                                          ListTileTitleAlignment.top,
                                      leading: Icon(
                                        site['site_proxy_enabled']
                                            ? Icons.link
                                            : Icons.link_off,
                                        color: site['site_proxy_enabled']
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      title: const Text("Site Proxy"),
                                      subtitle: site['site_proxy_enabled']
                                          ? Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    "/ -> 127.0.0.1:${site['site_proxy_port']}")
                                              ],
                                            )
                                          : const Text("Proxy Disabled"),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 200,
                                  height: 80,
                                  child: Container(
                                    decoration: BoxDecoration(
                                        border: Border.all(color: Colors.black),
                                        borderRadius: BorderRadius.circular(2)),
                                    child: ListTile(
                                      titleAlignment:
                                          ListTileTitleAlignment.top,
                                      leading: FaIcon(
                                        FontAwesomeIcons.php,
                                        color: site['site_php_enabled']
                                            ? Colors.blue
                                            : Colors.red,
                                      ),
                                      title: const Text("PHP"),
                                      subtitle: site['site_php_enabled']
                                          ? Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    "PHP Version : ${site['site_php_version']}")
                                              ],
                                            )
                                          : const Text("PHP Disabled"),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 200,
                                  height: 80,
                                  child: Container(
                                    decoration: BoxDecoration(
                                        border: Border.all(color: Colors.black),
                                        borderRadius: BorderRadius.circular(2)),
                                    child: ListTile(
                                      titleAlignment:
                                          ListTileTitleAlignment.top,
                                      leading:
                                          const Icon(Icons.settings_outlined),
                                      onTap: () async {
                                        final controller = CodeController(
                                          text: site['site_config'],
                                          // Initial code
                                          language: nginx,
                                        );

                                        showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                                  title: const Text(
                                                      "Additonal NGINX Config"),
                                                  content: SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width -
                                                            500,
                                                    height: 400,
                                                    child: CodeTheme(
                                                      data: CodeThemeData(
                                                          styles:
                                                              monokaiSublimeTheme),
                                                      // <= Pre-defined in flutter_highlight.
                                                      child:
                                                          SingleChildScrollView(
                                                        child: CodeField(
                                                          controller:
                                                              controller,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(),
                                                        child: const Text(
                                                            "Cancel")),
                                                    FilledButton(
                                                        onPressed: () => {
                                                              saveNginxConfig(
                                                                  site[
                                                                      'site_id'],
                                                                  controller
                                                                      .value
                                                                      .text)
                                                            },
                                                        child: const Text(
                                                            "Save & Reload"))
                                                  ],
                                                ));
                                      },
                                      title: const Text("NGINX Conf"),
                                      subtitle:
                                          const Text("Addl. Config for NGINX"),
                                    ),
                                  ),
                                )
                              ])
                            ]),
                      ),
                    ),
                  )
              ],
            )
          ],
        ),
      ),
      floatingActionButton: isLoading
          ? const Card(
              child: Padding(
                padding: EdgeInsets.all(18.0),
                child: CircularProgressIndicator(),
              ),
            )
          : FilledButton(
              onPressed: () => fetchWebsites(),
              child: const Icon(Icons.refresh)),
    );
  }
}
