/// Sales BLoC
/// Sales state management

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/sale_entity.dart';
import '../../domain/usecases/add_payment_usecase.dart';
import '../../domain/usecases/add_sale_item_usecase.dart';
import '../../domain/usecases/cancel_sale_usecase.dart';
import '../../domain/usecases/create_sale_usecase.dart';
import '../../domain/usecases/get_my_draft_sales_usecase.dart';
import '../../domain/usecases/get_sale_detail_usecase.dart';
import '../../domain/usecases/get_sales_usecase.dart';
import '../../domain/usecases/return_sale_item_usecase.dart';
import 'events/sales_event.dart';
import 'states/sales_state.dart';

/// Sales BLoC
class SalesBloc extends Bloc<SalesEvent, SalesState> {
  final GetSalesUseCase getSalesUseCase;
  final GetMyDraftSalesUseCase getMyDraftSalesUseCase;
  final CreateSaleUseCase createSaleUseCase;
  final AddSaleItemUseCase addSaleItemUseCase;
  final AddPaymentUseCase addPaymentUseCase;
  final CancelSaleUseCase cancelSaleUseCase;
  final GetSaleDetailUseCase getSaleDetailUseCase;
  final ReturnSaleItemUseCase returnSaleItemUseCase;

  SalesBloc({
    required this.getSalesUseCase,
    required this.getMyDraftSalesUseCase,
    required this.createSaleUseCase,
    required this.addSaleItemUseCase,
    required this.addPaymentUseCase,
    required this.cancelSaleUseCase,
    required this.getSaleDetailUseCase,
    required this.returnSaleItemUseCase,
  }) : super(const SalesInitial()) {
    on<GetSalesEvent>(_onGetSales);
    on<GetMyDraftSalesEvent>(_onGetMyDraftSales);
    on<CreateSaleEvent>(_onCreateSale);
    on<AddSaleItemEvent>(_onAddSaleItem);
    on<AddPaymentEvent>(_onAddPayment);
    on<CancelSaleEvent>(_onCancelSale);
    on<GetSaleDetailEvent>(_onGetSaleDetail);
    on<ReturnSaleItemEvent>(_onReturnSaleItem);
  }

  /// Get all sales
  Future<void> _onGetSales(
    GetSalesEvent event,
    Emitter<SalesState> emit,
  ) async {
    emit(const SalesLoading());
    final result = await getSalesUseCase();

    if (result.isSuccess && result.data != null) {
      emit(SalesLoaded(result.data!));
    } else {
      emit(SalesError(result.error ?? 'Sotuvlarni yuklashda xatolik'));
    }
  }

  /// Get my draft sales
  Future<void> _onGetMyDraftSales(
    GetMyDraftSalesEvent event,
    Emitter<SalesState> emit,
  ) async {
    emit(const SalesLoading());
    final result = await getMyDraftSalesUseCase();

    if (result.isSuccess && result.data != null) {
      emit(MyDraftSalesLoaded(result.data!));
    } else {
      emit(SalesError(result.error ?? 'Draft sotuvlarni yuklashda xatolik'));
    }
  }

  /// Create sale
  Future<void> _onCreateSale(
    CreateSaleEvent event,
    Emitter<SalesState> emit,
  ) async {
    emit(const SalesLoading());
    final result = await createSaleUseCase(customerId: event.customerId);

    if (result.isSuccess && result.data != null) {
      emit(SaleCreated(result.data!));
    } else {
      emit(SalesError(result.error ?? 'Sotuv yaratishda xatolik'));
    }
  }

  /// Add sale item
  Future<void> _onAddSaleItem(
    AddSaleItemEvent event,
    Emitter<SalesState> emit,
  ) async {
    emit(const SalesLoading());
    final result = await addSaleItemUseCase(
      saleId: event.saleId,
      productId: event.productId,
      quantity: event.quantity,
      salePrice: event.salePrice,
      minSalePrice: event.minSalePrice,
      comment: event.comment,
    );

    if (result.isSuccess) {
      emit(const SaleItemAdded());
    } else {
      emit(SalesError(result.error ?? 'Mahsulot qo\'shishda xatolik'));
    }
  }

  /// Add payment
  Future<void> _onAddPayment(
    AddPaymentEvent event,
    Emitter<SalesState> emit,
  ) async {
    emit(const SalesLoading());
    final result = await addPaymentUseCase(
      saleId: event.saleId,
      paymentType: event.paymentType,
      amount: event.amount,
    );

    if (result.isSuccess) {
      emit(const PaymentAdded());
    } else {
      emit(SalesError(result.error ?? 'To\'lov qo\'shishda xatolik'));
    }
  }

  /// Cancel sale
  Future<void> _onCancelSale(
    CancelSaleEvent event,
    Emitter<SalesState> emit,
  ) async {
    emit(const SalesLoading());
    final result = await cancelSaleUseCase(
      saleId: event.saleId,
      adminId: event.adminId,
    );

    if (result.isSuccess) {
      emit(const SaleCancelled());
    } else {
      emit(SalesError(result.error ?? 'Sotuvni bekor qilishda xatolik'));
    }
  }

  /// Get sale detail
  Future<void> _onGetSaleDetail(
    GetSaleDetailEvent event,
    Emitter<SalesState> emit,
  ) async {
    emit(const SaleDetailLoading());
    final result = await getSaleDetailUseCase(event.saleId);

    if (result.isSuccess && result.data != null) {
      emit(SaleDetailLoaded(result.data!));
    } else {
      emit(SalesError(result.error ?? 'Sotuvni yuklashda xatolik'));
    }
  }

  /// Return sale item
  Future<void> _onReturnSaleItem(
    ReturnSaleItemEvent event,
    Emitter<SalesState> emit,
  ) async {
    final result = await returnSaleItemUseCase(
      saleId: event.saleId,
      saleItemId: event.saleItemId,
      quantity: event.quantity,
      comment: event.comment,
    );

    if (result.isSuccess) {
      emit(const SaleItemReturned());
    } else {
      emit(SalesError(result.error ?? 'Tovarni qaytarishda xatolik'));
    }
  }
}
