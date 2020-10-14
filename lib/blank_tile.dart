import 'package:flutter/material.dart';

class BlankTTile extends StatefulWidget {
  @override
  _BlankTileState createState() => _BlankTileState();

}

class _BlankTileState extends State<BlankTTile> {
  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.all(10.0),
        color: Colors.grey[900],
        // Image(image: AssetImage('assets/wtw.png'));
        // width: 80.0,
        // height: 80.0,
    );
  }

}
