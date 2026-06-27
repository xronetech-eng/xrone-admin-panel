abstract final class AppRoutes {
  static const authLogin = '/auth/login';
  static const authForgotPassword = '/auth/forgot-password';

  static const dashboard = '/dashboard';
  static const users = '/users';
  static const pilots = '/pilots';
  static const pilotManagement = '/pilot-management';
  static const store = '/store';
  static const payments = '/payments';
  static const tracking = '/tracking';
  static const settings = '/settings';

  static const values = <String>[
    dashboard,
    users,
    pilots,
    pilotManagement,
    store,
    payments,
    tracking,
    settings,
  ];
}
