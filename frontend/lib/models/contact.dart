class EmergencyContact {
  final String id;
  final String name;
  final String relationship;
  final String phone;
  final String? assetImage;
  final String? networkImage;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.relationship,
    required this.phone,
    this.assetImage,
    this.networkImage,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      relationship: json['relationship'] ?? '',
      phone: json['phone'] ?? '',
      assetImage: json['assetImage'],
      networkImage: json['networkImage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'relationship': relationship,
      'phone': phone,
      'assetImage': assetImage,
      'networkImage': networkImage,
    };
  }

  static List<EmergencyContact> defaultContacts() {
    return const [
      EmergencyContact(
        id: 'c1',
        name: 'Ramesh Kumar',
        relationship: 'Son',
        phone: '+91 98765 43210',
        assetImage: 'assets/images/ramesh.jpg',
        networkImage:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDKvIyMuKxjnaVyzNOc7qs-KX7atFO7FB6uKpmzYhfjEIZd_T8b0OPgo25_mFmVC8c7EEPnOoutRu9uz85lhwPR05a5QrrN7CFi1K2ANxELy1JeDupyi_mf0acMC4j_HtTXyG8UZeOOJCKmczFVFLBlC950GBLk7zAduog5FXDbhXSUliLMelr1tLCAPwmUjhhHLyXtGku-Dw68oJJlsYG0u8EgG_RUORQJaQ3MjBUkDYUWIBq1kWUYbw',
      ),
      EmergencyContact(
        id: 'c2',
        name: 'Lakshmi',
        relationship: 'Daughter',
        phone: '+91 98765 43211',
        assetImage: 'assets/images/lakshmi.jpg',
        networkImage:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCaZbFILrOLfiHHhuM3KCxkIu8YLlu4XoZ7neH_XCextO_S2vazK-MyUzLvyi2m7ZljTqXqbm9z79GqC0e6FJXFlloKugUzfiTTW5cZ18vFn8hJYGSgTturnt4AbajmQ6_hmk8-EfqxogVeLHiMOygWIWxpNzqhUEOspnfm-FVVU13_Ovk_s16WO4o6Zb8PoOnQzmPldIZUTfUZECT6PkkpX5eKHcj-ucJUl0SxBaSJ5NWR2QLE8SRt-A',
      ),
      EmergencyContact(
        id: 'c3',
        name: 'Dr. Meera Iyer',
        relationship: 'Family Doctor',
        phone: '+91 98765 43212',
        assetImage: 'assets/images/doctor.jpg',
        networkImage:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAgbWtS-wJZ_25lXhBZ-vnnZwXzoah6EWe7CVxie_f9FGnw-wBCdOnwTzvxI8cOenHoLxagbt2FV52AgmNecu-VsuE6y9l4YsNkE1JxAgn_5vS3qDCgodUHC9nKGRXeAl7HmzzEuARYnbcLpDLzyOii1Tqc7F3zI-yEBql87Yk7AZ36g4_b_Jt-pKk5B5A_-ifl-7yADw9h5rqJsa5_DxCBoe4st9QILKCeuQPDhsG8aMr2CRARzoszog',
      ),
    ];
  }
}
