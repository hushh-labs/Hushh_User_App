class AppRoutes {
  static const String home = '/';
  static const String auth = '/auth';
  static const String userGuide = '/user-guide';
  static const String videoQA = '/video-qa';
  static const String coinPage = '/coin-page';
  static const String cardCreated = '/card-created';
  static const String mainPage = '/main-page';
  static const String mainAuth = '/main-auth';
  static const String pda = '/pda';
  static const String permissions = '/permissions';
  static const String deleteAccount = '/delete-account';

  // User guide specific routes
  static const String userGuideQuestion = '/user-guide/question';
  static const String userGuideLocation = '/user-guide/location';
  static const String userGuideGmail = '/user-guide/gmail';
  static const String userGuideCoinGmail = '/user-guide/coin-gmail';
  static const String createFirstCard = '/user-guide/create-first-card';

  // Card wallet routes
  static const CardWalletRoutes cardWallet = CardWalletRoutes();
}

class CardWalletRoutes {
  const CardWalletRoutes();

  String get settings => '/settings';
  String get notifications => '/notifications';
}
