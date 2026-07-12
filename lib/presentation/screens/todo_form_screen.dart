import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestflow/nestflow.dart';
import 'package:intl/intl.dart';

const _recurrenceLabels = <String, String>{
  'DAILY': 'Daily',
  'WEEKLY': 'Weekly',
  'MONTHLY': 'Monthly',
  'YEARLY': 'Yearly',
};

class TodoFormScreen extends StatefulWidget {
  final TodoModel? todo;
  const TodoFormScreen({super.key, this.todo});

  @override
  State<TodoFormScreen> createState() => _TodoFormScreenState();
}

class _TodoFormScreenState extends State<TodoFormScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.todo != null) {
      _titleController.text = widget.todo!.title;
      _descriptionController.text = widget.todo!.description ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocConsumer<TodoCubit, TodoState>(
      listener: (context, state) {
        if (state is TodoSuccess) {
          Navigator.pop(context);
        } else if (state is TodoError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final form = state is TodoFormInitial ? state : null;

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.todo == null ? 'New Task' : 'Edit Task'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Task Title *',
                    errorText: form?.errors['title'],
                    prefixIcon: const Icon(Icons.task_alt_outlined),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 20),

                // Description
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    prefixIcon: Icon(Icons.notes_outlined),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 24),

                // Priority
                Text(
                  'Priority',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: TodoPriority.values.map((p) {
                    final isSelected = form?.priority == p;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => context.read<TodoCubit>().setData(priority: p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? p.color.withValues(alpha: 0.15)
                                : colors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? p.color : colors.divider,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(p.icon, color: p.color, size: 20),
                              const SizedBox(height: 4),
                              Text(
                                p.label(context),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected ? p.color : colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Project
                Text(
                  'Project',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _pickProject(context, form),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.divider),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.folder_outlined,
                          color: colors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            form?.project?.name ?? 'No project (Inbox)',
                            style: TextStyle(
                              color: form?.project != null
                                  ? colors.textPrimary
                                  : colors.textPlaceholder,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (form?.project != null)
                          GestureDetector(
                            onTap: () => context
                                .read<TodoCubit>()
                                .setData(clearProject: true),
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: colors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Labels
                Text(
                  'Labels',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _pickLabels(context, form),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.divider),
                    ),
                    child: (form?.labels.isEmpty ?? true)
                        ? Row(
                            children: [
                              Icon(Icons.label_outline,
                                  color: colors.primary, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                'Add labels (optional)',
                                style: TextStyle(
                                  color: colors.textPlaceholder,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: form!.labels.map((label) {
                              final color = Color(int.parse(
                                  'FF' + label.color.replaceFirst('#', ''),
                                  radix: 16));
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  label.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Due Date
                Text(
                  'Due Date',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _pickDate(context, form),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.divider),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          color: colors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.access_time_outlined,
                          color: colors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            form?.dueDate != null
                                ? DateFormat('EEEE, MMM d yyyy')
                                    .format(form!.dueDate!)
                                : 'Select due date (optional)',
                            style: TextStyle(
                              color: form?.dueDate != null
                                  ? colors.textPrimary
                                  : colors.textPlaceholder,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (form?.dueDate != null)
                          GestureDetector(
                            onTap: () => context
                                .read<TodoCubit>()
                                .setData(clearDueDate: true),
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: colors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Repeat
                Text(
                  'Repeat',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _pickRecurrence(context, form),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.divider),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.repeat,
                          color: colors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            form?.recurrenceRule != null
                                ? (_recurrenceLabels[form!.recurrenceRule] ??
                                    'Repeats')
                                : 'Does not repeat',
                            style: TextStyle(
                              color: form?.recurrenceRule != null
                                  ? colors.textPrimary
                                  : colors.textPlaceholder,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (form?.recurrenceRule != null)
                          GestureDetector(
                            onTap: () => context
                                .read<TodoCubit>()
                                .setData(clearRecurrenceRule: true),
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: colors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: form?.processing == true
                        ? null
                        : () => _submit(context),
                    child: form?.processing == true
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.todo == null ? 'Create Task' : 'Update Task',
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickRecurrence(BuildContext context, TodoFormInitial? form) async {
    final cubit = context.read<TodoCubit>();
    const options = <String, String>{
      'NONE': 'Does not repeat',
      'DAILY': 'Daily',
      'WEEKLY': 'Weekly',
      'MONTHLY': 'Monthly',
      'YEARLY': 'Yearly',
    };
    final current = form?.recurrenceRule ?? 'NONE';
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.entries.map((entry) {
            final isSelected = current == entry.key;
            return ListTile(
              leading: Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: Text(entry.value),
              onTap: () => Navigator.pop(sheetContext, entry.key),
            );
          }).toList(),
        ),
      ),
    );
    if (!context.mounted || selected == null) return;
    if (selected == 'NONE') {
      cubit.setData(clearRecurrenceRule: true);
    } else {
      cubit.setData(recurrenceRule: selected);
    }
  }

  Future<void> _pickLabels(BuildContext context, TodoFormInitial? form) async {
    final cubit = context.read<TodoCubit>();
    final result = await Navigator.push<List<LabelModel>?>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => LabelCubit()..loadLabels(),
          child: LabelsScreen(selected: form?.labels ?? const []),
        ),
      ),
    );
    if (!context.mounted || result == null) return;
    cubit.setData(labels: result);
  }

  Future<void> _pickProject(BuildContext context, TodoFormInitial? form) async {
    final cubit = context.read<TodoCubit>();
    final result = await Navigator.push<ProjectModel?>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => ProjectCubit()..loadProjects(),
          child: ProjectsScreen(selected: form?.project),
        ),
      ),
    );
    if (!context.mounted) return;
    cubit.setData(project: result, clearProject: result == null);
  }

  Future<void> _pickDate(BuildContext context, TodoFormInitial? form) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: form?.dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (pickedDate == null || !context.mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: form?.dueDate != null
          ? TimeOfDay.fromDateTime(form!.dueDate!)
          : TimeOfDay.now(),
    );
    if (!context.mounted) return;

    final finalDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime?.hour ?? 0,
      pickedTime?.minute ?? 0,
    );
    context.read<TodoCubit>().setData(dueDate: finalDateTime);
  }

  void _submit(BuildContext context) {
    context.read<TodoCubit>().submit(
          existing: widget.todo,
          title: _titleController.text,
          description: _descriptionController.text,
        );
  }
}
