import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Front-end only Emergency SOS flow for Raahi.
/// Contacts are held in memory for now. Connect the APIs/database later.
class EmergencyContact {
  final String name;
  final String phone;
  final String relationship;
  final bool isPrimary;
  final bool call;
  final bool sms;
  final bool whatsapp;

  const EmergencyContact({
    required this.name,
    required this.phone,
    required this.relationship,
    this.isPrimary = false,
    this.call = true,
    this.sms = true,
    this.whatsapp = false,
  });

  EmergencyContact copyWith({
    String? name,
    String? phone,
    String? relationship,
    bool? isPrimary,
    bool? call,
    bool? sms,
    bool? whatsapp,
  }) {
    return EmergencyContact(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
      call: call ?? this.call,
      sms: sms ?? this.sms,
      whatsapp: whatsapp ?? this.whatsapp,
    );
  }
}

class EmergencySosSafetyScreen extends StatefulWidget {
  const EmergencySosSafetyScreen({super.key});

  @override
  State<EmergencySosSafetyScreen> createState() =>
      _EmergencySosSafetyScreenState();
}

class _EmergencySosSafetyScreenState extends State<EmergencySosSafetyScreen> {
  static const navy = Color(0xFF10213D);
  static const teal = Color(0xFF0796AE);
  static const border = Color(0xFFE1E6EC);
  static const headerAsset =
      'assets/images/raahi_assets/header/city_skyline54.png';
  static const footerAsset =
      'assets/images/raahi_assets/header/city_skyline53.png';
  static const logoAsset = 'assets/images/raahi_assets/brand/raahi_logo.png';

  final List<EmergencyContact> _contacts = [
    const EmergencyContact(
      name: 'Papa',
      phone: '+91 98267 54321',
      relationship: 'Father',
      isPrimary: true,
    ),
    const EmergencyContact(
      name: 'Mummy',
      phone: '+91 99073 21098',
      relationship: 'Mother',
    ),
    const EmergencyContact(
      name: 'Brother (Ayush)',
      phone: '+91 93028 77673',
      relationship: 'Brother',
    ),
  ];

  Future<void> _openManage() async {
    final updated = await Navigator.push<List<EmergencyContact>>(
      context,
      MaterialPageRoute(
        builder: (_) => ManageEmergencyContactsScreen(
          contacts: List.of(_contacts),
        ),
      ),
    );
    if (updated != null && mounted) {
      setState(() {
        _contacts
          ..clear()
          ..addAll(updated);
      });
    }
  }

