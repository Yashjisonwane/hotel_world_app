import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/api_constants.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _companyCtrl = TextEditingController();
  final _taglineCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _prefixCtrl = TextEditingController();
  final _validityCtrl = TextEditingController();
  final _backendUrlCtrl = TextEditingController();

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final s = context.read<SettingsProvider>().settings;
      _companyCtrl.text = s.companyName;
      _taglineCtrl.text = s.tagline;
      _phoneCtrl.text = s.phone;
      _emailCtrl.text = s.email;
      _websiteCtrl.text = s.website;
      _addressCtrl.text = s.address;
      _gstinCtrl.text = s.gstin;
      _panCtrl.text = s.pan;
      _prefixCtrl.text = s.quotePrefix;
      _validityCtrl.text = s.defaultValidityDays.toString();
      _backendUrlCtrl.text = context.read<SettingsProvider>().backendUrl;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _companyCtrl.dispose();
    _taglineCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _addressCtrl.dispose();
    _gstinCtrl.dispose();
    _panCtrl.dispose();
    _prefixCtrl.dispose();
    _validityCtrl.dispose();
    _backendUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final settingsProv = context.read<SettingsProvider>();
    final newBackend = _backendUrlCtrl.text.trim();
    if (newBackend.isNotEmpty && newBackend != settingsProv.backendUrl) {
      await settingsProv.updateBackendUrl(newBackend);
    }

    final data = {
      'companyName': _companyCtrl.text.trim(),
      'tagline': _taglineCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'website': _websiteCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'gstin': _gstinCtrl.text.trim().toUpperCase(),
      'pan': _panCtrl.text.trim().toUpperCase(),
      'quotePrefix': _prefixCtrl.text.trim(),
      'defaultValidityDays': int.tryParse(_validityCtrl.text) ?? 15,
    };

    final ok = await settingsProv.saveSettings(data);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Settings successfully saved!' : 'Failed to update settings.'),
          backgroundColor: ok ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProv = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('COMPANY SETTINGS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.primary400, size: 28),
            onPressed: settingsProv.isLoading ? null : _saveSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // BACKEND CONNECTION SETTINGS
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.cloud_sync, color: AppColors.primary600, size: 20),
                        SizedBox(width: 8),
                        Text('Backend API Connection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Hotel World syncs all quotes and catalog with the central enterprise cloud database.',
                      style: TextStyle(fontSize: 12, color: AppColors.slate500),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _backendUrlCtrl,
                      decoration: InputDecoration(
                        labelText: 'Server Base URL',
                        hintText: ApiConstants.defaultLiveUrl,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.restore, size: 20),
                          tooltip: 'Reset to Cloud Server Default',
                          onPressed: () {
                            _backendUrlCtrl.text = ApiConstants.defaultLiveUrl;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            _backendUrlCtrl.text = ApiConstants.defaultLiveUrl;
                          },
                          child: const Text('Live Cloud (Default)'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {
                            _backendUrlCtrl.text = 'http://10.0.2.2:5000';
                          },
                          child: const Text('Local Host'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // COMPANY PROFILE
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.business, color: AppColors.primary600, size: 20),
                        SizedBox(width: 8),
                        Text('Company Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 20),
                    TextField(controller: _companyCtrl, decoration: const InputDecoration(labelText: 'Company Trade Name *')),
                    const SizedBox(height: 12),
                    TextField(controller: _taglineCtrl, decoration: const InputDecoration(labelText: 'Tagline / Subtitle')),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Numbers'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email Address'))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Full Address')),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _gstinCtrl, decoration: const InputDecoration(labelText: 'GSTIN'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: _panCtrl, decoration: const InputDecoration(labelText: 'PAN Number'))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _prefixCtrl, decoration: const InputDecoration(labelText: 'Quote Number Prefix'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: _validityCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Validity (Days)'))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: settingsProv.isLoading ? null : _saveSettings,
                        child: settingsProv.isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Save All Settings'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

