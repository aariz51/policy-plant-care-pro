// lib/features/auth/widgets/personalization_widgets.dart
import 'package:flutter/material.dart';
import 'package:safemama/core/constants/app_colors.dart';

class ProgressIndicatorBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  const ProgressIndicatorBar({super.key, required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        return Expanded(
          child: Container(
            height: 6, // Slightly thicker for better visibility
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: index < currentStep ? AppColors.primary : AppColors.greyLight,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}

class PersonalizationSelectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const PersonalizationSelectionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 1.5,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: isSelected ? AppColors.primary.withOpacity(0.05) : AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.greyLight,
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 32, color: isSelected ? AppColors.primary : AppColors.textMedium),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMedium)),
                      ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: AppColors.primary, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}