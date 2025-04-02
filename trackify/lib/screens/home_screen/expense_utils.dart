// expense_utils.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


void deleteExpenseWhenEdit(BuildContext context, FirebaseFirestore firestore, String uid, String docId, String expenseId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Expense"),
        content: const Text("Are you sure you want to delete this expense?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              firestore
                  .collection('users')
                  .doc(uid)
                  .collection('expenseDocuments')
                  .doc(docId)
                  .collection('expenses')
                  .doc(expenseId)
                  .delete();

              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }



void deleteExpenseDocument(BuildContext context, FirebaseFirestore firestore, String uid, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Expense Document"),
        content: const Text("Are you sure you want to delete this expense document? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              firestore.collection('users').doc(uid).collection('expenseDocuments').doc(docId).delete();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Expense document deleted successfully')),
              );
              Navigator.pop(context);
              Navigator.pop(context); // Go back to the previous screen after deletion
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
