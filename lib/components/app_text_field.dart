import 'package:flutter/material.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool enabled;

  const AppTextField({
    super.key,
    required this.controller,
    this.keyboardType,
    this.enabled = true,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    _focusNode.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _focusNode.removeListener(_refresh);
    _focusNode.dispose();
    super.dispose();
  }

  Widget? _buildSuffixIcon() {
    final hasText = widget.controller.text.isNotEmpty;
    final isTyping = _focusNode.hasFocus;

    if (!hasText || !isTyping) {
      return null;
    }

    return IconButton(
      icon: const Icon(Icons.cancel, color: Color(0xFF5F6368)),
      onPressed: () {
        widget.controller.clear();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      keyboardType: widget.keyboardType,
      enabled: widget.enabled,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF1F1F1),
        suffixIcon: _buildSuffixIcon(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
