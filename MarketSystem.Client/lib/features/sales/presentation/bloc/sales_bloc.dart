// Sales BLoC
// Sales state management

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/add_payment_usecase.dart';
import '../../domain/usecases/add_sale_item_usecase.dart';
import '../../domain/usecases/cancel_sale_usecase.dart';
import '../../domain/usecases/create_sale_usecase.dart';
import '../../domain/usecases/delete_sale_usecase.dart';
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
  final DeleteSaleUseCase deleteSaleUseCase;
  final GetSaleDetailUseCase getSaleDetailUseCase;
  final ReturnSaleItemUseCase returnSaleItemUseCase;

  SalesBloc({
    required this.getSalesUseCase,
    required this.getMyDraftSalesUseCase,
    required this.createSaleUseCase,
    required this.addSaleItemUseCase,
    required this.addPaymentUseCase,
    required this.cancelSaleUseCase,
    required this.deleteSaleUseCase,
    required this.getSaleDetailUseCase,
    required this.returnSaleItemUseCase,
  }) : super(const SalesInitial()) {
    on<GetSalesEvent>(_onGetSales);
    on<LoadMoreSalesEvent>(_onLoadMoreSales);
    on<GetMyDraftSalesEvent>(_onGetMyDraftSales);
    on<CreateSaleEvent>(_onCreateSale);
    on<AddSaleItemEvent>(_onAddSaleItem);
    on<AddPaymentEvent>(_onAddPayment);
    on<CancelSaleEvent>(_onCancelSale);
    on<DeleteSaleEvent>(_onDeleteSale);
    on<GetSaleDetailEvent>(_onGetSaleDetail);
    on<ReturnSaleItemEvent>(_onReturnSaleItem);
  }

  /// Get sales — resets to page 1
  Future<void> _onGetSales(
    GetSalesEvent event,
    Emitter<SalesState> emit,
  ) async {
    emit(const SalesLoading());
    final result = await getSalesUseCase.paged(page: 1);
    if (result.data case final page? when result.isSuccess) {
      emit(SalesLoaded(page.items, hasMore: page.hasMore, currentPage: 1));
    } else {
      emit(SalesError(result.error ?? 'Sotuvlarni yuklashda xatolik'));
    }
  }

  /// Load next page — appends to existing list
  Future<void> _onLoadMoreSales(
    LoadMoreSalesEvent event,
    Emitter<SalesState> emit,
  ) async {
    final current = state;
    if (current is! SalesLoaded || !current.hasMore) return;

    final nextPage = current.currentPage + 1;
    emit(SalesLoadingMore(current.sales, currentPage: current.currentPage));

    final result = await getSalesUseCase.paged(page: nextPage);
    if (result.data case final page? when result.isSuccess) {
      emit(SalesLoaded(
        [...current.sales, ...page.items],
        hasMore: page.hasMore,
        currentPage: nextPage,
      ));
    } else {
      // Restore previous loaded state on failure
      emit(SalesLoaded(
        current.sales,
        hasMore: current.hasMore,
        currentPage: current.currentPage,
      ));
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

    if (result.data case final data? when result.isSuccess) {
      emit(MyDraftSalesLoaded(data));
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

    if (result.data case final data? when result.isSuccess) {
      emit(SaleCreated(data));
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
      final listResult = await getSalesUseCase.paged(page: 1);
      if (listResult.data case final page? when listResult.isSuccess) {
        emit(SalesLoaded(page.items, hasMore: page.hasMore, currentPage: 1));
      } else {
        emit(const PaymentAdded());
      }
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
    final result = await cancelSaleUseCase(saleId: event.saleId);

    if (result.isSuccess) {
      emit(const SaleCancelled());
    } else {
      emit(SalesError(result.error ?? 'Sotuvni bekor qilishda xatolik'));
    }
  }

  /// Delete sale (Owner data-cleanup)
  Future<void> _onDeleteSale(
    DeleteSaleEvent event,
    Emitter<SalesState> emit,
  ) async {
    emit(const SalesLoading());
    final result = await deleteSaleUseCase(saleId: event.saleId);

    if (result.isSuccess) {
      emit(const SaleDeleted());
    } else {
      emit(SalesError(result.error ?? 'Sotuvni o\'chirishda xatolik'));
    }
  }

  /// Get sale detail
  Future<void> _onGetSaleDetail(
    GetSaleDetailEvent event,
    Emitter<SalesState> emit,
  ) async {
    emit(const SaleDetailLoading());
    final result = await getSaleDetailUseCase(event.saleId);

    if (result.data case final data? when result.isSuccess) {
      emit(SaleDetailLoaded(data));
    } else {
      emit(SalesError(result.error ?? 'Sotuvni yuklashda xatolik'));
    }
  }

  /// Return sale item
  Future<void> _onReturnSaleItem(
    ReturnSaleItemEvent event,
    Emitter<SalesState> emit,
  ) async {
    emit(const SalesLoading());
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
