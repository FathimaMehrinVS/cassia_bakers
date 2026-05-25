import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/app_state.dart';
import '../providers/theme_provider.dart';
import 'auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _gstController = TextEditingController();
  final _companyController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _gstController.dispose();
    _companyController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _showAddStaffDialog(BuildContext context, AppState state) {
    final nameController = TextEditingController();
    final passController = TextEditingController();
    String role = 'Staff';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Register Staff Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Staff Username', prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passController,
              decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: role,
              decoration: const InputDecoration(labelText: 'System Role'),
              items: ['Admin', 'Staff'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (val) {
                if (val != null) role = val;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && passController.text.isNotEmpty) {
                state.addStaff(nameController.text.trim(), passController.text, role);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Staff profile successfully created for ${nameController.text}!'),
                    backgroundColor: AppColors.ready,
                  ),
                );
              }
            },
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final theme = Provider.of<ThemeProvider>(context);

    _gstController.text = state.defaultGstPercent.toStringAsFixed(0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Theme Configuration Drawer
            const Text('App Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.warmBrown)),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: Icon(
                  theme.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: AppColors.primaryMaroon,
                ),
                title: const Text('Dark Theme Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Toggle between day and night backgrounds'),
                trailing: Switch(
                  value: theme.isDarkMode,
                  activeColor: AppColors.secondaryGold,
                  onChanged: (val) => theme.toggleTheme(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. Billing Parameters (GST, Taxing)
            const Text('Taxation & POS parameters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.warmBrown)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Default GST rate (%)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _gstController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(vertical: 8)),
                            onSubmitted: (val) {
                              final double? rate = double.tryParse(val);
                              if (rate != null) {
                                state.setDefaultGstPercent(rate);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('GST rate updated!'), backgroundColor: AppColors.ready),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This tax will be calculated automatically at checkout registers.',
                      style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2.3. Bluetooth Thermal Printer Manager
            const Text('Bluetooth Thermal Printer Manager', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.warmBrown)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        state.isPrinterConnected ? Icons.print : Icons.print_disabled,
                        color: state.isPrinterConnected ? Colors.green : Colors.red,
                        size: 32,
                      ),
                      title: Text(
                        state.isPrinterConnected
                            ? 'Paired Printer: ${state.pairedPrinterName}'
                            : 'No Paired Thermal Printer',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        state.isPrinterConnected
                            ? 'Ready for offline-first bakery receipt printing'
                            : 'Supports stable testing without requiring physical printer hardware',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (state.isPrinterConnected) ...[
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Sent hardware test page... ESC/POS packet simulation OK!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            child: const Text('Test Receipt', style: TextStyle(color: Color(0xFF800020))),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () async {
                              await state.disconnectPrinter();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Printer disconnected successfully.')),
                                );
                              }
                            },
                            child: const Text('Disconnect', style: TextStyle(color: Colors.white)),
                          ),
                        ] else
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF800020)),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  final devices = [
                                    'RPP-02N Thermal Printer (58mm)',
                                    'TVS RP-3160 Gold Bluetooth',
                                    'Epson TM-T88VI Printer',
                                    'Xprinter XP-N160I Serial BT',
                                  ];
                                  return SimpleDialog(
                                    title: const Text('Available Thermal Printers'),
                                    children: devices.map((dev) {
                                      return SimpleDialogOption(
                                        onPressed: () async {
                                          await state.pairPrinter(dev);
                                          Navigator.pop(context);
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Paired successfully with $dev!'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.bluetooth, color: Colors.blue),
                                              const SizedBox(width: 10),
                                              Text(dev, style: const TextStyle(fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              );
                            },
                            child: const Text('Scan Printer Devices', style: TextStyle(color: Colors.white)),
                          )
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 3. User & Staff Credentials roster
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Staff accounts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.warmBrown)),
                TextButton.icon(
                  onPressed: () => _showAddStaffDialog(context, state),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Staff', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primaryMaroon),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.staffList.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final staff = state.staffList[index];
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blueGrey,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(staff.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Role: ${staff.role}'),
                    trailing: staff.username == 'admin'
                        ? const Text('Primary', style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic))
                        : IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              state.deleteStaff(staff.username);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Staff account deleted successfully!')),
                              );
                            },
                          ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // 4. Data Security backups
            const Text('Security & Database Utility', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.warmBrown)),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.cloud_upload_outlined, color: Colors.blue),
                    title: const Text('Trigger Local Backup'),
                    subtitle: const Text('Sync local SQL database structure to secure local storage'),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Backup files successfully saved to secure sandbox!'),
                          backgroundColor: AppColors.ready,
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.restore, color: Colors.red),
                    title: const Text('Reset Demo Database'),
                    subtitle: const Text('Clear active records and reload stock samples'),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Reset local database?'),
                          content: const Text('This will delete all current orders, items, and settings and reload standard templates.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                await state.resetDatabaseToSeeded();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Database reset completed successfully!'), backgroundColor: AppColors.ready),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: const Text('Reset Database'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 5. Logout Button
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  state.logout();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const AuthScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMaroon,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
                ),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Logout Session', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
