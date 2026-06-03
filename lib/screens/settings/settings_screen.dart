import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../core/user_session.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // تم حذف _energySavingEnabled لأنه غير مستخدم لتصفير الـ Warning
  bool _notificationsEnabled = true;
  bool _fireAlerts = true;
  bool _fallAlerts = true;
  bool _gasAlerts = true;
  bool _painAlerts = true;

  @override
  void initState() {
    super.initState();
    _loadSettingsFromFirebase();
  }

  Future<void> _loadSettingsFromFirebase() async {
    try {
      final snap = await FirebaseDatabase.instance
          .ref('aura/settings/${UserSession.uid}')
          .get();
      if (snap.value == null) return;
      final data = Map<String, dynamic>.from(snap.value as Map);
      if (!mounted) return;
      setState(() {
        _notificationsEnabled = data['notifications'] ?? true;
        _fireAlerts = data['fireAlerts'] ?? true;
        _fallAlerts = data['fallAlerts'] ?? true;
        _gasAlerts = data['gasAlerts'] ?? true;
        _painAlerts = data['painAlerts'] ?? true;
      });
    } catch (_) {}
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      await FirebaseDatabase.instance
          .ref('aura/settings/${UserSession.uid}/$key')
          .set(value);
    } catch (_) {}
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.redAccent : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showEditProfile() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameCtrl = TextEditingController(text: UserSession.name);
    final isAdmin = UserSession.role == 'Admin';
    final emailCtrl = TextEditingController(text: UserSession.email);
    final passCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetHandle(),
            const SizedBox(height: 20),
            Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            _sheetField(nameCtrl, 'Display Name', Icons.person_outline, isDark),
            if (isAdmin) ...[
              const SizedBox(height: 12),
              _sheetField(emailCtrl, 'Email', Icons.email_outlined, isDark),
              const SizedBox(height: 12),
              _sheetField(
                passCtrl,
                'New Password (leave blank to keep)',
                Icons.lock_outline,
                isDark,
                obscure: true,
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  final updates = <String, dynamic>{
                    'name': nameCtrl.text.trim(),
                  };
                  if (isAdmin) {
                    if (emailCtrl.text.trim().isNotEmpty) {
                      updates['email'] = emailCtrl.text.trim();
                    }
                    if (passCtrl.text.trim().isNotEmpty) {
                      updates['password'] = passCtrl.text.trim();
                    }
                  }
                  try {
                    await FirebaseDatabase.instance
                        .ref('aura/users/${UserSession.uid}')
                        .update(updates);
                    UserSession.name = nameCtrl.text.trim();
                    if (isAdmin && emailCtrl.text.trim().isNotEmpty) {
                      UserSession.email = emailCtrl.text.trim();
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    _showSnack('✅ Profile updated successfully');
                    setState(() {});
                  } catch (e) {
                    _showSnack(
                      '❌ Failed to update. Check connection.',
                      error: true,
                    );
                  }
                },
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFamilyMembers() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              _sheetHandle(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Family Members',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.person_add_outlined, color: primaryColor),
                    onPressed: () => _showAddMemberDialog(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  stream: FirebaseDatabase.instance.ref('aura/users').onValue,
                  builder: (_, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snap.hasData || snap.data!.snapshot.value == null) {
                      return Center(
                        child: Text(
                          'No members found',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      );
                    }
                    final all = Map<String, dynamic>.from(
                      snap.data!.snapshot.value as Map,
                    );
                    return ListView(
                      controller: scrollCtrl,
                      children: all.entries.map((entry) {
                        final u = Map<String, dynamic>.from(entry.value as Map);
                        final uName = u['name']?.toString() ?? 'Unknown';
                        final uRole = u['role']?.toString() ?? 'Guest';
                        final uEmail = u['email']?.toString() ?? '';
                        final isCurrentUser = entry.key == UserSession.uid;
                        final isAdminUser = uRole == 'Admin';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2A2A2A)
                                : const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCurrentUser
                                  ? primaryColor.withValues(alpha: 0.4)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: primaryColor.withValues(
                                  alpha: 0.18,
                                ),
                                child: Text(
                                  uName.isNotEmpty
                                      ? uName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      uName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      uEmail,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isAdminUser
                                      ? primaryColor.withValues(alpha: 0.15)
                                      : Colors.grey.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  uRole,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isAdminUser
                                        ? primaryColor
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                              if (!isCurrentUser) ...[
                                const SizedBox(width: 6),
                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                  color: isDark
                                      ? const Color(0xFF2A2A2A)
                                      : Colors.white,
                                  onSelected: (val) async {
                                    if (val == 'toggle_role') {
                                      final newRole = uRole == 'Admin'
                                          ? 'Guest'
                                          : 'Admin';
                                      try {
                                        await FirebaseDatabase.instance
                                            .ref('aura/users/${entry.key}/role')
                                            .set(newRole);
                                        _showSnack(
                                          '✅ Role changed to $newRole',
                                        );
                                      } catch (_) {
                                        _showSnack('❌ Failed', error: true);
                                      }
                                    } else if (val == 'delete') {
                                      _confirmDeleteMember(
                                        ctx,
                                        entry.key,
                                        uName,
                                      );
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'toggle_role',
                                      child: Text(
                                        uRole == 'Admin'
                                            ? 'Make Guest'
                                            : 'Make Admin',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        'Remove Member',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteMember(BuildContext sheetCtx, String uid, String name) {
    showDialog(
      context: sheetCtx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseDatabase.instance.ref('aura/users/$uid').remove();
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                _showSnack('✅ Member removed');
              } catch (_) {
                _showSnack('❌ Failed', error: true);
              }
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog(BuildContext sheetCtx) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String role = 'Guest';
    showDialog(
      context: sheetCtx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (_, setDlg) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          title: Text(
            'Add Member',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetField(nameCtrl, 'Name', Icons.person_outline, isDark),
                const SizedBox(height: 10),
                _sheetField(emailCtrl, 'Email', Icons.email_outlined, isDark),
                const SizedBox(height: 10),
                _sheetField(
                  passCtrl,
                  'Password',
                  Icons.lock_outline,
                  isDark,
                  obscure: true,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'Role:',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('Guest'),
                      selected: role == 'Guest',
                      onSelected: (_) => setDlg(() => role = 'Guest'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Admin'),
                      selected: role == 'Admin',
                      onSelected: (_) => setDlg(() => role = 'Admin'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty ||
                    emailCtrl.text.trim().isEmpty) {
                  _showSnack('Name and email are required', error: true);
                  return;
                }
                try {
                  final newRef = FirebaseDatabase.instance
                      .ref('aura/users')
                      .push();
                  await newRef.set({
                    'name': nameCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                    'password': passCtrl.text.trim(),
                    'role': role,
                    'houseName': UserSession.houseName,
                  });
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  _showSnack('✅ Member added');
                } catch (_) {
                  _showSnack('❌ Failed to add member', error: true);
                }
              },
              child: Text(
                'Add',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationPrefs() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = UserSession.role == 'Admin';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (_, setSheet) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHandle(),
              const SizedBox(height: 20),
              Text(
                'Notification Preferences',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isAdmin
                    ? 'Control all system alert types'
                    : 'Control your personal notifications',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              _toggleRow(
                ctx,
                setSheet,
                'All Notifications',
                'Master switch',
                _notificationsEnabled,
                Icons.notifications_outlined,
                Colors.blue,
                isDark,
                (v) async {
                  setSheet(() => _notificationsEnabled = v);
                  setState(() => _notificationsEnabled = v);
                  await _saveSetting('notifications', v);
                },
              ),
              if (isAdmin) ...[
                const Divider(height: 24),
                const Text(
                  'Alert Types',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _toggleRow(
                  ctx,
                  setSheet,
                  'Fire & Child Alerts',
                  'DISTRACT_CHILD / CLOSE_GAS',
                  _fireAlerts,
                  Icons.local_fire_department,
                  Colors.orange,
                  isDark,
                  (v) async {
                    setSheet(() => _fireAlerts = v);
                    setState(() => _fireAlerts = v);
                    await _saveSetting('fireAlerts', v);
                  },
                ),
                _toggleRow(
                  ctx,
                  setSheet,
                  'Fall Detection Alerts',
                  'FALL_DETECTED',
                  _fallAlerts,
                  Icons.personal_injury_outlined,
                  Colors.red,
                  isDark,
                  (v) async {
                    setSheet(() => _fallAlerts = v);
                    setState(() => _fallAlerts = v);
                    await _saveSetting('fallAlerts', v);
                  },
                ),
                _toggleRow(
                  ctx,
                  setSheet,
                  'Gas Leak Alerts',
                  'Auto-valve close',
                  _gasAlerts,
                  Icons.gas_meter_outlined,
                  Colors.blueAccent,
                  isDark,
                  (v) async {
                    setSheet(() => _gasAlerts = v);
                    setState(() => _gasAlerts = v);
                    await _saveSetting('gasAlerts', v);
                  },
                ),
                _toggleRow(
                  ctx,
                  setSheet,
                  'Pain & Chest Alerts',
                  'PAIN_DETECTED / CHEST_PAIN',
                  _painAlerts,
                  Icons.favorite_outline,
                  Colors.pink,
                  isDark,
                  (v) async {
                    setSheet(() => _painAlerts = v);
                    setState(() => _painAlerts = v);
                    await _saveSetting('painAlerts', v);
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmergencyContact() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final phoneCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    FirebaseDatabase.instance.ref('aura/config/emergencyContact').get().then((
      snap,
    ) {
      if (snap.value != null) {
        final data = Map<String, dynamic>.from(snap.value as Map);
        phoneCtrl.text = data['phone']?.toString() ?? '';
        nameCtrl.text = data['name']?.toString() ?? '';
      }
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetHandle(),
            const SizedBox(height: 20),
            Text(
              'Emergency Contact',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Auto-called after 10 min of unresolved fall/pain',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            _sheetField(nameCtrl, 'Contact Name', Icons.person_outline, isDark),
            const SizedBox(height: 12),
            _sheetField(
              phoneCtrl,
              'Phone Number',
              Icons.phone_outlined,
              isDark,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  if (phoneCtrl.text.trim().isEmpty) {
                    _showSnack('Phone number is required', error: true);
                    return;
                  }
                  try {
                    await FirebaseDatabase.instance
                        .ref('aura/config/emergencyContact')
                        .set({
                          'name': nameCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim(),
                          'updatedBy': UserSession.name,
                        });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _showSnack('✅ Emergency contact saved');
                  } catch (_) {
                    _showSnack('❌ Failed to save', error: true);
                  }
                },
                child: const Text(
                  'Save Emergency Contact',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCamerasSensors() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('aura/config/cameras').onValue,
        builder: (_, snap) {
          Map<String, dynamic> cameras = {
            'kitchen_cam': {
              'name': 'Kitchen Camera',
              'enabled': true,
              'sensitivity': 0.45,
            },
            'living_cam': {
              'name': 'Living Room Camera',
              'enabled': true,
              'sensitivity': 0.60,
            },
            'bedroom_cam': {
              'name': 'Bedroom Camera',
              'enabled': false,
              'sensitivity': 0.50,
            },
            'entrance_cam': {
              'name': 'Entrance Camera',
              'enabled': true,
              'sensitivity': 0.55,
            },
          };
          if (snap.hasData && snap.data!.snapshot.value != null) {
            cameras = Map<String, dynamic>.from(
              snap.data!.snapshot.value as Map,
            );
          }
          return StatefulBuilder(
            builder: (_, setSheet) => DraggableScrollableSheet(
              initialChildSize: 0.65,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              expand: false,
              builder: (_, scrollCtrl) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _sheetHandle(),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Cameras & Sensors',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Enable/disable cameras and set detection sensitivity',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        controller: scrollCtrl,
                        children: cameras.entries.map((entry) {
                          final cam = Map<String, dynamic>.from(
                            entry.value as Map,
                          );
                          final camName = cam['name']?.toString() ?? entry.key;
                          bool enabled = cam['enabled'] == true;
                          double sensitivity = (cam['sensitivity'] ?? 0.5)
                              .toDouble();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2A2A2A)
                                  : const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.videocam_outlined,
                                      color: enabled
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        camName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Switch(
                                      value: enabled,
                                      onChanged: (v) async {
                                        setSheet(
                                          () => cameras[entry.key] = {
                                            ...cam,
                                            'enabled': v,
                                          },
                                        );
                                        try {
                                          await FirebaseDatabase.instance
                                              .ref(
                                                'aura/config/cameras/${entry.key}/enabled',
                                              )
                                              .set(v);
                                        } catch (_) {}
                                      },
                                    ),
                                  ],
                                ),
                                if (enabled) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        'Sensitivity: ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black54,
                                        ),
                                      ),
                                      Text(
                                        sensitivity.toStringAsFixed(2),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Slider(
                                    value: sensitivity,
                                    min: 0.1,
                                    max: 0.9,
                                    divisions: 8,
                                    onChanged: (v) => setSheet(
                                      () => cameras[entry.key] = {
                                        ...cam,
                                        'sensitivity': v,
                                      },
                                    ),
                                    onChangeEnd: (v) async {
                                      try {
                                        await FirebaseDatabase.instance
                                            .ref(
                                              'aura/config/cameras/${entry.key}/sensitivity',
                                            )
                                            .set(v);
                                      } catch (_) {}
                                    },
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSystemInfo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetHandle(),
            const SizedBox(height: 20),
            Text(
              'System Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _infoRow('App Version', '1.0.0', isDark),
            _infoRow('AURA Core', 'v2.4.1', isDark),
            _infoRow('Firebase Sync', 'Active', isDark),
            _infoRow('AI Models', 'Fire, Fall, Pain, Child Safety', isDark),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpSupport() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetHandle(),
            const SizedBox(height: 20),
            Text(
              'Help & Support',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.email_outlined, color: Colors.blue),
              title: const Text('Email Support'),
              subtitle: const Text('support@aura.com'),
              onTap: () => _showSnack('📧 Email support would open here'),
            ),
            ListTile(
              leading: const Icon(Icons.call_outlined, color: Colors.green),
              title: const Text('Emergency Hotline'),
              subtitle: const Text('+1 234 567 890'),
              onTap: () => _showSnack('📞 Calling emergency hotline...'),
            ),
            ListTile(
              leading: const Icon(Icons.chat_outlined, color: Colors.orange),
              title: const Text('Live Chat'),
              onTap: () => _showSnack('💬 Live chat coming soon'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetHandle(),
            const SizedBox(height: 20),
            Text(
              'About AURA',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            const Icon(Icons.shield_outlined, size: 64, color: Colors.cyan),
            const SizedBox(height: 12),
            const Text(
              'AURA AI Safety Monitoring System',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Version 1.0.0', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            const Text(
              'Protecting homes with AI • Fall detection • Child safety • Fire & gas alerts • Smart IoT integration',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          ),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetHandle() => Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  Widget _sheetField(
    TextEditingController ctrl,
    String hint,
    IconData icon,
    bool isDark, {
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF2F2F2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Widget _toggleRow(
    BuildContext ctx,
    StateSetter setSheet,
    String title,
    String subtitle,
    bool value,
    IconData icon,
    Color color,
    bool isDark,
    Function(bool) onChanged,
  ) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  static void _dummyThemeChange(ThemeMode mode, Color color) {}

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final cardColor = isDark
        ? const Color(0xFF1E1E2E)
        : Colors.white.withValues(alpha: 0.95);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: primaryColor.withValues(alpha: 0.2),
                    child: Text(
                      UserSession.name.isNotEmpty
                          ? UserSession.name[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          UserSession.name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          UserSession.role == 'Admin'
                              ? 'Administrator'
                              : (UserSession.role == 'Guest'
                                    ? 'Guest'
                                    : 'Caregiver'),
                          style: TextStyle(fontSize: 14, color: subTextColor),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => _showEditProfile(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Edit Profile'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _settingsTile(
              Icons.account_circle_outlined,
              'Account Settings',
              () => _showEditProfile(),
              isDark,
            ),
            const SizedBox(height: 8),
            _settingsTile(
              Icons.notifications_outlined,
              'Notification Settings',
              () => _showNotificationPrefs(),
              isDark,
            ),
            const SizedBox(height: 8),
            _settingsTile(
              Icons.group_outlined,
              'Family Members',
              () => _showFamilyMembers(),
              isDark,
            ),
            const SizedBox(height: 8),
            _settingsTile(
              Icons.emergency_outlined,
              'Emergency Contacts',
              () => _showEmergencyContact(),
              isDark,
            ),
            const SizedBox(height: 8),
            _settingsTile(
              Icons.info_outline,
              'System Information',
              () => _showSystemInfo(),
              isDark,
            ),
            const SizedBox(height: 8),
            _settingsTile(
              Icons.help_outline,
              'Help & Support',
              () => _showHelpSupport(),
              isDark,
            ),
            const SizedBox(height: 8),
            _settingsTile(
              Icons.photo_camera_outlined,
              'About AURA',
              () => _showAbout(),
              isDark,
            ),
            const SizedBox(height: 60),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: const Text(
                'Logout',
                style: TextStyle(color: Colors.redAccent),
              ),
              onPressed: () {
                UserSession.clear();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const LoginScreen(onThemeChanged: _dummyThemeChange),
                  ),
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _settingsTile(
    IconData icon,
    String title,
    VoidCallback onTap,
    bool isDark,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(
        title,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }
}
