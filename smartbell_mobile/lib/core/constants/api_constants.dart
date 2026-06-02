class ApiConstants {
  // Base URL — change to your machine IP for real device testing
  // static const String baseUrl = 'http://localhost:8080/api';        // iOS simulator only
  // static const String baseUrl = 'http://10.0.2.2:8080/api';        // Android emulator
  // static const String baseUrl = 'http://192.168.1.42:8080/api';    // WiFi real device
  static const String baseUrl = 'https://aspirin-copious-unmoving.ngrok-free.dev/api';           // ADB reverse

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';

  // Members
  static const String members = '/members';
  static String memberByUser(int uid) => '/members/user/$uid';

  // Coaches
  static const String coaches = '/coaches';
  static String coachByUser(int uid) => '/coaches/user/$uid';

  // Courses
  static const String courses = '/courses';
  static const String courseReservations = '/courses/reservations';

  // Training
  static String trainingByMember(int id) => '/training/programs/member/$id';
  static String trainingByCoach(int id) => '/training/programs/coach/$id';

  // Nutrition
  static String nutritionByMember(int id) => '/nutrition-plans/member/$id';

  // Subscriptions
  static const String subscriptions = '/subscriptions';
  static String subscriptionsByUser(int uid) => '/subscriptions/user/$uid';

  // Payments
  static const String payments = '/payments';

  // Messages
  static String conversation(int u1, int u2) =>
      '/messages/conversation/$u1/$u2';
  static String sendMessage(int senderId) => '/messages/sender/$senderId';

  // Notifications
  static String unreadNotifications(int uid) =>
      '/notifications/user/$uid/unread';

  // Statistics
  static const String statistics = '/statistics';

  // Plans
  static const String plans = '/subscription-plans';

  // Group messaging
  static const String groupMessages = '/messages/group';

  // User profile
  static String userById(int id) => '/users/$id';
  static String userPasswordUrl(int id) => '/users/$id/password';
}
