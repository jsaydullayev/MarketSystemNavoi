import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_system_client/core/failure/api_result.dart';
import 'package:market_system_client/features/sales/domain/entities/sale_entity.dart';
import 'package:market_system_client/features/sales/domain/usecases/add_payment_usecase.dart';
import 'package:market_system_client/features/sales/domain/usecases/add_sale_item_usecase.dart';
import 'package:market_system_client/features/sales/domain/usecases/cancel_sale_usecase.dart';
import 'package:market_system_client/features/sales/domain/usecases/create_sale_usecase.dart';
import 'package:market_system_client/features/sales/domain/usecases/get_my_draft_sales_usecase.dart';
import 'package:market_system_client/features/sales/domain/usecases/get_sale_detail_usecase.dart';
import 'package:market_system_client/features/sales/domain/usecases/get_sales_usecase.dart';
import 'package:market_system_client/features/sales/domain/usecases/return_sale_item_usecase.dart';
import 'package:market_system_client/features/sales/presentation/bloc/events/sales_event.dart';
import 'package:market_system_client/features/sales/presentation/bloc/sales_bloc.dart';
import 'package:market_system_client/features/sales/presentation/bloc/states/sales_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetSales extends Mock implements GetSalesUseCase {}
class _MockGetDrafts extends Mock implements GetMyDraftSalesUseCase {}
class _MockCreate extends Mock implements CreateSaleUseCase {}
class _MockAddItem extends Mock implements AddSaleItemUseCase {}
class _MockAddPayment extends Mock implements AddPaymentUseCase {}
class _MockCancel extends Mock implements CancelSaleUseCase {}
class _MockGetDetail extends Mock implements GetSaleDetailUseCase {}
class _MockReturnItem extends Mock implements ReturnSaleItemUseCase {}

