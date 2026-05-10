import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/butcher_models.dart';
import '../../services/butcher_service.dart';

class AnimalIntakeScreen extends ConsumerStatefulWidget {
  const AnimalIntakeScreen({super.key});

  @override
  ConsumerState<AnimalIntakeScreen> createState() => _AnimalIntakeScreenState();
}

class _AnimalIntakeScreenState extends ConsumerState<AnimalIntakeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _batchIdController = TextEditingController();
  final _weightController = TextEditingController();
  final _sourceNameController = TextEditingController();
  final _sourceLocationController = TextEditingController();
  final _ownerController = TextEditingController();

  AnimalType? _selectedType;
  DateTime _intakeDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _generateBatchID();
  }

  void _generateBatchID() {
    final typeCode = _selectedType?.shortCode ?? 'ANM';
    final date = DateFormat('yyyyMMdd').format(DateTime.now());
    final time = DateFormat('HHmm').format(DateTime.now());
    final random = (100 + (DateTime.now().millisecond % 900)).toString();
    _batchIdController.text = '$typeCode-$date-$time-$random';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live Animal Intake', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text('Record animal details and supply source for traceability.', style: TextStyle(color: AppColors.textLight)),
          const SizedBox(height: AppSpacing.xl),
          
          Form(
            key: _formKey,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildIntakeForm(),
                ),
                const SizedBox(width: AppSpacing.xl),
                Expanded(
                  flex: 1,
                  child: _buildTraceabilitySummary(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntakeForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<AnimalType>(
                    value: _selectedType,
                    decoration: const InputDecoration(labelText: 'Animal Type', border: OutlineInputBorder()),
                    items: AnimalType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))).toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedType = v;
                        _generateBatchID();
                      });
                    },
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: TextFormField(
                    controller: _batchIdController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Generated Batch ID', border: OutlineInputBorder(), prefixIcon: Icon(Icons.qr_code)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.l),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(labelText: 'Intake Weight (kg)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.scale)),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final n = double.tryParse(v);
                      if (n == null || n <= 0) return 'Invalid weight';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(context: context, initialDate: _intakeDate, firstDate: DateTime(2023), lastDate: DateTime.now());
                      if (picked != null) setState(() => _intakeDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20, color: AppColors.textLight),
                          const SizedBox(width: 8),
                          Text(DateFormat('yyyy-MM-dd').format(_intakeDate)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const Divider(),
            const SizedBox(height: AppSpacing.xl),
            const Align(alignment: Alignment.centerLeft, child: Text('Supply Source (Traceability)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            const SizedBox(height: AppSpacing.l),
            TextFormField(
              controller: _sourceNameController,
              decoration: const InputDecoration(labelText: 'Source Farm/Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.house_siding)),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.m),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _sourceLocationController,
                    decoration: const InputDecoration(labelText: 'Location/Town', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on_outlined)),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: TextFormField(
                    controller: _ownerController,
                    decoration: const InputDecoration(labelText: 'Owner Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _submitIntake,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Confirm Intake & Create Batch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTraceabilitySummary() {
    return Column(
      children: [
        Card(
          color: AppColors.primaryMaroon.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppColors.primaryMaroon),
                    SizedBox(width: 8),
                    Text('Data Compliance', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryMaroon)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Every animal intake must be recorded with its source for GRA and Health Department compliance. Generated Batch IDs are used for all downstream processing labels.', 
                  style: TextStyle(fontSize: 12, color: AppColors.textLight)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _submitIntake() {
    if (_formKey.currentState!.validate()) {
      final log = SlaughterLog(
        id: _batchIdController.text,
        animalId: 'ANM-${DateTime.now().millisecond}',
        type: _selectedType!,
        weight: double.tryParse(_weightController.text) ?? 0,
        status: SlaughterStatus.pending,
      );

      ref.read(slaughterLogsProvider.notifier).addLog(log);
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Text('Intake Successful'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Batch ID ${_batchIdController.text} has been created.'),
              const SizedBox(height: 8),
              const Text('Traceability records have been synchronized with the master database.', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _resetForm();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMaroon, foregroundColor: Colors.white),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    _weightController.clear();
    _sourceNameController.clear();
    _sourceLocationController.clear();
    _ownerController.clear();
    _generateBatchID();
  }
}
