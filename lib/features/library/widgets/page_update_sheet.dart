import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/haptic_utils.dart';
import '../../../l10n/generated/app_localizations.dart';

class PageUpdateSheet extends StatefulWidget {
  final int currentPage;
  final int totalPages;
  final void Function(int page) onSave;

  const PageUpdateSheet({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onSave,
  });

  @override
  State<PageUpdateSheet> createState() => _PageUpdateSheetState();
}

class _PageUpdateSheetState extends State<PageUpdateSheet> {
  late double _sliderValue;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.currentPage.toDouble();
    _controller = TextEditingController(text: widget.currentPage.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.updateProgress,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            // Current page display
            Text(
              l10n.pagesOf(_sliderValue.round(), widget.totalPages),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            // Slider
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.backgroundDark,
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: _sliderValue,
                min: 0,
                max: widget.totalPages.toDouble(),
                divisions: widget.totalPages > 0 ? widget.totalPages : 1,
                onChanged: (value) {
                  setState(() {
                    _sliderValue = value;
                    _controller.text = value.round().toString();
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            // Manual input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.pageNumber,
                      labelStyle: const TextStyle(
                        color: AppColors.textMuted,
                      ),
                      filled: true,
                      fillColor: AppColors.backgroundDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      final page = int.tryParse(value);
                      if (page != null && page >= 0 && page <= widget.totalPages) {
                        setState(() {
                          _sliderValue = page.toDouble();
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Haptics.medium();
                  final page = _sliderValue.round();
                  widget.onSave(page);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.save,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
