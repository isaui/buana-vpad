import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:buana_vpad/database/db_helper.dart';
import 'package:buana_vpad/enums/url.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:buana_vpad/utils/settings_manager.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _deviceName;
  String? _deviceId;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final name = await SettingsManager.getDeviceName();
    final id = await SettingsManager.getDeviceId();
    setState(() {
      _deviceName = name;
      _deviceId = id;
    });
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Layouts'),
        content: const Text(
          'Are you sure you want to delete all controller layouts? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final dbHelper = DatabaseHelper();
        await dbHelper.deleteAllControllerLayouts();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All layouts deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting layouts: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showEditDeviceNameDialog(
      BuildContext context, String currentName) async {
    final controller = TextEditingController(text: currentName);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Device Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter device name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      await SettingsManager.setDeviceName(newName);
      setState(() {
        _deviceName = newName;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device name updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.grey[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[900]!,
              Colors.grey[850]!,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Device Section
            _buildSection(
              title: 'Device',
              children: [
                _buildListTile(
                  title: 'Device ID',
                  subtitle: _deviceId ?? 'Loading...',
                  trailing: const Icon(
                    Icons.copy,
                    color: Colors.blue,
                  ),
                  onTap: () async {
                    if (_deviceId != null) {
                      await Clipboard.setData(ClipboardData(text: _deviceId!));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Device ID copied to clipboard'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                ),
                _buildListTile(
                  title: 'Device Name',
                  subtitle: _deviceName ?? 'Loading...',
                  trailing: const Icon(
                    Icons.edit,
                    color: Colors.blue,
                  ),
                  onTap: () =>
                      _showEditDeviceNameDialog(context, _deviceName ?? ''),
                ),
              ],
            ),

            // Theme Section
            _buildSection(
              title: 'Theme',
              children: [
                _buildListTile(
                  title: 'Dark/Light Theme',
                  subtitle: 'Coming soon',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'In Development',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  onTap: () {}, // Disabled for now
                ),
              ],
            ),

            // Application Section
            _buildSection(
              title: 'Application',
              children: [
                _buildListTile(
                  title: 'Delete All Layouts',
                  subtitle: 'Remove all controller configurations',
                  trailing: const Icon(
                    Icons.delete_forever,
                    color: Colors.red,
                  ),
                  onTap: () => _showDeleteConfirmation(context),
                ),
              ],
            ),

            // Developer Section
            _buildSection(
              title: 'Developer',
              children: [
                _buildListTile(
                  title: 'LinkedIn',
                  subtitle: 'View developer profile',
                  trailing: const Icon(
                    Icons.launch,
                    color: Colors.blue,
                  ),
                  onTap: () => _launchUrl(Link.developerLinkedin.path),
                ),
                _buildListTile(
                  title: 'GitHub Profile',
                  subtitle: 'Check out other projects',
                  trailing: const Icon(
                    Icons.launch,
                    color: Colors.blue,
                  ),
                  onTap: () => _launchUrl(Link.developerGithubAccount.path),
                ),
              ],
            ),

            // Project Section
            _buildSection(
              title: 'Project',
              children: [
                _buildListTile(
                  title: 'GitHub Repository',
                  subtitle: 'View source code',
                  trailing: const Icon(
                    Icons.launch,
                    color: Colors.blue,
                  ),
                  onTap: () => _launchUrl(Link.githubSourceRepo.path),
                ),
                _buildListTile(
                  title: 'View Licenses',
                  subtitle: 'Open source licenses',
                  trailing: const Icon(
                    Icons.launch,
                    color: Colors.blue,
                  ),
                  onTap: () => _launchUrl('YOUR_LICENSE_URL'),
                ),
                _buildListTile(
                  title: 'Version',
                  subtitle: 'v1.0.0',
                ),
              ],
            ),

            // Support Section
            _buildSection(
              title: 'Support & Community',
              children: [
                _buildListTile(
                  title: 'Discord',
                  subtitle: 'isacitrabuana',
                  trailing: const Icon(
                    Icons.copy,
                    color: Colors.blue,
                  ),
                  onTap: () async {
                    await Clipboard.setData(
                        const ClipboardData(text: 'isacitrabuana'));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Discord username copied to clipboard'),
                          duration: Duration(seconds: 2),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),

            // Documentation Section
            _buildSection(
              title: 'Documentation',
              children: [
                _buildListTile(
                  title: 'User Guide',
                  subtitle: 'Learn how to use the app',
                  trailing: const Icon(
                    Icons.launch,
                    color: Colors.blue,
                  ),
                  onTap: () => _launchUrl(Link.userGuide.path),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          color: Colors.grey[850],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
              ),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
