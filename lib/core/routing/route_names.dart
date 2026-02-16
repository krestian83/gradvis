abstract final class RouteNames {
  static const profileSelect = '/';
  static const wizard = '/wizard';
  static const home = '/home';
  static const levels = '/levels/:subject';
  static const game = '/game/:subject/:level';
  static const store = '/store';

  static String levelsPath(String subject) => '/levels/$subject';
  static String gamePath(String subject, int level) => '/game/$subject/$level';
}
