import 'package:cloud_firestore/cloud_firestore.dart';

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

}