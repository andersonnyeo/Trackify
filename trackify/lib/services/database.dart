import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trackify/models/trackify.dart';

class DatabaseService {

  final String uid;
  DatabaseService({required this.uid});

  // Collection reference
  final CollectionReference trackifyCollection = FirebaseFirestore.instance.collection('trackify');
  
  Future updateUserData(String sugars, String name, int strength) async {
    return await trackifyCollection.doc(uid).set({
      'sugars' : sugars,
      'name' : name,
      'strength' : strength,
    });

  }


  // brew list from snapshot
  List<Trackify> _trackifyListFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      // Cast doc.data() to a Map for safe access
      final data = doc.data() as Map<String, dynamic>?;

      return Trackify(
        name: data?['name'] ?? 'Unnamed',
        strength: data?['strength'] ?? 0,
        sugars: data?['sugars'] ?? '0',
      );
    }).toList();
  }


  // get trackify stream
  Stream <List<Trackify>> get trackify {
    return trackifyCollection.snapshots()
    .map(_trackifyListFromSnapshot);
  }


}