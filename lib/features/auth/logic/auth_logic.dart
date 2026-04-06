class AuthLogic {
  static String? validateSignUp({
    required String id,
    required String password,
    required String passwordCheck,
  }) {
    if (id.trim().isEmpty) {
      return '아이디를 입력해주세요.';
    }

    if (password.trim().isEmpty) {
      return '비밀번호를 입력해주세요.';
    }

    if (passwordCheck.trim().isEmpty) {
      return '비밀번호 확인을 입력해주세요.';
    }

    if (password.length < 8) {
      return '비밀번호는 8자 이상이어야 합니다.';
    }

    if (password != passwordCheck) {
      return '비밀번호가 일치하지 않습니다.';
    }

    return null;
  }
}
