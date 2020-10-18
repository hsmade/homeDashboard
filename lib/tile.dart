import 'package:flutter/material.dart';

class Tile extends StatefulWidget {
  final String title;
  final Widget content;
  const Tile (this.title, this.content): super();

  @override
  _TileState createState() => _TileState();

}

class _TileState extends State<Tile> {
  @override
  Widget build(BuildContext context) {
    return
      Card(
          color: Colors.grey[900],
          child:
            Column(
              children: [
                Expanded(flex:1, child: FittedBox(fit: BoxFit.fill, child: Center(child: Text(widget.title, style: TextStyle(color: Colors.white))))),
                Expanded(flex: 7, child: widget.content)
              ],
            )
      );
  }
}
