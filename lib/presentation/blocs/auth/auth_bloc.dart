import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/usecases/auth/auth_usecases.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required WatchAuthStateUseCase watchAuthState,
    required SignInUseCase signIn,
    required RegisterUseCase register,
    required SignOutUseCase signOut,
    required SendPasswordResetUseCase sendPasswordReset,
  })  : _watchAuthState = watchAuthState,
        _signIn = signIn,
        _register = register,
        _signOut = signOut,
        _sendPasswordReset = sendPasswordReset,
        super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthPasswordResetRequested>(_onPasswordReset);
  }

  final WatchAuthStateUseCase _watchAuthState;
  final SignInUseCase _signIn;
  final RegisterUseCase _register;
  final SignOutUseCase _signOut;
  final SendPasswordResetUseCase _sendPasswordReset;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) {
    return emit.forEach<UserEntity?>(
      _watchAuthState(),
      onData: (user) => user == null
          ? state.copyWith(
              status: AuthStatus.unauthenticated,
              clearUser: true,
              isLoading: false,
            )
          : state.copyWith(
              status: AuthStatus.authenticated,
              user: user,
              isLoading: false,
            ),
      onError: (error, stackTrace) => state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
        isLoading: false,
      ),
    );
  }

  Future<void> _onLogin(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _signIn(email: event.email, password: event.password);
      emit(state.copyWith(isLoading: false));
    } on Failure catch (f) {
      emit(state.copyWith(isLoading: false, error: f.message));
    }
  }

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _register(
        name: event.name,
        email: event.email,
        password: event.password,
      );
      emit(state.copyWith(isLoading: false));
    } on Failure catch (f) {
      emit(state.copyWith(isLoading: false, error: f.message));
    }
  }

  Future<void> _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    try {
      await _signOut();
    } on Failure catch (f) {
      emit(state.copyWith(error: f.message));
    }
  }

  Future<void> _onPasswordReset(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _sendPasswordReset(event.email);
      emit(state.copyWith(isLoading: false, info: AppStrings.passwordResetSent));
    } on Failure catch (f) {
      emit(state.copyWith(isLoading: false, error: f.message));
    }
  }
}