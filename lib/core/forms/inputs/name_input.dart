import 'package:formz/formz.dart';

class NameInput extends FormzInput<String, String> {
  const NameInput.pure() : super.pure('');
  const NameInput.dirty([super.value = '']) : super.dirty();

  @override
  String? validator(String value) {
    if (value.trim().isEmpty) return 'Name is required';
    return null;
  }
}
