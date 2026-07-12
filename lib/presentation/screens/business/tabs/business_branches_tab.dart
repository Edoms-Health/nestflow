import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestflow/nestflow.dart';

class BusinessBranchesTab extends StatelessWidget {
  final BusinessLoaded loaded;
  const BusinessBranchesTab({super.key, required this.loaded});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (loaded.branches.isEmpty) {
      return Center(
        child: Text('No branches yet — tap + to add one',
            style: TextStyle(color: colors.textSecondary)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: loaded.branches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final b = loaded.branches[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.storefront_outlined, color: colors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(b.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (b.isMain) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Main', style: TextStyle(fontSize: 11, color: colors.primary)),
                        ),
                      ],
                    ]),
                    if (b.location != null)
                      Text(b.location!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                    if (b.phone != null || b.email != null)
                      Text(
                        [if (b.phone != null) b.phone, if (b.email != null) b.email].join('  •  '),
                        style: TextStyle(color: colors.textSecondary, fontSize: 12),
                      ),
                    if (b.managerName != null)
                      Text('Manager: ${b.managerName}',
                          style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<BusinessCubit>(),
                        child: BranchFormScreen(loaded: loaded, branch: b),
                      ),
                    ));
                  } else if (v == 'delete') {
                    context.read<BusinessCubit>().deleteBranch(b.id);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
