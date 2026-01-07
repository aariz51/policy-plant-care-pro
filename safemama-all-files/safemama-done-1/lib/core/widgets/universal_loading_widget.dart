// lib/core/widgets/universal_loading_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:safemama/core/constants/app_colors.dart';
// import 'package:safemama/l10n/app_localizations.dart'; // AppLocalizations is not directly used in this widget's build logic for texts. Texts are passed in.

class UniversalLoadingWidget extends StatefulWidget {
  final List<String> loadingTexts;
  final String initialText; // Can be the first text or a generic one

  const UniversalLoadingWidget({
    super.key,
    required this.loadingTexts,
    required this.initialText,
  });

  @override
  State<UniversalLoadingWidget> createState() => _UniversalLoadingWidgetState();
}

class _UniversalLoadingWidgetState extends State<UniversalLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartbeatController;
  late Animation<double> _heartbeatAnimation;

  Timer? _textChangeTimer;
  int _currentTextIndex = 0;
  late List<String> _actualLoadingTexts;

  // final Color _gradientColor1 = const Color(0xFFF8EBFD); // Not used directly in the widget itself, but in the screen that hosts it
  // final Color _gradientColor2 = const Color(0xFFFDF0E6); // Not used
  // final Color _gradientColor3 = const Color(0xFFE4E6FC); // Not used
  late Color _primaryAppColor;
  late Color _textAppColor;

  @override
  void initState() {
    super.initState();
    _actualLoadingTexts = widget.loadingTexts.isNotEmpty ? widget.loadingTexts : [widget.initialText];
    // Ensure initialText is part of the list if loadingTexts is empty, or use it as the only text
    if (_actualLoadingTexts.length == 1 && _actualLoadingTexts[0] != widget.initialText && widget.initialText.isNotEmpty){
         _actualLoadingTexts = [widget.initialText];
    } else if (_actualLoadingTexts.isEmpty && widget.initialText.isNotEmpty) {
         _actualLoadingTexts = [widget.initialText];
    } else if (_actualLoadingTexts.isEmpty && widget.initialText.isEmpty) {
         _actualLoadingTexts = ["Loading..."]; // Absolute fallback
    }


    _heartbeatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _heartbeatAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.2), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 0.95, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _heartbeatController,
      curve: Curves.easeInOut,
    ));
    _heartbeatController.repeat();

    if (_actualLoadingTexts.length > 1) {
      _startTextAnimation();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // These could also be passed as parameters if they vary by loading context
    _primaryAppColor = AppColors.primary; 
    // MODIFIED: Using AppColors.textDark as AppColors.textDarkPurple and AppColors.textPrimary are not available.
    _textAppColor = AppColors.textDark; 
  }

  void _startTextAnimation() {
    _textChangeTimer?.cancel();
    _textChangeTimer = Timer.periodic(const Duration(seconds: 2, milliseconds: 200), (timer) {
      if (mounted && _actualLoadingTexts.length > 1) {
        setState(() {
          _currentTextIndex = (_currentTextIndex + 1) % _actualLoadingTexts.length;
        });
      } else {
        timer.cancel(); // Cancel timer if not mounted or no texts to cycle
      }
    });
  }

  @override
  void dispose() {
    _heartbeatController.dispose();
    _textChangeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    String currentTextToShow = _actualLoadingTexts.isNotEmpty 
                              ? _actualLoadingTexts[_currentTextIndex % _actualLoadingTexts.length] 
                              : widget.initialText;
    if (currentTextToShow.isEmpty && widget.initialText.isNotEmpty) {
        currentTextToShow = widget.initialText;
    } else if (currentTextToShow.isEmpty) {
        currentTextToShow = "Loading..."; // Fallback if all else fails
    }


    return Container( // This widget is designed to be the child of a Dialog or centered on a screen
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        decoration: BoxDecoration(
            color: Theme.of(context).cardColor, // White card for the dialog content
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ]
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              "SafeMama", // This could also be a parameter if needed
              style: TextStyle(
                fontSize: screenWidth * 0.07,
                fontWeight: FontWeight.bold,
                color: _textAppColor, // Will now use AppColors.textDark
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            ScaleTransition(
              scale: _heartbeatAnimation,
              child: Icon(
                Icons.favorite,
                size: screenWidth * 0.15,
                color: _primaryAppColor,
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Text(
                currentTextToShow,
                key: ValueKey<String>(currentTextToShow), // Key on the text itself
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _textAppColor.withOpacity(0.9), // Will now use AppColors.textDark
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            if (_actualLoadingTexts.length > 1) ...[
              SizedBox(height: screenHeight * 0.03),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_actualLoadingTexts.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    height: 8.0,
                    width: _currentTextIndex == index ? 20.0 : 8.0,
                    decoration: BoxDecoration(
                      color: _currentTextIndex == index
                          ? _primaryAppColor
                          : _primaryAppColor.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  );
                }),
              ),
            ]
          ],
        ),
      );
  }
}

// Helper function to show this universal loading dialog
void showUniversalLoadingDialog(BuildContext context, {required List<String> texts, required String initialText}) {
  showDialog(
    context: context,
    barrierDismissible: false, // User cannot dismiss by tapping outside
    builder: (BuildContext dialogContext) {
      // Wrap UniversalLoadingWidget with Dialog for proper modal behavior
      // and to prevent system back button from dismissing it if not desired (though Android back button might still pop it depending on rootNavigator behavior)
      return PopScope( // Use PopScope for more control on dialog dismissal
        canPop: false, // Prevents accidental dismissal by back button, handle dismissal explicitly via hideUniversalLoadingDialog
        child: Dialog( 
          backgroundColor: Colors.transparent, // Dialog itself is transparent to show custom shape/shadows of child
          elevation: 0, // Elevation handled by UniversalLoadingWidget's container
          child: UniversalLoadingWidget(loadingTexts: texts, initialText: initialText),
        ),
      );
    },
  );
}

// Helper function to hide the universal loading dialog
void hideUniversalLoadingDialog(BuildContext context) {
  // Check if a dialog is currently shown by checking if the top-most route is a DialogRoute.
  // Navigator.of(context, rootNavigator: true).canPop() is a general check, 
  // but more specifically, we want to pop if it's our dialog.
  // For simplicity, we assume if canPop is true in the root navigator context, it's likely our dialog.
  // A more robust way might involve tracking if the dialog is shown.
  if (Navigator.of(context, rootNavigator: true).canPop()) {
     Navigator.of(context, rootNavigator: true).pop();
  }
}