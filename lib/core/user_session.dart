class UserSession {
  static String uid = '';
  static String role = 'Guest';
  static String name = 'Guest';
  static String email = '';
  static String houseName = 'My Home';

  static void clear() {
    uid = '';
    role = 'Guest';
    name = 'Guest';
    email = '';
    houseName = 'My Home';
  }
}
