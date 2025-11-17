import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pwa_demo/main.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/images_path.dart';
import '../../../constants/string_constants.dart';
import '../../../utils/button_loading_indicator.dart';
import '../../../utils/common_snackbar.dart';
import '../../profile_screen.dart';
import '../cubits/google_sign_in_cubit.dart';
import '../cubits/google_sign_in_state.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  static const String routeName = "/login";

  @override
  Widget build(BuildContext context) {
    final blocProvider = BlocProvider.of<GoogleSignInCubit>(context);
    TextEditingController emailController = TextEditingController();
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 600;

          return Row(
            children: [
              // LEFT SIDE - Illustration (only on large screen)
              if (!isMobile)
                Expanded(
                  child: Container(
                    color: Colors.blue.shade50,
                    child: Center(
                      child: Icon(Icons.lock_outline, color: Colors.blue, size: 200.w),
                    ),
                  ),
                ),

              // RIGHT SIDE - Login Form
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 24.w : 120.w, vertical: 40.h),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isMobile ? 400.w : 500.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome Back 👋",
                            style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            "Login to continue to your account",
                            style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade600),
                          ),
                          SizedBox(height: 40.h),

                          // Email field
                          TextField(
                            controller: emailController,
                            decoration: InputDecoration(
                              labelText: "Email",
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                            ),
                          ),
                          SizedBox(height: 20.h),
                          // Password field
                          TextField(
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: "Password",
                              prefixIcon: Icon(Icons.lock_outline),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                            ),
                          ),
                          SizedBox(height: 10.h),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: Text("Forgot Password?", style: TextStyle(fontSize: 14.sp)),
                            ),
                          ),
                          SizedBox(height: 20.h),

                          // Login button
                          SizedBox(
                            width: double.infinity,
                            height: 52.h,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                "Login",
                                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                          SizedBox(height: 20.h),
                          BlocConsumer<GoogleSignInCubit, GoogleSignInState>(
                            builder: (_, signInWithGoogleState) {
                              return SizedBox(
                                width: double.infinity,
                                height: 52.h,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                                    side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                  ),
                                  onPressed: (signInWithGoogleState is GoogleSignInLoadingState)
                                      ? null
                                      : () {
                                          context.read<GoogleSignInCubit>().googleSignIn();
                                        },
                                  icon: signInWithGoogleState is GoogleSignInLoadingState
                                      ? SizedBox(
                                          width: 20.sp,
                                          height: 20.sp,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : Image.asset(ImagesPath.googleLogo, height: 20.sp, width: 20.sp),
                                  label: Text(
                                    signInWithGoogleState is GoogleSignInLoadingState
                                        ? 'Signing in...'
                                        : StringConstants.lblLoginWithGoogle,
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                              );
                            },
                            listener: (BuildContext context, GoogleSignInState state) {
                              if (state is GoogleSignInFailState) {
                                commonSnackBar(context, message: state.error, type: SnackbarType.error);
                              }
                              if (state is GoogleSignInSuccessState) {
                                Router.neglect(context, () => context.go(ResponsiveHome.routeName));
                                commonSnackBar(context, message: "Google Sign in Success", type: SnackbarType.success);
                                return;
                              }
                            },
                          ),
                          SizedBox(height: 20.h),

                          // Signup link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Don’t have an account?", style: TextStyle(fontSize: 14.sp)),
                              TextButton(
                                onPressed: () {},
                                child: Text("Sign Up", style: TextStyle(fontSize: 14.sp)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
