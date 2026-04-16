import 'package:flutter/material.dart';

class FeedbackScreen extends StatefulWidget {
  final String productId;
  final String productName;
  final Future<void> Function(String type, String message) onSubmit;

  const FeedbackScreen({
    super.key,
    required this.productId,
    required this.productName,
    required this.onSubmit,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _messageController = TextEditingController();
  String _selectedType = 'other';
  bool _isSubmitting = false;

  static const _feedbackTypes = {
    'allergen_missing': 'אלרגן חסר',
    'allergen_wrong': 'אלרגן שגוי',
    'product_info_wrong': 'מידע מוצר שגוי',
    'other': 'אחר',
  };

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(_selectedType, _messageController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('הדיווח נשלח בהצלחה')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('דווח בעיה')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.productName,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'סוג דיווח'),
                items: _feedbackTypes.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedType = val);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'תיאור הבעיה',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('שלח דיווח'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
