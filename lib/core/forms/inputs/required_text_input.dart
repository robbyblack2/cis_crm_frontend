import 'package:formz/formz.dart';

class RequiredTextInput extends FormzInput<String, String> {
  const RequiredTextInput.pure() : super.pure('');
  const RequiredTextInput.dirty([super.value = '']) : super.dirty();

  @override
  String? validator(String value) {
    if (value.trim().isEmpty) return 'This field is required';
    return null;
  }
}
