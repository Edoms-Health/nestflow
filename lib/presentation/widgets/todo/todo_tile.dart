import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestflow/nestflow.dart';
import 'package:intl/intl.dart';

class TodoTile extends StatefulWidget {
  final TodoModel todo;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Called when the user wants to edit a sub-task rendered inside this
  /// tile (top-level tiles only; ignored when isSubtask is true).
  final void Function(TodoModel subtask)? onEditSubtask;

  final bool isSubtask;

  const TodoTile({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    this.onEditSubtask,
    this.isSubtask = false,
  });

  @override
  State<TodoTile> createState() => _TodoTileState();
}

class _TodoTileState extends State<TodoTile> {
  bool _expanded = false;
  bool _loadingSubtasks = false;
  List<TodoModel>? _subtasks;
  bool _showQuickAdd = false;
  final _quickAddController = TextEditingController();

  @override
  void dispose() {
    _quickAddController.dispose();
    super.dispose();
  }

  Future<void> _toggleExpanded() async {
    if (!_expanded && _subtasks == null) {
      setState(() => _loadingSubtasks = true);
      final subtasks = await context.read<TodoCubit>().fetchSubtasks(widget.todo.id);
      if (!mounted) return;
      setState(() {
        _subtasks = subtasks;
        _loadingSubtasks = false;
      });
    }
    if (!mounted) return;
    setState(() => _expanded = !_expanded);
  }

  Future<void> _refreshSubtasks() async {
    final subtasks = await context.read<TodoCubit>().fetchSubtasks(widget.todo.id);
    if (!mounted) return;
    setState(() => _subtasks = subtasks);
  }

  Future<void> _addSubtask() async {
    final title = _quickAddController.text;
    final ok = await context.read<TodoCubit>().createSubtask(
          parentId: widget.todo.id,
          title: title,
        );
    if (ok) {
      _quickAddController.clear();
      await _refreshSubtasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final todo = widget.todo;

    return Container(
      margin: EdgeInsets.only(
        bottom: widget.isSubtask ? 6 : 10,
        left: widget.isSubtask ? 28 : 0,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(widget.isSubtask ? 10 : 12),
        border: Border.all(
          color: todo.isOverdue
              ? colors.error.withValues(alpha: 0.5)
              : colors.divider,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: GestureDetector(
              onTap: widget.onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: widget.isSubtask ? 22 : 26,
                height: widget.isSubtask ? 22 : 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: todo.isCompleted ? colors.primary : Colors.transparent,
                  border: Border.all(
                    color: todo.isCompleted ? colors.primary : colors.textSecondary,
                    width: 2,
                  ),
                ),
                child: todo.isCompleted
                    ? Icon(Icons.check,
                        size: widget.isSubtask ? 13 : 16, color: Colors.white)
                    : null,
              ),
            ),
            title: Text(
              todo.title,
              style: TextStyle(
                fontSize: widget.isSubtask ? 14 : 15,
                fontWeight: FontWeight.w600,
                color: todo.isCompleted ? colors.textSecondary : colors.textPrimary,
                decoration:
                    todo.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (todo.description != null && todo.description!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    todo.description!,
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: todo.priority.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(todo.priority.icon, size: 12, color: todo.priority.color),
                          const SizedBox(width: 3),
                          Text(
                            todo.priority.shortLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: todo.priority.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (todo.dueDate != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: todo.isOverdue ? colors.error : colors.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        DateFormat('MMM d, yyyy  hh:mm a').format(todo.dueDate!),
                        style: TextStyle(
                          fontSize: 11,
                          color: todo.isOverdue ? colors.error : colors.textSecondary,
                          fontWeight: todo.isOverdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (todo.isOverdue) ...[
                        const SizedBox(width: 4),
                        Text(
                          'Overdue',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                    if (!widget.isSubtask && _subtasks != null && _subtasks!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.checklist_rtl_rounded, size: 12, color: colors.textSecondary),
                      const SizedBox(width: 2),
                      Text(
                        '${_subtasks!.where((s) => s.isCompleted).length}/${_subtasks!.length}',
                        style: TextStyle(fontSize: 11, color: colors.textSecondary),
                      ),
                    ],
                  ],
                ),
                if (todo.labels.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: todo.labels.map((label) {
                      final color = Color(int.parse(
                          'FF' + label.color.replaceFirst('#', ''),
                          radix: 16));
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 1),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          label.name,
                          style: TextStyle(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!widget.isSubtask)
                  _loadingSubtasks
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: Icon(
                            _expanded ? Icons.expand_less : Icons.expand_more,
                            color: colors.textSecondary,
                          ),
                          onPressed: _toggleExpanded,
                        ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: colors.textSecondary),
                  onSelected: (value) {
                    if (value == 'edit') widget.onEdit();
                    if (value == 'delete') widget.onDelete();
                    if (value == 'add_subtask') {
                      setState(() {
                        _expanded = true;
                        _showQuickAdd = true;
                      });
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    if (!widget.isSubtask)
                      const PopupMenuItem(
                        value: 'add_subtask',
                        child: Text('Add sub-task'),
                      ),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
          ),
          if (!widget.isSubtask && _expanded) ...[
            if (_subtasks != null)
              ..._subtasks!.map(
                (subtask) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TodoTile(
                    todo: subtask,
                    isSubtask: true,
                    onToggle: () async {
                      await context.read<TodoCubit>().toggleComplete(subtask);
                      await _refreshSubtasks();
                    },
                    onEdit: () => widget.onEditSubtask?.call(subtask),
                    onDelete: () async {
                      await context.read<TodoCubit>().delete(subtask);
                      await _refreshSubtasks();
                    },
                  ),
                ),
              ),
            if (_showQuickAdd)
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _quickAddController,
                        autofocus: true,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          isDense: true,
                          hintText: 'Add sub-task',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _addSubtask(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: _addSubtask,
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
