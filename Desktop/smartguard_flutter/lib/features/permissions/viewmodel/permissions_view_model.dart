import 'package:flutter/foundation.dart';
import 'package:smartguard_flutter/core/auth/user_role.dart';
import 'package:smartguard_flutter/features/permissions/model/managed_user.dart';

class PermissionsViewModel extends ChangeNotifier {
  PermissionsViewModel({
    required UserRole currentUserRole,
  }) : _currentUserRole = currentUserRole;

  final UserRole _currentUserRole;
  UserRole get currentUserRole => _currentUserRole;

  bool get canManageUsers => _currentUserRole == UserRole.admin;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<ManagedUser> _users = const [];
  List<ManagedUser> get users => _users;

  final Map<String, UserRole> _pendingRoleChanges = <String, UserRole>{};
  Map<String, UserRole> get pendingRoleChanges => Map.unmodifiable(_pendingRoleChanges);

  Future<void> init() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await Future<void>.delayed(const Duration(milliseconds: 180));
      _users = const [
        ManagedUser(id: 'u1', username: 'admin01', role: UserRole.admin),
        ManagedUser(id: 'u2', username: 'home01', role: UserRole.homeowner),
        ManagedUser(id: 'u3', username: 'viewer01', role: UserRole.viewer),
        ManagedUser(id: 'u4', username: 'viewer02', role: UserRole.viewer),
      ];
    } catch (e) {
      _errorMessage = 'Ne mogu učitati korisnike.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setRoleDraft(String userId, UserRole role) {
    if (!canManageUsers) return;
    _pendingRoleChanges[userId] = role;
    notifyListeners();
  }

  Future<bool> saveChanges() async {
    if (!canManageUsers) return false;
    if (_pendingRoleChanges.isEmpty) return true;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await Future<void>.delayed(const Duration(milliseconds: 240));
      _users = _users
          .map((u) => _pendingRoleChanges.containsKey(u.id)
              ? u.copyWith(role: _pendingRoleChanges[u.id])
              : u)
          .toList(growable: false);
      _pendingRoleChanges.clear();
      return true;
    } catch (e) {
      _errorMessage = 'Nije moguće sačuvati promjene.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void discardChanges() {
    _pendingRoleChanges.clear();
    notifyListeners();
  }
}

