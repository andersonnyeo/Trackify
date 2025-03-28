import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trackify/models/trackify.dart';
import 'package:trackify/models/user.dart';

class DatabaseService {

  final String uid;
  DatabaseService({required this.uid});

  // Collection reference
  final CollectionReference trackifyCollection = FirebaseFirestore.instance.collection('trackify');
  
  Future updateUserData(String name) async {
    return await trackifyCollection.doc(uid).set({
      'name' : name,
    });

  }


  // Trackify list from snapshot
    List<Trackify> _trackifyListFromSnapshot(QuerySnapshot snapshot) {
      return snapshot.docs.map((doc) {
        // Cast doc.data() to a Map for safe access
        final data = doc.data() as Map<String, dynamic>?;

        return Trackify(
          name: data?['name'] ?? 'Unnamed',
        );
      }).toList();
    }


  // UserData from snapshot
  UserData _userDataFromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>?; // Safe casting

    return UserData(
      uid: uid,
      name: data?['name'] ?? 'Unnamed',
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