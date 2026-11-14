import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final ApiService _apiService = ApiService();
  List<User> _users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getUsers();
      setState(() => _users = list);
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  void _showAddEditUserModal({User? user}) {
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final passwordCtrl = TextEditingController();
    String role = user?.role ?? 'STAFF';
    bool canViewAll = user?.canViewPreviousQuotations ?? false;
    bool canManageCat = user?.canManageCatalog ?? false;
    bool isActive = user?.isActive ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dCtx, setMState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(dCtx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user != null ? 'Edit Staff Account' : 'Create New User Account',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name *')),
                    const SizedBox(height: 10),
                    TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email Address *')),
                    const SizedBox(height: 10),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: user != null ? 'New Password (leave blank to keep unchanged)' : 'Password *',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: role,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: const [
                        DropdownMenuItem(value: 'STAFF', child: Text('Staff Member')),
                        DropdownMenuItem(value: 'ADMIN', child: Text('Administrator')),
                      ],
                      onChanged: (val) {
                        if (val != null) setMState(() => role = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Can View Previous Quotations', style: TextStyle(fontSize: 13)),
                      value: canViewAll,
                      activeColor: AppColors.primary500,
                      onChanged: (v) => setMState(() => canViewAll = v ?? false),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Can Manage Product Catalog', style: TextStyle(fontSize: 13)),
                      value: canManageCat,
                      activeColor: AppColors.primary500,
                      onChanged: (v) => setMState(() => canManageCat = v ?? false),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Account Active', style: TextStyle(fontSize: 13)),
                      value: isActive,
                      activeColor: AppColors.primary500,
                      onChanged: (v) => setMState(() => isActive = v),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          final email = emailCtrl.text.trim();
                          if (name.isEmpty || email.isEmpty) return;

                          final data = <String, dynamic>{
                            'name': name,
                            'email': email,
                            'role': role,
                            'canViewPreviousQuotations': canViewAll,
                            'canManageCatalog': canManageCat,
                            'isActive': isActive,
                          };
                          if (passwordCtrl.text.trim().isNotEmpty) {
                            data['password'] = passwordCtrl.text.trim();
                          }

                          try {
                            if (user != null) {
                              await _apiService.updateUser(user.id, data);
                            } else {
                              if (passwordCtrl.text.trim().isEmpty) return;
                              await _apiService.createUser(data);
                            }
                            if (mounted) {
                              Navigator.pop(ctx);
                              _fetchUsers();
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                              );
                            }
                          }
                        },
                        child: Text(user != null ? 'Update Account' : 'Create Account'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('USERS & ROLES'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchUsers),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary500))
          : _users.isEmpty
              ? const Center(child: Text('No users found'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final u = _users[idx];
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: u.isAdmin ? AppColors.primary500 : AppColors.slate200,
                          foregroundColor: u.isAdmin ? AppColors.slate950 : AppColors.slate800,
                          child: Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : 'U'),
                        ),
                        title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${u.email}\nRole: ${u.role} • ${u.isActive ? "Active" : "Disabled"}'),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'edit') {
                              _showAddEditUserModal(user: u);
                            } else if (val == 'delete') {
                              _apiService.deleteUser(u.id).then((_) => _fetchUsers());
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary500,
        foregroundColor: AppColors.slate950,
        icon: const Icon(Icons.person_add),
        label: const Text('New User', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showAddEditUserModal(),
      ),
    );
  }
}

