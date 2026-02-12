/// Get Zakups Use Case
/// Barcha xaridlarni olish biznes mantig'i

import '../../../../core/failure/api_result.dart';
import '../entities/zakup_entity.dart';
import '../repositories/zakup_repository_interface.dart';

/// Get Zakups Use Case
class GetZakupsUseCase {
  final ZakupRepositoryInterface repository;

  const GetZakupsUseCase(this.repository);

  /// Barcha xaridlarni olish
  Future<ApiResult<List<ZakupEntity>>> call() async {
    return repository.getAllZakups();
  }
}
