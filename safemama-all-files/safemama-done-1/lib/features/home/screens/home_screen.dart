// lib/features/home/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:safemama/core/models/scan_data.dart';
import 'package:safemama/core/services/scan_history_service.dart';
import 'package:safemama/core/theme/app_theme.dart';
import 'package:safemama/navigation/app_router.dart';
import 'package:safemama/core/providers/app_providers.dart';
import 'package:safemama/l10n/app_localizations.dart';
import 'package:safemama/features/home/widgets/personalized_header.dart';
import 'package:safemama/features/home/widgets/pregnancy_calendar_snippet.dart';
import 'package:safemama/features/home/widgets/membership_status_chip.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<ScanData> _recentScans = [];
  bool _isLoadingRecentScans = true;
  String? _recentScansError;
  final ScanHistoryService _historyService = ScanHistoryService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchRecentScans();
      }
    });
  }

  Future<void> _fetchRecentScans() async {
    if (!mounted) return;
    setState(() {
      _isLoadingRecentScans = true;
      _recentScansError = null;
    });
    try {
      if (!mounted) return;
      final String? userId = ref.read(userProfileNotifierProvider).userId;
      if (userId == null || userId.isEmpty) {
        if (mounted) {
          setState(() {
            _recentScans = [];
            _isLoadingRecentScans = false;
          });
        }
        return;
      }
      final fetchedScans =
          await _historyService.fetchRecentScanHistory(userId, limit: 3);
      if (mounted) {
        setState(() {
          _recentScans = fetchedScans;
          _isLoadingRecentScans = false;
        });
      }
    } catch (e) {
      print("[HomeScreen] Error fetching recent scans: $e");
      if (mounted) {
        final S = AppLocalizations.of(context);
        setState(() {
          _recentScansError =
              S?.homeErrorLoadingRecentScans ?? "Could not load recent scans.";
          _isLoadingRecentScans = false;
        });
      }
    }
  }

  Future<void> _navigateToScanProduct() async {
    if (!mounted) return;
    GoRouter.of(context).push(AppRouter.preScanGuidePath);
  }

  Widget _buildHeader(BuildContext context) {
    final userProfileState = ref.watch(userProfileNotifierProvider);
    final S = AppLocalizations.of(context)!;
    String greetingName =
        userProfileState.userProfile?.fullName?.isNotEmpty == true
            ? userProfileState.userProfile!.fullName!
            : S.mamaFallbackName;

    // We use SafeArea here to automatically handle the notch/status bar
    return SafeArea(
      // We only want SafeArea to apply to the top, not the bottom
      bottom: false,
      child: Padding(
        // This padding gives space around the entire header content
        padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // This Row contains the top bar elements
            Row(
              // This is the KEY FIX: It vertically aligns all items in the middle
              crossAxisAlignment: CrossAxisAlignment.center, 
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Menu Icon
                IconButton(
                    icon: const Icon(Icons.menu, size: 28),
                    onPressed: () => Scaffold.of(context).openDrawer()),
                
                // Title and Heart Icon
                Row(
                  // This makes sure the title and heart are also aligned with each other
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('SafeMama', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    // This Padding pushes the heart down slightly to visually align with the text
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: CustomPaint(size: const Size(24, 24), painter: _HeartIconPainter()),
                    ),
                ]),
                
                // Profile Avatar
                GestureDetector(
                  onTap: () => context.go(AppRouter.profilePath),
                  child: CircleAvatar(
                    radius: 22, // Slightly larger for better tap area
                    backgroundColor: AppTheme.primaryPurple.withOpacity(0.1),
                    backgroundImage: (userProfileState.profileImageUrl.isNotEmpty)
                        ? NetworkImage(userProfileState.profileImageUrl)
                        : null,
                    child: (userProfileState.profileImageUrl.isEmpty)
                        ? Text(
                            greetingName.isNotEmpty
                                ? greetingName[0].toUpperCase()
                                : 'S',
                            style: const TextStyle(
                                fontSize: 20,
                                color: AppTheme.primaryPurple,
                                fontWeight: FontWeight.bold))
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Membership Status Chip - Shows current plan
            const MembershipStatusChip(),
            const SizedBox(height: 24),
            const PersonalizedHeader(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.newHomeBackground,
      // --- FAB ICON UPDATED ---
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToScanProduct,
        backgroundColor: AppTheme.newScanTeal,
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRecentScans,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            _buildHeader(context),
            const SizedBox(height: 16),
            const PregnancyCalendarSnippet(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: InkWell(
                onTap: _navigateToScanProduct,
                borderRadius: BorderRadius.circular(20.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 20.0),
                  decoration: BoxDecoration(
                      color: AppTheme.newScanTeal,
                      borderRadius: BorderRadius.circular(20.0),
                      boxShadow: [
                        BoxShadow(
                            color: AppTheme.newScanTeal.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ]),
                  child: Row(
                    children: [
                      // --- MAIN BUTTON ICON UPDATED ---
                      const Icon(Icons.qr_code_scanner,
                          color: Colors.white, size: 40),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(S.scanFoodOrMedicine,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                            const SizedBox(height: 2),
                            Text(S.getInstantSafetyResults,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: Colors.white.withOpacity(0.9))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Pregnancy Tools Hub Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: InkWell(
                onTap: () => context.push(AppRouter.pregnancyToolsHubPath),
                borderRadius: BorderRadius.circular(16.0),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryPurple.withOpacity(0.8),
                        AppTheme.primaryPurple,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryPurple.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.pregnant_woman,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pregnancy Tools',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Calculators, Trackers & More',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildRecentScansList(S),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentScansList(AppLocalizations S) {
    if (_isLoadingRecentScans) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(strokeWidth: 2.5)));
    } else if (_recentScansError != null) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(_recentScansError!,
                  style: const TextStyle(color: AppTheme.avoidRed))));
    } else if (_recentScans.isEmpty) {
      return const SizedBox.shrink(); // Don't show anything if no recent scans
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 8.0),
            child: Text(S.homeRecentScansTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          ..._recentScans.map((scanItem) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _buildRecentScanItem(context, S, scanItem),
              )),
        ],
      );
    }
  }

  Widget _buildRecentScanItem(
      BuildContext context, AppLocalizations S, ScanData item) {
    final textTheme = Theme.of(context).textTheme;
    Color statusColor;
    IconData statusIcon;
    switch (item.riskLevel) {
      case RiskLevel.safe:
        statusColor = AppTheme.safeGreen;
        statusIcon = Icons.check_circle_outline;
        break;
      case RiskLevel.caution:
        statusColor = AppTheme.warningOrange;
        statusIcon = Icons.warning_amber_rounded;
        break;
      case RiskLevel.avoid:
        statusColor = AppTheme.avoidRed;
        statusIcon = Icons.dangerous_outlined;
        break;
      default:
        statusColor = AppTheme.textSecondary;
        statusIcon = Icons.help_outline;
    }
    String formattedTime;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final itemLocalDate = item.createdAt.toLocal();
    final itemDate =
        DateTime(itemLocalDate.year, itemLocalDate.month, itemLocalDate.day);
    final String currentLocale =
        Localizations.localeOf(context).toLanguageTag();
    if (itemDate == today) {
      formattedTime =
          S.scannedTodayAt(DateFormat.jm(currentLocale).format(itemLocalDate));
    } else if (itemDate == yesterday) {
      formattedTime = S.scannedYesterday;
    } else {
      formattedTime = DateFormat.yMMMd(currentLocale).format(itemLocalDate);
    }
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.inputFillColor,
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
              ? Image.network(item.imageUrl!, fit: BoxFit.cover)
              : Icon(statusIcon, color: statusColor, size: 28),
        ),
        title: Text(item.productName,
            style:
                textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(formattedTime,
            style:
                textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
        trailing:
            const Icon(Icons.chevron_right, color: AppTheme.iconColor),
        onTap: () {
          print('Tapped on recent scan: ${item.productName}, ID: ${item.id}');
          GoRouter.of(context).push(AppRouter.scanResultsPath, extra: item.id);
        },
      ),
    );
  }
}

// _HeartIconPainter remains unchanged
class _HeartIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryPurple
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, size.height * 0.35);
    path.cubicTo(size.width * 0.1, size.height * 0.1, -size.width * 0.2,
        size.height * 0.6, size.width / 2, size.height * 0.9);
    path.moveTo(size.width / 2, size.height * 0.35);
    path.cubicTo(size.width * 0.9, size.height * 0.1, size.width * 1.2,
        size.height * 0.6, size.width / 2, size.height * 0.9);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}