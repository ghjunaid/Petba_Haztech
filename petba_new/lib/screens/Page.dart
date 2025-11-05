import 'package:flutter/material.dart';

class PageWork extends StatefulWidget {
  PageWork({super.key});

  @override
  State<PageWork> createState() => _PageWorkState();
}

class _PageWorkState extends State<PageWork> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1a1a1a),
      appBar: AppBar(
        backgroundColor: Color(0xFF2d2d2d),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "New Page",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: Text(
          "This is the New Page",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }
}