import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcomeTitleNew => 'Your Safe Pregnancy Journey Starts Here!';

  @override
  String get welcomeSubtitleNew => 'Get personalized guidance, scan products, and stay informed every step of the way.';

  @override
  String get getStartedButton => 'Get Started';

  @override
  String get interactiveWelcomeTitle => 'SafeMama';

  @override
  String get interactiveWelcomeTagline => 'Guidance for your pregnancy journey, made easy.';

  @override
  String get loginFailedAfterSignupError => 'Account created, but auto sign-in failed. Please try logging in manually.';

  @override
  String get signupFailedErrorGeneral => 'Account creation failed. Please try again.';

  @override
  String get appTitle => 'SafeMama';

  @override
  String get welcomeScreenTitle => 'Welcome, Mommy!';

  @override
  String get welcomeScreenNewSubtitle => 'Let\'s keep your pregnancy safe — one scan at a time.';

  @override
  String get welcomeScreenSelectTrimesterPrompt => 'Select Your Trimester:';

  @override
  String get trimester1st => '1st Trimester';

  @override
  String get trimester1stWeeks => 'Weeks 1-12';

  @override
  String get trimester2nd => '2nd Trimester';

  @override
  String get trimester2ndWeeks => 'Weeks 13-26';

  @override
  String get trimester3rd => '3rd Trimester';

  @override
  String get trimester3rdWeeks => 'Weeks 27-40';

  @override
  String get allergySeafoodLabel => 'Seafood';

  @override
  String get personalizePregnancyTipPlaceholder => 'Stay hydrated! Aim to drink at least 8-10 glasses of water daily. This helps maintain amniotic fluid levels and can prevent dehydration, which can cause contractions.';

  @override
  String get loginScreenTitle => 'Login';

  @override
  String get welcomeBackTitle => 'Welcome Back!';

  @override
  String get loginSubtitle => 'Please enter your details to login';

  @override
  String get rememberMeLabel => 'Remember me';

  @override
  String get loginButtonLabel => 'Login';

  @override
  String get dontHaveAccountPrompt => 'Don\'t have an account?';

  @override
  String get signUpLink => 'Sign up';

  @override
  String get orContinueWithLabel => 'Or continue with';

  @override
  String get enterValidEmailError => 'Please enter a valid email address.';

  @override
  String get enterPasswordError => 'Please enter a password.';

  @override
  String get signupScreenTitle => 'Sign Up';

  @override
  String get joinSafeMamaTitle => 'Join SafeMama';

  @override
  String get signupSubtitle => 'Create an account to get started.';

  @override
  String get createPasswordLabel => 'Create Password';

  @override
  String get signUpButtonLabel => 'Sign Up & Continue';

  @override
  String get alreadyHaveAccountPromptShort => 'Already have an account?';

  @override
  String get loginLink => 'Login';

  @override
  String get signupSuccessConfirmationNeeded => 'Sign up successful! Please check your email to confirm your account.';

  @override
  String get signupSuccessLoggedIn => 'Signup successful! You are now logged in.';

  @override
  String get signupCompletedNoUserError => 'Sign up completed, but no user data received. Please try logging in.';

  @override
  String get enterPasswordMinLengthError => 'Password must be at least 6 characters';

  @override
  String get mamaFallbackName => 'Mama';

  @override
  String get homeScreenNewTitle => 'Dashboard';

  @override
  String get notificationsTooltip => 'Notifications';

  @override
  String get homeScreenNewSubtitle => 'Ready to scan your items?';

  @override
  String get homeDashboardScanFood => 'Scan Food or Medicine';

  @override
  String get homeDashboardScanFoodSub => 'Quick scan using camera';

  @override
  String get homeDashboardManualSearch => 'Manual Search';

  @override
  String get homeDashboardManualSearchSub => 'Search our database';

  @override
  String get homeDashboardScanHistory => 'Scan History';

  @override
  String get homeDashboardScanHistorySub => 'View past scans';

  @override
  String get homeDashboardProfile => 'Profile';

  @override
  String get homeDashboardProfileSub => 'Manage your account';

  @override
  String get homeDashboardGuideSub => 'Explore pregnancy tips';

  @override
  String get homeRecentScansTitle => 'Recent Scans';

  @override
  String get homeNoRecentScans => 'No recent scans yet. Start by scanning a product!';

  @override
  String get bottomNavScan => 'Scan';

  @override
  String get bottomNavSaved => 'Saved';

  @override
  String get scanProductScreenTitle => 'Scan Product';

  @override
  String get toggleFlashButtonLabel => 'Toggle flash';

  @override
  String get closeButtonLabel => 'Close';

  @override
  String get scanCameraUnavailable => 'Camera unavailable.';

  @override
  String get scanOpenSettingsButton => 'Open Settings';

  @override
  String get scanCenterProductLabel => 'Center the product label in frame';

  @override
  String get scanProductDetectedReady => 'Product detected! Ready to scan';

  @override
  String get scanEnsureLabelVisible => 'Ensure the product label is clearly visible';

  @override
  String get scanAlignProductPrompt => 'Align product in frame';

  @override
  String get scanProductAlignedPrompt => 'Product aligned! Ready to scan.';

  @override
  String get scanTakePhotoButton => 'Take Photo';

  @override
  String get scanUploadFromGalleryButton => 'Upload from Gallery';

  @override
  String get scanPrivacyProtected => 'Your privacy is protected. Images are processed securely.';

  @override
  String get scanProcessingImage => 'Processing image...';

  @override
  String get scanItemNotConsumableError => 'This item is not consumable. Please scan a valid food or medicine item.';

  @override
  String get unknownRisk => 'Unknown Risk';

  @override
  String get noDetailsProvided => 'No details provided.';

  @override
  String get noSpecificTip => 'No specific tip available.';

  @override
  String get scanAnalysisFailed => 'Failed to analyze product.';

  @override
  String get scanUnexpectedError => 'An unexpected error occurred.';

  @override
  String get scanConnectionError => 'Could not connect to the analysis server. Please try again later.';

  @override
  String scanAnalysisServerErrorParam(String details) => 'Analysis server error: $details';

  @override
  String get scanAnalysisServerError => 'Analysis server encountered an error. Please try again.';

  @override
  String scanRequestProblemParam(String details) => 'There was a problem with the request: $details';

  @override
  String get scanRequestProblem => 'There was a problem with the request. Please try again.';

  @override
  String get scanUnknownCameraError => 'Unknown camera error';

  @override
  String scanCaptureError(String details) => 'Error taking picture: $details';

  @override
  String get scanUnexpectedCaptureError => 'An unexpected error occurred during capture.';

  @override
  String scanGalleryPickError(String details) => 'Failed to pick image: $details';

  @override
  String scanCameraInitErrorParams(String description) => 'Could not initialize camera: $description';

  @override
  String get riskLevelSafe => 'Safe';

  @override
  String get riskLevelCaution => 'Use with Caution';

  @override
  String get riskLevelAvoid => 'Avoid';

  @override
  String get riskLevelUnknown => 'Unknown';

  @override
  String get saferAlternativesLabel => 'Safer Alternatives';

  @override
  String get shareDisclaimer => 'Disclaimer: This information is AI-generated and not a substitute for professional medical advice. Always consult your healthcare provider.';

  @override
  String get errorSharingContent => 'Could not share content at this time.';

  @override
  String get safetyTipsLabel => 'Safety Tips';

  @override
  String get scanResultSaveButton => 'Save to My List';

  @override
  String get scanResultSavedButton => 'Saved ✔';

  @override
  String get scanResultReadMoreButtonOld => 'Read More';

  @override
  String get pregnancyTipLabel => 'Pregnancy Tip';

  @override
  String get riskBannerSafeMessage => 'This product is generally considered safe during pregnancy.';

  @override
  String get riskBannerCautionMessage => 'Use this product with caution. Consult your doctor for advice.';

  @override
  String get riskBannerAvoidMessage => 'This product is best avoided during pregnancy.';

  @override
  String get riskBannerUnknownMessage => 'Safety information for this product is unknown or unclear. Consult your doctor.';

  @override
  String get profilePictureUpdatedSuccess => 'Profile picture updated successfully.';

  @override
  String get profileEmailCannotBeChanged => 'Email address cannot be changed here.';

  @override
  String get defaultUserName => 'Valued User';

  @override
  String profileMemberSincePlaceholder(String year) => 'Member since $year';

  @override
  String get emailNotificationsLabel => 'Email Notifications';

  @override
  String get emailNotificationsSubtitle => 'Receive updates and reminders';

  @override
  String get dataSharingLabel => 'Data Sharing';

  @override
  String get dataSharingSubtitle => 'Share anonymous data for research';

  @override
  String get dangerZoneTitle => 'Danger Zone';

  @override
  String get deleteAccountButton => 'Delete Account';

  @override
  String get deleteAccountSubtitle => 'Permanently remove your account and all data.';

  @override
  String get unknownProduct => 'Unknown Product';

  @override
  String get scanHistoryScreenTitle => 'Scan History';

  @override
  String get moreFiltersTooltip => 'More Filters';

  @override
  String get historySearchHint => 'Search in history...';

  @override
  String get filterAll => 'All';

  @override
  String get filterSafe => 'Safe';

  @override
  String get filterWarning => 'Warning';

  @override
  String get filterAvoid => 'Avoid';

  @override
  String historyErrorLoading(String errorDetails) => 'Error loading history: $errorDetails';

  @override
  String get historyNoScansYet => 'No Scans Yet';

  @override
  String get historyNoFilterResults => 'No Results Found';

  @override
  String get tagSafe => 'Safe';

  @override
  String get tagWarning => 'Warning';

  @override
  String get tagAvoid => 'Avoid';

  @override
  String get tagUnknown => 'Unknown';

  @override
  String get searchItemsScreenTitle => 'Search Items';

  @override
  String get searchItemsHint => 'Search products by name...';

  @override
  String get searchPromptStartTyping => 'Start typing to search for products.';

  @override
  String get searchNoResultsFound => 'No items found matching your search.';

  @override
  String get tagUseWithCaution => 'Caution';

  @override
  String get tagNotSafe => 'Avoid';

  @override
  String get tagInfo => 'Info';

  @override
  String get searchItemNoDescription => 'No description available.';

  @override
  String get helloMama => 'Hello, Mama!';

  @override
  String get homeScreenSubtitle => 'Instantly check what you\'re about to eat or take is pregnancy-safe.';

  @override
  String get scanProduct => 'Scan Product';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get uploadFromGallery => 'Upload from Gallery';

  @override
  String get welcomeScreenSubtitle => 'Your guide to safe choices during pregnancy. Instantly check food, medicine, and more.';

  @override
  String get selectYourTrimester => 'Select your trimester:';

  @override
  String get skip => 'Skip';

  @override
  String get scanFoodOrMedicine => 'Scan Food or Medicine';

  @override
  String get getInstantSafetyResults => 'Get instant safety results';

  @override
  String get personalizeTitle => 'Personalize Your Experience';

  @override
  String get savePreferences => 'Save Preferences';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get historyTitle => 'Scan History';

  @override
  String get alreadyHaveAccount => 'Already have an account? Login';

  @override
  String get profileSettingsTitle => 'Profile Settings';

  @override
  String get saveChangesTooltip => 'Save Changes';

  @override
  String get personalInformationTitle => 'Personal Information';

  @override
  String get emailLabel => 'Email Address';

  @override
  String get currentTrimesterLabel => 'Current Trimester';

  @override
  String get firstTrimester => 'First Trimester';

  @override
  String get secondTrimester => 'Second Trimester';

  @override
  String get thirdTrimester => 'Third Trimester';

  @override
  String get preferencesTitle => 'Preferences';

  @override
  String get languageSettingLabel => 'Language';

  @override
  String get notificationsSettingsLabel => 'Notifications';

  @override
  String get manageAlertsSubtitle => 'Manage alerts';

  @override
  String get dietaryPreferencesLabel => 'Dietary Preferences';

  @override
  String get allergiesLabel => 'Allergies';

  @override
  String get dataAndPrivacyTitle => 'Data & Privacy';

  @override
  String get clearScanHistoryButton => 'Clear Scan History';

  @override
  String get privacyPolicyButton => 'Privacy Policy';

  @override
  String get termsOfServiceButton => 'Terms of Service';

  @override
  String get signOutButton => 'Sign Out';

  @override
  String get profileSavedSuccess => 'Profile saved successfully!';

  @override
  String get profileSavedFailed => 'Failed to save profile.';

  @override
  String get clearScanHistoryDialogTitle => 'Clear Scan History?';

  @override
  String get clearScanHistoryDialogContent => 'Are you sure you want to delete all your saved scans and associated images? This action cannot be undone.';

  @override
  String get cancelButtonLabel => 'Cancel';

  @override
  String get clearHistoryButtonLabel => 'Clear History';

  @override
  String get errorUserNotAuthenticated => 'User not authenticated. Please log in.';

  @override
  String get scanHistoryClearedSuccess => 'Scan history cleared successfully.';

  @override
  String scanHistoryClearedFailed(String error) => 'Failed to clear history: $error';

  @override
  String get signOutDialogTitle => 'Sign Out?';

  @override
  String get signOutDialogContent => 'Are you sure you want to sign out?';

  @override
  String signOutFailed(String error) => 'Sign out failed: $error';

  @override
  String navigateToRoute(String routeName) => 'Navigate to $routeName (Not implemented yet)';

  @override
  String get selectLanguageDialogTitle => 'Select Language';

  @override
  String get english => 'English';

  @override
  String get hindi => 'Hindi';

  @override
  String get arabic => 'Arabic';

  @override
  String get loadingLabel => 'Loading...';

  @override
  String helloUser(String userName) => 'Hello, $userName!';

  @override
  String get manualSearchButtonLabel => 'Manual Search';

  @override
  String get scanHistoryButtonLabel => 'Scan History';

  @override
  String get profileButtonLabel => 'Profile';

  @override
  String get bottomNavHome => 'Home';

  @override
  String get bottomNavHistory => 'History';

  @override
  String get bottomNavGuide => 'Guides';

  @override
  String get bottomNavSettings => 'Settings';

  @override
  String get bottomNavAskExpert => 'Ask Expert';

  @override
  String get guideScreenTitle => 'Pregnancy Guide';

  @override
  String get guideNutritionTitle => 'Nutrition & Diet';

  @override
  String get guideNutritionTopicKeyNutrientsTitle => 'Key Nutrients';

  @override
  String get guideNutritionTopicKeyNutrientsContent => 'Focus on folic acid, iron, calcium, vitamin D, and protein. These are crucial for your baby\'s development and your health.';

  @override
  String get guideNutritionTopicFoodsToAvoidTitle => 'Foods to Avoid';

  @override
  String get guideNutritionTopicFoodsToAvoidContent => 'Avoid raw or undercooked meats, eggs, and seafood. Steer clear of unpasteurized dairy, certain types of fish high in mercury, and limit caffeine.';

  @override
  String get guideNutritionTopicHydrationTitle => 'Hydration';

  @override
  String get guideNutritionTopicHydrationContent => 'Drink plenty of water throughout the day (around 8-12 glasses). Proper hydration is essential for you and your baby.';

  @override
  String get guideMedicationsTitle => 'Medications & Supplements';

  @override
  String get guideMedicationsTopicConsultDoctorTitle => 'Always Consult Your Doctor';

  @override
  String get guideMedicationsTopicConsultDoctorContent => 'Never take any medication, herbal supplement, or over-the-counter drug without first consulting your healthcare provider.';

  @override
  String get guideMedicationsTopicGenerallySafeTitle => 'Generally Considered Safe (with Doctor\'s OK)';

  @override
  String get guideMedicationsTopicGenerallySafeContent => 'Some medications like acetaminophen (Tylenol) for pain, certain antacids, and prenatal vitamins are often considered safe, but always confirm with your doctor.';

  @override
  String get guideLifestyleTitle => 'Lifestyle & Wellbeing';

  @override
  String get guideLifestyleTopicExerciseTitle => 'Exercise';

  @override
  String get guideLifestyleTopicExerciseContent => 'Moderate exercise like walking, swimming, or prenatal yoga is generally beneficial. Avoid high-impact sports or activities with a risk of falling. Consult your doctor.';

  @override
  String get guideLifestyleTopicRestSleepTitle => 'Rest & Sleep';

  @override
  String get guideLifestyleTopicRestSleepContent => 'Aim for 7-9 hours of sleep. Listen to your body and rest when needed. Sleeping on your left side can improve circulation.';

  @override
  String get guideLifestyleTopicMorningSicknessTitle => 'Managing Morning Sickness';

  @override
  String get guideLifestyleTopicMorningSicknessContent => 'Eat small, frequent meals. Try bland foods like crackers. Ginger (tea, candies) and vitamin B6 may help. Stay hydrated. If severe, consult your doctor.';

  @override
  String homeScreenGreeting(String userName) => 'Hello, $userName!';

  @override
  String get homeScreenScanButton => 'Scan Food or Medicine';

  @override
  String get homeScreenManualSearch => 'Manual Search';

  @override
  String get homeScreenScanHistory => 'Scan History';

  @override
  String get homeScreenProfile => 'Profile';

  @override
  String get welcomeScreenFeatureScan => 'Scan any Food or Medicine';

  @override
  String get welcomeScreenFeatureResults => 'Get Instant Safety Results';

  @override
  String get alreadyHaveAccountLoginLink => 'Already have an account? Login';

  @override
  String get personalizeScreenTitle => 'Personalize Your Experience';

  @override
  String get savePreferencesTooltip => 'Save your preferences';

  @override
  String get personalizeScreenIntro => 'Help us provide you with safer, personalized recommendations.';

  @override
  String get personalizeSectionTrimester => 'Current Trimester';

  @override
  String get trimester1stTitle => '1st Trimester';

  @override
  String get trimester1stSubtitle => 'Weeks 1-12';

  @override
  String get trimester2ndTitle => '2nd Trimester';

  @override
  String get trimester2ndSubtitle => 'Weeks 13-26';

  @override
  String get trimester3rdTitle => '3rd Trimester';

  @override
  String get trimester3rdSubtitle => 'Weeks 27-40';

  @override
  String get personalizeSectionDiet => 'Dietary Preference';

  @override
  String get dietVegetarianLabel => 'Vegetarian';

  @override
  String get dietNonVegLabel => 'Non-Veg';

  @override
  String get dietVeganLabel => 'Vegan';

  @override
  String get personalizeSectionAllergies => 'Known Allergies';

  @override
  String get allergyNutsChip => 'Nuts';

  @override
  String get allergyDairyChip => 'Dairy';

  @override
  String get allergyEggsChip => 'Eggs';

  @override
  String get allergySoyChip => 'Soy';

  @override
  String get allergyNutsLabel => 'Nuts';

  @override
  String get allergyDairyLabel => 'Dairy';

  @override
  String get allergyEggsLabel => 'Eggs';

  @override
  String get allergySoyLabel => 'Soy';

  @override
  String get personalizeOtherAllergiesHint => 'Type other allergies (e.g., Gluten, Shellfish)';

  @override
  String get savePreferencesButton => 'Save & Continue';

  @override
  String get personalizeSaveSuccess => 'Preferences saved successfully!';

  @override
  String get personalizeSaveFailed => 'Failed to save preferences. Please try again.';

  @override
  String get pickFromGallery => 'Pick from Gallery';

  @override
  String get takeAPhoto => 'Take a Photo';

  @override
  String get profilePictureUploadFailed => 'Profile picture upload failed. Please try again.';

  @override
  String get scanResultsScreenTitle => 'Scan Results';

  @override
  String get riskLevelLabel => 'Risk Level';

  @override
  String get explanationLabel => 'Explanation';

  @override
  String get productLabel => 'Product';

  @override
  String get consumptionAdviceLabel => 'Consumption Advice';

  @override
  String get generalTipLabel => 'General Tip';

  @override
  String get shareWithDoctorButton => 'Share with Doctor';

  @override
  String get getSafeMamaAppPrompt => 'Get the SafeMama app for instant pregnancy safety checks:';

  @override
  String scanResultSubject(String productName) => 'SafeMama Scan Result: $productName';

  @override
  String get productScanned => 'Scanned Product';

  @override
  String get unknown => 'Unknown';

  @override
  String get notAvailable => 'N/A';

  @override
  String get genericSaveError => 'An error occurred. Please try again.';

  @override
  String get scanNotConsumableError => 'This item is not consumable. Please scan a valid food or medicine item.';

  @override
  String get scanNetworkError => 'Network error. Please check your connection and try again.';

  @override
  String get scanPermissionRequired => 'Camera permission is required to scan products.';

  @override
  String get scanEnableInSettings => 'Please enable it in your device\'s app settings.';

  @override
  String get scanCouldNotOpenSettings => 'Could not open app settings.';

  @override
  String get scanNoCamerasFound => 'No cameras found on this device.';

  @override
  String get scanCameraUnexpectedError => 'An unexpected error occurred while setting up the camera.';

  @override
  String scanFlashToggleError(String details) => 'Could not toggle flash: $details';

  @override
  String get scanFlashToggleFailed => 'Error toggling flash.';

  @override
  String get scanRequestTimeout => 'The request timed out. Please check your connection.';

  @override
  String get scanErrorUserNotLoggedIn => 'User not logged in. Cannot save to history.';

  @override
  String get tapFrameToAlignPrompt => 'Tap frame when product is aligned';

  @override
  String scannedTodayAt(String time) => 'Scanned today at $time';

  @override
  String get scannedYesterday => 'Scanned yesterday';

  @override
  String get homeErrorLoadingRecentScans => 'Could not load recent scans.';

  @override
  String get filterSaved => 'Saved';

  @override
  String historyNoFilterResultsForCategory(String categoryName) => 'No items found for "$categoryName".';

  @override
  String get historyNoScansYetSubtitle => 'Your scanned items will appear here.';

  @override
  String historyNoFilterResultsSubtitle(String searchTerm) => 'No items match your search for "$searchTerm".';

  @override
  String get historyErrorRefresh => 'Could not refresh history. Please try again.';

  @override
  String get alreadySavedMessage => 'This item is already in your saved list.';

  @override
  String get scanResultSavedToList => 'Saved to your list!';

  @override
  String errorSavingToList(String errorDetails) => 'Could not save to list: $errorDetails';

  @override
  String get errorDownloadingImageForShare => 'Could not download image for sharing.';

  @override
  String get scanResultMarkedAsSaved => 'Result saved!';

  @override
  String get scanResultButtonSaved => 'Saved';

  @override
  String get goToScanButtonLabel => 'Scan Product';

  @override
  String get tryDifferentFilterOrClear => 'Try a different filter or clear the current one.';

  @override
  String get historyRefreshed => 'History refreshed';

  @override
  String get retryButtonLabel => 'Retry';

  @override
  String get mobileNumberLabel => 'Mobile Number';

  @override
  String get countryLabel => 'Country';

  @override
  String get selectCountryPrompt => 'Select your country';

  @override
  String get passwordMinStrengthHint => 'Minimum 8 characters, 1 uppercase, 1 number.';

  @override
  String get agreeToTermsCheckbox => 'I agree to the';

  @override
  String get termsAndConditionsLink => 'Terms & Conditions';

  @override
  String get privacyPolicyLink => 'Privacy Policy';

  @override
  String get mustAgreeToTermsError => 'You must agree to the Terms & Conditions and Privacy Policy to continue.';

  @override
  String get otpSentSuccessfully => 'OTP sent successfully!';

  @override
  String get failedToSendOtp => 'Failed to send OTP. Please check the number and try again.';

  @override
  String get orSignUpWith => 'Or sign up with';

  @override
  String get otpVerificationTitle => 'OTP Verification';

  @override
  String enterOtpSentTo(String phoneNumber) => 'Enter the OTP sent to $phoneNumber';

  @override
  String get verifyOtpButtonLabel => 'Verify OTP';

  @override
  String get didNotReceiveOtpPrompt => 'Didn\'t receive the OTP?';

  @override
  String get resendOtpLink => 'Resend OTP';

  @override
  String resendOtpTimer(String minutes, String seconds) => 'Resend OTP in $minutes:$seconds';

  @override
  String get otpResentSuccessfully => 'OTP resent successfully!';

  @override
  String get failedToResendOtp => 'Failed to resend OTP. Please try again.';

  @override
  String get enterCompleteOtpError => 'Please enter the complete 6-digit OTP.';

  @override
  String get invalidOtpError => 'Invalid OTP. Please try again.';

  @override
  String profileCreationError(String error) => 'Failed to create your profile: $error';

  @override
  String get signupFailedNoUser => 'Signup failed. Could not create user.';

  @override
  String get enterFullNameError => 'Please enter your full name.';

  @override
  String get fullNameMinLengthError => 'Full name must be at least 3 characters.';

  @override
  String get searchCountryLabel => 'Search country';

  @override
  String get searchCountryHint => 'Start typing to search country';

  @override
  String get enterMobileNumberError => 'Please enter a valid mobile number.';

  @override
  String get enterValidMobileNumberError => 'Please enter a valid mobile number (7-15 digits).';

  @override
  String passwordMinLengthError(int minLength) => 'Password must be at least $minLength characters long.';

  @override
  String get passwordUppercaseError => 'Password must contain an uppercase letter.';

  @override
  String get passwordNumberError => 'Password must contain a number.';

  @override
  String get otpVerifiedSuccessfully => 'OTP verified successfully!';

  @override
  String get featureNotImplemented => 'This feature is not yet implemented.';

  @override
  String unexpectedError(String details) => 'An unexpected error occurred: $details';

  @override
  String signInFailedError(String details) => 'Sign-in failed: $details';

  @override
  String get tooManyRequestsError => 'Too many requests. Please try again later.';

  @override
  String get countryIsRequiredError => 'Country selection is required.';

  @override
  String get mobileNumberRequiredLabel => 'Mobile Number (Required for India)';

  @override
  String get mobileNumberOptionalLabel => 'Mobile Number (Optional)';

  @override
  String get enterOtpToFinalizeSignup => 'Enter OTP to finalize your signup.';

  @override
  String get createAccountToGetStarted => 'Create an account to get started.';

  @override
  String get sendOtpButtonLabel => 'Verify with WhatsApp OTP';

  @override
  String profileUpdateError(String error) => 'Profile update failed: $error';

  @override
  String get selectCountryPromptSocial => 'Please select your country before social sign-in.';

  @override
  String get loginFailedCheckCredentials => 'Login failed. Please check your email and password.';

  @override
  String get verifyMobileNumberTitle => 'Verify Mobile Number';

  @override
  String get verifyMobileIndiaPrompt => 'To continue, please verify your Indian mobile number.';

  @override
  String get enterValidIndianMobileError => 'Enter a valid 10-digit Indian mobile number.';

  @override
  String get sendOtpButtonLabelShort => 'Send OTP';

  @override
  String get verifyOtpAndContinueButton => 'Verify & Continue';

  @override
  String get phoneNumberVerifiedSuccess => 'Phone number verified successfully!';

  @override
  String get profileUpdateFailedError => 'Failed to update profile with phone verification.';

  @override
  String get personalizeTrimesterRequiredError => 'Please select your current trimester.';

  @override
  String get enterMobileNumberHint => 'Enter your 10-digit mobile number';

  @override
  String get skipForNowButton => 'Skip for now';

  @override
  String get bookmarkRemovedMessage => 'Removed from your list.';

  @override
  String errorUpdatingBookmark(String errorDetails) => 'Error updating bookmark: $errorDetails';

  @override
  String get removeBookmarkButtonLabel => 'Remove from List';

  @override
  String get addBookmarkButtonLabel => 'Save to List';

  @override
  String get loginToScan => 'Please log in to scan products.';

  @override
  String get deviceScanLimitTitle => 'Device Scan Limit Reached';

  @override
  String get deviceScanLimitMessage => 'This device has reached its free scan limit with other accounts. Please log in with an existing account or upgrade to premium for unlimited scans.';

  @override
  String get buttonUpgradeToPremium => 'Upgrade to Premium';

  @override
  String get paymentScreenNotImplemented => 'Payment screen not yet implemented.';

  @override
  String premiumFeatureDialogTitle(String featureName) => 'Unlock $featureName';

  @override
  String premiumFeatureDialogMessage(String featureName) => 'Upgrade to Premium to access the $featureName feature and get the best out of SafeMama!';

  @override
  String get scanLimitReachedTitle => 'Scan Limit Reached';

  @override
  String scanLimitReachedMessage(String count) => 'You\'ve used all your $count free scans. Upgrade to Premium for unlimited scans and more features!';

  @override
  String get detailedAnalysisFeatureName => 'Detailed Analysis';

  @override
  String get viewDetailedAnalysisPremiumButton => 'Full Analysis (Premium ✨)';

  @override
  String get scanResultReadMoreButton => 'View Full Analysis';

  @override
  String get filterHistoryTooltip => 'Filter history';

  @override
  String get advancedFiltersPremiumFeatureTitle => 'Advanced Filters';

  @override
  String get advancedFiltersPremiumFeatureMessage => 'Upgrade to premium to filter your scan history by risk level and bookmarks.';

  @override
  String get upgradeButtonLabel => 'Upgrade';

  @override
  String get tagCaution => 'Caution';

  @override
  String get filterScanHistoryTitle => 'Filter Scan History';

  @override
  String get filterByRiskLevelLabel => 'By Risk Level';

  @override
  String get filterShowBookmarkedOnlyLabel => 'Show Bookmarked Only';

  @override
  String get buttonClearFilters => 'Clear Filters';

  @override
  String get buttonApplyFilters => 'Apply Filters';

  @override
  String get historyNoResultsForAppliedFilters => 'No results match your current filters';

  @override
  String get homeDashboardAskExpert => 'Ask an Expert';

  @override
  String get homeDashboardAskExpertSub => 'AI-powered Q&A';

  @override
  String get askAnExpertTitle => 'Ask an Expert';

  @override
  String get askExpertDisclaimer => 'Ask our AI Expert about pregnancy, nutrition, or wellness. This is not a substitute for medical advice.';

  @override
  String get typeYourQuestionHint => 'Type your question here...';

  @override
  String get failedToGetAnswer => 'Failed to get an answerc. Please try again.';

  @override
  String get noGuidesAvailable => 'No guides available at the moment.';

  @override
  String get pregnancyGuideTitle => 'Pregnancy Guide';

  @override
  String get userProfileNotLoadedError => 'User profile could not be loaded. Please try again.';

  @override
  String get premiumFeatureLocked => 'This feature is for premium users only. Please upgrade to access.';

  @override
  String aiGuideGenerationFailedError(String topic) => 'Failed to generate AI guide for $topic. Showing available version.';

  @override
  String genericError(String details) => 'An error occurred: $details';

  @override
  String get premiumFeaturesInclude => 'Premium Benefits Include:';

  @override
  String get chooseYourPlanButton => 'Choose Your Plan';

  @override
  String get restorePurchasesButton => 'Restore Purchases';

  @override
  String get welcome_title_new => 'Welcome to SafeMama!';

  @override
  String get welcome_subtitle_new => 'Your trusted companion for a healthy pregnancy journey. Let\'s get started by personalizing your experience.';

  @override
  String get get_started_button => 'Get Started';

  @override
  String get whichTrimesterQuestion => 'Which trimester are you currently in?';

  @override
  String get trimesterFirst => 'First Trimester';

  @override
  String get trimesterSecond => 'Second Trimester';

  @override
  String get trimesterThird => 'Third Trimester';

  @override
  String get trimesterPlanningOrEarly => 'Planning / Early Stages';

  @override
  String get dietaryPreferencesTitle => 'Dietary Preferences';

  @override
  String get whatAreYourDietaryPreferencesQuestion => 'What are your dietary preferences?';

  @override
  String get dietNonVegetarian => 'Non-Vegetarian';

  @override
  String get dietVegetarian => 'Vegetarian';

  @override
  String get dietVegan => 'Vegan';

  @override
  String get dietPescatarian => 'Pescatarian';

  @override
  String get continueButton => 'Continue';

  @override
  String get knownAllergiesTitle => 'Known Allergies';

  @override
  String get anyKnownFoodAllergiesQuestion => 'Do you have any known food allergies?';

  @override
  String get helpsProvideSaferRecommendations => 'This helps us provide safer recommendations.';

  @override
  String get allergyNuts => 'Nuts';

  @override
  String get allergyDairy => 'Dairy';

  @override
  String get allergyGluten => 'Gluten';

  @override
  String get allergySoy => 'Soy';

  @override
  String get allergySeafood => 'Seafood';

  @override
  String get allergyEggs => 'Eggs';

  @override
  String get otherAllergiesLabel => 'Other Allergies (Optional)';

  @override
  String get otherAllergiesHint => 'e.g., Sesame, Mustard (comma-separated)';

  @override
  String get yourMainGoalTitle => 'Your Main Goal';

  @override
  String get whatIsYourMainGoalQuestion => 'What\'s your main goal for using SafeMama?';

  @override
  String get goalScanItems => 'Scan items to check safety';

  @override
  String get goalGetGuidance => 'Get daily pregnancy guidance';

  @override
  String get goalUnderstandNutrition => 'Understand nutritional needs';

  @override
  String get goalAskExpertAI => 'Ask expert questions (AI)';

  @override
  String get privacyMattersTitle => 'Your Privacy Matters to Us';

  @override
  String get privacyConsentSubtext => 'The information you provide helps us personalize SafeMama just for you. We\'re committed to keeping your data secure. You\'ll be able to review our full Privacy Policy before creating your account.';

  @override
  String get nextCreateAccountButton => 'Next: Create Your Account';

  @override
  String get createAccountTitle => 'Create Account';

  @override
  String get signInTitle => 'Sign In';

  @override
  String get signUpButton => 'Sign Up';

  @override
  String get signInButton => 'Sign In';

  @override
  String get fullNameLabel => 'Full Name';

  @override
  String get validatorFullNameRequired => 'Full name is required.';

  @override
  String get emailAddressLabel => 'Email Address';

  @override
  String get validatorEmailRequired => 'Email is required.';

  @override
  String get validatorInvalidEmail => 'Please enter a valid email.';

  @override
  String get selectCountryHint => 'Select Your Country';

  @override
  String get mobileNumberLabelOptional => 'Mobile Number (Optional for OTP)';

  @override
  String get validatorMobileRequiredForIndia => 'Mobile number is required for India.';

  @override
  String get passwordLabel => 'Password';

  @override
  String get validatorPasswordRequired => 'Password is required.';

  @override
  String get termsAndPolicyAgreement => 'By signing up, you agree to our Terms & Conditions and Privacy Policy.';

  @override
  String get signUpAndContinueButton => 'Sign Up & Continue';

  @override
  String get forgotPasswordLink => 'Forgot Password?';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get signInWithGoogle => 'Sign In with Google';

  @override
  String get signupSuccessCheckEmail => 'Signup successful! Please check your email to verify your account.';

  @override
  String get signupFailedError => 'Signup failed';

  @override
  String get loginFailedInvalidCredentials => 'Login failed. Please check your email and password.';

  @override
  String get loginFailedError => 'Login failed';

  @override
  String get googleSignInFailed => 'Google Sign-In failed';

  @override
  String get yourMobileNumberDefaultText => 'your mobile number';

  @override
  String get loadingButtonText => 'Loading...';

  @override
  String get verifyAndCreateAccountButton => 'Verify & Create Account';

  @override
  String get backToEditDetailsLink => 'Back to Edit Details';

  @override
  String get chooseVerificationMethodTitle => 'Choose your verification method';

  @override
  String get createAccountWithEmailLabel => 'Create Account with Email';

  @override
  String get orDividerText => '------ OR ------';

  @override
  String get alreadyHaveAccountPrompt => 'Already have an account?';

  @override
  String get signupSuccessAccountCreatedSignIn => 'Account created successfully! Please sign in.';

  @override
  String get genericSearchError => 'An error occurred while searching.';

  @override
  String get scanLogFailedError => 'Failed to save scan information. Please try again.';

  @override
  String get scanErrorUserProfileNotFound => 'Error: User profile not found. Please re-login.';

  @override
  String get scanFreeScansExhaustedTitle => 'Free Scans Exhausted';

  @override
  String scanFreeScansExhaustedMessage(int scanLimit) => 'You have used all your $scanLimit free scans. Upgrade to Premium for unlimited scans and more features!';

  @override
  String get genericErrorLoadingScan => 'Oops! We couldn\'t load the scan details.';

  @override
  String get genericErrorLoadingScanDetails => 'Error processing scan details. Please try again.';

  @override
  String get genericErrorInvalidScanData => 'Invalid scan data received. Please go back and try scanning again.';

  @override
  String get scanResultsTitle => 'Scan Result';

  @override
  String get scanNotFound => 'Scan not found.';

  @override
  String get emailAlreadyRegisteredError => 'This email address is already registered. Please try signing in.';

  @override
  String get tryAgainButtonLabel => 'Try Again';

  @override
  String get emailNotConfirmedError => 'Your email is not confirmed. Please check your inbox or resend confirmation.';

  @override
  String get tipFirstTrimester => 'Focus on folic acid intake. It\'s vital for your baby\'s early development!';

  @override
  String get tipSecondTrimester => 'Feeling more energetic? Gentle exercise like walking is great for you and baby.';

  @override
  String get tipThirdTrimester => 'Prepare your hospital bag and learn about signs of labor. You\'re getting close!';

  @override
  String get tipGeneral => 'Stay positive and listen to your body. Every day is a step closer to meeting your little one!';

  @override
  String get tipForYouToday => '💡 Tip for You Today';

  @override
  String get homePregnancyJourneyTitle => 'Your Journey';

  @override
  String get homeCalendarComingSoon => 'Full calendar view coming soon!';

  @override
  String get onboarding_slide1_title => 'Welcome to SafeMama';

  @override
  String get onboarding_slide1_subtitle => 'Your trusted companion for a healthy and informed pregnancy journey.';

  @override
  String get onboarding_slide2_title => 'Personalized For You';

  @override
  String get onboarding_slide2_subtitle => 'Access tailored guidance, track scans, and explore expert tips.';

  @override
  String get onboarding_slide3_title => 'Instant Safety Checks';

  @override
  String get onboarding_slide3_subtitle => 'Quickly scan food and medicine labels for immediate peace of mind.';

  @override
  String get onboarding_slide4_title => 'Clear, Actionable Advice';

  @override
  String get onboarding_slide4_subtitle => 'Understand safety with easy-to-read results and helpful information.';

  @override
  String get nextButton => 'Next';

  @override
  String get aiPersonalizedGuideScreenTitle => 'AI Personalized Guide';

  @override
  String get aiPersonalizedGuideComingSoon => 'Your AI-generated personalized pregnancy guide content will appear here soon!\n(Premium Feature - AI generation backend logic is pending)';

  @override
  String get journeyingBeyondDueDate => 'Journeying beyond due date!';

  @override
  String get dueToday => 'Due today!';

  @override
  String approxDaysLeft(int days) => 'Approx. $days days left!';

  @override
  String currentTrimesterStatus(String trimesterDisplay) => 'You\'re in your $trimesterDisplay.';

  @override
  String approxWeek(String currentWeek) => 'Approx. Week: $currentWeek';

  @override
  String calendarSnippetInfoComingSoon(String date) => 'More info for $date coming soon!';

  @override
  String get calendarSnippetTitle => 'Your Week at a Glance';

  @override
  String get drawerAiPersonalizedGuide => 'AI Personalized Guide';

  @override
  String get aiGuideErrorTopicEmpty => 'Please enter a topic for the guide.';

  @override
  String get aiGuideErrorInvalidResponse => 'Invalid response format from the server.';

  @override
  String aiGuideErrorFailedToGenerate(String statusCode) => 'Failed to generate guide. Server responded with status: $statusCode.';

  @override
  String get aiGuideTopicInputLabel => 'Enter guide topic';

  @override
  String get aiGuideTopicInputHint => 'e.g., Nutrition in first trimester';

  @override
  String get clearInputTooltip => 'Clear input';

  @override
  String get aiGuideGenerateButton => 'Generate Guide';

  @override
  String get aiGuideInitialPrompt => 'Enter a topic above and tap \'Generate Guide\' to get your personalized AI insights.';

  @override
  String get manualSearchScreenTitle => 'Manual Search';

  @override
  String get searchButtonLabel => 'Search';

  @override
  String premiumSearchComingSoonTitle(String searchTerm) => 'AI-Powered Search for "$searchTerm"';

  @override
  String get premiumSearchComingSoonMessage => 'Full database results with AI insights coming soon for Premium users!';

  @override
  String get freeSearchLimitMessage => 'You\'re searching your scan history. For a full AI-powered database search, upgrade to Premium!';

  @override
  String get buttonUpgrade => 'Upgrade';

  @override
  String searchNoResultsInHistory(String searchTerm) => 'No results found in your scan history for "$searchTerm".';

  @override
  String get searchItemNoAdditionalInfo => 'No additional information available.';

  @override
  String get aiGuideErrorUnknown => 'An unknown error occurred while generating the guide.';

  @override
  String aiGuideErrorUnexpected(String details) => 'An unexpected error occurred: $details';

  @override
  String get modalOptionBookmarked => 'Bookmarked Items';

  @override
  String get modalOptionScanFood => 'Scan Food / Medicine';

  @override
  String get modalOptionRecentScans => 'Recent Scans';

  @override
  String get modalOptionGuide => 'Pregnancy Guide';

  @override
  String get fabTooltipMain => 'Quick Actions';

  @override
  String get preScanSlide1Title => 'Clear View is Key';

  @override
  String get preScanSlide1Subtitle => 'Ensure the item is well-lit and in focus.';

  @override
  String get preScanSlide2Title => 'Capture All Text';

  @override
  String get preScanSlide2Subtitle => 'For labels, make sure all ingredients are visible.';

  @override
  String get preScanSlide3Title => 'One Item for Best Results';

  @override
  String get preScanSlide3Subtitle => 'Scan individual items for accurate analysis.';

  @override
  String get preScanGuideScreenTitle => 'Quick Scan Guide';

  @override
  String get preScanGuideStartScanningButton => 'Start Scanning';

  @override
  String get profileDueDateLabel => 'Due Date';

  @override
  String get profileNoDueDateSet => 'Tap to set your due date';

  @override
  String get profileSetDueDateButton => 'Set Due Date';

  @override
  String get profileChangeDueDateButton => 'Change Due Date';

  @override
  String get profileClearDueDateButton => 'Clear Due Date';

  @override
  String get okButtonLabel => 'OK';

  @override
  String get homeCalendarSnippetTitle => 'Your Pregnancy Journey';

  @override
  String get homeCalendarSnippetAddDueDatePrompt => 'Add your due date in Profile Settings to get weekly updates on your baby\'s development!';

  @override
  String get homeCalendarSnippetGoToSettingsButton => 'Go to Settings';

  @override
  String homeCalendarSnippetWeekDataUnavailable(String weekNumber) => 'Information for Week $weekNumber is currently unavailable.';

  @override
  String homeCalendarSnippetCurrentWeekTitle(String weekNumber) => 'Week $weekNumber';

  @override
  String get homeCalendarTapForMore => 'Tap for more details';

  @override
  String get homeCalendarBabySizeLabel => 'Baby\'s Size';

  @override
  String get homeCalendarKeyDevelopmentLabel => 'Key Development';

  @override
  String homeCalendarSnippetWeekDetailTitle(String weekNumber) => 'Week $weekNumber Highlights';

  @override
  String get closeButton => 'Close';

  @override
  String get errorProcessingScan => 'Error processing scan. Please try again.';

  @override
  String get commonDialogCloseButton => 'Close';

  @override
  String homeCalendarSnippetBabySize(String sizeComparison) => 'Baby is about the size of a $sizeComparison.';

  @override
  String get homeCalendarDialogBabySizeLabel => 'Baby\'s Size:';

  @override
  String get homeCalendarDialogDevelopmentHighlightsLabel => 'Baby\'s Development:';

  @override
  String get cameraScreenTitle => 'Scan Item';

  @override
  String get cameraModePhoto => 'Photo';

  @override
  String get cameraModeBarcode => 'Barcode';

  @override
  String get cameraModeLabel => 'Label';

  @override
  String get cameraModeGallery => 'Gallery';

  @override
  String get cameraOverlayAlignLabel => 'Align label within the frame';

  @override
  String get loginRequiredError => 'Login is required to perform this action.';

  @override
  String get premiumFeatureDialogUnlockPrompt => 'Upgrade to unlock:';

  @override
  String get commonDialogCancelButton => 'Cancel';

  @override
  String get premiumFeatureDialogUpgradeButton => 'Upgrade Now';

  @override
  String get barcodeDetectedTitle => 'Barcode Detected';

  @override
  String get barcodeValueLabel => 'Value';

  @override
  String get commonDialogOkButton => 'OK';

  @override
  String get cameraGalleryModeActive => 'Select image from gallery...';

  @override
  String get cameraOverlayAlignBarcode => 'Center barcode in the box';

  @override
  String searchNoResultsMessage(String searchTerm) => 'No results found for \'$searchTerm\'.';

  @override
  String get unknownProductName => 'Unknown Product';

  @override
  String get appLoadingMessage => 'Preparing your journey...';

  @override
  String get processingScanMessage => 'Processing your scan...';

  @override
  String get appLoadingMessage1 => 'Hold on, we\'re checking what\'s best for you and your baby...';

  @override
  String get appLoadingMessage2 => 'Analyzing vital information...';

  @override
  String get appLoadingMessage3 => 'Preparing your personalized guidance...';

  @override
  String get appLoadingMessage4 => 'Almost there, excitement is building!';

  @override
  String get scanResultErrorNoIdDetails => 'Could not load scan results: Invalid or missing scan information. Please try scanning again.';

  @override
  String get genericErrorProcessingRequest => 'Cannot process request: data unavailable.';

  @override
  String get unknownText => 'Unknown';

  @override
  String get detailedAnalysisNoSummary => 'No summary provided for this product.';

  @override
  String get unknownIngredient => 'Unknown Ingredient';

  @override
  String get unknownAlternative => 'Unknown Alternative';

  @override
  String get detailedAnalysisErrorDecoding => 'Error: Could not process the analysis data.';

  @override
  String get detailedAnalysisNotAvailable => 'Detailed analysis is not available for this product.';

  @override
  String get detailedAnalysisTitle => 'Detailed Analysis';

  @override
  String get specificConcernsTitle => 'Specific Concerns for Pregnancy';

  @override
  String get referencesTitle => 'References & Sources';

  @override
  String get ingredientsAnalysisTitle => 'Ingredients Analysis';

  @override
  String get notesLabel => 'Notes';

  @override
  String get detailedAnalysisNoNotes => 'No additional notes available.';

  @override
  String get nutritionalInformationTitle => 'Nutritional Information';

  @override
  String get suggestedAlternativesTitle => 'Suggested Alternatives';

  @override
  String get bookmarkingNotAvailableForSearch => 'Bookmarking directly from search results is not yet available. View the full scan to bookmark.';

  @override
  String get errorToggleBookmark => 'Failed to update bookmark';

  @override
  String get itemBookmarkedSuccessfully => 'Item bookmarked successfully!';

  @override
  String get itemUnbookmarkedSuccessfully => 'Item unbookmarked successfully!';

  @override
  String get ingredientsLabel => 'Ingredients';

  @override
  String get nutrientsLabel => 'Nutrients';

  @override
  String get warningsLabel => 'Warnings';

  @override
  String get alternativesLabel => 'Alternatives';

  @override
  String get detailedAnalysisButton => 'View Detailed Analysis';

  @override
  String get errorLoadingScanDetails => 'Could not load scan details.';

  @override
  String get bookmarkItemTooltip => 'Bookmark this item';

  @override
  String get unbookmarkItemTooltip => 'Remove bookmark';

  @override
  String get tagNeedsMoreInfo => 'More Info Needed';

  @override
  String get categoryLabel => 'Category';

  @override
  String get cameraGalleryModeActiveWhenProcessing => 'Processing selected image...';

  @override
  String get processingScanMessage1 => 'Processing your scan...';

  @override
  String get processingScanMessage2 => 'Analyzing image details...';

  @override
  String get processingScanMessage3 => 'Checking safety information...';

  @override
  String get processingScanMessage4 => 'Consulting our knowledge base...';

  @override
  String get processingScanMessage5 => 'Cross-referencing safety data...';

  @override
  String get processingScanMessage6 => 'Finalizing your personalized insights...';

  @override
  String get paymentStatusTitleReceived => 'Payment Received';

  @override
  String get paymentStatusMsg1Received => 'Your payment is being confirmed.';

  @override
  String get paymentStatusMsg2Received => 'We\'re preparing to activate your plan.';

  @override
  String get paymentStatusProcessingShort => 'Processing...';

  @override
  String get paymentStatusTitleProcessing => 'Activating Your Plan';

  @override
  String get paymentStatusMsg1Processing => 'Your premium membership is being activated.';

  @override
  String get paymentStatusMsg2Processing => 'Thank you for trusting SafeMama.';

  @override
  String paymentStatusProcessingLong(String seconds) => 'Processing: $seconds seconds remaining';

  @override
  String get paymentStatusTitleSuccessful => 'Payment Successful';

  @override
  String get paymentStatusMsg1Successful => 'Your premium benefits are now available.';

  @override
  String get paymentStatusMsg2Successful => 'All features unlocked for a healthier pregnancy journey!';

  @override
  String get paymentStatusProcessingComplete => 'Complete!';

  @override
  String get paymentStatusTitleFailed => 'Payment Failed';

  @override
  String get paymentStatusMsg1Failed => 'Unfortunately, your payment could not be processed.';

  @override
  String get paymentStatusMsg2Failed => 'Please try again or contact support if the issue persists.';

  @override
  String get paymentStatusProcessingFailed => 'Failed';

  @override
  String paymentStatusRedirectingIn(String seconds) => 'Redirecting in $seconds seconds...';

  @override
  String get paymentStatusProceedButton => 'Proceed to Dashboard';

  @override
  String get paymentStatusTryAgainButton => 'Try Again';

  @override
  String get paymentGatewayTitle => 'Secure Payment';

  @override
  String get paymentCancelConfirmTitle => 'Cancel Payment?';

  @override
  String get paymentCancelConfirmMsg => 'Are you sure you want to cancel the payment process?';

  @override
  String get commonDialogNo => 'No';

  @override
  String get commonDialogYes => 'Yes';

  @override
  String get paymentPageLoadError => 'Failed to load payment page. Please check your internet connection and try again.';

  @override
  String get paymentStatusMsg1Received_alt => 'Your payment is being processed.';

  @override
  String get paymentStatusMsg2Received_alt_ps => 'We\'re activating your plan now!';

  @override
  String get paymentStatusMsg1Processing_alt => 'Your payment is being processed.';

  @override
  String get paymentStatusMsg2Processing_alt_ps => 'Your premium membership will be activated soon.\nThank you for trusting SafeMama.\nYour premium benefits will be available shortly!\nAll features unlocked for a healthier pregnancy journey!';

  @override
  String get paymentStatusMsg1Successful_alt => 'Your payment has been processed.';

  @override
  String get paymentStatusMsg2Successful_alt_ps => 'Your premium membership is now active!\nThank you for trusting SafeMama.\nYour premium benefits are available immediately.\nAll features unlocked for a healthier pregnancy journey!';

  @override
  String get paymentStatusMsg1Failed_alt_ps => 'Unfortunately, your payment could not be processed.\nPlease try again or contact support.';

  @override
  String get bottomNavAIGuide => 'AI Guide';

  @override
  String get voiceSearchNotAvailable => 'Voice search is not available at the moment.';

  @override
  String get searchByVoiceTooltip => 'Search by voice';

  @override
  String get searchResultsSectionHistory => 'From Your Scan History';

  @override
  String get searchResultsSectionAI => 'AI Search Results';

  @override
  String get freeSearchAiPrompt => 'Upgrade to Premium to get AI-powered search results for any item.';

  @override
  String get aiGuideErrorNoContent => 'No guide could be generated for this topic. Please try another one or refine your topic.';

  @override
  String get drawerAIPersonalizedGuide => 'AI Personalized Guide';

  @override
  String get forgotPasswordTitle => 'Forgot Password';

  @override
  String get forgotPasswordInstructions => 'Enter your account\'s email address and we will send you a link to reset your password.';

  @override
  String get sendResetLinkButton => 'Send Reset Link';

  @override
  String get passwordResetLinkSentTitle => 'Check Your Email';

  @override
  String passwordResetLinkSentMessage(String email) => 'A password reset link has been sent to $email. Please follow the instructions in the email to set a new password.';

  @override
  String get passwordResetFailedError => 'Failed to send password reset link. Please try again.';

  @override
  String get ok => 'OK';

  @override
  String get getStarted => 'Get Started';

  @override
  String get welcomeTitle1 => 'Scan Products Instantly';

  @override
  String get welcomeDesc1 => 'Get immediate safety information on food and medicine by scanning barcodes.';

  @override
  String get welcomeTitle2 => 'Personalized for You';

  @override
  String get welcomeDesc2 => 'Receive expert-written guides and insights tailored to your pregnancy trimester.';

  @override
  String get welcomeTitle3 => 'Ask an Expert';

  @override
  String get welcomeDesc3 => 'Get answers to your pregnancy questions from our friendly AI-powered assistant.';

  @override
  String get welcomeTitle4 => 'Your Journey, Supported';

  @override
  String get welcomeDesc4 => 'Track your progress and stay informed every step of the way. Welcome to SafeMama.';

  @override
  String get forgotPasswordPhoneInstructions => 'Enter the phone number you registered with to receive a password reset OTP.';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get sendOtpButton => 'Send OTP';

  @override
  String get otpLabel => 'OTP Code';

  @override
  String get newPasswordLabel => 'New Password';

  @override
  String get confirmNewPasswordLabel => 'Confirm New Password';

  @override
  String get resetPasswordButton => 'Reset Password';

  @override
  String get taskInProgressLoadingMessage => 'Processing, please wait...';

  @override
  String get scanLimitReached => 'Scan Limit Reached';

  @override
  String get consentScreenTitle => 'Consent & Preferences';

  @override
  String get consentScreenSubtitle => 'Help us personalize your experience';

  @override
  String get emailNotificationsTitle => 'Email Notifications';

  @override
  String get emailNotificationsDescription => 'Receive updates about your pregnancy journey';

  @override
  String get dataSharingTitle => 'Data Sharing';

  @override
  String get dataSharingDescription => 'Help improve our service by sharing anonymous data';

  @override
  String get consentRequiredError => 'Please enable at least one option to continue';

  @override
  String get freeLimitReachedMessage => 'You\'ve used all your free scans.';

  @override
  String get limitsResetMonthly => 'Your free limits will reset on the 1st of next month.';

  @override
  String get upgradeForMore => 'Upgrade to Premium for more features!';

  @override
  String get premiumLimitReachedMessage => 'You have used all your scans for this period. Your limits will reset at the start of your next billing cycle.';

  @override
  String get buttonUpgradeNow => 'Upgrade Now';

  @override
  String get buttonCancel => 'Cancel';

}
