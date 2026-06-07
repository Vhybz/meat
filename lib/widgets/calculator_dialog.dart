import 'package:flutter/material.dart';
import '../core/constants.dart';

class CalculatorDialog extends StatefulWidget {
  const CalculatorDialog({super.key});

  @override
  State<CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  String _output = "0";
  String _expression = "";
  String _currentNumber = "";
  double _num1 = 0;
  String _operand = "";

  void _buttonPressed(String buttonText) {
    setState(() {
      if (buttonText == "CLEAR") {
        _output = "0";
        _expression = "";
        _currentNumber = "";
        _num1 = 0;
        _operand = "";
      } else if (buttonText == "+" || buttonText == "-" || buttonText == "/" || buttonText == "x") {
        if (_currentNumber.isNotEmpty || _output != "0") {
          _num1 = double.parse(_output);
          _operand = buttonText;
          _expression = "${_formatValue(_num1)} $buttonText ";
          _output = "0";
          _currentNumber = "";
        }
      } else if (buttonText == "=") {
        if (_operand.isNotEmpty && _currentNumber.isNotEmpty) {
          double num2 = double.parse(_currentNumber);
          double result = 0;
          if (_operand == "+") result = _num1 + num2;
          if (_operand == "-") result = _num1 - num2;
          if (_operand == "x") result = _num1 * num2;
          if (_operand == "/") result = _num1 / num2;

          _expression = "$_expression$num2 =";
          _output = _formatValue(result);
          _num1 = result;
          _operand = "";
          _currentNumber = "";
        }
      } else {
        // Numbers, 00, and decimal
        if (buttonText == "." && _currentNumber.contains(".")) return;
        
        _currentNumber += buttonText;
        _output = _currentNumber;
      }
    });
  }

  String _formatValue(double v) {
    String s = v.toString();
    if (s.endsWith(".0")) return s.substring(0, s.length - 2);
    if (s.length > 12) return s.substring(0, 12);
    return s;
  }

  Widget _buildButton(String buttonText, {Color? color, Color? textColor}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            backgroundColor: color,
            side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
          ),
          onPressed: () => _buttonPressed(buttonText),
          child: Text(
            buttonText,
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: textColor ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.l)),
        ),
        child: const Row(
          children: [
            Icon(Icons.calculate_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text('Quick Calculator', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            constraints: const BoxConstraints(minHeight: 20),
            child: Text(
              _expression,
              style: TextStyle(fontSize: 16.0, color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Text(
              _output,
              style: const TextStyle(fontSize: 42.0, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),
          Column(
            children: [
              Row(children: [
                _buildButton("7"),
                _buildButton("8"),
                _buildButton("9"),
                _buildButton("/", color: theme.colorScheme.primary.withValues(alpha: 0.1), textColor: theme.colorScheme.primary),
              ]),
              Row(children: [
                _buildButton("4"),
                _buildButton("5"),
                _buildButton("6"),
                _buildButton("x", color: theme.colorScheme.primary.withValues(alpha: 0.1), textColor: theme.colorScheme.primary),
              ]),
              Row(children: [
                _buildButton("1"),
                _buildButton("2"),
                _buildButton("3"),
                _buildButton("-", color: theme.colorScheme.primary.withValues(alpha: 0.1), textColor: theme.colorScheme.primary),
              ]),
              Row(children: [
                _buildButton("."),
                _buildButton("0"),
                _buildButton("00"),
                _buildButton("+", color: theme.colorScheme.primary.withValues(alpha: 0.1), textColor: theme.colorScheme.primary),
              ]),
              Row(children: [
                _buildButton("CLEAR", color: Colors.red.withValues(alpha: 0.1), textColor: Colors.red),
                _buildButton("=", color: theme.colorScheme.primary, textColor: Colors.white),
              ]),
            ],
          )
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("CLOSE"),
        )
      ],
    );
  }
}
