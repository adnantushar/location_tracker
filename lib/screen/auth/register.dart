import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // final TextEditingController firstnameController = TextEditingController();
  // final TextEditingController lastnameController = TextEditingController();
  final TextEditingController fullnameController = TextEditingController();
  // final TextEditingController genderController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscureText = true;
  String? _selectedGender = '男性';

  @override
  void dispose() {
    // firstnameController.dispose();
    // lastnameController.dispose();
    fullnameController.dispose();
    dobController.dispose();
    // genderController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _validateAndNavigate() {
    if (_formKey.currentState?.validate() ?? false) {
      final personalInfo = {
        // 'firstname': firstnameController.text,
        // 'lastname': lastnameController.text,
        'fullname': fullnameController.text,
        // 'gender': _selectedGender!,
        'dob': dobController.text,
        'email': emailController.text,
        'password': passwordController.text,
      };

      // Navigate to the next page and pass data
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => AdditionalInfoPage(personalInfo: personalInfo),
      //   ),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final fontSize = size.width * 0.04;
    final inputHeight = size.height * 0.07;
    final spacing = size.height * 0.02;
    final dobheight = size.height * 0.008;
    final height = size.height * 0.006;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "個人情報",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
        ),
        centerTitle: true,
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: Padding(
        padding: EdgeInsets.all(size.width * 0.05),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // _buildTextField(
                //   firstnameController,
                //   '姓',
                //   Icons.person,
                //   fontSize,
                //   inputHeight,
                // ),
                // _buildTextField(
                //   lastnameController,
                //   '名',
                //   Icons.person,
                //   fontSize,
                //   inputHeight,
                // ),
                _buildTextField(
                  fullnameController,
                  '姓名',
                  Icons.person,
                  fontSize,
                  inputHeight,
                ),
                _buildGenderField(fontSize, inputHeight),
                SizedBox(height: dobheight),
                _buildDOBField(fontSize, inputHeight),
                _buildTextField(
                  emailController,
                  'Eメール',
                  Icons.email,
                  fontSize,
                  inputHeight,
                  keyboardType: TextInputType.emailAddress,
                ),
                _buildPasswordField(fontSize, inputHeight),
                SizedBox(height: spacing),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _validateAndNavigate,
                  child: Text("次へ", style: TextStyle(fontSize: fontSize)),
                ),
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
        TextInputType? keyboardType,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: fontSize),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red),
          ),
          prefixIcon: Icon(icon, size: fontSize),
        ),
        style: TextStyle(fontSize: fontSize),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$labelは必須です。';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordField(double fontSize, double height) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: passwordController,
        obscureText: _obscureText,
        decoration: InputDecoration(
          labelText: 'パスワード',
          labelStyle: TextStyle(fontSize: fontSize),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red),
          ),
          prefixIcon: Icon(Icons.lock, size: fontSize),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility : Icons.visibility_off,
              size: fontSize,
            ),
            onPressed: () => setState(() => _obscureText = !_obscureText),
          ),
        ),
        style: TextStyle(fontSize: fontSize),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'パスワードは必須です。';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildGenderField(double fontSize, double height) {
    return SizedBox(
      height: height,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Icon(Icons.male, size: fontSize, color: Colors.black),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildRadioOption('男性', fontSize),
                  _buildRadioOption('女性', fontSize),
                  _buildRadioOption('その他', fontSize),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption(String value, double fontSize) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: _selectedGender,
          onChanged: (newValue) {
            setState(() => _selectedGender = newValue);
          },
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        Text(value, style: TextStyle(fontSize: fontSize * 0.8)),
      ],
    );
  }

  Widget _buildDOBField(double fontSize, double height) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: TextFormField(
        controller: dobController,
        readOnly: true,
        decoration: InputDecoration(
          labelText: '誕生日',
          labelStyle: TextStyle(fontSize: fontSize),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red),
          ),
          prefixIcon: Icon(Icons.calendar_today, size: fontSize),
          suffixIcon: IconButton(
            icon: Icon(Icons.date_range, size: fontSize),
            onPressed: _selectDate,
          ),
        ),
        style: TextStyle(fontSize: fontSize),
        onTap: _selectDate,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '誕生日は必須です。';
          }
          return null;
        },
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dobController.text = '${picked.year}-${picked.month}-${picked.day}';
      });
    }
  }
}
