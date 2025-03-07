import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:trackify/models/user.dart';
import 'package:trackify/services/database.dart';

class AuthService {

  // final FirebaseAuth _auth = FirebaseAuth.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;



  // create user obj based on FirebaseUser
  User? _userFromFirebaseUser(firebase_auth.User? user) {
    return user != null ? User(uid: user.uid) : null;
  }



  // auth change user stream
  Stream<User?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }



  // sign in anon

  Future<User?> signInAnon() async {
    try {
      firebase_auth.UserCredential result = await _auth.signInAnonymously();
      firebase_auth.User? user = result.user;
      return _userFromFirebaseUser(user);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }


  // sign in with email and password
  Future signInWithEmailAndPassword(String email, String password) async {
    try {
      firebase_auth.UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      firebase_auth.User? user = result.user;
      return _userFromFirebaseUser(user);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }


  // register with email and password
  Future registerWithEmailAndPassword(String email, String password) async {
    try {
      firebase_auth.UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      firebase_auth.User? user = result.user;

      // create a new document for the user with the uid
      if (user != null) {
        // Create a new document for the user with the UID
        await DatabaseService(uid: user.uid).updateUserData('0', 'new user', 100);
        return _userFromFirebaseUser(user);
      } else {
        return null;
      }
    }catch(e){
      print(e.toString());
      return null;

    }
  }

  // update password
  Future updatePassword(String newPassword) async {
    try {
      firebase_auth.User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      }
    } catch (e) {
      print(e.toString());
      // throw e;
    }
  }



  // sign out
  Future signOut() async {
    try {
      return await _auth.signOut();
    } catch(e){
      print(e.toString());
      return null;
    }
  }

}