void main() {
  late _MockGetSales getSales;
  late _MockGetDrafts getDrafts;
  late _MockCreate create;
  late _MockAddItem addItem;
  late _MockAddPayment addPayment;
  late _MockCancel cancel;
  late _MockGetDetail getDetail;
  late _MockReturnItem returnItem;

  SalesBloc buildBloc() => SalesBloc(
        getSalesUseCase: getSales,
        getMyDraftSalesUseCase: getDrafts,
        createSaleUseCase: create,
        addSaleItemUseCase: addItem,
        addPaymentUseCase: addPayment,
        cancelSaleUseCase: cancel,
        getSaleDetailUseCase: getDetail,
        returnSaleItemUseCase: returnItem,
      );

  final sample = SaleEntity(
    id: 's-1',
    sellerId: 'u-1',
    totalAmount: 100,
    paidAmount: 0,
    remainingAmount: 100,
    status: SaleStatus.draft,
    createdAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() {
    getSales = _MockGetSales();
    getDrafts = _MockGetDrafts();
    create = _MockCreate();
    addItem = _MockAddItem();
    addPayment = _MockAddPayment();
    cancel = _MockCancel();
    getDetail = _MockGetDetail();
    returnItem = _MockReturnItem();
  });

  // ───────────────────── List queries ─────────────────────

  group('GetSalesEvent', () {
    blocTest<SalesBloc, SalesState>(
      'emits [Loading, Loaded] on success',
      build: () {
        when(() => getSales())
            .thenAnswer((_) async => ApiResult.success([sample]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const GetSalesEvent()),
      expect: () => [const SalesLoading(), SalesLoaded([sample])],
    );

    blocTest<SalesBloc, SalesState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(() => getSales()).thenAnswer((_) async =>
            ApiResult<List<SaleEntity>>.failure('net'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const GetSalesEvent()),
      expect: () => [const SalesLoading(), const SalesError('net')],
    );
  });

  group('GetMyDraftSalesEvent', () {
    blocTest<SalesBloc, SalesState>(
      'emits MyDraftSalesLoaded (separate state from SalesLoaded)',
      build: () {
        when(() => getDrafts())
            .thenAnswer((_) async => ApiResult.success([sample]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const GetMyDraftSalesEvent()),
      expect: () => [const SalesLoading(), MyDraftSalesLoaded([sample])],
    );
  });

  // ───────────────────── CreateSaleEvent ─────────────────────

  group('CreateSaleEvent', () {
    blocTest<SalesBloc, SalesState>(
      'forwards customerId and emits SaleCreated on success',
      build: () {
        when(() => create(customerId: any(named: 'customerId')))
            .thenAnswer((_) async => ApiResult.success(sample));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const CreateSaleEvent(customerId: 'c-1')),
      expect: () => [const SalesLoading(), SaleCreated(sample)],
      verify: (_) {
        verify(() => create(customerId: 'c-1')).called(1);
      },
    );
  });

  // ───────────────────── AddPaymentEvent ─────────────────────
  //
  // The interesting branch — on success the bloc re-fetches the sales
  // list (so a debt-status sale moves up), and the test must mock BOTH
  // the payment AND the follow-up getSales(). If we forget the second
  // mock, the bloc still tries to call it, mocktail returns its default
  // (null) and the bloc silently emits PaymentAdded instead of SalesLoaded.

  group('AddPaymentEvent', () {
    blocTest<SalesBloc, SalesState>(
      'on success, refetches list and emits SalesLoaded with the fresh data',
      build: () {
        when(() => addPayment(
              saleId: any(named: 'saleId'),
              paymentType: any(named: 'paymentType'),
              amount: any(named: 'amount'),
            )).thenAnswer((_) async => ApiResult<void>.success(null));
        when(() => getSales())
            .thenAnswer((_) async => ApiResult.success([sample]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const AddPaymentEvent(
        saleId: 's-1',
        paymentType: 'Cash',
        amount: 50,
      )),
      expect: () => [const SalesLoading(), SalesLoaded([sample])],
    );

    blocTest<SalesBloc, SalesState>(
      'falls back to PaymentAdded when the follow-up list fetch fails',
      build: () {
        when(() => addPayment(
              saleId: any(named: 'saleId'),
              paymentType: any(named: 'paymentType'),
              amount: any(named: 'amount'),
            )).thenAnswer((_) async => ApiResult<void>.success(null));
        when(() => getSales()).thenAnswer((_) async =>
            ApiResult<List<SaleEntity>>.failure('flaky'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const AddPaymentEvent(
        saleId: 's-1',
        paymentType: 'Cash',
        amount: 50,
      )),
      expect: () => [const SalesLoading(), const PaymentAdded()],
    );

    blocTest<SalesBloc, SalesState>(
      'emits Error when the payment itself fails',
      build: () {
        when(() => addPayment(
              saleId: any(named: 'saleId'),
              paymentType: any(named: 'paymentType'),
              amount: any(named: 'amount'),
            )).thenAnswer((_) async => ApiResult<void>.failure('insufficient'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const AddPaymentEvent(
        saleId: 's-1',
        paymentType: 'Cash',
        amount: 50,
      )),
      expect: () => [const SalesLoading(), const SalesError('insufficient')],
      verify: (_) {
        // The bloc must NOT re-fetch the list when the payment failed.
        verifyNever(() => getSales());
      },
    );
  });

  // ───────────────────── CancelSaleEvent ─────────────────────

  group('CancelSaleEvent', () {
    blocTest<SalesBloc, SalesState>(
      'emits SaleCancelled on success',
      build: () {
        when(() => cancel(saleId: any(named: 'saleId')))
            .thenAnswer((_) async => ApiResult<void>.success(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const CancelSaleEvent(saleId: 's-1')),
      expect: () => [const SalesLoading(), const SaleCancelled()],
    );

    blocTest<SalesBloc, SalesState>(
      'emits Error when cancel is refused',
      build: () {
        when(() => cancel(saleId: any(named: 'saleId')))
            .thenAnswer((_) async => ApiResult<void>.failure('forbidden'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const CancelSaleEvent(saleId: 's-1')),
      expect: () => [const SalesLoading(), const SalesError('forbidden')],
    );
  });

  // ───────────────────── GetSaleDetailEvent ─────────────────────

  group('GetSaleDetailEvent', () {
    blocTest<SalesBloc, SalesState>(
      'uses SaleDetailLoading (not SalesLoading) and emits SaleDetailLoaded',
      build: () {
        when(() => getDetail(any())).thenAnswer((_) async =>
            ApiResult<Map<String, dynamic>>.success(const {'id': 's-1'}));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const GetSaleDetailEvent('s-1')),
      expect: () => [
        const SaleDetailLoading(),
        const SaleDetailLoaded({'id': 's-1'}),
      ],
    );
  });

  // ───────────────────── ReturnSaleItemEvent ─────────────────────

  group('ReturnSaleItemEvent', () {
    blocTest<SalesBloc, SalesState>(
      'emits SaleItemReturned WITHOUT a Loading state (it skips the spinner)',
      build: () {
        when(() => returnItem(
              saleId: any(named: 'saleId'),
              saleItemId: any(named: 'saleItemId'),
              quantity: any(named: 'quantity'),
              comment: any(named: 'comment'),
            )).thenAnswer((_) async => ApiResult<void>.success(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ReturnSaleItemEvent(
        saleId: 's-1',
        saleItemId: 'si-1',
        quantity: 1,
      )),
      // Deliberate — the bloc handler doesn't emit a SalesLoading first.
      // Pinning the current behaviour so any refactor that adds one
      // gets reviewed (it would change the spinner UX on the return
      // confirmation dialog).
      expect: () => [const SaleItemReturned()],
    );
  });
}
