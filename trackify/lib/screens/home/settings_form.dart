import 'package:flutter/material.dart';
import 'package:trackify/shared/constants.dart';


class SettingsForm extends StatefulWidget {
  const SettingsForm({super.key});

  @override
  State<SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<SettingsForm> {

  final _formKey = GlobalKey<FormState>();
  final List<String> sugars = ['0', '1', '2', '3', '4'];


  String? _currentName;
  String? _currentSugars;
  int? _currentStrength;


  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          const Text(
            'Update your trackify settings',
            style: TextStyle(fontSize: 18.0),
          ),
          const SizedBox(height: 20.0),
          TextFormField(
            decoration: textInputDecoration,
            validator: (val) => val!.isEmpty ? 'Please enter a name' : null,
            onChanged: (val) => setState(() => _currentName = val),
          ),
          const SizedBox(height: 20.0),


          // dropdown
          DropdownButtonFormField(
            decoration: textInputDecoration,
            value: _currentSugars ?? '0',
            items: sugars.map((sugar){
              return DropdownMenuItem(
                value: sugar,
                child: Text('$sugar sugars'),
              );
            }).toList(),
            onChanged: (val) {
              setState(() => _currentSugars = val);
            },
          ),



          // slider
          Slider(
            value: (_currentStrength ?? 100).toDouble(),
            activeColor: Colors.brown[_currentStrength ?? 100],
            inactiveColor: Colors.brown,
            min: 100.0,
            max: 900.0,
            divisions: 8,
            onChanged: (val) => setState(() => _currentStrength = val.round()),
          ),
          

          // Submit button 
          ElevatedButton  (
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink[400], // Button color
            ),
            child: const Text(
              'Update',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () async {
              print(_currentName);
              print(_currentSugars);
              print(_currentStrength);
            }
          )
        ],
      ),
    );
  }
}