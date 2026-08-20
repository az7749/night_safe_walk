import 'package:flutter/material.dart';
import 'package:night_safe_walk/components/app_text_field.dart';
import 'package:night_safe_walk/components/password_text_field.dart';
import 'package:night_safe_walk/features/auth/service/auth_service.dart';
import 'package:night_safe_walk/utils/phone_number_formatter.dart';

class ProfileEditScreen extends StatefulWidget {
  final int userId;

  const ProfileEditScreen({super.key, required this.userId});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController loginIdController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController birthController = TextEditingController();
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController newPasswordCheckController =
      TextEditingController();

  String? selectedGender;
  bool isLoading = true;
  bool isSaving = false;
  bool showPasswordFields = false;
  bool isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final result = await AuthService.getProfile(userId: widget.userId);

      if (!mounted) return;

      if (result['success'] != true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result['message'])));
        Navigator.pop(context);
        return;
      }

      final user = result['user'] as Map<String, dynamic>;

      setState(() {
        loginIdController.text = user['login_id']?.toString() ?? '';
        nameController.text = user['name']?.toString() ?? '';
        phoneController.text = formatPhoneNumber(
          user['phone']?.toString() ?? '',
        );
        birthController.text = user['birth_date']?.toString() ?? '';
        selectedGender = user['gender']?.toString();
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('서버 연결 중 오류가 발생했습니다.')));
      Navigator.pop(context);
    }
  }

  Future<void> handleSave() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final birth = birthController.text.trim();
    final gender = selectedGender;

    if (name.isEmpty || phone.isEmpty || birth.isEmpty || gender == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('모든 항목을 입력해주세요.')));
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final result = await AuthService.updateProfile(
        userId: widget.userId,
        name: name,
        phone: phone,
        birth: birth,
        gender: gender,
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
        isSaving = false;
      });
    }
  }

  Future<void> handleChangePassword() async {
    final currentPassword = currentPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final newPasswordCheck = newPasswordCheckController.text.trim();

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        newPasswordCheck.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('비밀번호 항목을 모두 입력해주세요.')));
      return;
    }

    if (newPassword.length < 8) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('새 비밀번호는 8자 이상이어야 합니다.')));
      return;
    }

    if (newPassword != newPasswordCheck) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('새 비밀번호가 일치하지 않습니다.')));
      return;
    }

    setState(() {
      isChangingPassword = true;
    });

    try {
      final result = await AuthService.changePassword(
        userId: widget.userId,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result['message'])));

      if (result['success'] == true) {
        setState(() {
          showPasswordFields = false;
          currentPasswordController.clear();
          newPasswordController.clear();
          newPasswordCheckController.clear();
        });
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('서버 연결 중 오류가 발생했습니다.')));
    } finally {
      if (!mounted) return;

      setState(() {
        isChangingPassword = false;
      });
    }
  }

  @override
  void dispose() {
    loginIdController.dispose();
    nameController.dispose();
    phoneController.dispose();
    birthController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    newPasswordCheckController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('내 정보 수정'),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('아이디'),
                    AppTextField(controller: loginIdController, enabled: false),
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
                    const _FieldLabel('생년월일'),
                    AppTextField(
                      controller: birthController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    const _FieldLabel('성별'),
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
                            DropdownMenuItem(value: '남성', child: Text('남성')),
                            DropdownMenuItem(value: '여성', child: Text('여성')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedGender = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            showPasswordFields = !showPasswordFields;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6546FF),
                          side: const BorderSide(color: Color(0xFF6546FF)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          showPasswordFields ? '비밀번호 변경 닫기' : '비밀번호 변경',
                        ),
                      ),
                    ),
                    if (showPasswordFields) ...[
                      const SizedBox(height: 24),
                      const _FieldLabel('현재 비밀번호'),
                      PasswordTextField(controller: currentPasswordController),
                      const SizedBox(height: 24),
                      const _FieldLabel('새 비밀번호'),
                      PasswordTextField(controller: newPasswordController),
                      const SizedBox(height: 24),
                      const _FieldLabel('새 비밀번호 확인'),
                      PasswordTextField(controller: newPasswordCheckController),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isChangingPassword
                              ? null
                              : handleChangePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF111827),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(isChangingPassword ? '변경 중' : '비밀번호 저장'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6546FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(isSaving ? '저장 중' : '저장'),
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
