import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthEvent {}
class CheckAuthEvent extends AuthEvent {}
class LogoutEvent extends AuthEvent {}

abstract class AuthState {}
class AuthInitial extends AuthState {}
class Authenticated extends AuthState {
  final User user;
  Authenticated(this.user);
}
class Unauthenticated extends AuthState {}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<CheckAuthEvent>((event, emit) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    });

    on<LogoutEvent>((event, emit) async {
      await FirebaseAuth.instance.signOut();
      emit(Unauthenticated());
    });
  }
}
