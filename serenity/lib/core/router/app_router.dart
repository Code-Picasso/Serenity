import 'package:flutter/material.dart';

import '../../data/models/article.dart';
import '../../data/models/conversation.dart';
import '../../data/models/profile.dart';
import '../../presentation/features/auth/forgot_password_screen.dart';
import '../../presentation/features/auth/landing_screen.dart';
import '../../presentation/features/auth/login_screen.dart';
import '../../presentation/features/auth/register_screen.dart';
import '../../presentation/features/auth/splash_screen.dart';
import '../../presentation/features/auth/verify_email_screen.dart';
import '../../presentation/features/chat/chat_screen.dart';
import '../../presentation/features/feed/read_article_screen.dart';
import '../../presentation/features/home/home_shell.dart';
import '../../presentation/features/notifications/notifications_screen.dart';
import '../../presentation/features/onboarding/onboarding_screen.dart';
import '../../presentation/features/post/create_post_screen.dart';
import '../../presentation/features/post/saved_screen.dart';
import '../../presentation/features/profile/top_readers_screen.dart';
import '../../presentation/features/profile/user_profile_screen.dart';
import 'app_routes.dart';

/// Native Navigator routing (no go_router). Routes are registered by name and
/// receive their data through [RouteSettings.arguments].
class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;
    switch (settings.name) {
      case AppRoutes.splash:
        return _route(const SplashScreen());
      case AppRoutes.landing:
        return _route(const LandingScreen());
      case AppRoutes.login:
        return _route(const LoginScreen());
      case AppRoutes.register:
        return _route(const RegisterScreen());
      case AppRoutes.verifyEmail:
        return _route(VerifyEmailScreen(args: args as VerifyEmailArgs));
      case AppRoutes.forgotPassword:
        return _route(const ForgotPasswordScreen());
      case AppRoutes.onboarding:
        return _route(const OnboardingScreen());
      case AppRoutes.home:
        return _route(const HomeShell());
      case AppRoutes.readArticle:
        return _route(ReadArticleScreen(article: args as Article));
      case AppRoutes.createPost:
        return _route(const CreatePostScreen());
      case AppRoutes.saved:
        return _route(const SavedScreen());
      case AppRoutes.profile:
        return _route(UserProfileScreen(profile: args as Profile));
      case AppRoutes.topReaders:
        return _route(const TopReadersScreen());
      case AppRoutes.chatDetail:
        return _route(ChatScreen(conversation: args as Conversation));
      case AppRoutes.notifications:
        return _route(const NotificationsScreen());
      default:
        return _route(const SplashScreen());
    }
  }

  static MaterialPageRoute<dynamic> _route(Widget page) =>
      MaterialPageRoute(builder: (_) => page);
}
