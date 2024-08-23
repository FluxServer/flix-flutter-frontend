import 'dart:async';
import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

class VirtualKeyboardView extends StatelessWidget {
  const VirtualKeyboardView(this.keyboard, {super.key});

  final VirtualKeyboard keyboard;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: keyboard,
      builder: (context, child) => ToggleButtons(
        isSelected: [keyboard.ctrl, keyboard.alt, keyboard.shift],
        onPressed: (index) {
          switch (index) {
            case 0:
              keyboard.ctrl = !keyboard.ctrl;
              break;
            case 1:
              keyboard.alt = !keyboard.alt;
              break;
            case 2:
              keyboard.shift = !keyboard.shift;
              break;
          }
        },
        children: const [Text('Ctrl'), Text('Alt'), Text('Shift')],
      ),
    );
  }
}

class VirtualKeyboard extends TerminalInputHandler with ChangeNotifier {
  final TerminalInputHandler _inputHandler;

  VirtualKeyboard(this._inputHandler);

  bool _ctrl = false;

  bool get ctrl => _ctrl;

  set ctrl(bool value) {
    if (_ctrl != value) {
      _ctrl = value;
      notifyListeners();
    }
  }

  bool _shift = false;

  bool get shift => _shift;

  set shift(bool value) {
    if (_shift != value) {
      _shift = value;
      notifyListeners();
    }
  }

  bool _alt = false;

  bool get alt => _alt;

  set alt(bool value) {
    if (_alt != value) {
      _alt = value;
      notifyListeners();
    }
  }

  @override
  String? call(TerminalKeyboardEvent event) {
    return _inputHandler.call(event.copyWith(
      ctrl: event.ctrl || _ctrl,
      shift: event.shift || _shift,
      alt: event.alt || _alt,
    ));
  }
}

class XtermPage extends StatefulWidget {
  final String host;
  final int port;
  final String username;
  final String password;
  const XtermPage({super.key, required this.host, required this.username, required this.password, required this.port});

  @override
  // ignore: library_private_types_in_public_api
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<XtermPage> {
  late final terminal = Terminal(inputHandler: keyboard);

  final keyboard = VirtualKeyboard(defaultInputHandler);

  var title = "SSH Terminal";

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100) , () => initTerminal());
  }

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> initTerminal() async {

    if(kIsWeb) {
      terminal.write('dartssh2 does not supports web client \r\n');
      return;
    }

    terminal.write('Connecting...\r\n');
    late SSHClient client;

    void startTerminalSession() async {
      terminal.write('Connected\r\n');

      final session = await client.shell(
        pty: SSHPtyConfig(
          width: terminal.viewWidth,
          height: terminal.viewHeight,
        ),
      );

      terminal.buffer.clear();
      terminal.buffer.setCursor(0, 0);

      terminal.onTitleChange = (title) {
        setState(() => this.title = title);
      };

      terminal.onResize = (width, height, pixelWidth, pixelHeight) {
        session.resizeTerminal(width, height, pixelWidth, pixelHeight);
      };

      terminal.onOutput = (data) {
        session.write(utf8.encode(data));
      };

      session.stdout
          .cast<List<int>>()
          .transform(Utf8Decoder())
          .listen(terminal.write);

      session.stderr
          .cast<List<int>>()
          .transform(Utf8Decoder())
          .listen(terminal.write);
    }

    if(widget.host == "auto") {
      showDialog(context: context, builder: (ctx) => AlertDialog(
        title: const Text('SSH Connection'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _hostController,
                decoration: const InputDecoration(labelText: 'Host'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter host';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _portController,
                decoration: const InputDecoration(labelText: 'Port'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter port';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter username';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter password';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
              terminal.write("Cancelled\n");
            },
          ),
          TextButton(
            child: const Text('Connect'),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                client = SSHClient(
                  await SSHSocket.connect(_hostController.text, int.parse(_portController.text)),
                  username: _usernameController.text,
                  onPasswordRequest: () => _passwordController.text,
                );

                startTerminalSession();
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ));
    }else{
      client = SSHClient(
        await SSHSocket.connect(widget.host, widget.port),
        username: widget.username,
        onPasswordRequest: () => widget.password,
      );

      startTerminalSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: TerminalView(terminal),
          ),
          VirtualKeyboardView(keyboard),
        ],
      ),
    );
  }
}