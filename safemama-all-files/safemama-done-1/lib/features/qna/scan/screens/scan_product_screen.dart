// lib/features/scan/screens/scan_product_screen.dart
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart'; // Required for WriteBuffer
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ADDED for Riverpod
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:provider/provider.dart'; // REMOVED - No longer using provider package
import 'package:safemama/core/models/scan_data.dart';
import 'package:safemama/core/models/user_profile.dart';
import 'package:safemama/core/services/scan_history_service.dart';
import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/core/widgets/paywall_dialog.dart'; // Added for PaywallDialog
import 'package:safemama/navigation/app_router.dart';
// import 'package:safemama/navigation/providers/user_profile_provider.dart'; // UserProfileProvider CLASS // No longer needed directly
// Ensure userProfileNotifierProvider (the actual provider instance) is accessible
import 'package:safemama/core/providers/app_providers.dart'; // <<< ADDED THIS IMPORT
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:safemama/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

// MODIFIED: Changed to ConsumerStatefulWidget
class ScanProductScreen extends ConsumerStatefulWidget {
  const ScanProductScreen({super.key});

  @override
  // MODIFIED: Changed to ConsumerState
  _ScanProductScreenState createState() => _ScanProductScreenState();
}

// MODIFIED: Changed to extend ConsumerState<ScanProductScreen>
class _ScanProductScreenState extends ConsumerState<ScanProductScreen> with WidgetsBindingObserver {
  static const int freeScanLimit = 4;

  CameraController? _cameraController;
  bool _isCameraPermissionGranted = false;
  bool _isCameraInitialized = false;
  bool _isCameraInitializing = true;
  bool _isFlashOn = false;
  String _cameraError = '';
  bool _isProcessingImage = false;
  bool _isCurrentlyInitializingCamera = false;

  final ImagePicker _picker = ImagePicker();
  final ScanHistoryService _historyService = ScanHistoryService();

  static const String _backendBaseUrl = String.fromEnvironment(
    'BACKEND_API_URL',
    defaultValue: 'http://192.168.29.229:3001',
  );

  final String _takePhotoIconPath = 'assets/icons/icon_take_photo.png';
  final String _uploadGalleryIconPath = 'assets/icons/icon_upload_gallery.png';
  final String _privacyShieldIconPath = 'assets/icons/icon_shield_check.png';
  final String _cameraPlaceholderIconPath = 'assets/icons/icon_camera_placeholder.png';
  final String _alertIconPath = 'assets/icons/icon_alert_triangle.png';

  double _minZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;
  double _currentZoomLevel = 1.0;
  double _pinchStartZoomLevel = 1.0;

  ObjectDetector? _objectDetector;
  bool _isObjectInFrame = false;
  bool _isProcessingStream = false;
  Rect? _normalizedScanWindow;

  final Set<String> _productLikeLabels = {
    'Bottle', 'Box', 'Can', 'Container', 'Jar', 'Packaged goods', 'Packaging', 'Product',
    'Carton', 'Wrapper', 'Packet', 'Sachet', 'Blister pack',
    'Food', 'Fruit', 'Vegetable', 'Snack food', 'Drink', 'Beverage',
    'Medicine', 'Pill', 'Tablet',
    'Home good',
    'Fashion good',
  };
  static const double _minLabelConfidence = 0.45;


