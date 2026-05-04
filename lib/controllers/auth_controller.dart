import 'package:project_granith/ViewModels/AuthViewModel.dart';

// Compatibilidade de API para transicao do padrao antigo (Controller) para MVVM.
class AuthController extends AuthViewModel {
  AuthController({super.service, super.bootstrapOnInit});
}
