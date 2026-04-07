import 'package:flutter/material.dart';
import 'package:night_safe_walk/features/auth/screen/signup_screen.dart';
import 'package:night_safe_walk/components/app_text_field.dart';
import 'package:night_safe_walk/components/password_text_field.dart';
import 'package:night_safe_walk/features/auth/logic/auth_logic.dart';
import 'package:night_safe_walk/features/main/main_screen.dart';
import 'package:night_safe_walk/service/auth_service.dart';
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreen();
}

class _LoginScreen extends State<LoginScreen> {
  final TextEditingController useridController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> handleLogin() async {
    final userid = useridController.text.trim();
    final password = passwordController.text.trim();

    final message = AuthLogic.validateLogin(id: userid, password: password);

    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    try {
      final result = await AuthService.login(
        userid: userid,
        password: password,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result['message'])));

      if (result['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('서버 연결 중 오류가 발생했습니다.')));
    }

    debugPrint('아이디 : $userid');
    debugPrint('비밀번호 : $password');
  }

  @override
  void dispose() {
    useridController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 100),

              const Text(
                '아이디',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // 아이디 입력창
              AppTextField(controller: useridController),
              SizedBox(height: 30),
              // 비밀번호 입력창
              const Text(
                '비밀번호',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              PasswordTextField(controller: passwordController),
              SizedBox(height: 5),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    '비밀번호를 잊으셨나요?',
                    style: TextStyle(fontSize: 14, color: Colors.blue),
                  ),
                ),
              ),
              SizedBox(height: 16),
              // 로그인 버튼
              SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6546FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text('로그인', style: TextStyle(color: Colors.white)),
                ),
              ),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignUpScreen()),
                    );
                  },

                  child: Text(
                    '회원가입',
                    style: TextStyle(fontSize: 14, color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
