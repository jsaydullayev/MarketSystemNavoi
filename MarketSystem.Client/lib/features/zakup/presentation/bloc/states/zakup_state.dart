/// Zakup States
/// Zakup BLoC uchun holatlar

import 'package:equatable/equatable.dart';
import '../../../domain/entities/zakup_entity.dart';

/// Zakup State base class
abstract class ZakupState extends Equatable {
  const ZakupState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ZakupInitial extends ZakupState {
  const ZakupInitial();
}

/// Loading state
class ZakupLoading extends ZakupState {
  const ZakupLoading();
}

/// Zakups loaded state
class ZakupLoaded extends ZakupState {
  final List<ZakupEntity> zakups;

  const ZakupLoaded(this.zakups);

  @override
  List<Object?> get props => [zakups];
}

/// Zakup created state
class ZakupCreated extends ZakupState {
  final ZakupEntity zakup;

  const ZakupCreated(this.zakup);

  @override
  List<Object?> get props => [zakup];
}

/// Error state
class ZakupError extends ZakupState {
  final String message;

  const ZakupError(this.message);

  @override
  List<Object?> get props => [message];
}
