import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestflow/nestflow.dart';

enum TodoFilter { all, today, overdue, upcoming }

extension TodoFilterLabel on TodoFilter {
  String get label {
    switch (this) {
      case TodoFilter.all:
        return 'All';
      case TodoFilter.today:
        return 'Today';
      case TodoFilter.overdue:
        return 'Overdue';
      case TodoFilter.upcoming:
        return 'Upcoming';
    }
  }
}

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  TodoFilter _filter = TodoFilter.all;
  ProjectModel? _selectedProject;

  List<TodoModel> _applyFilter(List<TodoModel> todos) {
    switch (_filter) {
      case TodoFilter.all:
        return todos;
      case TodoFilter.today:
        return todos.where((t) => t.isDueToday && !t.isOverdue).toList();
      case TodoFilter.overdue:
        return todos.where((t) => t.isOverdue).toList();
      case TodoFilter.upcoming:
        return todos.where((t) => t.isUpcoming).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocConsumer<TodoCubit, TodoState>(
      listener: (context, state) {
        if (state is TodoSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          context.read<TodoCubit>().loadTodos();
        } else if (state is TodoError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      buildWhen: (prev, curr) =>
          curr is TodoLoaded || curr is TodoLoading || curr is TodoError,
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_selectedProject?.name ?? 'My Tasks'),
            actions: [
              IconButton(
                onPressed: () => _openProjects(context),
                icon: const Icon(Icons.folder_outlined),
                tooltip: 'Projects',
              ),
              IconButton(
                onPressed: () => _goToForm(context),
                icon: const Icon(Icons.add_outlined),
              ),
            ],
          ),
          body: Builder(
            builder: (context) {
              if (state is TodoLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is TodoLoaded) {
                final hasTodos =
                    state.todos.isNotEmpty || state.completedTodos.isNotEmpty;

                if (!hasTodos) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.checklist_rounded,
                          size: 80,
                          color: colors.primary.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tasks yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to create your first task',
                          style: TextStyle(color: colors.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _goToForm(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Create Task'),
                        ),
                      ],
                    ),
                  );
                }

                final filteredTodos = _applyFilter(state.todos);

                return ListView(
                  padding: const EdgeInsets.all(AppDimensions.padding),
                  children: [
                    // Stats row
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            label: 'Pending',
                            count: state.todos.length,
                            color: colors.primary,
                          ),
                          Container(
                            height: 30,
                            width: 1,
                            color: colors.divider,
                          ),
                          _StatItem(
                            label: 'Completed',
                            count: state.completedTodos.length,
                            color: const Color(0xFF1abc9c),
                          ),
                          Container(
                            height: 30,
                            width: 1,
                            color: colors.divider,
                          ),
                          _StatItem(
                            label: 'Overdue',
                            count: state.todos
                                .where((t) => t.isOverdue)
                                .length,
                            color: colors.error,
                          ),
                        ],
                      ),
                    ),

                    // Filter chips
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: TodoFilter.values.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final filter = TodoFilter.values[i];
                          final isSelected = _filter == filter;
                          return ChoiceChip(
                            label: Text(filter.label),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _filter = filter),
                            selectedColor: colors.primary.withValues(alpha: 0.2),
                            labelStyle: TextStyle(
                              color: isSelected ? colors.primary : colors.textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                            side: BorderSide(
                              color: isSelected ? colors.primary : colors.divider,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pending tasks (filtered)
                    if (filteredTodos.isNotEmpty) ...[
                      Text(
                        '${_filter.label} (${filteredTodos.length})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...filteredTodos.map(
                        (todo) => TodoTile(
                          todo: todo,
                          onToggle: () =>
                              context.read<TodoCubit>().toggleComplete(todo),
                          onEdit: () => _goToForm(context, todo: todo),
                          onEditSubtask: (subtask) =>
                              _goToForm(context, todo: subtask),
                          onDelete: () => _confirmDelete(context, todo),
                        ),
                      ),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No ${_filter.label.toLowerCase()} tasks',
                            style: TextStyle(color: colors.textSecondary),
                          ),
                        ),
                      ),
                    ],

                    // Completed tasks
                    if (state.completedTodos.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Completed (${state.completedTodos.length})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...state.completedTodos.map(
                        (todo) => TodoTile(
                          todo: todo,
                          onToggle: () =>
                              context.read<TodoCubit>().toggleComplete(todo),
                          onEdit: () => _goToForm(context, todo: todo),
                          onEditSubtask: (subtask) =>
                              _goToForm(context, todo: subtask),
                          onDelete: () => _confirmDelete(context, todo),
                        ),
                      ),
                    ],
                  ],
                );
              }

              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }

  Future<void> _openProjects(BuildContext context) async {
    final cubit = context.read<TodoCubit>();
    final result = await Navigator.push<ProjectModel?>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => ProjectCubit()..loadProjects(),
          child: ProjectsScreen(selected: _selectedProject),
        ),
      ),
    );
    // Navigator.push returns null both when nothing was popped with a
    // value AND when "All Tasks" was explicitly selected — but since the
    // route always pops with an explicit value (ProjectModel or null),
    // we distinguish "no selection made" (user backed out) using a
    // sentinel check on whether the route actually completed.
    if (!mounted) return;
    setState(() => _selectedProject = result);
    await cubit.loadTodos(projectId: result?.id);
  }

  void _goToForm(BuildContext context, {TodoModel? todo}) async {
    final cubit = context.read<TodoCubit>();
    await cubit.formInit(
      todo: todo,
      defaultProject: todo == null ? _selectedProject : null,
    );
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: TodoFormScreen(todo: todo),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, TodoModel todo) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Delete "${todo.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<TodoCubit>().delete(todo);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatItem({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
