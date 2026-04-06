import 'package:flutter/material.dart';
import 'package:night_safe_walk/features/auth/logic/auth_logic.dart';
import '../../../components/password_text_field.dart';
import '../../../components/app_text_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController useridController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordCheckController = TextEditingController();

  void handleSignUp() {
    final userid = useridController.text;
    final name = nameController.text;
    final phone = phoneController.text;
    final password = passwordController.text;
    final passwordCheck = passwordCheckController.text;

    final message = AuthLogic.validateSignUp(
      id: userid,
      password: password,
      passwordCheck: passwordCheck,
    );

    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('회원가입 성공')));

    debugPrint('아이디 : $userid');
    debugPrint('이름 : $name');
    debugPrint('전화번호 : $phone');
    debugPrint('비밀번호 : $password');
    debugPrint('비밀번호 확인 : $passwordCheck');

    // Navigator.pop(context);
  }

  @override
  void dispose() {
    useridController.dispose();
    nameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    passwordCheckController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_ios),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),

              const Text(
                '아이디',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // 아이디 입력창
              const SizedBox(height: 8),
              AppTextField(controller: emailController, errorText: emailError),

              SizedBox(height: 30),
              // 이름 입력창
              const Text(
                '이름',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppTextField(controller: nameController),

              SizedBox(height: 30),
              //
              const Text(
                '전화번호',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppTextField(controller: phoneController),
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

              SizedBox(height: 30),
              // 비밀번호 확인 입력창
              const Text(
                '비밀번호 확인',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              PasswordTextField(controller: passwordCheckController),

              SizedBox(height: 50),
              // 회원가입 버튼
              SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: handleSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6546FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text('회원가입', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
