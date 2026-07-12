import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestflow/nestflow.dart';

/// Multi-select label picker. Pops with the final List<LabelModel>
/// selection when the user taps Done, or null if they back out without
/// confirming (caller should treat null as "no change").
class LabelsScreen extends StatefulWidget {
  final List<LabelModel> selected;

  const LabelsScreen({super.key, this.selected = const []});

  @override
  State<LabelsScreen> createState() => _LabelsScreenState();
}

class _LabelsScreenState extends State<LabelsScreen> {
  late Set<int> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.selected.map((l) => l.id).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocConsumer<LabelCubit, LabelState>(
      listener: (context, state) {
        if (state is LabelError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final labels = state is LabelLoaded ? state.labels : <LabelModel>[];
        return Scaffold(
          appBar: AppBar(
            title: const Text('Labels'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showCreateDialog(context),
              ),
              TextButton(
                onPressed: () {
                  final selected =
                      labels.where((l) => _selectedIds.contains(l.id)).toList();
                  Navigator.pop(context, selected);
                },
                child: const Text('Done'),
              ),
            ],
          ),
          body: state is LabelLoading
              ? const Center(child: CircularProgressIndicator())
              : labels.isEmpty
                  ? Center(
                      child: Text(
                        'No labels yet — tap + to create one',
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(AppDimensions.padding),
                      children: labels.map((label) {
                        final isSelected = _selectedIds.contains(label.id);
                        final color = _colorFromHex(label.color);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color:
                                isSelected ? color.withValues(alpha: 0.1) : colors.surface,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => setState(() {
                                if (isSelected) {
                                  _selectedIds.remove(label.id);
                                } else {
                                  _selectedIds.add(label.id);
                                }
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? color : colors.divider,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.label_outline, color: color, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        label.name,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(Icons.check_circle, color: color, size: 20),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline,
                                          size: 18, color: colors.textSecondary),
                                      onPressed: () async {
                                        setState(() => _selectedIds.remove(label.id));
                                        await context
                                            .read<LabelCubit>()
                                            .deleteLabel(label.id);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
        );
      },
    );
  }

  void _showCreateDialog(BuildContext context) {
    final controller = TextEditingController();
    final cubit = context.read<LabelCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Label'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Label name'),
          onSubmitted: (_) async {
            await cubit.createLabel(controller.text);
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await cubit.createLabel(controller.text);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Color _colorFromHex(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }
}
