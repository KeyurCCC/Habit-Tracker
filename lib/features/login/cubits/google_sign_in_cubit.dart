import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pwa_demo/features/login/cubits/google_sign_in_state.dart';
import 'package:http/http.dart' as http;

class GoogleSignInCubit extends Cubit<GoogleSignInState> {
  GoogleSignInCubit() : super(GoogleSignInDefaultState());

  String? accessToken;
  String? idToken;

  /// 🔹 Sign in with Google and request Gemini scopes
  Future<void> googleSignIn() async {
    try {
      emit(GoogleSignInLoadingState());

      final FirebaseAuth auth = FirebaseAuth.instance;
      final GoogleAuthProvider googleAuthProvider = GoogleAuthProvider();

      googleAuthProvider.setCustomParameters({'prompt': 'consent select_account'});

      final UserCredential userCredential = await auth
          .signInWithPopup(googleAuthProvider)
          .timeout(
            const Duration(minutes: 1),
            onTimeout: () {
              throw FirebaseAuthException(code: 'popup-closed', message: 'Sign-in popup was closed or timed out.');
            },
          );

      final credential = userCredential.credential;
      accessToken = credential?.accessToken;
      idToken = credential?.token.toString();

      if (userCredential.user == null) {
        throw FirebaseAuthException(code: "firebase-null-user", message: "User returned null from Firebase");
      }

      print("✅ AccessToken: $accessToken");
      print("✅ ID Token: $idToken");

      emit(GoogleSignInSuccessState());
    } on FirebaseAuthException catch (e) {
      print("firebase error: $e");
      emit(GoogleSignInFailState(error: e.toString()));
    } catch (e) {
      print("error: $e");
      emit(GoogleSignInFailState(error: e.toString()));
    }
  }

  /// 🔹 Call Gemini API with user's Google OAuth token
  Future<void> callGeminiAPI(String accessToken, String prompt) async {
    const model = "gemini-2.5-flash";
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=AIzaSyDHJlZDzyVHTRLMIpu5kfcwHsdFrimnhRQ",
    );

    final headers = {"Content-Type": "application/json"};

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt},
          ],
        },
      ],
    });

    final res = await http.post(url, headers: headers, body: body);

    if (res.statusCode == 200) {
      print("✅ Gemini Response: ${res.body}");
    } else {
      print("❌ Gemini API error: ${res.statusCode} - ${res.body}");
    }
  }
}
