import 'package:drift/drift.dart';
import 'package:nestflow/nestflow.dart';

part 'project_dao.g.dart';

@DriftAccessor(tables: [Projects])
class ProjectDao extends DatabaseAccessor<AppDatabase> with _$ProjectDaoMixin {
  ProjectDao(super.db);

  Future<List<Project>> findAllOrdered() {
    return (select(projects)
          ..orderBy([(p) => OrderingTerm(expression: p.sortOrder)]))
        .get();
  }

  Future<Project?> findById(int id) {
    return (select(projects)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertProject(ProjectsCompanion project) =>
      into(projects).insert(project);

  Future<bool> updateProject(ProjectsCompanion project) =>
      update(projects).replace(project);

  Future<int> deleteProject(int id) =>
      (delete(projects)..where((p) => p.id.equals(id))).go();
}
