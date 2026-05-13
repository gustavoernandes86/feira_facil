import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feira_facil/core/theme/app_colors.dart';
import 'package:feira_facil/features/lists/domain/fair_list.dart';
import 'package:feira_facil/core/theme/theme_ext.dart';

class MarketListSelector extends ConsumerWidget {
  final List<FairList> lists;
  final FairList? selectedList;
  final ValueChanged<FairList?> onListSelected;

  const MarketListSelector({
    super.key,
    required this.lists,
    required this.selectedList,
    required this.onListSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (lists.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Nenhuma lista encontrada. Crie uma para começar a registrar preços.',
          style: TextStyle(color: context.colorTextSecondary),
        ),
      );
    }

    // Find selected from current list by ID to avoid stale reference issues
    final currentSelected = selectedList != null
        ? lists.cast<FairList?>().firstWhere(
              (l) => l?.id == selectedList!.id,
              orElse: () => null,
            )
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: context.colorCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colorBorder),
        boxShadow: context.shadow1,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentSelected?.id,
          hint: Text('Selecione uma lista...'),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: context.colorOrange),
          items: lists.map((list) {
            return DropdownMenuItem<String>(
              value: list.id,
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: list.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      list.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (selectedId) {
            if (selectedId == null) return;
            final selected = lists.firstWhere((l) => l.id == selectedId);
            onListSelected(selected);
          },
        ),
      ),
    );
  }
}
