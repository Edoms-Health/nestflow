import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestflow/nestflow.dart';

/// Simple project picker/manager. Pushed on top of TodoScreen with the
/// TodoCubit's own ProjectCubit provided fresh (projects don't need to
/// persist state across the tab like TodoCubit does).
///
/// Pops with a ProjectModel? — null means "All / Inbox" was selected.
class ProjectsScreen extends StatelessWidget {
  final ProjectModel? selected;

  const ProjectsScreen({super.key, this.selected});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocConsumer<ProjectCubit, ProjectState>(
      listener: (context, state) {
        if (state is ProjectError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Projects'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showCreateDialog(context),
              ),
            ],
          ),
          body: state is ProjectLoading
              ? const Center(child: CircularProgressIndicator())
              : state is ProjectLoaded
                  ? ListView(
                      padding: const EdgeInsets.all(AppDimensions.padding),
                      children: [
                        _ProjectTile(
                          name: 'All Tasks',
                          color: colors.textSecondary,
                          isSelected: selected == null,
                          icon: Icons.inbox_outlined,
                          onTap: () => Navigator.pop(context, null),
                        ),
                        const SizedBox(height: 8),
                        ...state.projects.map(
                          (project) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ProjectTile(
                              name: project.name,
                              color: _colorFromHex(project.color),
                              isSelected: selected?.id == project.id,
                              icon: Icons.folder_outlined,
                              onTap: () => Navigator.pop(context, project),
                              onDelete: () =>
                                  _confirmDelete(context, project),
                            ),
                          ),
                        ),
                        if (state.projects.isEmpty) ...[
                          const SizedBox(height: 40),
                          Center(
                            child: Text(
                              'No projects yet — tap + to create one',
                              style: TextStyle(color: colors.textSecondary),
                            ),
                          ),
                        ],
                      ],
                    )
                  : const SizedBox.shrink(),
        );
      },
    );
  }

  void _showCreateDialog(BuildContext context) {
    final controller = TextEditingController();
    final cubit = context.read<ProjectCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Project'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Project name'),
          onSubmitted: (_) async {
            await cubit.createProject(controller.text);
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
              await cubit.createProject(controller.text);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ProjectModel project) {
    final cubit = context.read<ProjectCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text(
          'Delete "${project.name}"? Tasks inside it will move to All Tasks.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await cubit.deleteProject(project.id);
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

  Color _colorFromHex(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }
}

class _ProjectTile extends StatelessWidget {
  final String name;
  final Color color;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _ProjectTile({
    required this.name,
    required this.color,
    required this.isSelected,
    required this.icon,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: isSelected ? color.withValues(alpha: 0.1) : colors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : colors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      size: 18, color: colors.textSecondary),
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
