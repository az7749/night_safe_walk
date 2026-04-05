class AuthLogic {
  static String? validateLogin({
    required String userid,
    required String password,
  }) {
    if (userid.isEmpty || password.isEmpty) {
      return '아이디와 비밀번호를 입력해주세요.';
    }
    return null;
  }
}
