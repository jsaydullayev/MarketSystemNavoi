/// Zakup BLoC
/// Zakup state management

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_zakup_usecase.dart';
import '../../domain/usecases/get_zakups_by_date_range_usecase.dart';
import '../../domain/usecases/get_zakups_usecase.dart';
import 'events/zakup_event.dart';
import 'states/zakup_state.dart';

/// Zakup BLoC
class ZakupBloc extends Bloc<ZakupEvent, ZakupState> {
  final GetZakupsUseCase getZakupsUseCase;
  final GetZakupsByDateRangeUseCase getZakupsByDateRangeUseCase;
  final CreateZakupUseCase createZakupUseCase;

  ZakupBloc({
    required this.getZakupsUseCase,
    required this.getZakupsByDateRangeUseCase,
    required this.createZakupUseCase,
  }) : super(const ZakupInitial()) {
    on<GetZakupsEvent>(_onGetZakups);
    on<GetZakupsByDateRangeEvent>(_onGetZakupsByDateRange);
    on<CreateZakupEvent>(_onCreateZakup);
  }

  /// Get all zakups
  Future<void> _onGetZakups(
    GetZakupsEvent event,
    Emitter<ZakupState> emit,
  ) async {
    emit(const ZakupLoading());
    final result = await getZakupsUseCase();

    if (result.isSuccess && result.data != null) {
      emit(ZakupLoaded(result.data!));
    } else {
      emit(ZakupError(result.error ?? 'Xaridlarni yuklashda xatolik'));
    }
  }

  /// Get zakups by date range
  Future<void> _onGetZakupsByDateRange(
    GetZakupsByDateRangeEvent event,
    Emitter<ZakupState> emit,
  ) async {
    emit(const ZakupLoading());
    final result = await getZakupsByDateRangeUseCase(
      event.start,
      event.end,
    );

    if (result.isSuccess && result.data != null) {
      emit(ZakupLoaded(result.data!));
    } else {
      emit(ZakupError(result.error ?? 'Sana bo\'yicha xaridlarni yuklashda xatolik'));
    }
  }

  /// Create zakup
  Future<void> _onCreateZakup(
    CreateZakupEvent event,
    Emitter<ZakupState> emit,
  ) async {
    emit(const ZakupLoading());
    final result = await createZakupUseCase(
      productId: event.productId,
      quantity: event.quantity,
      costPrice: event.costPrice,
    );

    if (result.isSuccess && result.data != null) {
      emit(ZakupCreated(result.data!));
    } else {
      emit(ZakupError(result.error ?? 'Xarid yaratishda xatolik'));
    }
  }
}
