import 'package:project_granith/models/client_account_model.dart';
import 'package:project_granith/services/client_portal_access_service.dart';

class FakeClientPortalAccessService extends ClientPortalAccessService {
  ClientAccount? lastInvitedAccount;
  Object? inviteError;
  ClientPortalInviteResult inviteResult = ClientPortalInviteResult(
    account: ClientAccount.empty(),
    message: 'Convite enviado.',
  );

  @override
  Future<ClientPortalInviteResult> createOrResendAccess(
    ClientAccount account,
  ) async {
    lastInvitedAccount = account;
    if (inviteError != null) {
      throw inviteError!;
    }
    return inviteResult.account.id.isEmpty
        ? ClientPortalInviteResult(
          account: account,
          message: inviteResult.message,
        )
        : inviteResult;
  }
}
