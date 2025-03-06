import 'package:flutter/material.dart';
import 'package:trackify/models/trackify.dart';


class TrackifyTile extends StatelessWidget {

  final Trackify trackify; // Correct final variable initialization

  const TrackifyTile({super.key, required this.trackify});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Card(
        margin: const EdgeInsets.fromLTRB(20.0, 6.0, 20.0, 0.0),
        child: ListTile(
          leading: CircleAvatar(
            radius: 25.0,
            backgroundColor: Colors.brown[trackify.strength],
            backgroundImage: const AssetImage('assets/coffee_icon.png'),
          ),
          title: Text(trackify.name),
          subtitle: Text('Takes ${trackify.sugars} sugar(s)'),
        ),
      ),
      );
  }
}