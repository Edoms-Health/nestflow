import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestflow/nestflow.dart';

abstract class LabelState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LabelLoading extends LabelState {}

class LabelLoaded extends LabelState {
  final List<LabelModel> labels;
  LabelLoaded(this.labels);

  @override
  List<Object?> get props => [labels];
}

class LabelError extends LabelState {
  final String message;
  LabelError(this.message);

  @override
  List<Object?> get props => [message];
}

const _presetLabelColors = [
  '#95A5A6',
  '#E67E22',
  '#3498DB',
  '#2ECC71',
  '#9B59B6',
  '#E74C3C',
];

class LabelCubit extends Cubit<LabelState> {
  final LabelDao _dao = AppDatabase.instance.labelDao;

  LabelCubit() : super(LabelLoading());

  Future<void> loadLabels() async {
    try {
      final rows = await _dao.findAll();
      final labels = rows
          .map((r) => LabelModel(id: r.id, name: r.name, color: r.color))
          .toList();
      emit(LabelLoaded(labels));
    } catch (e) {
      emit(LabelError('Failed to load labels'));
    }
  }

  Future<bool> createLabel(String name, {String? color}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    try {
      final currentCount =
          state is LabelLoaded ? (state as LabelLoaded).labels.length : 0;
      await _dao.insertLabel(
        LabelsCompanion(
          name: Value(trimmed),
          color: Value(
              color ?? _presetLabelColors[currentCount % _presetLabelColors.length]),
        ),
      );
      await loadLabels();
      return true;
    } catch (e) {
      emit(LabelError('Failed to create label'));
      return false;
    }
  }

  Future<bool> deleteLabel(int id) async {
    try {
      await _dao.deleteLabel(id);
      await loadLabels();
      return true;
    } catch (e) {
      emit(LabelError('Failed to delete label'));
      return false;
    }
  }
}
