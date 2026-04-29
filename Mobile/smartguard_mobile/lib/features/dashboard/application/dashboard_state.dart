enum DashboardStatus { idle, loading, ready, error }

class DashboardState {
  const DashboardState._({
    required this.status,
    required this.unreadNotifications,
    required this.activeCameras,
    required this.newAlarms,
    required this.message,
  });

  const DashboardState.idle()
    : this._(
        status: DashboardStatus.idle,
        unreadNotifications: 0,
        activeCameras: 0,
        newAlarms: 0,
        message: null,
      );

  const DashboardState.loading()
    : this._(
        status: DashboardStatus.loading,
        unreadNotifications: 0,
        activeCameras: 0,
        newAlarms: 0,
        message: null,
      );

  const DashboardState.ready({
    required int unreadNotifications,
    required int activeCameras,
    required int newAlarms,
  }) : this._(
         status: DashboardStatus.ready,
         unreadNotifications: unreadNotifications,
         activeCameras: activeCameras,
         newAlarms: newAlarms,
         message: null,
       );

  const DashboardState.error(String message)
    : this._(
        status: DashboardStatus.error,
        unreadNotifications: 0,
        activeCameras: 0,
        newAlarms: 0,
        message: message,
      );

  final DashboardStatus status;
  final int unreadNotifications;
  final int activeCameras;
  final int newAlarms;
  final String? message;
}
