import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_system_client/core/failure/api_result.dart';
import 'package:market_system_client/features/zakup/domain/entities/zakup_entity.dart';
import 'package:market_system_client/features/zakup/domain/usecases/create_zakup_usecase.dart';
import 'package:market_system_client/features/zakup/domain/usecases/get_zakups_by_date_range_usecase.dart';
import 'package:market_system_client/features/zakup/domain/usecases/get_zakups_usecase.dart';
import 'package:market_system_client/features/zakup/presentation/bloc/events/zakup_event.dart';
import 'package:market_system_client/features/zakup/presentation/bloc/states/zakup_state.dart';
import 'package:market_system_client/features/zakup/presentation/bloc/zakup_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockGet extends Mock implements GetZakupsUseCase {}
class _MockGetByRange extends Mock implements GetZakupsByDateRangeUseCase {}
class _MockCreate extends Mock implements CreateZakupUseCase {}

void main() {
  late _MockGet get;
  late _MockGetByRange getByRange;
  late _MockCreate create;

  ZakupBloc buildBloc() => ZakupBloc(
        getZakupsUseCase: get,
        getZakupsByDateRangeUseCase: getByRange,
        createZakupUseCase: create,
      );

  final sample = ZakupEntity(
    id: 'z-1',
    productId: 'p-1',
    productName: 'Taxta',
    quantity: 10,
    costPrice: 18000,
    createdAt: DateTime.utc(2026, 1, 1),
    createdBy: 'admin',
  );

  setUp(() {
    get = _MockGet();
    getByRange = _MockGetByRange();
    create = _MockCreate();
  });

  group('GetZakupsEvent', () {
    blocTest<ZakupBloc, ZakupState>(
      'emits [Loading, Loaded] on success',
      build: () {
        when(() => get()).thenAnswer((_) async => ApiResult.success([sample]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const GetZakupsEvent()),
      expect: () => [const ZakupLoading(), ZakupLoaded([sample])],
    );

    blocTest<ZakupBloc, ZakupState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(() => get()).thenAnswer((_) async =>
            ApiResult<List<ZakupEntity>>.failure('net'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const GetZakupsEvent()),
      expect: () => [const ZakupLoading(), const ZakupError('net')],
    );
  });

  group('GetZakupsByDateRangeEvent', () {
    blocTest<ZakupBloc, ZakupState>(
      'forwards start/end to the use case and emits Loaded on success',
      build: () {
        when(() => getByRange(any(), any()))
            .thenAnswer((_) async => ApiResult.success([sample]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(GetZakupsByDateRangeEvent(
        start: DateTime.utc(2026, 1, 1),
        end: DateTime.utc(2026, 1, 31),
      )),
      expect: () => [const ZakupLoading(), ZakupLoaded([sample])],
      verify: (_) {
        verify(() => getByRange(
              DateTime.utc(2026, 1, 1),
              DateTime.utc(2026, 1, 31),
            )).called(1);
      },
    );

    blocTest<ZakupBloc, ZakupState>(
      'emits Error when the date-range fetch fails',
      build: () {
        when(() => getByRange(any(), any())).thenAnswer((_) async =>
            ApiResult<List<ZakupEntity>>.failure('bad-range'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(GetZakupsByDateRangeEvent(
        start: DateTime.utc(2026, 1, 1),
        end: DateTime.utc(2026, 1, 31),
      )),
      expect: () => [const ZakupLoading(), const ZakupError('bad-range')],
    );
  });

  group('CreateZakupEvent', () {
    blocTest<ZakupBloc, ZakupState>(
      'emits ZakupCreated on success',
      build: () {
        when(() => create(
              productId: any(named: 'productId'),
              quantity: any(named: 'quantity'),
              costPrice: any(named: 'costPrice'),
            )).thenAnswer((_) async => ApiResult.success(sample));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const CreateZakupEvent(
        productId: 'p-1',
        quantity: 10,
        costPrice: 18000,
      )),
      expect: () => [const ZakupLoading(), ZakupCreated(sample)],
    );

    blocTest<ZakupBloc, ZakupState>(
      'emits Error on create failure',
      build: () {
        when(() => create(
              productId: any(named: 'productId'),
              quantity: any(named: 'quantity'),
              costPrice: any(named: 'costPrice'),
            )).thenAnswer((_) async =>
                ApiResult<ZakupEntity>.failure('Product not found'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const CreateZakupEvent(
        productId: 'unknown',
        quantity: 1,
        costPrice: 100,
      )),
      expect: () => [const ZakupLoading(), const ZakupError('Product not found')],
    );
  });
}
