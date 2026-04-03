import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/book_note.dart';
import '../../../core/utils/haptic_utils.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../cubit/book_notes_cubit.dart';

/// Bottom sheet for viewing and adding book notes during a focus session.
class BookNotesSheet extends StatefulWidget {
  final String bookId;
  final String bookTitle;
  final int? currentPage;

  const BookNotesSheet({
    super.key,
    required this.bookId,
    required this.bookTitle,
    this.currentPage,
  });

  @override
  State<BookNotesSheet> createState() => _BookNotesSheetState();
}

class _BookNotesSheetState extends State<BookNotesSheet> {
  final _contentController = TextEditingController();
  final _pageController = TextEditingController();
  final _contentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _pageController.text = widget.currentPage?.toString() ?? '';
    context.read<BookNotesCubit>().loadNotes(widget.bookId);
  }

  @override
  void dispose() {
    _contentController.dispose();
    _pageController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _saveTextNote() {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    final page = int.tryParse(_pageController.text);
    Haptics.light();

    context.read<BookNotesCubit>().addTextNote(
          content: content,
          pageNumber: page,
        );

    // Close modal — timer resumes automatically
    Navigator.pop(context);
  }

  void _takePhoto() {
    final content = _contentController.text.trim();
    final page = int.tryParse(_pageController.text);
    Haptics.light();

    context.read<BookNotesCubit>().addPhotoNote(
          content: content.isNotEmpty ? content : null,
          pageNumber: page,
        );

    // Close modal — timer resumes automatically
    Navigator.pop(context);
  }

  void _pickFromGallery() {
    final content = _contentController.text.trim();
    final page = int.tryParse(_pageController.text);
    Haptics.light();

    context.read<BookNotesCubit>().addPhotoFromGallery(
          content: content.isNotEmpty ? content : null,
          pageNumber: page,
        );

    // Close modal — timer resumes automatically
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(
                    Icons.sticky_note_2_rounded,
                    color: AppColors.amber,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.bookNotes,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          widget.bookTitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Inline compose area
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Note text input
                  TextField(
                    controller: _contentController,
                    focusNode: _contentFocusNode,
                    maxLines: 3,
                    minLines: 2,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.writeYourNote,
                      hintStyle: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: AppColors.backgroundDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(12),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Bottom row: page number + actions
                  Row(
                    children: [
                      // Page number (compact)
                      SizedBox(
                        width: 80,
                        height: 36,
                        child: TextField(
                          controller: _pageController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: l10n.pageNumberOptional,
                            hintStyle: TextStyle(
                              color: AppColors.textMuted.withValues(alpha: 0.5),
                              fontSize: 11,
                            ),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(
                                Icons.bookmark_outline_rounded,
                                color: AppColors.textMuted,
                                size: 14,
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                            filled: true,
                            fillColor: AppColors.backgroundDark,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 0),
                            isDense: true,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Camera button
                      _ActionIcon(
                        icon: Icons.camera_alt_rounded,
                        onTap: _takePhoto,
                      ),
                      const SizedBox(width: 6),

                      // Gallery button
                      _ActionIcon(
                        icon: Icons.photo_library_rounded,
                        onTap: _pickFromGallery,
                      ),
                      const SizedBox(width: 10),

                      // Save button
                      GestureDetector(
                        onTap: _saveTextNote,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.send_rounded,
                                  size: 14, color: Colors.white),
                              const SizedBox(width: 5),
                              Text(
                                l10n.saveNote,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            const Divider(color: Color(0x14FFFFFF), height: 1),

            // Notes list
            Expanded(
              child: BlocBuilder<BookNotesCubit, BookNotesState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  if (state.isSaving) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            l10n.savingNote,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state.notes.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.note_add_rounded,
                              size: 40,
                              color:
                                  AppColors.textMuted.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              l10n.noNotesYet,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.noNotesDescription,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted
                                    .withValues(alpha: 0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    itemCount: state.notes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _NoteCard(
                        note: state.notes[index],
                        onDelete: () {
                          final noteId = state.notes[index].id;
                          if (noteId != null) {
                            context.read<BookNotesCubit>().deleteNote(noteId);
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final BookNote note;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: page number + badges + time + delete
          Row(
            children: [
              if (note.pageNumber != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    l10n.pageN(note.pageNumber!),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              if (note.hasImage && note.pageNumber != null)
                const SizedBox(width: 5),
              if (note.hasImage)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.image_rounded,
                          size: 10, color: AppColors.amber),
                      const SizedBox(width: 3),
                      Text(
                        l10n.photo,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              if (note.createdAt != null)
                Text(
                  _formatTime(note.createdAt!),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _confirmDelete(context),
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),

          // Image preview
          if (note.hasImage) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: GestureDetector(
                onTap: () => _showFullImage(context, note.imageBase64!),
                child: Image.memory(
                  base64Decode(note.imageBase64!),
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 60,
                    color: AppColors.backgroundDark,
                    child: const Center(
                      child: Icon(Icons.broken_image_rounded,
                          color: AppColors.textMuted, size: 20),
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Text content
          if (note.hasContent) ...[
            const SizedBox(height: 8),
            Text(
              note.content!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _confirmDelete(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.deleteNote,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          l10n.deleteNoteConfirm,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: Text(
              l10n.delete,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String base64Image) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InteractiveViewer(
                child: Image.memory(
                  base64Decode(base64Image),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 22,
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
