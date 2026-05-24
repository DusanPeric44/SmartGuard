class AppStrings {
  const AppStrings._();

  static const String appTitle = 'SmartGuard';

  static const String loginTitle = 'Login';
  static const String registerTitle = 'Register';
  static const String emailOrUsernameLabel = 'Email or username';
  static const String fullNameLabel = 'Full name';
  static const String firstNameLabel = 'First name';
  static const String lastNameLabel = 'Last name';
  static const String emailLabel = 'Email';
  static const String passwordLabel = 'Password';
  static const String confirmPasswordLabel = 'Confirm password';
  static const String logout = 'Logout';

  static const String actionLogin = 'Login';
  static const String actionRegister = 'Create account';
  static const String actionGoToRegister = 'Create an account';
  static const String actionGoToLogin = 'I already have an account';
  static const String actionSave = 'Save';
  static const String actionCancel = 'Cancel';
  static const String actionRetry = 'Retry';
  static const String actionConnect = 'Start Stream';
  static const String actionDisconnect = 'Disconnect';
  static const String actionReconnect = 'Reconnect';
  static const String actionContinueWithGoogle = 'Continue with Google';

  static const String validationRequired = 'This field is required';
  static const String validationInvalidEmail = 'Enter a valid email';
  static const String validationPasswordTooShort = 'Password is too short';
  static const String validationPasswordTooLong = 'Password is too long';
  static const String validationPasswordsDoNotMatch = 'Passwords do not match';

  static const String errorNetwork = 'No internet connection';
  static const String errorTimeout = 'Request timed out';
  static const String errorUnauthorized =
      'Session expired. Please log in again.';
  static const String errorOAuthLoginFailed = 'Google login failed';
  static const String errorUnknown = 'Something went wrong';

  static const String liveStreamTitle = 'Live Stream';
  static const String liveStreamSelectDevice = 'Select device';
  static const String liveStreamConnecting = 'Connecting…';
  static const String liveStreamReconnecting = 'Reconnecting…';
  static const String liveStreamNoFrames = 'Waiting for frames…';
  static const String liveStreamRecord = 'Record';
  static const String liveStreamStop = 'Stop';
  static const String liveStreamClipSaved = 'Clip saved';

  static const String statusIdle = 'Idle';
  static const String statusConnecting = 'Connecting';
  static const String statusPlaying = 'Playing';
  static const String statusBuffering = 'Buffering';
  static const String statusReconnecting = 'Reconnecting';
  static const String statusError = 'Error';

  static const String profileTitle = 'Profile';
  static const String profileSectionAccount = 'Account';
  static const String profileSectionSecurity = 'Security';
  static const String profileSectionSession = 'Session';
  static const String profileEdit = 'Edit profile';
  static const String profileChangePassword = 'Change password';

  static const String profileNamePrefix = 'Name';
  static const String profileEmailPrefix = 'Email';
  static const String profileUsernamePrefix = 'Username';
  static const String logoutConfirmMessage =
      'Are you sure you want to log out?';

  static const String currentPasswordLabel = 'Current password';
  static const String newPasswordLabel = 'New password';
  static const String confirmNewPasswordLabel = 'Confirm new password';
  static const String passwordUpdated = 'Password updated';

  static const String knownPersonsTitle = 'Known Persons';
  static const String knownPersonsInfo =
      'Manage recognized individuals and their notification preferences. Toggle notifications to receive alerts when these persons are detected by your cameras.';
  static const String knownPersonsNotificationsLabel = 'Notifications';
  static const String knownPersonsEmpty = 'No known persons found.';

  static const String navHome = 'Home';
  static const String navLive = 'Live';
  static const String navArchive = 'Archive';
  static const String navAlarms = 'Alarms';
  static const String navPersons = 'Persons';

  static const String recordingArchiveTitle = 'Archive';
  static const String alertsTitle = 'Alarms';

  static const String dashboardTitle = 'Dashboard';
  static const String dashboardSystemStatusTitle = 'System Status';
  static const String dashboardSystemStatusArmed = 'Armed';
  static const String dashboardActiveTitle = 'Active';
  static const String dashboardNewAlarmsTitle = 'New Alarms';
  static const String dashboardActionRequired = 'Action Required';
  static const String dashboardQuickAccessTitle = 'Quick Access';
  static const String dashboardQuickAccessEmpty = 'No devices available.';
  static const String dashboardLoadFailed = 'Failed to load dashboard.';
}
