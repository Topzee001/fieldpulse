import 'package:flutter/material.dart';

class AuthField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final String? labelText;
  final bool obscureText;
  final int maxLines;
  final TextInputType? keyboardType;
  final VoidCallback? toggleVisibily;
  final bool? showPassword;
  final Widget? prefixIcon;

  const AuthField({
    super.key,
    required this.controller,
    required this.hintText,
    this.labelText,
    required this.obscureText,
    this.maxLines = 1,
    this.keyboardType,
    this.toggleVisibily,
    this.showPassword,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 23.0),
      child: TextFormField(
        keyboardType: keyboardType,
        maxLines: maxLines,
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: labelText ?? hintText,
          // floatingLabelBehavior: FloatingLabelBehavior.always,
          prefixIcon: prefixIcon,
          border: const OutlineInputBorder(),
          fillColor: Colors.white,
          filled: true,
          hintText: hintText,
          hintStyle: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: Colors.grey[600],
          ),
          suffixIcon: toggleVisibily != null
              ? IconButton(
                  icon: Icon(
                    (showPassword ?? false)
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: toggleVisibily,
                )
              : null,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please $hintText';
          }

          return null;
        },
      ),
    );
  }
}
