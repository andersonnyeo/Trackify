import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trackify/models/trackify.dart';
import 'package:trackify/models/user.dart';

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


  // UserData from snapshot
  UserData _userDataFromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>?; // Safe casting

    return UserData(
      uid: uid,
      name: data?['name'] ?? 'Unnamed',
      sugars: data?['sugars'] ?? '0',
      strength: data?['strength'] ?? 0,
    );
  }

  // get trackify stream
  Stream <List<Trackify>> get trackify {
    return trackifyCollection.snapshots()
    .map(_trackifyListFromSnapshot);
  }



  // get user doc stream
  Stream<UserData> get userData {
    return trackifyCollection.doc(uid).snapshots().map(_userDataFromSnapshot);
  }


}