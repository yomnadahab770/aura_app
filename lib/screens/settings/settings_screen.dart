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
  bool _energySavingEnabled = true;
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
        _energySavingEnabled = data['energySaving'] ?? true;
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

  Widget _sectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white38 : Colors.black38,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool adminOnly = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLocked = adminOnly && UserSession.role != 'Admin';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLocked
              ? (isDark ? Colors.white10 : Colors.black12)
              : (isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isLocked
                ? Colors.grey.withOpacity(0.15)
                : iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            isLocked ? Icons.lock_outline : icon,
            color: isLocked ? Colors.grey : iconColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isLocked
                ? (isDark ? Colors.white38 : Colors.black38)
                : (isDark ? Colors.white : Colors.black87),
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                isLocked ? 'Admin only' : subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              )
            : null,
        trailing: isLocked
            ? null
            : (trailing ??
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey,
                  )),
        onTap: isLocked ? null : onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
    );
  }

  // ── Edit Profile ─────────────────────────────────────────
  void _showEditProfile() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameCtrl = TextEditingController(text: UserSession.name);
    final isAdmin = UserSession.role == 'Admin';
    final emailCtrl = TextEditingController(text: UserSession.email);
    final passCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
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

  // ── House Management ─────────────────────────────────────
  void _showHouseManagement() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final houseCtrl = TextEditingController(text: UserSession.houseName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
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
              'House Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            _sheetField(houseCtrl, 'House Name', Icons.home_outlined, isDark),
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
                  try {
                    await FirebaseDatabase.instance
                        .ref('aura/users/${UserSession.uid}/houseName')
                        .set(houseCtrl.text.trim());
                    UserSession.houseName = houseCtrl.text.trim();
                    if (ctx.mounted) Navigator.pop(ctx);
                    _showSnack('✅ House name updated');
                    setState(() {});
                  } catch (_) {
                    _showSnack('❌ Failed to save', error: true);
                  }
                },
                child: const Text(
                  'Save',
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

  // ── Family Members ───────────────────────────────────────
  void _showFamilyMembers() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
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
                                ? const Color(0xFF242424)
                                : const Color(0xFFF8F8F8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCurrentUser
                                  ? primaryColor.withOpacity(0.4)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: primaryColor.withOpacity(0.18),
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
                                      ? primaryColor.withOpacity(0.15)
                                      : Colors.grey.withOpacity(0.15),
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
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
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

  // ── Notification Preferences ─────────────────────────────
  void _showNotificationPrefs() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = UserSession.role == 'Admin';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
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
                ctx: ctx,
                setSheet: setSheet,
                title: 'All Notifications',
                subtitle: 'Master switch',
                value: _notificationsEnabled,
                icon: Icons.notifications_outlined,
                color: Colors.blue,
                isDark: isDark,
                onChanged: (v) async {
                  setSheet(() => _notificationsEnabled = v);
                  setState(() => _notificationsEnabled = v);
                  await _saveSetting('notifications', v);
                },
              ),
              if (isAdmin) ...[
                const Divider(height: 24),
                Text(
                  'Alert Types',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                _toggleRow(
                  ctx: ctx,
                  setSheet: setSheet,
                  title: 'Fire & Child Alerts',
                  subtitle: 'DISTRACT_CHILD / CLOSE_GAS',
                  value: _fireAlerts,
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                  isDark: isDark,
                  onChanged: (v) async {
                    setSheet(() => _fireAlerts = v);
                    setState(() => _fireAlerts = v);
                    await _saveSetting('fireAlerts', v);
                  },
                ),
                _toggleRow(
                  ctx: ctx,
                  setSheet: setSheet,
                  title: 'Fall Detection Alerts',
                  subtitle: 'FALL_DETECTED',
                  value: _fallAlerts,
                  icon: Icons.personal_injury_outlined,
                  color: Colors.red,
                  isDark: isDark,
                  onChanged: (v) async {
                    setSheet(() => _fallAlerts = v);
                    setState(() => _fallAlerts = v);
                    await _saveSetting('fallAlerts', v);
                  },
                ),
                _toggleRow(
                  ctx: ctx,
                  setSheet: setSheet,
                  title: 'Gas Leak Alerts',
                  subtitle: 'Auto-valve close',
                  value: _gasAlerts,
                  icon: Icons.gas_meter_outlined,
                  color: Colors.blueAccent,
                  isDark: isDark,
                  onChanged: (v) async {
                    setSheet(() => _gasAlerts = v);
                    setState(() => _gasAlerts = v);
                    await _saveSetting('gasAlerts', v);
                  },
                ),
                _toggleRow(
                  ctx: ctx,
                  setSheet: setSheet,
                  title: 'Pain & Chest Alerts',
                  subtitle: 'PAIN_DETECTED / CHEST_PAIN',
                  value: _painAlerts,
                  icon: Icons.favorite_outline,
                  color: Colors.pink,
                  isDark: isDark,
                  onChanged: (v) async {
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

  // ── Alert Thresholds ─────────────────────────────────────
  void _showAlertThresholds() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double dangerDist = 10.0;
    double warningDist = 15.0;
    double acDefault = 22.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (_, setSheet) => Padding(
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
                'Alert Thresholds',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Fire detection sensitivity (Python model config)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              _sliderRow(
                setSheet: setSheet,
                isDark: isDark,
                label: 'Danger Distance',
                unit: 'm',
                value: dangerDist,
                min: 2,
                max: 20,
                divisions: 18,
                color: Colors.red,
                onChanged: (v) => setSheet(() => dangerDist = v),
              ),
              const SizedBox(height: 12),
              _sliderRow(
                setSheet: setSheet,
                isDark: isDark,
                label: 'Warning Distance',
                unit: 'm',
                value: warningDist,
                min: 5,
                max: 30,
                divisions: 25,
                color: Colors.orange,
                onChanged: (v) => setSheet(() => warningDist = v),
              ),
              const SizedBox(height: 12),
              _sliderRow(
                setSheet: setSheet,
                isDark: isDark,
                label: 'Default AC Temperature',
                unit: '°C',
                value: acDefault,
                min: 16,
                max: 30,
                divisions: 14,
                color: Colors.blueAccent,
                onChanged: (v) => setSheet(() => acDefault = v),
              ),
              const SizedBox(height: 24),
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
                    try {
                      await FirebaseDatabase.instance
                          .ref('aura/config/thresholds')
                          .set({
                            'danger_distance_m': dangerDist,
                            'warning_distance_m': warningDist,
                            'ac_default_temp': acDefault,
                            'updatedBy': UserSession.name,
                            'updatedAt': DateTime.now().toIso8601String(),
                          });
                      if (ctx.mounted) Navigator.pop(ctx);
                      _showSnack('✅ Thresholds saved to Firebase');
                    } catch (_) {
                      _showSnack('❌ Failed to save', error: true);
                    }
                  },
                  child: const Text(
                    'Apply & Save',
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
      ),
    );
  }

  // ── Emergency Contact ────────────────────────────────────
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
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
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

  // ── Personal Preferences ─────────────────────────────────
  void _showPersonalPreferences() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double lightBrightness = 80.0;
    double acTemp = 22.0;
    double curtainLevel = 50.0;
    String tvChannel = '1';

    FirebaseDatabase.instance
        .ref('aura/preferences/${UserSession.uid}')
        .get()
        .then((snap) {
          if (snap.value != null) {
            final data = Map<String, dynamic>.from(snap.value as Map);
            lightBrightness = (data['light_brightness'] ?? 80.0).toDouble();
            acTemp = (data['ac_temp'] ?? 22.0).toDouble();
            curtainLevel = (data['curtain_level'] ?? 50.0).toDouble();
            tvChannel = data['tv_channel']?.toString() ?? '1';
          }
        });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (_, setSheet) => Padding(
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
                'My Preferences',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'AURA learns and applies these automatically on your entry',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              _sliderRow(
                setSheet: setSheet,
                isDark: isDark,
                label: 'Lighting Brightness',
                unit: '%',
                value: lightBrightness,
                min: 0,
                max: 100,
                divisions: 20,
                color: Colors.amber,
                onChanged: (v) => setSheet(() => lightBrightness = v),
              ),
              const SizedBox(height: 12),
              _sliderRow(
                setSheet: setSheet,
                isDark: isDark,
                label: 'AC Temperature',
                unit: '°C',
                value: acTemp,
                min: 16,
                max: 30,
                divisions: 14,
                color: Colors.blueAccent,
                onChanged: (v) => setSheet(() => acTemp = v),
              ),
              const SizedBox(height: 12),
              _sliderRow(
                setSheet: setSheet,
                isDark: isDark,
                label: 'Curtains',
                unit: '%',
                value: curtainLevel,
                min: 0,
                max: 100,
                divisions: 10,
                color: Colors.brown,
                onChanged: (v) => setSheet(() => curtainLevel = v),
              ),
              const SizedBox(height: 16),
              Text(
                'Preferred TV Channel',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              _sheetField(
                TextEditingController(text: tvChannel),
                'TV Channel Number',
                Icons.tv_outlined,
                isDark,
                keyboardType: TextInputType.number,
              ),
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
                    try {
                      await FirebaseDatabase.instance
                          .ref('aura/preferences/${UserSession.uid}')
                          .set({
                            'light_brightness': lightBrightness,
                            'ac_temp': acTemp,
                            'curtain_level': curtainLevel,
                            'tv_channel': tvChannel,
                            'updatedAt': DateTime.now().toIso8601String(),
                          });
                      if (ctx.mounted) Navigator.pop(ctx);
                      _showSnack('✅ Preferences saved');
                    } catch (_) {
                      _showSnack('❌ Failed to save', error: true);
                    }
                  },
                  child: const Text(
                    'Save Preferences',
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
      ),
    );
  }

  // ── Cameras & Sensors ────────────────────────────────────
  void _showCamerasSensors() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
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
                                  ? const Color(0xFF242424)
                                  : const Color(0xFFF8F8F8),
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
                                    onChanged: (v) {
                                      setSheet(
                                        () => cameras[entry.key] = {
                                          ...cam,
                                          'sensitivity': v,
                                        },
                                      );
                                    },
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

  // ── Sheet Helpers ────────────────────────────────────────
  Widget _sheetHandle() => Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.3),
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

  Widget _toggleRow({
    required BuildContext ctx,
    required StateSetter setSheet,
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Color color,
    required bool isDark,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
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

  Widget _sliderRow({
    required StateSetter setSheet,
    required bool isDark,
    required String label,
    required String unit,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Color color,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            Text(
              '${value.toStringAsFixed(unit == 'm' || unit == '°C' ? 1 : 0)}$unit',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: color,
          onChanged: onChanged,
        ),
      ],
    );
  }

  // ── Reports ──────────────────────────────────────────────
  Widget _buildDailyReport(bool isDark, Color primaryColor) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('aura/reports/daily').onValue,
      builder: (context, snap) {
        Map<String, dynamic> daily = {};
        if (snap.hasData && snap.data!.snapshot.value != null) {
          daily = Map<String, dynamic>.from(snap.data!.snapshot.value as Map);
        }
        final energy = daily['energy_kwh']?.toString() ?? '—';
        final avgTemp = daily['avg_temp']?.toString() ?? '—';
        final motions = daily['motion_count']?.toString() ?? '—';
        final safety = daily['safety_status']?.toString() ?? '—';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primaryColor.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.today_outlined, color: primaryColor, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Daily Report',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _reportRow('⚡ Energy', '$energy kWh', Colors.green, isDark),
              const Divider(height: 16),
              _reportRow('🌡️ Avg Temp', '$avgTemp °C', Colors.blue, isDark),
              const Divider(height: 16),
              _reportRow('🚶 Motion', '$motions times', Colors.purple, isDark),
              const Divider(height: 16),
              _reportRow('🔥 Safety', safety, Colors.orange, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeeklyReport(bool isDark, Color primaryColor) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('aura/reports/weekly').onValue,
      builder: (context, snap) {
        Map<String, dynamic> weekly = {};
        if (snap.hasData && snap.data!.snapshot.value != null) {
          weekly = Map<String, dynamic>.from(snap.data!.snapshot.value as Map);
        }
        final uptime = weekly['uptime_percent']?.toString() ?? '—';
        final energy = weekly['energy_kwh']?.toString() ?? '—';
        final threats = weekly['threats_blocked']?.toString() ?? '—';
        final pings = weekly['sensor_pings']?.toString() ?? '—';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primaryColor.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    color: primaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Weekly Diagnostics',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _reportRow('📡 Uptime', '$uptime%', Colors.teal, isDark),
              const Divider(height: 16),
              _reportRow('⚡ Energy', '$energy kWh', Colors.green, isDark),
              const Divider(height: 16),
              _reportRow('🛡️ Threats Blocked', threats, Colors.red, isDark),
              const Divider(height: 16),
              _reportRow('🔔 Sensor Pings', pings, Colors.blue, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _reportRow(String title, String value, Color color, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // ── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isAdmin = UserSession.role == 'Admin';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: primaryColor.withOpacity(0.2),
                    child: Icon(
                      isAdmin
                          ? Icons.admin_panel_settings
                          : Icons.person_outline,
                      size: 32,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          UserSession.name,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          UserSession.email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                UserSession.role,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                UserSession.houseName,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
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
            ),

            _sectionHeader('ACCOUNT'),
            _tile(
              icon: Icons.person_outline,
              iconColor: Colors.blueAccent,
              title: 'Edit Profile',
              subtitle: isAdmin ? 'Name, email, password' : 'Display name only',
              onTap: _showEditProfile,
            ),

            _sectionHeader('HOUSE'),
            _tile(
              icon: Icons.home_outlined,
              iconColor: Colors.teal,
              title: 'House Management',
              subtitle: 'Rename your home',
              adminOnly: true,
              onTap: _showHouseManagement,
            ),
            _tile(
              icon: Icons.group_outlined,
              iconColor: Colors.teal,
              title: 'Family Members',
              subtitle: 'Add, remove, change roles',
              adminOnly: true,
              onTap: _showFamilyMembers,
            ),

            _sectionHeader('SAFETY & ALERTS'),
            _tile(
              icon: Icons.notifications_outlined,
              iconColor: Colors.deepOrange,
              title: 'Notification Preferences',
              subtitle: isAdmin
                  ? 'Fire, fall, gas, pain alerts'
                  : 'My personal notifications',
              onTap: _showNotificationPrefs,
            ),
            _tile(
              icon: Icons.tune_outlined,
              iconColor: Colors.amber,
              title: 'Alert Thresholds',
              subtitle: 'Danger distance, AC temp',
              adminOnly: true,
              onTap: _showAlertThresholds,
            ),
            _tile(
              icon: Icons.phone_in_talk_outlined,
              iconColor: Colors.redAccent,
              title: 'Emergency Contact',
              subtitle: 'Auto-called after 10 min',
              adminOnly: true,
              onTap: _showEmergencyContact,
            ),

            _sectionHeader('DEVICES'),
            _tile(
              icon: Icons.videocam_outlined,
              iconColor: Colors.purple,
              title: 'Cameras & Sensors',
              subtitle: 'Enable, disable, sensitivity',
              adminOnly: true,
              onTap: _showCamerasSensors,
            ),
            _tile(
              icon: Icons.bolt_outlined,
              iconColor: Colors.green,
              title: 'Energy Saving Mode',
              subtitle: _energySavingEnabled ? 'Enabled' : 'Disabled',
              adminOnly: true,
              trailing: Switch(
                value: _energySavingEnabled,
                onChanged: isAdmin
                    ? (v) async {
                        setState(() => _energySavingEnabled = v);
                        await _saveSetting('energySaving', v);
                        await FirebaseDatabase.instance
                            .ref('aura/config/energySaving')
                            .set(v);
                      }
                    : null,
              ),
              onTap: null,
            ),

            _sectionHeader('PREFERENCES'),
            _tile(
              icon: Icons.tune,
              iconColor: Colors.purpleAccent,
              title: 'My Preferences',
              subtitle: 'Lights, AC, curtains, TV',
              onTap: _showPersonalPreferences,
            ),

            _sectionHeader('REPORTS'),
            _buildDailyReport(isDark, primaryColor),
            const SizedBox(height: 12),
            _buildWeeklyReport(isDark, primaryColor),

            if (isAdmin) ...[
              _sectionHeader('ADMIN'),
              _tile(
                icon: Icons.history,
                iconColor: Colors.blueGrey,
                title: 'System Log Files',
                subtitle: 'Export CSV safety metrics',
                onTap: () => _showSnack('📄 Log export coming soon...'),
              ),
            ],

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text(
                  'Logout from Account',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
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
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  static void _dummyThemeChange(ThemeMode mode, Color color) {}
}
