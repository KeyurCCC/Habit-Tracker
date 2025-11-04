abstract class GoogleSignInState {}

class GoogleSignInDefaultState extends GoogleSignInState {}

class GoogleSignInLoadingState extends GoogleSignInState {}

class GoogleSignInSuccessState extends GoogleSignInState {}

class GoogleSignInFailState extends GoogleSignInState {
  final String error;
  GoogleSignInFailState({required this.error});
}
