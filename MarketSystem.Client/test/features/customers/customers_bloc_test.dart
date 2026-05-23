import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_system_client/core/failure/api_result.dart';
import 'package:market_system_client/features/customers/domain/entities/customer_entity.dart';
import 'package:market_system_client/features/customers/domain/usecases/create_customer_usecase.dart';
import 'package:market_system_client/features/customers/domain/usecases/delete_customer_usecase.dart';
import 'package:market_system_client/features/customers/domain/usecases/get_customer_by_phone_usecase.dart';
import 'package:market_system_client/features/customers/domain/usecases/get_customer_debts_usecase.dart';
import 'package:market_system_client/features/customers/domain/usecases/get_customers_usecase.dart';
import 'package:market_system_client/features/customers/domain/usecases/update_customer_usecase.dart';
import 'package:market_system_client/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:market_system_client/features/customers/presentation/bloc/events/customers_event.dart';
import 'package:market_system_client/features/customers/presentation/bloc/states/customers_state.dart';
import 'package:mocktail/mocktail.dart';

/// FAZA 2 / test scaffold — first BLoC unit-test suite.
///
/// Covers every event on CustomersBloc against a fully-mocked use-case
/// graph (mocktail). For each handler we pin the state TRANSITION the
/// bloc emits — `Loading → Loaded` on success, `Loading → Error` on
/// failure — using the `blocTest()` helper from `bloc_test`. The
/// emitted state is asserted by value (Equatable) so the test fails
/// loudly if a refactor renames a state or accidentally re-orders a
/// transition.

class _MockGetCustomers extends Mock implements GetCustomersUseCase {}
class _MockGetByPhone extends Mock implements GetCustomerByPhoneUseCase {}
class _MockCreate extends Mock implements CreateCustomerUseCase {}
class _MockUpdate extends Mock implements UpdateCustomerUseCase {}
class _MockDelete extends Mock implements DeleteCustomerUseCase {}
class _MockGetDebts extends Mock implements GetCustomerDebtsUseCase {}

