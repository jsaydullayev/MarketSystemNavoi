import 'package:flutter/material.dart';

class ReturnQuantityDialog extends StatefulWidget {
  final String productName;
  final double maxQuantity; // ✅ DECIMAL

  const ReturnQuantityDialog({
    required this.productName,
    required this.maxQuantity,
  });

  @override
  State<ReturnQuantityDialog> createState() => ReturnQuantityDialogState();
}

class ReturnQuantityDialogState extends State<ReturnQuantityDialog> {
  late TextEditingController _quantityController;
  double _returnQuantity = 1.0; // ✅ DECIMAL
  bool _isValid = true;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Mahsulotni qaytarish: ${widget.productName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Mavjud: ${widget.maxQuantity}'), // ✅ "ta" olib tashlandi
          const SizedBox(height: 16),
          TextField(
            controller: _quantityController,
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true), // ✅ DECIMAL
            decoration: InputDecoration(
              labelText: 'Qaytarish miqdori',
              border: const OutlineInputBorder(),
              errorText: _isValid ? null : 'Iltimos, to\'g\'ri miqdor kiriting',
              // suffixText: 'ta',  // ✅ Unit nomi backenddan keladi
            ),
            onChanged: (value) {
              setState(() {
                _returnQuantity = double.tryParse(value) ?? 0.0; // ✅ DECIMAL
                _isValid = _returnQuantity > 0 &&
                    _returnQuantity <= widget.maxQuantity;
              });
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Maksimal: ${widget.maxQuantity}', // ✅ "ta" olib tashlandi
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Bekor qilish'),
        ),
        ElevatedButton(
          onPressed:
              _isValid ? () => Navigator.pop(context, _returnQuantity) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Qaytarish'),
        ),
      ],
    );
  }
}
