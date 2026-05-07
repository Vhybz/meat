import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../widgets/responsive_layout.dart';
import '../../models/butcher_models.dart';

class AnimalIntakeScreen extends StatefulWidget {
  const AnimalIntakeScreen({super.key});

  @override
  State<AnimalIntakeScreen> createState() => _AnimalIntakeScreenState();
}

class _AnimalIntakeScreenState extends State<AnimalIntakeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _sourceController = TextEditingController();
  final _weightController = TextEditingController();
  
  AnimalType? _selectedType;
  double _estimatedYield = 0.0;

  @override
  void initState() {
    super.initState();
    _generateSmartID();
  }

  void _generateSmartID() {
    final prefix = _selectedType?.name.substring(0, 2).toUpperCase() ?? 'ANM';
    final date = DateFormat('yyMMdd').format(DateTime.now());
    final random = (100 + (DateTime.now().millisecond % 900)).toString();
    _idController.text = '$prefix-$date-$random';
  }

  void _calculateYield() {
    if (_selectedType != null && _weightController.text.isNotEmpty) {
      final weight = double.tryParse(_weightController.text) ?? 0.0;
      setState(() {
        _estimatedYield = weight * _selectedType!.dressingPercentage;
      });
    } else {
      setState(() {
        _estimatedYield = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Record New Animal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20, color: AppColors.textLight),
                          onPressed: _generateSmartID,
                          tooltip: 'Regenerate ID',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.l),
                    _buildResponsiveRow(
                      isMobile,
                      [
                        TextFormField(
                          controller: _idController,
                          decoration: const InputDecoration(
                            labelText: 'Animal ID', 
                            border: OutlineInputBorder(),
                            helperText: 'Auto-generated unique identifier',
                          ),
                          validator: (v) => v!.isEmpty ? 'ID required' : null,
                        ),
                        TextFormField(
                          controller: _sourceController,
                          decoration: const InputDecoration(
                            labelText: 'Source/Farm', 
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                          validator: (v) => v!.isEmpty ? 'Farm source required' : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.m),
                    _buildResponsiveRow(
                      isMobile,
                      [
                        DropdownButtonFormField<AnimalType>(
                          value: _selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Animal Type',
                            border: OutlineInputBorder(),
                          ),
                          items: AnimalType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type.displayName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedType = value;
                              _generateSmartID();
                              _calculateYield();
                            });
                          },
                          validator: (v) => v == null ? 'Select type' : null,
                        ),
                        TextFormField(
                          controller: _weightController,
                          decoration: const InputDecoration(
                            labelText: 'Live Weight (kg)', 
                            border: OutlineInputBorder(),
                            suffixText: 'kg',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _calculateYield(),
                          validator: (v) {
                            if (v!.isEmpty) return 'Weight required';
                            if (double.tryParse(v) == null) return 'Invalid number';
                            return null;
                          },
                        ),
                      ],
                    ),
                    if (_estimatedYield > 0) ...[
                      const SizedBox(height: AppSpacing.l),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.s),
                          border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: AppColors.accentGreen, size: 20),
                            const SizedBox(width: AppSpacing.m),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Smart Prediction', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentGreen, fontSize: 12)),
                                Text(
                                  'Estimated Meat Yield: ${_estimatedYield.toStringAsFixed(2)} kg',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'Based on ${_selectedType!.displayName}\'s standard dressing percentage (${(_selectedType!.dressingPercentage * 100).toInt()}%).',
                                  style: const TextStyle(fontSize: 10, color: AppColors.textLight),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Animal Intake Recorded Successfully')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryMaroon,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                        ),
                        child: const Text('Confirm & Record Intake'),
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

  Widget _buildResponsiveRow(bool isMobile, List<Widget> children) {
    if (isMobile) {
      return Column(
        children: children.map((c) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.m), child: c)).toList(),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s), child: c))).toList(),
    );
  }
}
