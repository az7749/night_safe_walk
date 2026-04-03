import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LogineScreen();
}

class _LoginScreen extends State<LoginScreen> {
  final TextEditingController useridController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    useridController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void handleLogin() {
    final userid = useridController.text;
    final password = passwordController.text;

    debugPrint('아이디 : $userid');
    debugPrint('비밀번호 : $password');
  }
}
