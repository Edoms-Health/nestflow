import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestflow/nestflow.dart';

abstract class ProjectState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProjectLoading extends ProjectState {}

class ProjectLoaded extends ProjectState {
  final List<ProjectModel> projects;
  ProjectLoaded(this.projects);

  @override
  List<Object?> get props => [projects];
}

class ProjectError extends ProjectState {
  final String message;
  ProjectError(this.message);

  @override
  List<Object?> get props => [message];
}

const _presetColors = [
  '#4A90D9',
  '#1abc9c',
  '#D32F2F',
  '#FFC107',
  '#8E24AA',
  '#546E7A',
];

class ProjectCubit extends Cubit<ProjectState> {
  final ProjectDao _dao = AppDatabase.instance.projectDao;

  ProjectCubit() : super(ProjectLoading());

  Future<void> loadProjects() async {
    try {
      final rows = await _dao.findAllOrdered();
      final projects = rows
          .map((r) => ProjectModel(
                id: r.id,
                name: r.name,
                color: r.color,
                sortOrder: r.sortOrder,
                createdAt: r.createdAt,
              ))
          .toList();
      emit(ProjectLoaded(projects));
    } catch (e) {
      emit(ProjectError('Failed to load projects'));
    }
  }

  Future<bool> createProject(String name, {String? color}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    try {
      final currentCount =
          state is ProjectLoaded ? (state as ProjectLoaded).projects.length : 0;
      await _dao.insertProject(
        ProjectsCompanion(
          name: Value(trimmed),
          color: Value(color ?? _presetColors[currentCount % _presetColors.length]),
          sortOrder: Value(currentCount),
        ),
      );
      await loadProjects();
      return true;
    } catch (e) {
      emit(ProjectError('Failed to create project'));
      return false;
    }
  }

  Future<bool> deleteProject(int id) async {
    try {
      await _dao.deleteProject(id);
      await loadProjects();
      return true;
    } catch (e) {
      emit(ProjectError('Failed to delete project'));
      return false;
    }
  }

  static List<String> get presetColors => _presetColors;
}
