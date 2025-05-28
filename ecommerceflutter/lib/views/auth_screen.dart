import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _loading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'package_name://login-callback',
        authScreenLaunchMode: LaunchMode.inAppWebView,
        queryParams: {
          'prompt': 'select_account',
          'access_type': 'offline',
          'include_granted_scopes': 'true',
        },
      );
    } on AuthException catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.message);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('There is an error. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 600;
    final isTablet = screenWidth >= 600;

    double panelWidthRatio =
        isSmallScreen ? 0.95 : (isMediumScreen ? 0.9 : (isTablet ? 0.7 : 0.8));
    double panelHeightRatio =
        isSmallScreen ? 0.5 : (isMediumScreen ? 0.45 : (isTablet ? 0.35 : 0.4));

    final panelW =
        (screenWidth * panelWidthRatio).clamp(300.0, isTablet ? 500.0 : 450.0);
    final panelH = (screenHeight * panelHeightRatio)
        .clamp(280.0, isTablet ? 350.0 : 400.0);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/auth_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade400,
                        Colors.purple.shade400,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: panelW,
                maxHeight: panelH,
              ),
              child: GlassmorphicContainer(
                width: panelW,
                height: panelH,
                borderRadius: isTablet ? 24 : 20,
                blur: isTablet ? 20 : 16,
                border: 2,
                linearGradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: isTablet ? 0.06 : 0.04),
                    Colors.white.withValues(alpha: isTablet ? 0.03 : 0.02),
                  ],
                ),
                borderGradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.2),
                    Colors.white.withValues(alpha: 0.1),
                  ],
                ),
                child:
                    _buildPanelContent(panelW, panelH, isSmallScreen, isTablet),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelContent(
      double panelW, double panelH, bool isSmallScreen, bool isTablet) {
    final contentPadding = panelW * (isTablet ? 0.08 : 0.06);
    final availableWidth = panelW - (contentPadding * 2);
    final availableHeight = panelH - (contentPadding * 2);

    final titleFontSize = (panelW * (isTablet ? 0.055 : 0.065))
        .clamp(18.0, isTablet ? 28.0 : 32.0);
    final subtitleFontSize = (panelW * (isTablet ? 0.03 : 0.035))
        .clamp(12.0, isTablet ? 15.0 : 16.0);
    final infoFontSize = (panelW * (isTablet ? 0.025 : 0.028))
        .clamp(10.0, isTablet ? 13.0 : 14.0);

    final spaceBetweenElements = (availableHeight * 0.08).clamp(8.0, 20.0);
    final largeSpace = (availableHeight * 0.12).clamp(12.0, 30.0);

    return Padding(
      padding: EdgeInsets.all(contentPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: spaceBetweenElements * 0.5),
          _buildTitle(availableWidth, titleFontSize, isTablet),
          SizedBox(height: largeSpace),
          _buildSubtitle(availableWidth, subtitleFontSize, isTablet),
          SizedBox(height: largeSpace * 1.2),
          _buildGoogleSignInButton(
              availableWidth, panelH, isSmallScreen, isTablet),
          SizedBox(height: largeSpace),
          _buildInfoText(availableWidth, infoFontSize, isTablet),
          SizedBox(height: spaceBetweenElements * 0.5),
        ],
      ),
    );
  }

  Widget _buildTitle(double availableWidth, double fontSize, bool isTablet) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: availableWidth),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome',
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.white,
                fontWeight: isTablet ? FontWeight.w200 : FontWeight.w300,
                letterSpacing: isTablet ? 1.5 : 0.5,
              ),
            ),
            SizedBox(width: fontSize * (isTablet ? 0.3 : 0.25)),
            Text(
              'ECommerce',
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: isTablet ? 1.2 : 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitle(double availableWidth, double fontSize, bool isTablet) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: availableWidth),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'Hesabınızla giriş yapın',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.white.withValues(alpha: isTablet ? 0.85 : 0.8),
            letterSpacing: isTablet ? 0.8 : 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton(
      double availableWidth, double panelH, bool isSmallScreen, bool isTablet) {
    final buttonHeight =
        (panelH * (isTablet ? 0.16 : 0.14)).clamp(45.0, isTablet ? 70.0 : 65.0);
    final buttonWidth = (availableWidth * (isTablet ? 0.85 : 0.95))
        .clamp(200.0, isTablet ? 400.0 : 350.0);

    final iconSize = (buttonHeight * 0.35).clamp(16.0, 24.0);
    final fontSize = (buttonHeight * (isTablet ? 0.25 : 0.28))
        .clamp(12.0, isTablet ? 16.0 : 18.0);
    final horizontalPadding = buttonWidth * 0.04;

    return Container(
      width: buttonWidth,
      height: buttonHeight,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _loading
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: isTablet ? 0.95 : 0.9),
            foregroundColor: Colors.black87,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
            ),
            elevation: _loading ? 0 : (isTablet ? 6 : 4),
            shadowColor: Colors.black.withValues(alpha: 0.3),
          ),
          onPressed: _loading ? null : _signInWithGoogle,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: iconSize,
                height: iconSize,
                child: _loading
                    ? CircularProgressIndicator(
                        color: Colors.black87,
                        strokeWidth: (iconSize * 0.1).clamp(1.5, 3.0),
                      )
                    : Icon(
                        FontAwesomeIcons.google,
                        size: iconSize,
                        color: Colors.red.shade600,
                      ),
              ),
              SizedBox(width: horizontalPadding),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _loading ? 'Giriş yapılıyor...' : 'Google ile Giriş Yap',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: isTablet ? FontWeight.w500 : FontWeight.w600,
                      letterSpacing: isTablet ? 0.5 : 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoText(double availableWidth, double fontSize, bool isTablet) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: availableWidth),
      child: Text(
        'Google hesabınızı seçerek güvenli giriş yapın',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.white.withValues(alpha: isTablet ? 0.75 : 0.7),
          height: isTablet ? 1.4 : 1.3,
          letterSpacing: isTablet ? 0.4 : 0.2,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
