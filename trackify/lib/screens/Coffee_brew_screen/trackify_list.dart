import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackify/models/trackify.dart';
import 'package:trackify/screens/Coffee_brew_screen/trackify_tile.dart';

class TrackifyList extends StatefulWidget {
  const TrackifyList({super.key});

  @override
  State<TrackifyList> createState() => _TrackifyListState();
}


class _TrackifyListState extends State<TrackifyList> {
  @override
  Widget build(BuildContext context) {
    final trackify = Provider.of<List<Trackify>?>(context) ?? [];

    // if (trackify == null) {
    //   return const Center(child: CircularProgressIndicator());
    // }

    return ListView.builder(
      itemCount: trackify.length,
      itemBuilder: (content, index) {
        
        return TrackifyTile(trackify: trackify[index]);
      },
    );
  }
}
