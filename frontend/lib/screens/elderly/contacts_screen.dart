import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/contacts_provider.dart';
import '../../widgets/contact_card.dart';
import '../../widgets/contact_options_sheet.dart';
import 'add_contact_dialog.dart';

class ContactsScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const ContactsScreen({super.key, this.onBack});

  void _openAddModal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddContactDialog()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contactsProvider = context.watch<ContactsProvider>();
    final contacts = contactsProvider.contacts;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        leading: onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: onBack,
              )
            : null,
        title: const Text(
          'Emergency Contacts',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.slate900,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () => _openAddModal(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.brandBlueLight,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.add,
                  color: AppColors.brandBlue,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: AppColors.slate100, height: 1),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: contacts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return ContactCard(
                      contact: contact,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) => ContactOptionsSheet(
                            contact: contact,
                            onRemove: () {
                              contactsProvider.removeContact(contact.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${contact.name} removed from priority alerts',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: AppColors.slate900,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Add Emergency Contact Bottom CTA (Stitch Screen 4)
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openAddModal(context),
                    icon: const Icon(Icons.add, color: AppColors.brandBlue, size: 22),
                    label: const Text(
                      'Add Emergency Contact',
                      style: TextStyle(
                        color: AppColors.brandBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.brandBlueLight,
                      side: const BorderSide(color: AppColors.brandBlueBorder, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
