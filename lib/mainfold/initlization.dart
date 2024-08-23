import 'package:flutter/material.dart';

class InitPage extends StatefulWidget {
  const InitPage({super.key, required this.apiURI});

  final String apiURI;

  @override
  State<InitPage> createState() => _InitPageState();
}

class _InitPageState extends State<InitPage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}