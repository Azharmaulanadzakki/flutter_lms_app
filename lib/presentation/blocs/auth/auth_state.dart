part of 'auth_bloc.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isLoading = false,
    this.error,
    this.info,
  });

  final AuthStatus status;
  final UserEntity? user;
  final bool isLoading;

  /// Pesan sementara: otomatis hilang pada emit berikutnya.
  final String? error;
  final String? info;

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    bool clearUser = false,
    bool? isLoading,
    String? error,
    String? info,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: error,
      info: info,
    );
  }

  @override
  List<Object?> get props => [status, user, isLoading, error, info];
}