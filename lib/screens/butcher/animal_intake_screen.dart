import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/butcher_models.dart';
import '../../services/butcher_service.dart';
import '../../services/user_provider.dart';
import '../../widgets/responsive_layout.dart';

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
  bool _isChicken = false;
  bool _isHard = true;
  bool _isSubmitting = false;
  DateTime _intakeDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _generateBatchID();
  }

  void _generateBatchID() {
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String suffix = timestamp.substring(timestamp.length - 12);
    _batchIdController.text = '00000000-0000-0000-0000-$suffix';
  }

  Widget _buildTypeDropdown() {
    final List<Map<String, dynamic>> categories = [
      {'label': 'Cow', 'type': AnimalType.cow},
      {'label': 'Bull', 'type': AnimalType.bull},
      {'label': 'Pig', 'type': AnimalType.pig},
      {'label': 'Sheep', 'type': AnimalType.sheep},
      {'label': 'Goat', 'type': AnimalType.goat},
      {'label': 'Chicken', 'type': 'chicken'},
      {'label': 'Turkey', 'type': AnimalType.turkey},
      {'label': 'Rabbit', 'type': AnimalType.rabbit},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<dynamic>(
          value: _isChicken ? 'chicken' : _selectedType,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Animal Type', border: OutlineInputBorder(), isDense: true),
          items: categories.map((c) => DropdownMenuItem(value: c['type'], child: Text(c['label'], overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (v) {
            setState(() {
              if (v == 'chicken') {
                _isChicken = true;
                _selectedType = _isHard ? AnimalType.hardChicken : AnimalType.softChicken;
              } else {
                _isChicken = false;
                _selectedType = v as AnimalType;
              }
              _generateBatchID();
            });
          },
          validator: (v) => v == null ? 'Required' : null,
        ),
        if (_isChicken) ...[
          const SizedBox(height: AppSpacing.m),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(AppRadius.s),
              border: Border.all(color: AppColors.borderGray),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Chicken Category:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ChoiceChip(
                  label: const Text('Hard (Layers)', style: TextStyle(fontSize: 11)),
                  selected: _isHard,
                  onSelected: (val) {
                    setState(() {
                      _isHard = val;
                      _selectedType = val ? AnimalType.hardChicken : AnimalType.softChicken;
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('Soft (Broilers)', style: TextStyle(fontSize: 11)),
                  selected: !_isHard,
                  onSelected: (val) {
                    setState(() {
                      _isHard = !val;
                      _selectedType = val ? AnimalType.softChicken : AnimalType.hardChicken;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBatchField() {
    return TextFormField(
      controller: _batchIdController,
      readOnly: true,
      decoration: const InputDecoration(labelText: 'Generated Batch ID', border: OutlineInputBorder(), prefixIcon: Icon(Icons.qr_code), isDense: true),
    );
  }

  Widget _buildWeightField() {
    return TextFormField(
      controller: _weightController,
      decoration: const InputDecoration(labelText: 'Intake Weight (kg)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.scale), isDense: true),
      keyboardType: TextInputType.number,
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        final n = double.tryParse(v);
        if (n == null || n <= 0) return 'Invalid weight';
        return null;
      },
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: _intakeDate, firstDate: DateTime(2023), lastDate: DateTime.now());
        if (picked != null) setState(() => _intakeDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: AppColors.textLight),
            const SizedBox(width: 8),
            Text(DateFormat('yyyy-MM-dd').format(_intakeDate), style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationField() {
    return TextFormField(
      controller: _sourceLocationController,
      decoration: const InputDecoration(labelText: 'Location/Town', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on_outlined), isDense: true),
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  }

  Widget _buildOwnerField() {
    return TextFormField(
      controller: _ownerController,
      decoration: const InputDecoration(labelText: 'Owner Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline), isDense: true),
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveLayout.isDesktop(context);
    
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
            child: isDesktop 
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildIntakeForm(isDesktop)),
                    const SizedBox(width: AppSpacing.xl),
                    Expanded(flex: 1, child: _buildTraceabilitySummary()),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIntakeForm(isDesktop),
                    const SizedBox(height: AppSpacing.l),
                    _buildTraceabilitySummary(),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntakeForm(bool isDesktop) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            isDesktop 
              ? Row(
                  children: [
                    Expanded(child: _buildTypeDropdown()),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(child: _buildBatchField()),
                  ],
                )
              : Column(
                  children: [
                    _buildTypeDropdown(),
                    const SizedBox(height: AppSpacing.m),
                    _buildBatchField(),
                  ],
                ),
            const SizedBox(height: AppSpacing.l),
            isDesktop 
              ? Row(
                  children: [
                    Expanded(child: _buildWeightField()),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(child: _buildDateField()),
                  ],
                )
              : Column(
                  children: [
                    _buildWeightField(),
                    const SizedBox(height: AppSpacing.m),
                    _buildDateField(),
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
            isDesktop 
              ? Row(
                  children: [
                    Expanded(child: _buildLocationField()),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(child: _buildOwnerField()),
                  ],
                )
              : Column(
                  children: [
                    _buildLocationField(),
                    const SizedBox(height: AppSpacing.m),
                    _buildOwnerField(),
                  ],
                ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitIntake,
                icon: _isSubmitting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_rounded),
                label: Text(_isSubmitting ? 'Processing...' : 'Confirm Intake & Create Batch', 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
          color: AppColors.primaryMaroon.withValues(alpha: 0.05),
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

  Future<void> _submitIntake() async {
    final user = ref.read(currentUserProvider);
    if (user?.branchCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No branch code assigned. Please contact Admin.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      if (_selectedType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an animal type.')),
        );
        return;
      }

      setState(() => _isSubmitting = true);

      try {
        final batchId = _batchIdController.text;
        final type = _selectedType!;
        final weight = double.tryParse(_weightController.text) ?? 0;
        final branchCode = user!.branchCode!;

        final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final String suffix = timestamp.substring(timestamp.length - 12);
        final String animalUuid = 'aaaaaaaa-aaaa-aaaa-aaaa-$suffix';

        final log = SlaughterLog(
          id: batchId,
          animalId: animalUuid,
          type: type,
          weight: weight,
          status: SlaughterStatus.pending,
        );

        final batch = MeatBatch(
          id: batchId,
          meatType: type.displayName,
          weight: weight,
          createdAt: DateTime.now(),
          status: 'waiting', 
          source: BatchSource(
            name: _sourceNameController.text,
            location: _sourceLocationController.text,
            owner: _ownerController.text,
          ),
        );

        // 0. Record the animal first (Satisfies Foreign Key constraints)
        await ref.read(butcherServiceProvider).addAnimal(
          branchCode,
          animalUuid, 
          type, 
          weight, 
          _sourceNameController.text
        );

        // 1. Create the slaughter log
        await ref.read(slaughterLogsProvider.notifier).addLog(log);
        
        // 2. Create the corresponding meat batch
        await ref.read(meatBatchesProvider.notifier).addBatch(batch);
        
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 12),
                  Expanded(child: Text('Intake Successful')),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Intake has been recorded successfully.', style: TextStyle(fontSize: 13)),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.s),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('GENERATED BATCH ID', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                            const SizedBox(height: 4),
                            SelectableText(
                              batchId, 
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace')
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Traceability records have been synchronized with the master database.', 
                        style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                    ],
                  ),
                ),
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
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to complete intake: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
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
