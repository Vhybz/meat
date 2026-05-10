import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/user_model.dart';
import '../../services/user_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _surnameController;
  late TextEditingController _phoneController;
  
  String? _selectedGender;
  DateTime? _selectedDob;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _surnameController = TextEditingController(text: user?.surname ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _selectedGender = user?.gender;
    _selectedDob = user?.dob;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Center(child: Text('No user logged in.'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(user),
          const SizedBox(height: AppSpacing.xl),
          _buildInfoSection(user),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserAccount user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primaryMaroon.withOpacity(0.1),
              child: const Icon(Icons.person, size: 50, color: AppColors.primaryMaroon),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(user.email, style: const TextStyle(color: AppColors.textLight)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primaryMaroon, borderRadius: BorderRadius.circular(20)),
                    child: Text(user.role.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => setState(() => _isEditing = !_isEditing),
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              label: Text(_isEditing ? 'Cancel' : 'Edit Profile'),
              style: ElevatedButton.styleFrom(backgroundColor: _isEditing ? Colors.grey : AppColors.primaryMaroon, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(UserAccount user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 32),
            if (!_isEditing) ...[
              _infoRow(Icons.phone, 'Phone Number', user.phone ?? 'Not set'),
              _infoRow(Icons.wc, 'Gender', user.gender ?? 'Not set'),
              _infoRow(Icons.cake, 'Date of Birth', user.dob != null ? DateFormat('yyyy-MM-dd').format(user.dob!) : 'Not set'),
              _infoRow(Icons.calendar_today, 'Joined On', DateFormat('MMMM d, yyyy').format(user.createdAt)),
            ] else ...[
              _buildEditField(_firstNameController, 'First Name'),
              const SizedBox(height: 16),
              _buildEditField(_surnameController, 'Surname'),
              const SizedBox(height: 16),
              _buildEditField(_phoneController, 'Phone Number'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (v) => setState(() => _selectedGender = v),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDob ?? DateTime(2000),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _selectedDob = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                  child: Row(
                    children: [
                      const Icon(Icons.cake_outlined, size: 20, color: AppColors.textLight),
                      const SizedBox(width: 8),
                      Text(_selectedDob == null ? 'Date of Birth' : DateFormat('yyyy-MM-dd').format(_selectedDob!)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
                  child: const Text('Save Profile Details'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textLight),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textLight))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEditField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
  }

  void _saveProfile() {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      ref.read(userProvider.notifier).updateProfile(
        user.id,
        firstName: _firstNameController.text,
        surname: _surnameController.text,
        phone: _phoneController.text,
        gender: _selectedGender,
        dob: _selectedDob,
      );
      
      // Data is handled by userProvider. notifier.state update not needed for regular Provider.
      
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
    }
  }
}
