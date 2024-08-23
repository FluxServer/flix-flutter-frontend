import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_client/utils/request.dart';
import 'package:highlight/languages/http.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/responsive.dart';

class File {
  final String filePath;
  final String name;
  final String size;
  final bool isBinary;
  final String extname;
  final bool isDirectory;

  File({
    required this.filePath,
    required this.name,
    required this.size,
    required this.isBinary,
    required this.extname,
    required this.isDirectory,
  });

  factory File.fromJson(Map<String, dynamic> json) {
    return File(
      filePath: json['file_path'],
      name: json['name'],
      size: json['size'],
      isBinary: json['is_binary'],
      extname: json['extname'],
      isDirectory: json['is_directory'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'file_path': filePath,
      'name': name,
      'size': size,
      'is_binary': isBinary,
      'extname': extname,
      'is_directory': isDirectory,
    };
  }
}

class FileResponse {
  final bool status;
  final String message;
  final String currentPath;
  final List<File> files;

  FileResponse({
    required this.status,
    required this.message,
    required this.currentPath,
    required this.files,
  });

  factory FileResponse.fromJson(Map<String, dynamic> json) {
    var filesList = json['files'] as List;
    List<File> fileList = filesList.map((i) => File.fromJson(i)).toList();

    return FileResponse(
      status: json['status'],
      message: json['message'],
      currentPath: json['currentPath'],
      files: fileList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'currentPath': currentPath,
      'files': files.map((file) => file.toJson()).toList(),
    };
  }
}

class FilesPage extends StatefulWidget {
  const FilesPage({super.key, required this.callback});

  final Function callback;

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  late SharedPreferences prefs;
  final TextEditingController _currentPath = TextEditingController(text: "/");

  bool isLoading = false;
  bool multiSelect = false;
  File? selectedFile;
  DateTime? lastTap;
  List<File> selectedFiles = [];
  List<Map> trashList = [];

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

    openPath(_currentPath.value.text);
  }

  Widget colOrRow({required List<Widget> children}) {
    return isMobile(context)
        ? Column(
            children: children,
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: children,
          );
  }

  FileResponse _fileResponse = FileResponse(
      status: true, message: "message", currentPath: "/", files: []);