void main() {
  late _MockGetCustomers getCustomers;
  late _MockGetByPhone getByPhone;
  late _MockCreate create;
  late _MockUpdate update;
  late _MockDelete delete;
  late _MockGetDebts getDebts;

  CustomersBloc buildBloc() => CustomersBloc(
        getCustomersUseCase: getCustomers,
        getCustomerByPhoneUseCase: getByPhone,
        createCustomerUseCase: create,
        updateCustomerUseCase: update,
        deleteCustomerUseCase: delete,
        getCustomerDebtsUseCase: getDebts,
      );

  // Stable sample entity reused across tests so equality assertions
  // don't fluctuate with DateTime.now() drift.
  final sampleCustomer = CustomerEntity(
    id: 'c-1',
    phone: '998901234567',
    fullName: 'Test Mijoz',
    createdAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() {
    getCustomers = _MockGetCustomers();
    getByPhone = _MockGetByPhone();
    create = _MockCreate();
    update = _MockUpdate();
    delete = _MockDelete();
    getDebts = _MockGetDebts();
  });

  // ───────────────────── GetCustomersEvent ─────────────────────

  group('GetCustomersEvent', () {
    blocTest<CustomersBloc, CustomersState>(
      'emits [Loading, Loaded] when the use case returns data',
      build: () {
        when(() => getCustomers())
            .thenAnswer((_) async => ApiResult.success([sampleCustomer]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const GetCustomersEvent()),
      expect: () => [
        const CustomersLoading(),
        CustomersLoaded([sampleCustomer]),
      ],
    );

    blocTest<CustomersBloc, CustomersState>(
      'emits [Loading, Error] when the use case fails',
      build: () {
        when(() => getCustomers())
            .thenAnswer((_) async => ApiResult.failure('boom'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const GetCustomersEvent()),
      expect: () => [
        const CustomersLoading(),
        const CustomersError('boom'),
      ],
    );
  });

  // ───────────────────── GetCustomerByPhoneEvent ─────────────────────

  group('GetCustomerByPhoneEvent', () {
    blocTest<CustomersBloc, CustomersState>(
      'emits CustomerFound when the lookup returns data',
      build: () {
        when(() => getByPhone(any()))
            .thenAnswer((_) async => ApiResult.success(sampleCustomer));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const GetCustomerByPhoneEvent('998901234567')),
      expect: () => [
        const CustomersLoading(),
        CustomerFound(sampleCustomer),
      ],
    );

    blocTest<CustomersBloc, CustomersState>(
      'emits CustomerNotFound when the lookup succeeds with null',
      build: () {
        when(() => getByPhone(any()))
            // ApiResult.success(null) — backend 200 with empty body / no match.
            .thenAnswer((_) async =>
                ApiResult<CustomerEntity?>.success(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const GetCustomerByPhoneEvent('998000000000')),
      expect: () => [
        const CustomersLoading(),
        const CustomerNotFound(),
      ],
    );

    blocTest<CustomersBloc, CustomersState>(
      'emits Error when the lookup fails',
      build: () {
        when(() => getByPhone(any()))
            .thenAnswer((_) async => ApiResult<CustomerEntity?>.failure('net'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const GetCustomerByPhoneEvent('998000000001')),
      expect: () => [
        const CustomersLoading(),
        const CustomersError('net'),
      ],
    );
  });

  // ───────────────────── CreateCustomerEvent ─────────────────────

  group('CreateCustomerEvent', () {
    blocTest<CustomersBloc, CustomersState>(
      'emits CustomerCreated on success',
      build: () {
        when(() => create(
              phone: any(named: 'phone'),
              fullName: any(named: 'fullName'),
              comment: any(named: 'comment'),
              initialDebt: any(named: 'initialDebt'),
            )).thenAnswer((_) async => ApiResult.success(sampleCustomer));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const CreateCustomerEvent(
        phone: '998901234567',
        fullName: 'Test Mijoz',
      )),
      expect: () => [
        const CustomersLoading(),
        CustomerCreated(sampleCustomer),
      ],
    );

    blocTest<CustomersBloc, CustomersState>(
      'emits Error when the create call fails',
      build: () {
        when(() => create(
              phone: any(named: 'phone'),
              fullName: any(named: 'fullName'),
              comment: any(named: 'comment'),
              initialDebt: any(named: 'initialDebt'),
            )).thenAnswer((_) async => ApiResult<CustomerEntity>.failure('duplicate'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const CreateCustomerEvent(
        phone: '998901234567',
        fullName: 'Test Mijoz',
      )),
      expect: () => [
        const CustomersLoading(),
        const CustomersError('duplicate'),
      ],
    );
  });

  // ───────────────────── UpdateCustomerEvent ─────────────────────

  group('UpdateCustomerEvent', () {
    blocTest<CustomersBloc, CustomersState>(
      'emits CustomerUpdated on success',
      build: () {
        when(() => update(
              phone: any(named: 'phone'),
              fullName: any(named: 'fullName'),
            )).thenAnswer((_) async => ApiResult.success(sampleCustomer));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const UpdateCustomerEvent(
        phone: '998901234567',
        fullName: 'Updated Name',
      )),
      expect: () => [
        const CustomersLoading(),
        CustomerUpdated(sampleCustomer),
      ],
    );
  });

  // ───────────────────── DeleteCustomerEvent ─────────────────────

  group('DeleteCustomerEvent', () {
    blocTest<CustomersBloc, CustomersState>(
      'emits CustomerDeleted on success',
      build: () {
        when(() => delete(any()))
            .thenAnswer((_) async => ApiResult<void>.success(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const DeleteCustomerEvent('c-1')),
      expect: () => [
        const CustomersLoading(),
        const CustomerDeleted(),
      ],
    );

    blocTest<CustomersBloc, CustomersState>(
      'emits Error when delete fails',
      build: () {
        when(() => delete(any()))
            .thenAnswer((_) async => ApiResult<void>.failure('referenced'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const DeleteCustomerEvent('c-1')),
      expect: () => [
        const CustomersLoading(),
        const CustomersError('referenced'),
      ],
    );
  });

  // ───────────────────── GetCustomerDebtsEvent ─────────────────────

  group('GetCustomerDebtsEvent', () {
    blocTest<CustomersBloc, CustomersState>(
      'emits [DebtsLoading, DebtsLoaded] on success',
      build: () {
        when(() => getDebts(any())).thenAnswer((_) async =>
            ApiResult<List<Map<String, dynamic>>>.success([
              {'id': 'd1', 'amount': 100}
            ]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const GetCustomerDebtsEvent('c-1')),
      expect: () => [
        const CustomerDebtsLoading(),
        const CustomerDebtsLoaded([
          {'id': 'd1', 'amount': 100}
        ]),
      ],
    );
  });
}
