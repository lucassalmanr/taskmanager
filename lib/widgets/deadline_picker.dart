import 'package:flutter/material.dart';

class DeadlinePicker extends StatelessWidget {
  final DateTime? deadline;
  final ValueChanged<DateTime?> onChanged;

  const DeadlinePicker({
    super.key,
    required this.deadline,
    required this.onChanged,
  });

  Future<void> _pickDeadline(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    final pickedDate = date;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Horário (opcional — toque em Cancel para pular)',
    );

    if (time != null) {
      onChanged(DateTime(pickedDate.year, pickedDate.month, pickedDate.day, time.hour, time.minute));
    } else {
      onChanged(DateTime(pickedDate.year, pickedDate.month, pickedDate.day, 23, 59));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pickDeadline(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 20, color: Colors.grey),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                deadline == null
                    ? 'Digite seu prazo'
                    : '${deadline!.day.toString().padLeft(2, '0')}/${deadline!.month.toString().padLeft(2, '0')}/${deadline!.year}  '
                        '${deadline!.hour.toString().padLeft(2, '0')}:${deadline!.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: deadline == null ? Colors.grey.shade600 : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
            if (deadline != null)
              GestureDetector(
                onTap: () => onChanged(null),
                child: const Icon(Icons.close, size: 18, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