  Future<void> _dial(String number) async {
    final uri = Uri(scheme: 'tel', path: number.replaceAll(' ', ''));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _shareTrip() async {
    // UI placeholder: live-location sharing will be connected with backend later.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Live trip sharing will be connected in the next phase.'),
      ),
    );
  }

  Future<void> _activateSos() async {
    // Do not silently send alerts before the SOS service is connected.
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Emergency SOS'),
        content: const Text(
          'SOS alert service will be connected in the next phase. '
          'If you are in immediate danger, call 112 now.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _dial('112');
            },
            child: const Text('Call 112'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RaahiHeader(
                title: 'Emergency SOS & Safety',
                subtitle: 'Your safety is our priority',
                logoAsset: logoAsset,
                skylineAsset: headerAsset,
                onBack: () => Navigator.pop(context),
              ),
              const SizedBox(height: 9),
              _sosBanner(),
              const SizedBox(height: 10),
              _quickActions(),
              const SizedBox(height: 12),
              _contactsCard(),
              const SizedBox(height: 12),
              const Text(
                'Safety Features',
                style: TextStyle(
                  color: navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              _safetyFeatures(),
              const SizedBox(height: 10),
              _safetyTips(),
              const SizedBox(height: 4),
              _FooterSkyline(asset: footerAsset),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sosBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE91D32), Color(0xFFC9001D)],
        ),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: const BoxDecoration(
              color: Color(0x35FFFFFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sos,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Alert your emergency contacts with your live location instantly.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          InkWell(
            onTap: _activateSos,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: 104,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Column(
                children: [
                  Text(
                    'Tap to Activate',
                    style: TextStyle(
                      color: Color(0xFFC9001D),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'SOS',
                    style: TextStyle(
                      color: Color(0xFFC9001D),
                      fontSize: 24,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActions() {
    return Row(
      children: [
        Expanded(
          child: _quickAction(
            Icons.call,
            Colors.blue,
            'Call Police',
            '(112)',
            () => _dial('112'),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _quickAction(
            Icons.medical_services,
            Colors.red,
            'Call Ambulance',
            '(108)',
            () => _dial('108'),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _quickAction(
            Icons.groups,
            Colors.green,
            'Call Support',
            '(24×7)',
            () => _dial('9302877673'),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _quickAction(
            Icons.verified_user_outlined,
            Colors.deepPurple,
            'Share Live',
            'Trip',
            _shareTrip,
          ),
        ),
      ],
    );
  }

  Widget _quickAction(
    IconData icon,
    Color color,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 83,
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFBFD),
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 27),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: const TextStyle(
                color: navy,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: navy,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactsCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.groups_outlined, color: navy, size: 23),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'My Emergency Contacts',
                  style: TextStyle(
                    color: navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: _openManage,
                child: const Text(
                  'Manage  ›',
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          ..._contacts.take(3).map(
                (contact) => _contactPreview(contact),
              ),
        ],
      ),
    );
  }

  Widget _contactPreview(EmergencyContact contact) {
    final initial = contact.name.isEmpty ? '?' : contact.name[0].toUpperCase();
    return Container(
      height: 54,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: const Color(0xFFE1F3FC),
            child: Text(
              initial,
              style: const TextStyle(
                color: Color(0xFF1768B5),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  contact.phone,
                  style: const TextStyle(color: navy, fontSize: 10.5),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => _dial(contact.phone),
            icon: const Icon(Icons.call, color: Colors.green, size: 21),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: _openManage,
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 21),
          ),
        ],
      ),
    );
  }

  Widget _safetyFeatures() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _featureCard(
                Icons.location_on_outlined,
                Colors.green,
                const Color(0xFFE7F8ED),
                'Share Live Location',
                'Share your real-time trip with family & friends',
                _shareTrip,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _featureCard(
                Icons.verified_user_outlined,
                Colors.blueGrey,
                const Color(0xFFE4F6FA),
                'Trip Safety Check',
                'Get trip updates during your ride',
                () => _showFeatureMessage('Trip Safety Check'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: _featureCard(
                Icons.warning_amber_rounded,
                Colors.deepOrange,
                const Color(0xFFFFF1E0),
                'Report an Issue',
                'Report driver, vehicle or any safety concern',
                () => _showFeatureMessage('Report an Issue'),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _featureCard(
                Icons.headset_mic_outlined,
                Colors.deepPurple,
                const Color(0xFFF4E9FF),
                'Contact Support',
                'Get quick help from our support team (24×7)',
                () => _dial('9302877673'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _featureCard(
    IconData icon,
    Color color,
    Color background,
    String title,
    String description,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 83,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFFCFDFE),
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 49,
              height: 53,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 29),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: navy,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: navy,
                      fontSize: 9.5,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: navy),
          ],
        ),
      ),
    );
  }

  Widget _safetyTips() {
    const tips = [
      'Always verify your driver and vehicle details before starting the ride.',
      'Share your live trip with a trusted contact.',
      'Prefer well-lit and public pickup/drop locations.',
      'In case of any emergency, use the SOS button or call 112.',
    ];
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F6FC),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_user_outlined, color: navy, size: 23),
              SizedBox(width: 8),
              Text(
                'Safety Tips for a Secure Ride',
                style: TextStyle(
                  color: navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 17),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(
                        color: navy,
                        fontSize: 10.5,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFeatureMessage(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature will be connected in the next phase.')),
    );
  }
}

class ManageEmergencyContactsScreen extends StatefulWidget {
  final List<EmergencyContact> contacts;

  const ManageEmergencyContactsScreen({
    super.key,
    required this.contacts,
  });

  @override
  State<ManageEmergencyContactsScreen> createState() =>
      _ManageEmergencyContactsScreenState();
}

class _ManageEmergencyContactsScreenState
    extends State<ManageEmergencyContactsScreen> {
  static const navy = Color(0xFF10213D);
  static const border = Color(0xFFE1E6EC);
  static const headerAsset =
      'assets/images/raahi_assets/header/city_skyline54.png';
  static const footerAsset =
      'assets/images/raahi_assets/header/city_skyline53.png';
  static const logoAsset = 'assets/images/raahi_assets/brand/raahi_logo.png';

  late List<EmergencyContact> contacts;
  int? selectedIndex;

  @override
  void initState() {
    super.initState();
    contacts = List.of(widget.contacts);
    if (contacts.isNotEmpty) {
      selectedIndex = contacts.indexWhere((c) => c.isPrimary);
      if (selectedIndex == -1) selectedIndex = 0;
    }
  }

  void _returnContacts() => Navigator.pop(context, contacts);

  Future<void> _addContact() async {
    if (contacts.length >= 5) {
      _message('You can add up to 5 emergency contacts.');
      return;
    }
    final result = await Navigator.push<EmergencyContact>(
      context,
      MaterialPageRoute(builder: (_) => const AddEmergencyContactScreen()),
    );
    if (result != null && mounted) {
      setState(() {
        contacts.add(result.copyWith(isPrimary: contacts.isEmpty || result.isPrimary));
        if (result.isPrimary || contacts.length == 1) {
          _setPrimary(contacts.length - 1);
        }
      });
    }
  }

  Future<void> _editContact(int index) async {
    final result = await Navigator.push<EmergencyContact>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEmergencyContactScreen(contact: contacts[index]),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        contacts[index] = result;
        if (result.isPrimary) _setPrimary(index);
      });
    }
  }

  void _setPrimary(int index) {
    contacts = [
      for (int i = 0; i < contacts.length; i++)
        contacts[i].copyWith(isPrimary: i == index),
    ];
    selectedIndex = index;
  }

  void _deleteContact(int index) {
    setState(() {
      contacts.removeAt(index);
      if (contacts.isEmpty) {
        selectedIndex = null;
      } else {
        final primary = contacts.indexWhere((c) => c.isPrimary);
        _setPrimary(primary >= 0 ? primary : 0);
      }
    });
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _returnContacts();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RaahiHeader(
                  title: 'Manage Emergency Contacts',
                  subtitle: 'Add trusted people who can help in an emergency',
                  logoAsset: logoAsset,
                  skylineAsset: headerAsset,
                  onBack: _returnContacts,
                ),
                const SizedBox(height: 10),
                _infoBanner(
                  Icons.verified_user,
                  'Stay Safe, Stay Connected',
                  'Your emergency contacts will be notified in case of an SOS or emergency situation.',
                ),
                const SizedBox(height: 10),
                _addContactButton(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Emergency Contacts',
                        style: TextStyle(
                          color: navy,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      '(${contacts.length})   Max 5 contacts',
                      style: const TextStyle(color: navy, fontSize: 10.5),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                ...List.generate(contacts.length, _contactCard),
                if (selectedIndex != null && selectedIndex! < contacts.length)
                  _editPanel(),
                const SizedBox(height: 10),
                _infoBanner(
                  Icons.lightbulb_outline,
                  'Important',
                  'Make sure your emergency contacts are always up to date. You can change or remove contacts anytime.',
                ),
                const SizedBox(height: 5),
                _FooterSkyline(asset: footerAsset),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _returnContacts,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF078DA8),
                  ),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoBanner(IconData icon, String title, String message) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F6FC),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF087C9A), size: 39),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _addContactButton() {
    return InkWell(
      onTap: _addContact,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_add_alt_1, color: Color(0xFF087C9A), size: 31),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add New Contact',
                    style: TextStyle(
                      color: navy,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Add family, friends or trusted people',
                    style: TextStyle(color: navy, fontSize: 10.5),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFF078DA8),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add, color: Colors.white, size: 18),
                  SizedBox(width: 4),
                  Text(
                    'Add Contact',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactCard(int index) {
    final contact = contacts[index];
    final isSelected = selectedIndex == index;
    final initial = contact.name.isEmpty ? '?' : contact.name[0].toUpperCase();
    final colors = [
      const Color(0xFFD9F2FC),
      const Color(0xFFFFE4EA),
      const Color(0xFFEDE3FF),
      const Color(0xFFE2F6E9),
      const Color(0xFFFFEEDC),
    ];
    return InkWell(
      onTap: () => setState(() => selectedIndex = index),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF5FCFA) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF7BD9C5) : border,
            width: isSelected ? 1.3 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: colors[index % colors.length],
              child: Text(
                initial,
                style: const TextStyle(
                  color: Color(0xFF1768B5),
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          contact.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: navy,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (contact.isPrimary) ...[
                        const SizedBox(width: 6),
                        const _PrimaryTag(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '☎  ${contact.phone}',
                    style: const TextStyle(color: navy, fontSize: 10.5),
                  ),
                  Text(
                    '♙  ${contact.relationship}',
                    style: const TextStyle(color: navy, fontSize: 10.5),
                  ),
                ],
              ),
            ),
            _smallAction(
              Icons.edit_outlined,
              const Color(0xFFE5F4FC),
              Colors.blue,
              () => _editContact(index),
            ),
            const SizedBox(width: 5),
            _smallAction(
              Icons.delete_outline,
              const Color(0xFFFFEEF1),
              Colors.red,
              () => _deleteContact(index),
            ),
            if (!contact.isPrimary)
              Radio<int>(
                value: index,
                groupValue: selectedIndex,
                onChanged: (_) => setState(() => _setPrimary(index)),
                activeColor: Colors.green,
                visualDensity: VisualDensity.compact,
              )
            else
              const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _smallAction(
    IconData icon,
    Color background,
    Color color,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          width: 38,
          height: 39,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
      ),
    );
  }

  Widget _editPanel() {
    final index = selectedIndex!;
    final contact = contacts[index];
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF0F8FC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: const Row(
              children: [
                Icon(Icons.person_outline, color: navy),
                SizedBox(width: 8),
                Text(
                  'Edit Contact',
                  style: TextStyle(
                    color: navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Spacer(),
                Icon(Icons.keyboard_arrow_up, color: navy),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: _detailField('Full Name', contact.name)),
                    const SizedBox(width: 10),
                    Expanded(child: _detailField('Phone Number', contact.phone)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _detailField('Relationship', contact.relationship)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Set as Primary Contact',
                            style: TextStyle(
                              color: navy,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Switch(
                            value: contact.isPrimary,
                            activeColor: Colors.green,
                            onChanged: (value) {
                              setState(() {
                                if (value) {
                                  _setPrimary(index);
                                } else {
                                  contacts[index] =
                                      contacts[index].copyWith(isPrimary: false);
                                }
                              });
                            },
                          ),
                          const Text(
                            'This contact will be notified first.',
                            style: TextStyle(color: navy, fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteContact(index),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete Contact'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.redAccent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _editContact(index),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit Details'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF078DA8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: navy,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: navy, fontSize: 10.5),
          ),
        ),
      ],
    );
  }
}

class AddEmergencyContactScreen extends StatefulWidget {
  final EmergencyContact? contact;

  const AddEmergencyContactScreen({super.key, this.contact});

  @override
  State<AddEmergencyContactScreen> createState() =>
      _AddEmergencyContactScreenState();
}

class _AddEmergencyContactScreenState extends State<AddEmergencyContactScreen> {
  static const navy = Color(0xFF10213D);
  static const teal = Color(0xFF078DA8);
  static const border = Color(0xFFDCE3EA);
  static const headerAsset =
      'assets/images/raahi_assets/header/city_skyline54.png';
  static const footerAsset =
      'assets/images/raahi_assets/header/city_skyline53.png';
  static const logoAsset = 'assets/images/raahi_assets/brand/raahi_logo.png';

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  String? _relationship;
  bool _call = true;
  bool _sms = true;
  bool _whatsapp = false;
  bool _primary = true;

  final relationships = const [
    'Father',
    'Mother',
    'Brother',
    'Sister',
    'Spouse',
    'Friend',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final contact = widget.contact;
    _nameController = TextEditingController(text: contact?.name ?? '');
    _phoneController = TextEditingController(text: contact?.phone ?? '');
    _relationship = contact?.relationship;
    _call = contact?.call ?? true;
    _sms = contact?.sms ?? true;
    _whatsapp = contact?.whatsapp ?? false;
    _primary = contact?.isPrimary ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_relationship == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a relationship.')),
      );
      return;
    }
    if (!_call && !_sms && !_whatsapp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one contact preference.')),
      );
      return;
    }
    Navigator.pop(
      context,
      EmergencyContact(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        relationship: _relationship!,
        isPrimary: _primary,
        call: _call,
        sms: _sms,
        whatsapp: _whatsapp,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.contact != null;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RaahiHeader(
                  title: editing ? 'Edit Emergency Contact' : 'Add Emergency Contact',
                  subtitle: 'Add a trusted person for quick help in an emergency',
                  logoAsset: logoAsset,
                  skylineAsset: headerAsset,
                  onBack: () => Navigator.pop(context),
                ),
                const SizedBox(height: 10),
                _infoBanner(
                  Icons.add_moderator,
                  'Trusted Emergency Contact',
                  'This person will be notified with your trip details and live location when you use SOS or an emergency feature.',
                ),
                const SizedBox(height: 14),
                _inputLabel('Full Name *'),
                const SizedBox(height: 5),
                _textField(
                  controller: _nameController,
                  hint: 'Enter full name',
                  icon: Icons.person_outline,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter full name' : null,
                ),
                const SizedBox(height: 12),
                _inputLabel('Mobile Number *'),
                const SizedBox(height: 5),
                _textField(
                  controller: _phoneController,
                  hint: 'Enter mobile number',
                  icon: Icons.call_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                    if (digits.length < 10) return 'Enter a valid mobile number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _inputLabel('Relationship *'),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: border),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _relationship,
                      isExpanded: true,
                      hint: const Row(
                        children: [
                          Icon(Icons.groups_outlined, color: navy),
                          SizedBox(width: 12),
                          Text('Select relationship'),
                        ],
                      ),
                      items: relationships
                          .map(
                            (r) => DropdownMenuItem(value: r, child: Text(r)),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _relationship = value),
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                _preferenceCard(),
                const SizedBox(height: 12),
                _primaryCard(),
                const SizedBox(height: 12),
                _noteCard(),
                const SizedBox(height: 15),
                SizedBox(
                  height: 49,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check, size: 23),
                    label: Text(
                      editing ? 'Save Changes' : 'Save Contact',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _FooterSkyline(asset: footerAsset),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoBanner(IconData icon, String title, String message) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F6FC),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF087C9A), size: 43),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: navy,
        fontSize: 13,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: navy, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF78869A), fontSize: 13),
        prefixIcon: Icon(icon, color: navy, size: 22),
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: teal, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _preferenceCard() {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.cell_tower, color: navy, size: 23),
              SizedBox(width: 9),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Preference',
                    style: TextStyle(
                      color: navy,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Choose how you want to reach this contact',
                    style: TextStyle(color: navy, fontSize: 10.5),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _preferenceOption(
                  'Call',
                  Icons.call_outlined,
                  _call,
                  (v) => setState(() => _call = v),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _preferenceOption(
                  'SMS',
                  Icons.chat_bubble_outline,
                  _sms,
                  (v) => setState(() => _sms = v),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _preferenceOption(
                  'WhatsApp',
                  Icons.chat,
                  _whatsapp,
                  (v) => setState(() => _whatsapp = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _preferenceOption(
    String title,
    IconData icon,
    bool selected,
    ValueChanged<bool> onChanged,
  ) {
    return InkWell(
      onTap: () => onChanged(!selected),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE9FBF0) : Colors.white,
          border: Border.all(
            color: selected ? const Color(0xFF5DC98B) : border,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? Icons.check_box : Icons.check_box_outline_blank,
              color: selected ? Colors.green : const Color(0xFF8B96A5),
              size: 17,
            ),
            const SizedBox(width: 3),
            Icon(icon, color: Colors.green, size: 17),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: navy,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_border, color: navy, size: 27),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set as Primary Contact',
                  style: TextStyle(
                    color: navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Primary contact will be notified first in an emergency.',
                  style: TextStyle(color: navy, fontSize: 10.5),
                ),
              ],
            ),
          ),
          Switch(
            value: _primary,
            activeColor: Colors.green,
            onChanged: (value) => setState(() => _primary = value),
          ),
        ],
      ),
    );
  }

  Widget _noteCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F6FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: navy, size: 21),
              SizedBox(width: 8),
              Text(
                'Note:',
                style: TextStyle(
                  color: navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 5),
          Text(
            '• You can add up to 5 emergency contacts.\n'
            '• Make sure the mobile number is correct and active.\n'
            '• You can edit or remove contacts anytime from the Manage Emergency Contacts screen.',
            style: TextStyle(
              color: navy,
              fontSize: 10.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _RaahiHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String logoAsset;
  final String skylineAsset;
  final VoidCallback onBack;

  const _RaahiHeader({
    required this.title,
    required this.subtitle,
    required this.logoAsset,
    required this.skylineAsset,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: onBack,
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFF10213D),
                    size: 27,
                  ),
                ),
              ),
              Image.asset(
                logoAsset,
                width: 166,
                height: 44,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Text(
                  'Raahi',
                  style: TextStyle(
                    color: Color(0xFF10213D),
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF10172F),
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF10213D),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 31,
          width: double.infinity,
          child: Image.asset(
            skylineAsset,
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class _FooterSkyline extends StatelessWidget {
  final String asset;

  const _FooterSkyline({required this.asset});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 57,
      width: double.infinity,
      child: Image.asset(
        asset,
        fit: BoxFit.fill,
        alignment: Alignment.bottomCenter,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}

class _PrimaryTag extends StatelessWidget {
  const _PrimaryTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE1F8E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        '✓ Primary',
        style: TextStyle(
          color: Colors.green,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
