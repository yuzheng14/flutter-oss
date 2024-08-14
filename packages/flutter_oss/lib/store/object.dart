import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_oss/api.dart';
import 'package:flutter_oss/model/list_entry.dart';

// Reference: https://pub.dev/packages/equatable https://bloclibrary.dev/ https://pub.dev/packages/flutter_bloc

// State
abstract class ObjectState extends Equatable {
  @override
  List<Object> get props => [];
}

class ObjectLoading extends ObjectState {}

class ObjectLoaded extends ObjectState {
  final List<ListEntry> objects;
  ObjectLoaded(this.objects);

  @override
  List<Object> get props => [objects];
}

class ObjectError extends ObjectState {}

// Event
abstract class ObjectEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class FetchObjects extends ObjectEvent {}

// Bloc
class ObjectBloc extends Bloc<ObjectEvent, ObjectState> {
  final ApiService apiService;

  ObjectBloc({required this.apiService}) : super(ObjectLoading()) {
    on<FetchObjects>((event, emit) async {
      emit(ObjectLoading());
      try {
        final objects = await apiService.fetchObjects();
        emit(ObjectLoaded(objects));
      } catch (e) {
        emit(ObjectError());
      }
    });
  }
}