  @override
  void initState() {
    super.initState();
    print("[ScanProductScreen] initState");
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("[ScanProductScreen] addPostFrameCallback: Calling _initializeCameraAndPermissions");
      if (mounted) {
        _initializeCameraAndPermissions();
      }
    });
  }

  @override
  void dispose() {
    print("[ScanProductScreen] dispose CALLED");
    WidgetsBinding.instance.removeObserver(this);
    _objectDetector?.close();
    final controllerToDispose = _cameraController;
    controllerToDispose?.stopImageStream().catchError((e) {
      print("[ScanProductScreen] Error stopping image stream on dispose: $e");
    });
    _cameraController = null;
    controllerToDispose?.dispose().then((_) {
      print("[ScanProductScreen] Camera controller disposed in main dispose method.");
    }).catchError((e) {
      print("[ScanProductScreen] Error disposing camera controller: $e");
    });
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print("[ScanProductScreen] AppLifecycleState changed to: ${state.name}");

    if (!_isCameraPermissionGranted && state != AppLifecycleState.resumed) {
        print("[ScanProductScreen] AppLifecycleState: No camera permission and not resuming. Returning.");
        return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        final CameraController? controllerOnResume = _cameraController;
        print("[ScanProductScreen] App Resumed. Controller exists: ${controllerOnResume != null}, Controller Initialized: ${controllerOnResume?.value.isInitialized ?? false}, Our flag _isCameraInitialized: $_isCameraInitialized");
        if (_isCameraPermissionGranted) {
          if (!_isCameraInitialized || controllerOnResume == null || !controllerOnResume.value.isInitialized) {
            print("[ScanProductScreen] Resuming app: Camera needs full re-initialization.");
            if (mounted && !_isCurrentlyInitializingCamera) {
              _initializeCamera().then((_) {
                 if(mounted && _isCameraInitialized && _cameraController != null && _cameraController!.value.isInitialized) {
                    _startImageStream();
                 }
              });
            }
          } else {
             print("[ScanProductScreen] Resuming app: Camera already initialized. Ensuring image stream is running.");
             _startImageStream();
          }
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        print("[ScanProductScreen] App ${state.name}. Preparing to stop stream and dispose camera controller.");
        final CameraController? controllerToStop = _cameraController;

        controllerToStop?.stopImageStream().catchError((e) {
          print("[ScanProductScreen] Error stopping image stream on ${state.name}: $e");
        });

        if (mounted) {
          setState(() {
            print("[ScanProductScreen] UI Reset: _isCameraInitialized=false, _isObjectInFrame=false due to ${state.name}");
            _isCameraInitialized = false;
            _isObjectInFrame = false;
          });
        }

        final controllerToDispose = _cameraController;
        _cameraController = null;
        _isCameraInitialized = false;

        controllerToDispose?.dispose().then((_) {
          print("[ScanProductScreen] Controller successfully disposed due to app state: ${state.name}");
        }).catchError((e) {
          print("[ScanProductScreen] Error disposing controller on app state ${state.name}: $e");
        });

        _objectDetector?.close();
        _objectDetector = null;
        break;
      case AppLifecycleState.detached:
        print("[ScanProductScreen] App Detached. Disposing all resources.");
        _objectDetector?.close();
        _objectDetector = null;
        final controllerOnDetached = _cameraController;
        _cameraController = null;
        _isCameraInitialized = false;
        controllerOnDetached?.stopImageStream().catchError((e){print("Error stopping image stream on detached: $e");});
        controllerOnDetached?.dispose();
        print("[ScanProductScreen] Controller disposed (detached).");
        break;
    }
  }

  Future<void> _initializeCameraAndPermissions() async {
    print("[ScanProductScreen] _initializeCameraAndPermissions");
    if (!mounted) return;
    setState(() {
      _isCameraInitializing = true;
      _cameraError = '';
      _isObjectInFrame = false;
    });

    final S = AppLocalizations.of(context);
    if (S == null) {
      if (mounted) setState(() { _isCameraInitializing = false; _cameraError = 'Localization not ready.'; });
      return;
    }

    var cameraStatus = await Permission.camera.status;
    if (!mounted) return;

    if (!cameraStatus.isGranted) {
      cameraStatus = await Permission.camera.request();
      if (!mounted) return;
    }

    if (cameraStatus.isGranted) {
      if (mounted) setState(() => _isCameraPermissionGranted = true);
      await _initializeCamera();
    } else {
      String errorMessage = S.scanPermissionRequired;
      if (cameraStatus.isPermanentlyDenied || (Platform.isIOS && cameraStatus == PermissionStatus.denied)) {
        errorMessage += '\n${S.scanEnableInSettings}';
      }
      if (mounted) {
        setState(() {
          _isCameraPermissionGranted = false; _isCameraInitializing = false; _isCameraInitialized = false;
          _cameraError = errorMessage;
        });
      }
    }
  }

  Future<void> _initializeObjectDetector() async {
    if (_objectDetector != null) {
       await _objectDetector!.close();
       _objectDetector = null;
    }
    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: options);
    print("[ScanProductScreen] Object detector initialized.");
  }

  Future<void> _initializeCamera() async {
    print("[ScanProductScreen] _initializeCamera called.");
    if (!_isCameraPermissionGranted) {
       if (mounted && _isCameraInitializing) setState(() => _isCameraInitializing = false);
       print("[ScanProductScreen] Camera permission not granted. Aborting init.");
       return;
    }
    if (!mounted || _isCurrentlyInitializingCamera) {
      print("[ScanProductScreen] Not mounted or already initializing. Aborting init.");
      if(mounted && _isCameraInitializing && !_isCameraInitialized) {
          setState(() => _isCameraInitializing = false);
      }
      return;
    }

    _isCurrentlyInitializingCamera = true;
    if (mounted && !_isCameraInitializing) setState(() => _isCameraInitializing = true);

    final S = AppLocalizations.of(context);
    if (S == null) {
        if (mounted) setState(() { _isCameraInitializing = false; _isCameraInitialized = false; _cameraError = 'Localization context error.'; });
        _isCurrentlyInitializingCamera = false;
        print("[ScanProductScreen] Localization context error. Aborting init.");
        return;
    }

    await _initializeObjectDetector();

    if (_cameraController != null) {
        print("[ScanProductScreen] Disposing existing camera controller before new init.");
        await _cameraController!.stopImageStream().catchError((e){ print("Error stopping old stream during re-init: $e"); });
        await _cameraController!.dispose();
        _cameraController = null;
        _isCameraInitialized = false;
    }

    try {
      final List<CameraDescription> cameras = await availableCameras();
      if (!mounted) { _isCurrentlyInitializingCamera = false; return; }

      if (cameras.isEmpty) {
        if (mounted) setState(() { _isCameraInitializing = false; _isCameraInitialized = false; _cameraError = S.scanNoCamerasFound; });
        _isCurrentlyInitializingCamera = false; return;
      }

      CameraDescription selectedCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first);

      final CameraController newController = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );

      print("[ScanProductScreen] Initializing new CameraController instance...");
      await newController.initialize();
      print("[ScanProductScreen] New CameraController instance initialized.");

      if (!mounted) {
        print("[ScanProductScreen] Not mounted after new controller init. Disposing new controller.");
        await newController.dispose();
        _isCurrentlyInitializingCamera = false;
        return;
      }

      _cameraController = newController;

      _minZoomLevel = await _cameraController!.getMinZoomLevel();
      _maxZoomLevel = await _cameraController!.getMaxZoomLevel();
      _currentZoomLevel = (_minZoomLevel <= 1.0 && 1.0 <= _maxZoomLevel) ? 1.0 : _minZoomLevel;
      _pinchStartZoomLevel = _currentZoomLevel;
      await _cameraController!.setZoomLevel(_currentZoomLevel);
      await _cameraController!.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);

      if (mounted) {
        setState(() {
          _isCameraInitializing = false;
          _isCameraInitialized = true;
          _cameraError = '';
          _isObjectInFrame = false;
          print("[ScanProductScreen] Init SUCCESS: _isCameraInitialized set to true and controller assigned.");
        });
        _calculateNormalizedScanWindow(MediaQuery.of(context).size);
        _startImageStream();
      } else {
         print("[ScanProductScreen] Not mounted before final setState. Disposing controller.");
         await _cameraController?.dispose();
         _cameraController = null;
         _isCameraInitialized = false;
      }

    } on CameraException catch (e) {
      print("[ScanProductScreen] CameraException during init: ${e.code} - ${e.description}");
      if (mounted) setState(() { _isCameraInitializing = false; _isCameraInitialized = false; _cameraError = S.scanCameraInitErrorParams(e.description ?? S.scanUnknownCameraError); });
      _cameraController = null;
      _isCameraInitialized = false;
    } catch (e, stacktrace) {
      print('[ScanProductScreen] Unexpected error in _initializeCamera: $e\n$stacktrace');
      if (mounted) setState(() { _isCameraInitializing = false; _isCameraInitialized = false; _cameraError = S.scanCameraUnexpectedError; });
      _cameraController = null;
      _isCameraInitialized = false;
    } finally {
      _isCurrentlyInitializingCamera = false;
      if (mounted && _isCameraInitializing && !_isCameraInitialized) {
        setState(() => _isCameraInitializing = false);
      }
      print("[ScanProductScreen] _initializeCamera finished. _isCameraInitialized: $_isCameraInitialized, _cameraController is null: ${_cameraController == null}");
    }
  }

  void _calculateNormalizedScanWindow(Size screenSize) {
    if (!mounted || _cameraController == null || !_cameraController!.value.isInitialized) return;
    final previewAspectRatio = _cameraController!.value.aspectRatio;
    const double frameWidthRatioOnScreen = 0.8;
    const double frameHeightToWidthAspectRatioOnScreen = (2.0 / 3.5);
    double previewDisplayWidth;
    double previewDisplayHeight;
    if (screenSize.width / screenSize.height > previewAspectRatio) {
      previewDisplayHeight = screenSize.height;
      previewDisplayWidth = previewDisplayHeight * previewAspectRatio;
    } else {
      previewDisplayWidth = screenSize.width;
      previewDisplayHeight = previewDisplayWidth / previewAspectRatio;
    }
    final double uiFrameWidthPixels = screenSize.width * frameWidthRatioOnScreen;
    final double uiFrameHeightPixels = screenSize.width * frameHeightToWidthAspectRatioOnScreen;
    double normLeftInPreview = (previewDisplayWidth - uiFrameWidthPixels) / 2 / previewDisplayWidth;
    double normWidthInPreview = uiFrameWidthPixels / previewDisplayWidth;
    final double columnCenterYInStackScreenCoords = screenSize.height * 0.375;
    final double cameraPreviewTopOffsetScreen = (screenSize.height - previewDisplayHeight) / 2;
    final double uiFrameTopScreenCoords = columnCenterYInStackScreenCoords - (uiFrameHeightPixels / 2);
    double normTopInPreview = (uiFrameTopScreenCoords - cameraPreviewTopOffsetScreen) / previewDisplayHeight;
    double normHeightInPreview = uiFrameHeightPixels / previewDisplayHeight;
    normLeftInPreview = normLeftInPreview.clamp(0.0, 1.0);
    normWidthInPreview = normWidthInPreview.clamp(0.0, 1.0 - normLeftInPreview);
    normTopInPreview = normTopInPreview.clamp(0.0, 1.0);
    normHeightInPreview = normHeightInPreview.clamp(0.0, 1.0 - normTopInPreview);
    _normalizedScanWindow = Rect.fromLTWH(normLeftInPreview, normTopInPreview, normWidthInPreview, normHeightInPreview);
  }

  void _startImageStream() {
    if (_cameraController != null &&
        _cameraController!.value.isInitialized &&
        !_cameraController!.value.isStreamingImages &&
        _objectDetector != null) {
      _cameraController!.startImageStream(_processCameraImage).then((_) {
        print("[ScanProductScreen] Image stream successfully started.");
      }).catchError((e) {
        print("[ScanProductScreen] Error starting image stream: $e");
      });
    } else {
      print("[ScanProductScreen] Conditions not met to start image stream. Controller init: ${_cameraController?.value.isInitialized}, Streaming: ${_cameraController?.value.isStreamingImages}, Detector: ${_objectDetector != null}");
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image, CameraDescription cameraDescription) {
    final imageRotation = InputImageRotationValue.fromRawValue(cameraDescription.sensorOrientation) ?? InputImageRotation.rotation0deg;
    final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw);

    if (inputImageFormat == null) {
      print('[ScanProductScreen] Unsupported image format from camera: ${image.format.group} / ${image.format.raw}');
      return null;
    }
     if (image.width == 0 || image.height == 0) {
      print("[ScanProductScreen] CameraImage has zero width or height.");
      return null;
    }
    if (image.planes.isEmpty || image.planes[0].bytes.isEmpty) {
      print("[ScanProductScreen] Image planes are empty or first plane bytes are empty.");
      return null;
    }

    final inputImageData = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    if (bytes.isEmpty) {
      print("[ScanProductScreen] Concatenated bytes for InputImage are empty.");
      return null;
    }

    return InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
  }

  Future<void> _processCameraImage(CameraImage cameraImage) async {
    if (_objectDetector == null ||
        !_isCameraInitialized ||
        _isProcessingStream ||
        _normalizedScanWindow == null ||
        !mounted) {
      return;
    }

    _isProcessingStream = true;

    final inputImage = _inputImageFromCameraImage(cameraImage, _cameraController!.description);
    if (inputImage == null) {
      print("[ScanProductScreen] _inputImageFromCameraImage returned null in _processCameraImage.");
      _isProcessingStream = false;
      return;
    }

    try {
      final List<DetectedObject> objects = await _objectDetector!.processImage(inputImage);
      bool objectFoundAndIsProductLike = false;

      if (objects.isNotEmpty) {
        final double imageWidthForBoxes = (inputImage.metadata!.rotation == InputImageRotation.rotation90deg ||
                                        inputImage.metadata!.rotation == InputImageRotation.rotation270deg)
                                       ? inputImage.metadata!.size.height
                                       : inputImage.metadata!.size.width;
        final double imageHeightForBoxes = (inputImage.metadata!.rotation == InputImageRotation.rotation90deg ||
                                         inputImage.metadata!.rotation == InputImageRotation.rotation270deg)
                                        ? inputImage.metadata!.size.width
                                        : inputImage.metadata!.size.height;

        final Rect scanRectPixels = Rect.fromLTWH(
          _normalizedScanWindow!.left * imageWidthForBoxes,
          _normalizedScanWindow!.top * imageHeightForBoxes,
          _normalizedScanWindow!.width * imageWidthForBoxes,
          _normalizedScanWindow!.height * imageHeightForBoxes,
        );

        for (final DetectedObject detectedObject in objects) {
          print("[ScanProductScreen] Detected: ${detectedObject.labels.map((l) => '${l.text} (${l.confidence.toStringAsFixed(2)})').join(', ')} | BBox: ${detectedObject.boundingBox}");
          if (scanRectPixels.overlaps(detectedObject.boundingBox)) {
            for (final Label label in detectedObject.labels) {
              print("  ---> Overlapping Object Label: ${label.text}, Confidence: ${label.confidence.toStringAsFixed(2)}, InProductList: ${_productLikeLabels.contains(label.text)}, MeetsThreshold: ${label.confidence >= _minLabelConfidence}");
              if (_productLikeLabels.contains(label.text) && label.confidence >= _minLabelConfidence) {
                print("[ScanProductScreen] ---> PRODUCT-LIKE OBJECT OVERLAPPING scan window: ${label.text} (Confidence: ${label.confidence.toStringAsFixed(2)})");
                objectFoundAndIsProductLike = true;
                break;
              }
            }
          }
          if (objectFoundAndIsProductLike) {
            break;
          }
        }
      }

      if (mounted && _isObjectInFrame != objectFoundAndIsProductLike) {
        setState(() {
          _isObjectInFrame = objectFoundAndIsProductLike;
        });
      }
    } catch (e, stackTrace) {
      print("[ScanProductScreen] Error processing image stream with ML Kit: $e");
      print(stackTrace);
    } finally {
      _isProcessingStream = false;
    }
  }


  void _toggleFlash() {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _isProcessingImage) return;
    final S = AppLocalizations.of(context)!;
    try {
      final newFlashMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
      controller.setFlashMode(newFlashMode).then((_) {
        if (mounted) { setState(() => _isFlashOn = !_isFlashOn); }
      }).catchError((error) {
        print("Error setting flash: $error");
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.scanFlashToggleError(error.toString()))));
      });
    } catch (e) {
      print("Error toggling flash: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.scanFlashToggleFailed)));
    }
  }

  void _handleZoomScaleStart(ScaleStartDetails details) {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _minZoomLevel >= _maxZoomLevel) return;
    _pinchStartZoomLevel = _currentZoomLevel;
  }

  void _handleZoomScaleUpdate(ScaleUpdateDetails details) {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isProcessingImage || _minZoomLevel >= _maxZoomLevel) return;
    if ((details.scale - 1.0).abs() < 0.02 && details.scale != 0) return;
    double newZoomLevel = (_pinchStartZoomLevel * details.scale).clamp(_minZoomLevel, _maxZoomLevel);
    if ((newZoomLevel - _currentZoomLevel).abs() > 0.01) {
      _cameraController!.setZoomLevel(newZoomLevel).then((_) {
        if (mounted) { _currentZoomLevel = newZoomLevel; }
      }).catchError((e) { print("[ScanProductScreen] Error setting zoom on pinch: $e"); });
    }
  }

  void _onScanFrameTap() {
    print("[ScanProductScreen] Scan frame tapped (Manual alignment logic removed).");
  }

  MediaType _getMediaType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    if (extension == 'jpg' || extension == 'jpeg') return MediaType('image', 'jpeg');
    if (extension == 'png') return MediaType('image', 'png');
    return MediaType('image', 'jpeg');
  }

  Future<void> _processImageFile(XFile imageFile) async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    // final router = GoRouter.of(context); // OLD way
    final S = AppLocalizations.of(context)!;
    final String? currentUserId = Supabase.instance.client.auth.currentUser?.id;

    if (currentUserId == null) {
      messenger.showSnackBar(SnackBar(content: Text(S.scanErrorUserNotLoggedIn), backgroundColor: AppTheme.avoidColor));
      if (mounted) setState(() => _isProcessingImage = false);
      return;
    }
    setState(() { _isProcessingImage = true; });
    File? tempCompressedFile;
    String finalPathForResultsScreenAndUpload = imageFile.path;

    try {
      final originalFile = File(imageFile.path);
      int originalSizeBytes = await originalFile.length();
      File fileToUploadToBackend = originalFile;
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String baseName = imageFile.name.split('/').last.replaceAll(RegExp(r'[^\w.-]'), '_');
      final String newFileName = '${DateTime.now().millisecondsSinceEpoch}_$baseName';
      final String persistentDisplayPath = '${appDocDir.path}/$newFileName';
      await originalFile.copy(persistentDisplayPath);
      finalPathForResultsScreenAndUpload = persistentDisplayPath;
      if (originalSizeBytes > (150 * 1024)) {
        final tempDirForCompression = await getTemporaryDirectory();
        final targetCompressionPath = '${tempDirForCompression.path}/${DateTime.now().millisecondsSinceEpoch}_backend_compressed.jpg';
        final XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
            originalFile.absolute.path, targetCompressionPath, quality: 70, format: CompressFormat.jpeg);
        if (!mounted) return;
        if (compressedXFile != null) {
          tempCompressedFile = File(compressedXFile.path);
          fileToUploadToBackend = tempCompressedFile;
        } else {
          fileToUploadToBackend = File(finalPathForResultsScreenAndUpload);
        }
      } else {
         fileToUploadToBackend = File(finalPathForResultsScreenAndUpload);
      }
      if (!await fileToUploadToBackend.exists()) {
         throw Exception("File to upload to backend does not exist: ${fileToUploadToBackend.path}");
      }
      var request = http.MultipartRequest('POST', Uri.parse('$_backendBaseUrl/api/analyze-product'));
      MediaType mediaType = _getMediaType(fileToUploadToBackend.path);
      request.files.add(await http.MultipartFile.fromPath('productImage', fileToUploadToBackend.path, contentType: mediaType));
      var streamedResponse = await request.send().timeout(const Duration(seconds: 30), onTimeout: () {
          throw TimeoutException(S.scanRequestTimeout);
      });
      var response = await http.Response.fromStream(streamedResponse);
      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> analysisResultData = jsonDecode(response.body);
        bool isConsumable = analysisResultData['isConsumable'] ?? false;

        if (!isConsumable) {
          messenger.showSnackBar(SnackBar(content: Text(S.scanNotConsumableError), backgroundColor: AppTheme.warningColor));
        } else {
          // MODIFIED: Use ref.read for UserProfileProvider
          // userProfileNotifierProvider is available from app_providers.dart
          final userProvider = ref.read(userProfileNotifierProvider);
          final UserProfile? userProfile = userProvider.userProfile;

          if (userProfile != null && userProfile.membershipTier == 'free') {
            print("[ScanProductScreen] Free user. Attempting to increment scan count BEFORE logging history.");
            final newScanCount = (userProfile.scanCount ?? 0) + 1;
            try {
              await Supabase.instance.client
                  .from('profiles')
                  .update({'scan_count': newScanCount})
                  .eq('id', userProfile.id);

              userProvider.updateLocalProfile(userProfile.copyWith(scanCount: newScanCount));
              print('[ScanProductScreen] Scan count incremented in Supabase for user ${userProfile.id} to $newScanCount.');
            } catch (e) {
              print('[ScanProductScreen] Error incrementing scan count BEFORE logging: $e.');
            }
          }

          print("[ScanProductScreen] Attempting to log scan to history...");
          final ScanData? loggedScanData = await _historyService.logScanToHistory(
            rawParsedOpenAiResponse: analysisResultData,
            userId: currentUserId,
            localImagePathToUpload: finalPathForResultsScreenAndUpload,
          );

          if (!mounted) return;

          if (loggedScanData != null) {
            print("[ScanProductScreen] Navigating to scan results using root navigator for context."); // ADDED PRINT
            // MODIFIED to use rootNavigatorKey
            GoRouter.of(AppRouter.rootNavigatorKey.currentContext!).pushReplacement(
              AppRouter.scanResultsPath,
              extra: loggedScanData.id,
            );

            if (mounted) {
              setState(() { _isObjectInFrame = false; });
            }
          } else {
            print("[ScanProductScreen] ERROR: logScanToHistory returned null. Cannot navigate to results. Scan count might have been incremented if user is free.");
            messenger.showSnackBar(
              SnackBar(
                content: Text(S.scanLogFailedError ?? "Failed to save scan information. Please try again."),
                backgroundColor: AppTheme.avoidColor
              ),
            );
          }
        }
      } else {
        String errorMessage = S.scanAnalysisFailed;
        try { final errorData = jsonDecode(response.body); errorMessage = errorData['error'] ?? errorData['details'] ?? errorMessage; } catch (_) {}
        throw Exception('$errorMessage (Status: ${response.statusCode})');
      }
    } catch (e, stacktrace) {
      print('[ScanProductScreen] Error in _processImageFile: $e\n$stacktrace');
      if (!mounted) return;
      String friendlyErrorMessage = S.scanUnexpectedError;
      if (e is SocketException || e is http.ClientException) { friendlyErrorMessage = S.scanNetworkError; }
      else if (e is TimeoutException) { friendlyErrorMessage = e.message ?? S.scanRequestTimeout; }
      else if (e is Exception) {
         String errorString = e.toString().replaceFirst('Exception: ', '');
         if (errorString.contains('Status: 5')) {
             final detailMatch = RegExp(r'^(.*?)\s*\(Status: 5\d{2}\)').firstMatch(errorString);
             friendlyErrorMessage = (detailMatch?.group(1)?.trim().isNotEmpty ?? false)
                ? S.scanAnalysisServerErrorParam(detailMatch!.group(1)!.trim()) : S.scanAnalysisServerError;
         } else if (errorString.contains('Status: 4')) {
             final detailMatch = RegExp(r'^(.*?)\s*\(Status: 4\d{2}\)').firstMatch(errorString);
              friendlyErrorMessage = (detailMatch?.group(1)?.trim().isNotEmpty ?? false)
                ? S.scanRequestProblemParam(detailMatch!.group(1)!.trim()) : S.scanRequestProblem;
         } else { friendlyErrorMessage = errorString; }
      }
      messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage), backgroundColor: AppTheme.avoidColor));
    } finally {
      if (tempCompressedFile != null && tempCompressedFile.path != imageFile.path) {
        try { if (await tempCompressedFile.exists()) await tempCompressedFile.delete(); } catch (e) { print("Error deleting temp: $e"); }
      }
      if (mounted) { setState(() { _isProcessingImage = false; }); }
    }
  }

  Future<void> _captureFromPreviewAndProcess() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _isProcessingImage) return;
    if (controller.value.isTakingPicture) return;

    final S = AppLocalizations.of(context)!;

    // MODIFIED: Use ref.read for UserProfileProvider
    // userProfileNotifierProvider is available from app_providers.dart
    final userProvider = ref.read(userProfileNotifierProvider);
    final userProfile = userProvider.userProfile;

    if (userProfile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.scanErrorUserProfileNotFound ?? 'Error: User profile not found. Please re-login.')));
      }
      return;
    }

    bool isPremium = userProfile.membershipTier == 'premium';
    int currentScanCount = userProfile.scanCount ?? 0;

    if (!isPremium && currentScanCount >= freeScanLimit) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return CustomPaywallDialog(
              title: S.scanFreeScansExhaustedTitle ?? 'Free Scans Exhausted',
              message: S.scanFreeScansExhaustedMessage(freeScanLimit) ?? 'You have used all your $freeScanLimit free scans. Upgrade to Premium for unlimited scans and more features!',
              icon: Icons.camera_alt_outlined,
              iconColor: AppTheme.accentColor,
            );
          },
        );
      }
      return;
    }

    if (!_isObjectInFrame) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.scanAlignProductPrompt)));
        return;
    }

    XFile? image;
    try {
      if(controller.value.isPreviewPaused) {
        await controller.resumePreview();
         if (!mounted) return;
      }
      image = await controller.takePicture();
      if (!mounted) return;
      if (_isFlashOn) {
         final currentController = _cameraController;
         if (currentController != null && currentController.value.isInitialized) {
             currentController.setFlashMode(FlashMode.off).catchError((e){ print("Error turning flash off post-capture: $e"); });
             if (mounted) setState(() => _isFlashOn = false);
         }
      }
      await _processImageFile(image);
    } on CameraException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.scanCaptureError(e.description ?? S.scanUnknownCameraError))));
      }
    } catch (e, stacktrace) {
      print("[ScanProductScreen] Error in _captureFromPreviewAndProcess (before _processImageFile): $e\n$stacktrace");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.scanUnexpectedCaptureError)));
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
     if (_isProcessingImage) return;
     final S = AppLocalizations.of(context)!;

    // MODIFIED: Use ref.read for UserProfileProvider
    // userProfileNotifierProvider is available from app_providers.dart
    final userProvider = ref.read(userProfileNotifierProvider);
    final userProfile = userProvider.userProfile;

    if (userProfile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.scanErrorUserProfileNotFound ?? 'Error: User profile not found. Please re-login.')));
      }
      return;
    }

    bool isPremium = userProfile.membershipTier == 'premium';
    int currentScanCount = userProfile.scanCount ?? 0;

    if (!isPremium && currentScanCount >= freeScanLimit) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return CustomPaywallDialog(
              title: S.scanFreeScansExhaustedTitle ?? 'Free Scans Exhausted',
              message: S.scanFreeScansExhaustedMessage(freeScanLimit) ?? 'You have used all your $freeScanLimit free scans. Upgrade to Premium for unlimited scans and more features!',
              icon: Icons.camera_alt_outlined,
              iconColor: AppTheme.accentColor,
            );
          },
        );
      }
      return;
    }

     try {
       final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
       if (!mounted) return;
       if (image != null) {
          await _processImageFile(image);
       }
     } catch (e, stacktrace) {
       print("[ScanProductScreen] Error in _pickImageFromGallery: $e\n$stacktrace");
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.scanGalleryPickError(e.toString()))));
       }
     }
   }


  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context);
    if (S == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final textTheme = Theme.of(context).textTheme;
    final screenSize = MediaQuery.of(context).size;

    final bool canShowPreview = _isCameraPermissionGranted &&
                                _isCameraInitialized &&
                                _cameraController != null &&
                                _cameraController!.value.isInitialized &&
                                !(_cameraController!.value.isPreviewPaused ?? true) ;

    Widget cameraPreviewWidget;
    if (canShowPreview) {
      final previewAspectRatio = _cameraController!.value.aspectRatio;
      cameraPreviewWidget = AspectRatio(
        aspectRatio: previewAspectRatio,
        child: (_minZoomLevel < _maxZoomLevel)
            ? GestureDetector(
                onScaleStart: _handleZoomScaleStart,
                onScaleUpdate: _handleZoomScaleUpdate,
                child: CameraPreview(_cameraController!),
              )
            : CameraPreview(_cameraController!),
      );
    } else {
      cameraPreviewWidget = Container(
        color: Colors.black,
        child: Center(
          child: _isCameraInitializing
              ? const CircularProgressIndicator(color: AppTheme.whiteColor)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(_cameraPlaceholderIconPath, width: 80, height: 80, color: AppTheme.whiteColor.withOpacity(0.7),
                      errorBuilder: (c,e,s) => Icon(Icons.broken_image, size: 80, color: AppTheme.whiteColor.withOpacity(0.7))),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Text(
                        _cameraError.isNotEmpty ? _cameraError : S.scanCameraUnavailable,
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(color: AppTheme.whiteColor.withOpacity(0.9)),
                      ),
                    ),
                    if (!_isCameraPermissionGranted && (_cameraError.contains(S.scanEnableInSettings.substring(0,10)) || _cameraError.contains("permanently denied")) ) ...[
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _openAppSettings,
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue.withOpacity(0.8)),
                        child: Text(S.scanOpenSettingsButton, style: textTheme.labelLarge?.copyWith(color: AppTheme.whiteColor)),
                      ),
                    ]
                  ],
                ),
        ),
      );
    }


    final Color currentScanFrameColor = _isObjectInFrame ? Colors.green : Colors.red;

    Widget scanningFrameAndGuidance = Align(
      alignment: const Alignment(0.0, -0.25),
      child: Padding(
        padding: EdgeInsets.only(
          top: kToolbarHeight + MediaQuery.of(context).padding.top + 20,
          left: 20, right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: screenSize.width * 0.8,
              height: screenSize.width * 0.8 * (2.0 / 3.5),
              decoration: BoxDecoration(
                border: Border.all(color: currentScanFrameColor.withOpacity(0.8), width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _isObjectInFrame ? S.scanProductDetectedReady : S.scanCenterProductLabel,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return PopScope(
      canPop: !_isProcessingImage,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (!_isProcessingImage) {
          if (GoRouter.of(context).canPop()) GoRouter.of(context).pop();
          else GoRouter.of(context).go(AppRouter.homePath);
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(S.scanProductScreenTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          backgroundColor: Colors.black.withOpacity(0.3),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          actionsIconTheme: const IconThemeData(color: Colors.white),
          actions: [
             if (canShowPreview)
              IconButton(
                icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
                tooltip: S.toggleFlashButtonLabel,
                onPressed: _isProcessingImage ? null : _toggleFlash,
              ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: S.closeButtonLabel,
              onPressed: _isProcessingImage ? null : () {
                if (GoRouter.of(context).canPop()) {
                   GoRouter.of(context).pop();
                 } else {
                   GoRouter.of(context).go(AppRouter.homePath);
                 }
              },
            ),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: cameraPreviewWidget),
            scanningFrameAndGuidance,
            Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                elevation: 4,
                color: AppTheme.cardBackground.withOpacity(0.95),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))
                ),
                child: SafeArea(
                  top: false, left: false, right: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(S.scanEnsureLabelVisible, textAlign: TextAlign.center, style: textTheme.bodyMedium?.copyWith(color: AppTheme.textPrimary)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: Image.asset(_takePhotoIconPath, width: 24, height: 24,
                              errorBuilder: (c,e,s) => Icon(Icons.camera_alt, color: AppTheme.whiteColor, size: 24)),
                            label: Text(S.scanTakePhotoButton),
                            style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
                              minimumSize: MaterialStateProperty.all(const Size(double.infinity, 52)),
                              backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                                (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.disabled)) return Theme.of(context).disabledColor.withOpacity(0.3);
                                  if (!_isObjectInFrame && canShowPreview) return Theme.of(context).colorScheme.primary.withOpacity(0.6);
                                  return Theme.of(context).colorScheme.primary;
                                },
                              ),
                               foregroundColor: MaterialStateProperty.resolveWith<Color?>(
                                (Set<MaterialState> states) {
                                   if (states.contains(MaterialState.disabled)) return AppTheme.textSecondary.withOpacity(0.5);
                                  return AppTheme.whiteColor;
                                },
                              )
                            ),
                            onPressed: (!canShowPreview || _isProcessingImage || !_isObjectInFrame) ? null : _captureFromPreviewAndProcess,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            icon: Image.asset(_uploadGalleryIconPath, width: 24, height: 24,
                              errorBuilder: (c,e,s) => Icon(Icons.photo_library, color: AppTheme.primaryBlue, size: 24)),
                            label: Text(S.scanUploadFromGalleryButton),
                            style: Theme.of(context).outlinedButtonTheme.style?.copyWith(minimumSize: MaterialStateProperty.all(const Size(double.infinity, 52))),
                            onPressed: _isProcessingImage ? null : _pickImageFromGallery,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(_privacyShieldIconPath, width: 16, height: 16,
                                errorBuilder: (c,e,s) => Icon(Icons.shield_outlined, color: AppTheme.textSecondary, size: 16)),
                              const SizedBox(width: 8),
                              Text(S.scanPrivacyProtected, style: textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
                            ]
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_isProcessingImage)
              Positioned.fill(
                child: Container(
                  color: AppTheme.scaffoldBackground.withOpacity(0.85),
                  child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const CircularProgressIndicator(), const SizedBox(height: 20),
                    Text(S.scanProcessingImage, style: textTheme.titleMedium?.copyWith(color: AppTheme.textPrimary)),
                  ],),),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAppSettings() async {
    if (!mounted) return;
    final S = AppLocalizations.of(context)!;
    if (!await openAppSettings()) {
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.scanCouldNotOpenSettings)));
       }
    }
  }
}