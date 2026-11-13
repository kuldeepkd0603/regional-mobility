
import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../auth/auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> userFuture;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  void loadProfile() {
    userFuture = ApiService.getCurrentUser();
  }

  Future<void> refreshProfile() async {
    setState(() {
      loadProfile();
    });

    await userFuture;
  }

  Future<void> logout() async {
    await ApiService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const AuthScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> editProfile(String currentName) async {
    final controller = TextEditingController(text: currentName);
    String? errorText;
    bool saving = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Profile'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: const OutlineInputBorder(),
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final name = controller.text.trim();

                          if (name.length < 2) {
                            setDialogState(() {
                              errorText = 'Enter a valid name';
                            });
                            return;
                          }

                          setDialogState(() {
                            saving = true;
                            errorText = null;
                          });

                          try {
                            await ApiService.updateProfile(
                              fullName: name,
                            );

                            if (!dialogContext.mounted) return;

                            Navigator.pop(dialogContext, true);
                          } catch (e) {
                            setDialogState(() {
                              saving = false;
                              errorText = e
                                  .toString()
                                  .replaceFirst('Exception: ', '');
                            });
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (result == true && mounted) {
      setState(() {
        loadProfile();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget profileItem(String label, String value, IconData icon) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFF1746A2),
        ),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            tooltip: 'Refresh profile',
            onPressed: refreshProfile,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person_off_outlined,
                    size: 55,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  const Text('Unable to load profile'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: refreshProfile,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          final user = snapshot.data!;
          final fullName =
              user['full_name']?.toString() ?? 'Passenger';

          return RefreshIndicator(
            onRefresh: refreshProfile,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 15),

                const CircleAvatar(
                  radius: 48,
                  backgroundColor: Color(0xFF1746A2),
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 52,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  fullName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 22),

                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => editProfile(fullName),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1746A2),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                profileItem(
                  'Full Name',
                  fullName,
                  Icons.person_outline,
                ),

                profileItem(
                  'Phone Number',
                  user['phone']?.toString() ?? 'Not available',
                  Icons.phone,
                ),

                profileItem(
                  'Email',
                  user['email']?.toString() ?? 'Not provided',
                  Icons.email_outlined,
                ),

                profileItem(
                  'Account Role',
                  user['role']?.toString() ?? 'Passenger',
                  Icons.badge_outlined,
                ),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(15),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