  void deleteFile(String filePath, String name) async {
    setState(() {
      isLoading = true;
    });

    Map<String, dynamic> response = await makeRequest(
        prefs: prefs,
        method: "POST",
        data: {"path": filePath, "object": name},
        endpoint: "v1/auth/files/trash/move");

    if (!context.mounted) return;

    if (_fileResponse.status == false) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(response['message']),
        behavior: SnackBarBehavior.floating,
        width: 280,
      ));
    } else {
      openPath(_currentPath.text);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(response['message']),
        behavior: SnackBarBehavior.floating,
        width: 280,
      ));
    }
  }

  void openPath(String path) async {
    setState(() {
      isLoading = true;
    });

    Map<String, dynamic> response = await makeRequest(
        prefs: prefs,
        method: "POST",
        data: {"path": path},
        endpoint: "v1/auth/files/list");

    if (!context.mounted) return;

    setState(() {
      _fileResponse = FileResponse.fromJson(response);
      _currentPath.text = _fileResponse.currentPath; // Update the current path
      isLoading = false;
      selectedFile = null; // Clear selection when opening a new path
      selectedFiles.clear(); // Clear multi-selection when opening a new path
    });

    if (_fileResponse.status == false) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(response['message']),
        behavior: SnackBarBehavior.floating,
        width: 280,
      ));
    }
  }

  void handleTap(File file) {
    DateTime now = DateTime.now();
    if (lastTap != null &&
        now.difference(lastTap!) < Duration(milliseconds: 500)) {
      handleDoubleClick(file);
    } else {
      if (multiSelect) {
        setState(() {
          if (selectedFiles.contains(file)) {
            selectedFiles.remove(file);
          } else {
            selectedFiles.add(file);
          }
        });
      } else {
        setState(() {
          selectedFile = file;
        });
      }
    }
    lastTap = now;
  }

  void handleDoubleClick(File file) {
    if (file.isDirectory) {
      openPath(file.filePath);
    } else if (isImageFile(file.extname)) {
      widget.callback(file.filePath);
    }
  }

  void handleBottomNavAction(int index) {
    if (index == 0 && selectedFile != null) {
      if (selectedFile!.isDirectory) {
        openPath(selectedFile!.filePath);
      }
    } else if (index == 1) {
      if (selectedFiles.isEmpty) {
        deleteFile(selectedFile!.filePath, selectedFile!.name);
      } else {
        for (var file in selectedFiles) {
          deleteFile(file.filePath, file.name);
        }
      }
    } else if (index == 2) {
      print('Info ${selectedFile?.name}');
    }

    setState(() {
      selectedFile = null;
      selectedFiles = [];
    });
  }

  void navigateBack() {
    String currentPath = _currentPath.text;
    if (currentPath != "/") {
      String backPath = currentPath.substring(0, currentPath.lastIndexOf('/'));
      if (backPath.isEmpty) {
        backPath = "/";
      }
      openPath(backPath);
    }
  }

  IconData getFileIcon(String extname) {
    if (extname == "") {
      return Icons.folder;
    }
    switch (extname) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
        return Icons.image;
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.doc':
      case '.docx':
        return Icons.description;
      case '.xls':
      case '.xlsx':
        return Icons.table_chart;
      case '.txt':
        return Icons.text_snippet;
      case '.zip':
      case '.rar':
        return Icons.archive;
      case '.mp3':
      case '.wav':
        return Icons.music_note;
      case '.mp4':
      case '.avi':
      case '.mov':
        return Icons.videocam;
      case '.html':
      case '.css':
      case '.js':
      case '.dart':
      case '.cpp':
      case '.py':
        return Icons.code;
      default:
        return Icons.insert_drive_file;
    }
  }

  bool isImageFile(String extname) {
    return ['.jpg', '.jpeg', '.png', '.gif'].contains(extname.toLowerCase());
  }

  void restoreTrash(String trashId) async {
    setState(() {
      isLoading = true;
    });

    Map<String, dynamic> response = await makeRequest(
        prefs: prefs,
        method: "POST",
        data: {'trash_id': trashId},
        endpoint: "v1/auth/files/trash/restore");

    if (response['status'] == true) {
      setState(() {
        isLoading = false;
      });

      openPath(_currentPath.text);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(response['message']),
        behavior: SnackBarBehavior.floating,
        width: 280,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(response['message']),
        behavior: SnackBarBehavior.floating,
        width: 280,
      ));
    }
  }

  void openTrash() async {
    setState(() {
      isLoading = true;
    });

    Map<String, dynamic> response = await makeRequest(
        prefs: prefs,
        method: "GET",
        data: {},
        endpoint: "v1/auth/files/trash/list");

    setState(() {
      trashList = List.from(response['files']);
      isLoading = false;
    });

    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Trash Items"),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  height: 400,
                  child: Column(
                    children: [
                      for (var trash in trashList)
                        Column(
                          children: [
                            Row(
                              children: [
                                IconButton(
                                    onPressed: () =>
                                        restoreTrash(trash['trash_id']),
                                    icon: const Icon(Icons.restore)),
                                Text(trash['name'])
                              ],
                            ),
                            const Divider()
                          ],
                        )
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Cancel"))
              ],
            ));
  }

  void uploadFile() async {
    showDialog(
        context: context,
        builder: (ctx) {
          double _uploadProgress = 0.0;
          bool _isUploading = false;
          return StatefulBuilder(
            builder: (BuildContext context,
                void Function(void Function()) setState) {
              Future<void> _uploadFile(
                  Uint8List fileData, String fileName) async {
                setState(() {
                  _isUploading = true;
                  _uploadProgress = 0.0;
                });

                var headers = {
                  'Authorization': 'Token ${prefs.getString("login_token")}'
                };

                String? apiUri = prefs
                    .getString("!server:${prefs.getString("currentServer")}");

                var request = http.MultipartRequest(
                    'POST', Uri.parse('${apiUri}v1/auth/files/upload'));
                request.fields.addAll({'path': _currentPath.text});

                var multipartFile = http.MultipartFile.fromBytes(
                  'file',
                  fileData,
                  filename: fileName,
                );

                request.files.add(multipartFile);
                request.headers.addAll(headers);

                var response = await request.send();
                List<int> responseBytes = [];
                response.stream.listen((value) {
                  setState(() {
                    _uploadProgress += value.length / response.contentLength!;
                  });
                  responseBytes.addAll(value);
                }).onDone(() async {
                  if (response.statusCode == 200) {
                    String responseString = utf8.decode(responseBytes);
                    print(responseString);
                    openPath(_currentPath
                        .text); // Refresh the file list after upload
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('File uploaded successfully'),
                        behavior: SnackBarBehavior.floating,
                        width: 280,
                      ),
                    );
                    Navigator.of(context).pop();
                  } else {
                    print(response.reasonPhrase);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('File upload failed'),
                        behavior: SnackBarBehavior.floating,
                        width: 280,
                      ),
                    );
                  }
                  setState(() {
                    _isUploading = false;
                  });
                });
              }

              Future<void> _pickFile() async {
                final XFile? files = await openFile();

                _uploadFile(await files!.readAsBytes(), files.name);
              }

              return AlertDialog(
                title: const Text('Upload File'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _isUploading
                        ? LinearProgressIndicator(value: _uploadProgress)
                        : ElevatedButton(
                            onPressed: _pickFile,
                            child: const Text('Pick File'),
                          ),
                  ],
                ),
                actions: [
                  _isUploading
                      ? const SizedBox.shrink()
                      : TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Cancel'),
                        ),
                ],
              );
            },
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Explorer'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: navigateBack,
        ),
        actions: [
          FilledButton(
              onPressed: () => openTrash(), child: const Text("Trash")),
          const SizedBox(
            width: 2,
          ),
          Row(
            children: [
              const Text("Enable Multi-Select"),
              IconButton(
                icon: Icon(multiSelect
                    ? Icons.check_box
                    : Icons.check_box_outline_blank),
                onPressed: () {
                  setState(() {
                    multiSelect = !multiSelect;
                    if (!multiSelect) {
                      selectedFiles.clear();
                    }
                  });
                },
              ),
            ],
          )
        ],
      ),
      floatingActionButton: isLoading
          ? const Card(
              child: CircularProgressIndicator(),
            )
          : const SizedBox(),
      bottomNavigationBar: selectedFile != null || selectedFiles.isNotEmpty
          ? BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.open_in_new),
                  label: 'Open',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.delete),
                  label: 'Delete',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.info),
                  label: 'Info',
                ),
              ],
              onTap: handleBottomNavAction,
            )
          : const SizedBox.shrink(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              colOrRow(
                children: [
                  SizedBox(
                    width: isMobile(context)
                        ? null
                        : MediaQuery.of(context).size.width - 500,
                    child: TextFormField(
                      controller: _currentPath,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Current Path"),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  FilledButton(
                      onPressed: () {
                        openPath(_currentPath.text);
                      },
                      child: const Row(
                        children: [Text("Open"), Icon(Icons.navigate_next)],
                      )),
                  PopupMenuButton(
                    icon: const Icon(Icons.add),
                    onSelected: (value) {
                      if(value == "upload_file") uploadFile();
                    },
                    itemBuilder: (BuildContext bc) {
                      return const [
                        PopupMenuItem(
                          value: "new_file",
                          child: Text("New File"),
                        ),
                        PopupMenuItem(
                          value: "new_folder",
                          child: Text("New Folder"),
                        ),
                        PopupMenuItem(
                          value: "upload_file",
                          child: Text("Upload"),
                        ),
                      ];
                    },
                  )
                ],
              ),
              const SizedBox(height: 10),
              _fileResponse.files.isEmpty
                  ? const Text('No files found')
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isMobile(context) ? 2 : 4,
                        // Number of columns
                        childAspectRatio: 3 / 2, // Aspect ratio of each item
                      ),
                      itemCount: _fileResponse.files.length,
                      itemBuilder: (context, index) {
                        final file = _fileResponse.files[index];
                        bool isSelected = multiSelect
                            ? selectedFiles.contains(file)
                            : selectedFile == file;
                        return GestureDetector(
                          onTap: () {
                            handleTap(file);
                          },
                          onDoubleTap: () {
                            handleDoubleClick(file);
                          },
                          child: Card(
                            elevation: 4.0,
                            margin: const EdgeInsets.all(8.0),
                            color: isSelected ? Colors.blue[100] : null,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(getFileIcon(file.extname)),
                                  Text(
                                    file.name,
                                    style: const TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text('Size: ${file.size}'),
                                  Text(
                                      'Binary: ${file.isBinary ? 'Yes' : 'No'}'),
                                  Text(
                                      'Directory: ${file.isDirectory ? 'Yes' : 'No'}'),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
