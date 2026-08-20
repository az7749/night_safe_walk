import 'package:flutter/material.dart';
import 'package:night_safe_walk/components/app_text_field.dart';
import 'package:night_safe_walk/components/password_text_field.dart';
import 'package:night_safe_walk/features/auth/service/auth_service.dart';
import 'package:night_safe_walk/utils/phone_number_formatter.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final TextEditingController useridController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordCheckController = TextEditingController();

  bool isSubmitting = false;

  Future<void> handleResetPassword() async {
    final userid = useridController.text.trim();
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();
    final passwordCheck = passwordCheckController.text.trim();

    if (userid.isEmpty ||
        name.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        passwordCheck.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('모든 항목을 입력해주세요.')));
      return;
    }

    if (password.length < 8) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('비밀번호는 8자 이상이어야 합니다.')));
      return;
    }

    if (password != passwordCheck) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')));
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final result = await AuthService.resetPassword(
        userid: userid,
        name: name,
        phone: phone,
        newPassword: password,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result['message'])));

      if (result['success'] == true) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('서버 연결 중 오류가 발생했습니다.')));
    } finally {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });
    }
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
        title: const Text('비밀번호 찾기'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel('아이디'),
              AppTextField(controller: useridController),
              const SizedBox(height: 24),
              const _FieldLabel('이름'),
              AppTextField(controller: nameController),
              const SizedBox(height: 24),
              const _FieldLabel('전화번호'),
              AppTextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: const [PhoneNumberInputFormatter()],
              ),
              const SizedBox(height: 24),
              const _FieldLabel('새 비밀번호'),
              PasswordTextField(controller: passwordController),
              const SizedBox(height: 24),
              const _FieldLabel('새 비밀번호 확인'),
              PasswordTextField(controller: passwordCheckController),
              const SizedBox(height: 40),
              SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : handleResetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6546FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(isSubmitting ? '변경 중' : '비밀번호 변경'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.grey,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
