import 'package:flutter/material.dart';
import 'package:night_safe_walk/features/auth/logic/auth_logic.dart';
import 'package:night_safe_walk/service/auth_service.dart';
import 'package:night_safe_walk/components/app_text_field.dart';
import 'package:night_safe_walk/components/password_text_field.dart';
import 'dart:async';

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
  final TextEditingController birthController = TextEditingController();
  final TextEditingController passwordCheckController = TextEditingController();

  String? selectedGender;

  String? userIdMessage;
  bool isUserIdAvailable = false;
  bool isCheckingUserId = false;

  Timer? _userIdDebounce;

  Future<void> handleSignUp() async {
    final userid = useridController.text.trim();
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final birth = birthController.text.trim();
    final password = passwordController.text.trim();
    final passwordCheck = passwordCheckController.text.trim();

    final message = AuthLogic.validateSignUp(
      id: userid,
      name: name,
      phone: phone,
      password: password,
      passwordCheck: passwordCheck,
    );

    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    try {
      final result = await AuthService.signUp(
        userid: userid,
        name: name,
        phone: phone,
        birth: birth,
        gender: selectedGender!,
        password: password,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result['message'])));

      if (result['success'] == true) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('서버 연결 중 오류가 발생했습니다.')));
    }

    debugPrint('아이디 : $userid');
    debugPrint('이름 : $name');
    debugPrint('전화번호 : $phone');
    debugPrint('생년월일 : $birth');
    debugPrint('성별 : $selectedGender');
    debugPrint('비밀번호 : $password');
    debugPrint('비밀번호 확인 : $passwordCheck');

    // Navigator.pop(context);
  }

  @override
  void dispose() {
    useridController.dispose();
    nameController.dispose();
    phoneController.dispose();
    birthController.dispose();
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),

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
                AppTextField(controller: useridController),

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
                const Text(
                  '전화번호',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AppTextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 30),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '생년월일',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          AppTextField(
                            controller: birthController,
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '성별',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F1F1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedGender,
                                hint: const Text('선택'),
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(
                                    value: '남성',
                                    child: Text('남성'),
                                  ),
                                  DropdownMenuItem(
                                    value: '여성',
                                    child: Text('여성'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    selectedGender = value;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

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
      ),
    );
  }
}
