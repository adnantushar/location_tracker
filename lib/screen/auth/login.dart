import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:location_tracker/screen/auth/register.dart';
import 'package:location_tracker/bloc/auth/auth_bloc.dart';
import 'package:location_tracker/bloc/auth/auth_event.dart';
import 'package:location_tracker/bloc/auth/auth_state.dart';
import 'package:location_tracker/enum.dart';
import 'package:location_tracker/screen/message/chat_screen.dart';

class AuthScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          if (state.unreadCount != null && state.unreadCount! > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'あなたが持っている ${state.unreadCount} 未読メッセージ${state.unreadCount == 1 ? '' : 's'}',
                ),
              ),
            );
          }
          if (state.message.isNotEmpty) {
            _showSnackBar(context, state.message, Colors.green);
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => ChatScreen()),
          );
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(context),
        backgroundColor: Colors.white,
        body: LayoutBuilder(
          builder: (context, constraints) => _buildBody(context, constraints),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final fontSize = size.width * 0.04;

    return AppBar(
      title: Text(
        'ログイン',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
      ),
      centerTitle: true,
      backgroundColor: Colors.lightBlueAccent,
    );
  }

  Widget _buildBody(BuildContext context, BoxConstraints constraints) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < AppConstants.smallScreenBreakpoint;
    final isLargeScreen = size.width >= AppConstants.largeScreenBreakpoint;
    final isLandscape = constraints.maxWidth > constraints.maxHeight;

    final logoSize =
        size.width * AppConstants.logoScale * (isSmallScreen ? 0.8 : 1.0);
    final inputHeight = size.height * AppConstants.inputHeightScale;
    final fontSize =
        size.width * AppConstants.fontScale * (isSmallScreen ? 0.9 : 1.0);
    final paddingValue = size.width * AppConstants.paddingScale;
    final buttonHeight = size.height * AppConstants.buttonHeightScale;
    final spacing = size.height * AppConstants.spacingScale;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: paddingValue,
          vertical: isLandscape ? paddingValue * 0.5 : paddingValue,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isLargeScreen ? 400 : double.infinity,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: logoSize, color: Colors.lightBlueAccent),
                SizedBox(height: spacing),
                _buildTextField(
                  emailController,
                  'Eメール',
                  Icons.email,
                  fontSize,
                  inputHeight,
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: spacing),
                _buildTextField(
                  passwordController,
                  'パスワード',
                  Icons.lock,
                  fontSize,
                  inputHeight,
                  obscureText: true,
                ),
                SizedBox(height: spacing),
                _buildErrorMessage(context, fontSize),
                SizedBox(height: spacing * 0.5),
                _buildLoginButton(context, fontSize, buttonHeight),
                // SizedBox(height: spacing),
                // _buildRegisterButton(context, fontSize),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon,
      double fontSize,
      double height, {
        bool obscureText = false,
        TextInputType? keyboardType,
      }) {
    return SizedBox(
      height: height,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: (value) => value == null || value.isEmpty ? '' : null,
        decoration: _inputDecoration(label, icon, fontSize),
        style: TextStyle(fontSize: fontSize),

        textAlignVertical: TextAlignVertical.center,
      ),
    );
  }

  Widget _buildErrorMessage(BuildContext context, double fontSize) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder:
          (context, state) =>
      state is AuthFailure
          ? Text(
        'メールアドレスまたはパスワードが無効です。もう一度お試しください。',
        style: TextStyle(
          color: Colors.red,
          fontSize: fontSize * 0.8,
        ),
        textAlign: TextAlign.center,
      )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildLoginButton(
      BuildContext context,
      double fontSize,
      double height,
      ) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder:
          (context, state) => ElevatedButton(
        onPressed:
        state is AuthLoading
            ? null
            : () => _handleLogin(
          context,
          emailController.text.trim(),
          passwordController.text.trim(),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.lightBlueAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child:
        state is AuthLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text('ログイン', style: TextStyle(fontSize: fontSize)),
      ),
    );
  }

  // Widget _buildRegisterButton(BuildContext context, double fontSize) {
  //   return TextButton(
  //     onPressed:
  //         () => Navigator.push(
  //       context,
  //       MaterialPageRoute(builder: (_) => const RegisterPage()),
  //     ),
  //     child: Text(
  //       "アカウントを持っていない方はこちら",
  //       style: TextStyle(
  //         color: Colors.lightBlueAccent,
  //         fontSize: fontSize * 0.9,
  //       ),
  //     ),
  //   );
  // }

  InputDecoration _inputDecoration(
      String label,
      IconData icon,
      double fontSize,
      ) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: fontSize),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      prefixIcon: Icon(icon, size: fontSize),
      contentPadding: const EdgeInsets.symmetric(vertical: 0),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
      errorStyle: const TextStyle(height: 0, fontSize: 0),
    );
  }

  void _handleLogin(BuildContext context, String email, String password) {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar(context, '入力内容にエラーがあります。ご確認ください。', Colors.red);
      return;
    }
    context.read<AuthBloc>().add(LoginEvent(email, password));
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }
}
