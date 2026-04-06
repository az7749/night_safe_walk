class AuthLogic {
  static String? validateLogin({required String id, required String password}) {
    if (id.trim().isEmpty && password.trim().isEmpty) {
      return '아이디와 비밀번호를 입력해주세요.';
    }

    if (id.trim().isEmpty) {
      return '아이디를 입력해주세요.';
    }

    if (password.trim().isEmpty) {
      return '비밀번호를 입력해주세요.';
    }

    return null;
  }

  static String? validateSignUp({
    required String id,
    required String name,
    required String phone,
    required String password,
    required String passwordCheck,
  }) {
    if (id.trim().isEmpty) {
      return '아이디를 입력해주세요.';
    }

    if (name.trim().isEmpty) {
      return '이름을 입력해주세요.';
    }

    if (phone.trim().isEmpty) {
      return '전화번호를 입력해주세요.';
    }

    if (!RegExp(r'^[0-9]{10,11}$').hasMatch(phone.trim())) {
      return '전화번호 형식이 올바르지 않습니다.';
    }

    if (password.trim().isEmpty) {
      return '비밀번호를 입력해주세요.';
    }

    if (password.length < 8) {
      return '비밀번호는 8자 이상이어야 합니다.';
    }

    if (passwordCheck.trim().isEmpty) {
      return '비밀번호 확인을 입력해주세요.';
    }

    if (password != passwordCheck) {
      return '비밀번호가 일치하지 않습니다.';
    }

    return null;
  }
}
