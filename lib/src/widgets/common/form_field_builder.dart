import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final numbersOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (numbersOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final number = int.parse(numbersOnly);
    final reais = number ~/ 100;
    final centavos = number % 100;

    final reaisFormatted = reais.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    
    final formattedText = 'R\$ $reaisFormatted,${centavos.toString().padLeft(2, '0')}';
    
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class CustomFormFields {
  static Widget buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String? hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    );
  }

  static Widget buildDropdownField(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged, {
    bool enabled = true,
    String? hintText,
  }) {
    final List<String> uniqueItems = [];
    for (final it in items) {
      if (!uniqueItems.contains(it)) uniqueItems.add(it);
    }
    final effectiveValue = (value.isEmpty ? null : (uniqueItems.contains(value) ? value : null));

    bool needsMultipleLines(String text) {
      return text.length > 35;
    }

    return DropdownButtonFormField<String>(
      initialValue: effectiveValue,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      items: uniqueItems.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              item,
              maxLines: null,
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
      isExpanded: true,
      menuMaxHeight: 300,
      dropdownColor: Colors.white,
      icon: const Icon(Icons.arrow_drop_down),
      iconEnabledColor: enabled ? Colors.grey[600] : Colors.grey[400],
      style: TextStyle(
        color: enabled ? Colors.black87 : Colors.grey[600],
        fontSize: 16,
      ),
      isDense: false,
      selectedItemBuilder: (BuildContext context) {
        return uniqueItems.map<Widget>((String item) {
          final bool isLongText = needsMultipleLines(item);
          
          return Container(
            constraints: BoxConstraints(
              minHeight: isLongText ? 56 : 24,
            ),
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(right: 32),
              child: Text(
                item,
                maxLines: isLongText ? 2 : 1,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: enabled ? Colors.black87 : Colors.grey[600],
                  fontSize: 16,
                  height: 1.3,
                ),
              ),
            ),
          );
        }).toList();
      },
    );
  }

  static Widget buildDropdownFieldFromMaps(
    String label,
    String? value,
    List<Map<String, dynamic>> items,
    Function(String?) onChanged, {
    bool enabled = true,
    String? hintText,
    required String Function(Map<String, dynamic>) getDisplayText,
    required String Function(Map<String, dynamic>) getValue,
  }) {
    bool needsMultipleLines(String text) {
      return text.length > 35;
    }

    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      items: items.map<DropdownMenuItem<String>>((item) {
        final displayText = getDisplayText(item);
        final itemValue = getValue(item);
        return DropdownMenuItem<String>(
          value: itemValue,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              displayText,
              maxLines: null,
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
      isExpanded: true,
      menuMaxHeight: 300,
      dropdownColor: Colors.white,
      icon: const Icon(Icons.arrow_drop_down),
      iconEnabledColor: enabled ? Colors.grey[600] : Colors.grey[400],
      style: TextStyle(
        color: enabled ? Colors.black87 : Colors.grey[600],
        fontSize: 16,
      ),
      isDense: false,
      selectedItemBuilder: (BuildContext context) {
        return items.map<Widget>((item) {
          final displayText = getDisplayText(item);
          final bool isLongText = needsMultipleLines(displayText);
          
          return Container(
            constraints: BoxConstraints(
              minHeight: isLongText ? 56 : 24,
            ),
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(right: 32),
              child: Text(
                displayText,
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: enabled ? Colors.black87 : Colors.grey[600],
                  fontSize: 16,
                  height: 1.3,
                ),
              ),
            ),
          );
        }).toList();
      },
    );
  }

  static Widget buildCurrencyField(
    String label,
    TextEditingController controller, {
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [CurrencyInputFormatter()],
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText ?? 'R\$ 0,00',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    );
  }

  static Widget buildDateField(
    String label,
    TextEditingController controller,
    BuildContext context,
    Function(DateTime) onDateSelected,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'dd/mm/aaaa',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 30)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              locale: const Locale('pt', 'BR'),
            );

            if (picked != null) {
              controller.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
              onDateSelected(picked);
            }
          },
        ),
      ),
      readOnly: true,
    );
  }
}
