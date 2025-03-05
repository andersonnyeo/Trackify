import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackify/models/trackify.dart';

class TrackifyList extends StatefulWidget {
  const TrackifyList({super.key});

  @override
  State<TrackifyList> createState() => _TrackifyListState();
}


class _TrackifyListState extends State<TrackifyList> {
  @override
  Widget build(BuildContext context) {
    final trackify = Provider.of<List<Trackify>?>(context);

    if (trackify == null) {
      return const Center(child: CircularProgressIndicator());
    }

    trackify.forEach((trackify){
      print(trackify.name);
      print(trackify.sugars);
      print(trackify.strength);

    });

    return Container();
  }
}
