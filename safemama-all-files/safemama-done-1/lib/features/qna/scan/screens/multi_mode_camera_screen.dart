// lib/features/scan/screens/multi_mode_camera_screen.dart
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:safemama/core/constants/app_constants.dart';
import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/core/widgets/paywall_dialog.dart';
import 'package:safemama/features/qna/scan/widgets/scan_in_progress_widget.dart';
import 'package:safemama/l10n/app_localizations.dart';
import 'package:safemama/core/constants/app_colors.dart';
import 'package:safemama/navigation/app_router.dart';
import 'package:safemama/core/services/api_service.dart';
import 'package:safemama/core/services/scan_history_service.dart';
import 'package:safemama/core/providers/app_providers.dart';
import 'package:safemama/core/models/scan_data.dart';


enum CameraScanMode { photo, gallery }

class MultiModeCameraScreen extends ConsumerStatefulWidget {
  const MultiModeCameraScreen({super.key});

  @override
  ConsumerState<MultiModeCameraScreen> createState() => _MultiModeCameraScreenState();
}

class _MultiModeCameraScreenState extends ConsumerState<MultiModeCameraScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  CameraScanMode _currentMode = CameraScanMode.photo;
  FlashMode _currentFlashMode = FlashMode.off;
  bool _isProcessing = false;

  final ImagePicker _picker = ImagePicker();
  late ApiService _apiService;
  late ScanHistoryService _scanHistoryService;

  @override
  void initState() {
    super.initState();
    _apiService = ref.read(apiServiceProvider);
    _scanHistoryService = ref.read(scanHistoryServiceProvider);
    WidgetsBinding.instance.addObserver(this);
    if (_currentMode == CameraScanMode.photo) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
      if (mounted) setState(() => _isCameraInitialized = false);
    } else if (state == AppLifecycleState.resumed) {
      if (_currentMode == CameraScanMode.photo) _initializeCamera(cameraController.description);
    }
  }

  Future<void> _initializeCamera([CameraDescription? cameraDescription]) async {
    if (_currentMode != CameraScanMode.photo) {
        if (mounted) setState(() => _isCameraInitialized = false);
        await _cameraController?.dispose(); _cameraController = null; return;
    }
    if (_cameras == null || _cameras!.isEmpty) {
      try { _cameras = await availableCameras(); } catch (e) {
        print("Error fetching cameras: $e"); if (mounted) setState(() => _isCameraInitialized = false); return;
      }
      if (_cameras!.isEmpty) { print("No cameras available"); if (mounted) setState(() => _isCameraInitialized = false); return;}
    }
    final CameraDescription selectedCamera = cameraDescription ?? _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back, orElse: () => _cameras!.first);
    if (_cameraController != null && _cameraController!.description.name == selectedCamera.name && _cameraController!.value.isInitialized) {
      if(mounted) setState(() => _isCameraInitialized = true); return;
    }
    await _cameraController?.dispose();
    _cameraController = CameraController( selectedCamera, ResolutionPreset.high, enableAudio: false, imageFormatGroup: ImageFormatGroup.jpeg);
    try {
      await _cameraController!.initialize(); await _cameraController!.setFlashMode(_currentFlashMode);
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) { print("Error initializing camera: $e"); if (mounted) setState(() => _isCameraInitialized = false);}
  }

  Future<File?> _compressImage(String filePath) async {
    Directory tempDir = await getTemporaryDirectory();
    String targetFileName = "${DateTime.now().millisecondsSinceEpoch}_${p.basename(filePath)}";
    if (!targetFileName.toLowerCase().endsWith('.jpg') && !targetFileName.toLowerCase().endsWith('.jpeg')) {
        targetFileName = "${p.basenameWithoutExtension(targetFileName)}.jpg";
    }
    String targetPath = p.join(tempDir.path, targetFileName);

    print("[CompressImage] Original path: $filePath");
    print("[CompressImage] Target compressed path: $targetPath");

    try {
      final XFile? result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        targetPath,
        quality: 70,
        minWidth: 1080,
        minHeight: 1920,
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        File originalFile = File(filePath);
        File compressedFile = File(result.path);
        print("[CompressImage] Original size: ${originalFile.existsSync() ? originalFile.lengthSync() : 'N/A'} bytes");
        print("[CompressImage] Compressed size: ${compressedFile.lengthSync()} bytes to ${result.path}");
        return compressedFile;
      }
      print("[CompressImage] Compression returned null.");
      return null;
    } catch (e) {
      print("[CompressImage] Error during compression: $e");
      return null;
    }
  }

  Future<void> _processImageAndNavigate(String imagePath) async {
    if (!mounted) return;
    final S = AppLocalizations.of(context)!;
    final routerContext = AppRouter.rootNavigatorKey.currentContext; 
    
    if (routerContext == null) {
        print("[ProcessImage] Aborting: Root navigator context is null.");
        return;
    }

    if (mounted) setState(() => _isProcessing = true);

    // ===================================================================
    // =========== THIS IS THE ONLY LINE THAT HAS BEEN CHANGED ===========
    // ===================================================================
    // We now push our new, beautiful, custom loading screen.
    // We create a custom PageRoute for a clean full-screen presentation.
    Navigator.of(routerContext).push(
      MaterialPageRoute(builder: (context) => const ScanInProgressWidget()),
    );
    // ===================================================================
    // ======================= END OF CHANGED LINE =======================
    // ===================================================================

    final userProfileProvider = ref.read(userProfileNotifierProvider);
    final String? userId = userProfileProvider.userProfile?.id;

    if (userId == null) {
      if (mounted) {
        if (GoRouter.of(routerContext).canPop()) GoRouter.of(routerContext).pop();
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.loginRequiredError)));
      }
      return;
    }

    String? finalScanId;

    try {
      File? compressedFile = await _compressImage(imagePath);
      if (!mounted) return;

      File imageToUpload = compressedFile ?? File(imagePath);

      final Map<String, dynamic> analysisJson = await _apiService.analyzeProductImage(imageToUpload);
      if (!mounted) return;

      final Map<String, dynamic> rawOpenAiResponseForLog = analysisJson;

      final ScanData? loggedScanData = await _scanHistoryService.logScanToHistory(
        rawParsedOpenAiResponse: rawOpenAiResponseForLog,
        userId: userId,
        localImagePathToUpload: imageToUpload.path,
        isBookmarkedInitially: false,
      );
      if (!mounted) return;

      if (loggedScanData == null || loggedScanData.id == null || loggedScanData.id!.isEmpty) {
        throw Exception(S.errorProcessingScan);
      }

      finalScanId = loggedScanData.id!;
      
      await ref.read(userProfileNotifierProvider.notifier).loadUserProfile();
      if (!mounted) return;

      if (GoRouter.of(routerContext).canPop()) {
           GoRouter.of(routerContext).pop();
      }

      if (mounted) {
          setState(() => _isProcessing = false);
          GoRouter.of(routerContext).pushReplacement(AppRouter.scanResultsPath, extra: finalScanId);
      }
    } catch (e) {
      print("[ProcessImage] CAUGHT ERROR for path $imagePath: $e");
      if (!mounted) return;
      
      if (GoRouter.of(routerContext).canPop()) GoRouter.of(routerContext).pop();
      setState(() => _isProcessing = false);
      
      final errorMessage = e.toString();

      if (errorMessage.contains('limitReached: true') || errorMessage.contains('LIMIT_REACHED')) {
        final userProfile = ref.read(userProfileNotifierProvider).userProfile;
        final isFreeUser = (userProfile?.membershipTier ?? 'free') == 'free';
        
        CustomPaywallDialog.showScanLimitDialog(
          context,
          isFreeUser: isFreeUser,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.errorProcessingScan)));
      }
    }
  }

  Future<void> _onTakePicturePressed() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized ||
        _cameraController!.value.isTakingPicture || _isProcessing) {
      return;
    }
    try {
      final XFile imageFile = await _cameraController!.takePicture();
      if (mounted) {
        _processImageAndNavigate(imageFile.path);
      }
    } catch (e) {
      print("Error taking picture: $e");
      if (mounted && _isProcessing) {
            final routerContext = AppRouter.rootNavigatorKey.currentContext ?? context;
            if (GoRouter.of(routerContext).canPop()) {
                 GoRouter.of(routerContext).pop();
            }
            setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _onPickFromGalleryPressed() async {
    if (_isProcessing) return;
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        _processImageAndNavigate(image.path);
      }
    } catch (e) {
      print("Error picking image from gallery: $e");
       if (mounted) {
         if (_isProcessing) { 
            final routerContext = AppRouter.rootNavigatorKey.currentContext ?? context;
            if (GoRouter.of(routerContext).canPop()) {
                 GoRouter.of(routerContext).pop();
            }
            setState(() => _isProcessing = false);
         }
         final S = AppLocalizations.of(context);
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.errorProcessingScan)));
      }
    }
  }

  void _changeCameraMode(CameraScanMode mode) async {
    if (_currentMode == mode || _isProcessing) return;

    if (mounted) { 
        setState(() => _currentMode = mode);
    }

    if (mode == CameraScanMode.photo) {
      await _initializeCamera();
    } else if (mode == CameraScanMode.gallery) {
      await _cameraController?.dispose();
      _cameraController = null;
      if (mounted) setState(() => _isCameraInitialized = false);
    }
  }

  void _toggleFlash() {
    if (_isProcessing || _currentMode != CameraScanMode.photo) return;
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    FlashMode newFlashMode = _currentFlashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    _cameraController!.setFlashMode(newFlashMode).then((_) {
      if (mounted) setState(() => _currentFlashMode = newFlashMode);
    }).catchError((e) => print("Error setting photo flash: $e"));
  }

  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context)!;
    bool showPhotoCamera = (_currentMode == CameraScanMode.photo) && _isCameraInitialized && _cameraController != null && _cameraController!.value.isInitialized;
    Widget cameraViewWidget;

    if (showPhotoCamera) {
      cameraViewWidget = AspectRatio(aspectRatio: _cameraController!.value.aspectRatio, child: CameraPreview(_cameraController!),);
    } else if (_currentMode == CameraScanMode.gallery && !_isProcessing) {
      cameraViewWidget = Center(child: Text(S.cameraGalleryModeActive, style: const TextStyle(color: Colors.white70, fontSize: 16)));
    } else if (_isProcessing && _currentMode == CameraScanMode.gallery) {
        cameraViewWidget = Center(child: Text(S.cameraGalleryModeActiveWhenProcessing, style: const TextStyle(color: Colors.white38, fontSize: 16)));
    }
     else {
      cameraViewWidget = const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Positioned.fill(child: cameraViewWidget),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10, left: 10, right: 10,
            child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                IconButton( icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => _isProcessing ? null : context.pop(),),
                Row( children: [
                    if (_currentMode == CameraScanMode.photo && !_isProcessing) 
                        IconButton( icon: Icon(_currentFlashMode == FlashMode.torch ? Icons.flash_on : Icons.flash_off, color: Colors.white, size: 28),
                                    onPressed: _toggleFlash,), 
                    IconButton( icon: const Icon(Icons.help_outline, color: Colors.white, size: 28), onPressed: _isProcessing ? null : () {
                        GoRouter.of(AppRouter.rootNavigatorKey.currentContext ?? context).push(AppRouter.preScanGuidePath);},),
                  ],)],),),

          if (!_isProcessing) 
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.only(bottom: 30, top: 20),
                color: Colors.black.withOpacity(0.5),
                child: Column( mainAxisSize: MainAxisSize.min, children: [
                    _buildModeSelector(S),
                    const SizedBox(height: 20),
                    Opacity(
                      opacity: _currentMode == CameraScanMode.photo ? 1.0 : 0.0,
                      child: IgnorePointer(
                        ignoring: _currentMode != CameraScanMode.photo,
                        child: GestureDetector(
                          onTap: _onTakePicturePressed, 
                          child: Container(
                            width: 70, height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300, width: 4),
                            ),
                            child: const Icon(Icons.camera_alt, color: AppColors.primary, size: 30),
                          ),
                        ),
                      ),
                    ),
                  ],),),),
        ],
      ),
    );
  }

  Widget _buildModeSelector(AppLocalizations S) {
    Widget modeButton(CameraScanMode mode, String label, IconData iconData) {
      final bool isActive = _currentMode == mode;
      
      return GestureDetector(
        onTap: () { 
            if (mode == CameraScanMode.gallery) {
              if(_currentMode != CameraScanMode.gallery && mounted) {
                 setState(() => _currentMode = CameraScanMode.gallery);
                 _cameraController?.dispose();
                 _cameraController = null;
                 setState(() => _isCameraInitialized = false);
              }
              _onPickFromGalleryPressed();
            } else { 
              _changeCameraMode(mode); 
            }
          },
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: isActive? AppColors.primary : Colors.white54, width: 1.5)
            ),
            child: Row( mainAxisSize: MainAxisSize.min, children: [
                Icon(iconData, color: Colors.white, size: 20), const SizedBox(width: 8),
                Text( label, style: TextStyle( color: Colors.white, fontSize: 14, fontWeight: isActive ? FontWeight.bold : FontWeight.normal,),),
              ],),),
        );
    }
     return Padding(
       padding: const EdgeInsets.symmetric(horizontal: 20.0),
       child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
            modeButton(CameraScanMode.photo, S.cameraModePhoto, Icons.camera_alt_outlined),
            modeButton(CameraScanMode.gallery, S.cameraModeGallery, Icons.photo_library_outlined),
          ],),
     );
  }
}