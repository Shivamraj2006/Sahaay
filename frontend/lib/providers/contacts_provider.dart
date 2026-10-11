import 'package:flutter/material.dart';
import '../models/contact.dart';

class ContactsProvider extends ChangeNotifier {
  final List<EmergencyContact> _contacts = [];

  List<EmergencyContact> get contacts => List.unmodifiable(_contacts);
  int get count => _contacts.length;

  ContactsProvider() {
    _contacts.addAll(EmergencyContact.defaultContacts());
  }

  void addContact({
    required String name,
    required String relationship,
    required String phone,
  }) {
    final newContact = EmergencyContact(
      id: 'c_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      relationship: relationship,
      phone: phone.startsWith('+91') ? phone : '+91 $phone',
    );
    _contacts.add(newContact);
    notifyListeners();
  }

  void removeContact(String id) {
    _contacts.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}
