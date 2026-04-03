import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/models/book_note.dart';
import '../../../core/services/book_note_service.dart';
import '../../../core/services/remote_logger_service.dart';
import '../../../core/utils/image_compress_utils.dart';

/// State for book notes during a focus session.
class BookNotesState {
  final List<BookNote> notes;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const BookNotesState({
    this.notes = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  BookNotesState copyWith({
    List<BookNote>? notes,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BookNotesState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class BookNotesCubit extends Cubit<BookNotesState> {
  final BookNoteService _noteService;
  final ImagePicker _imagePicker;
  String? _currentBookId;

  BookNotesCubit({
    required BookNoteService noteService,
    ImagePicker? imagePicker,
  })  : _noteService = noteService,
        _imagePicker = imagePicker ?? ImagePicker(),
        super(const BookNotesState());

  /// Set current book and load its notes.
  Future<void> loadNotes(String bookId) async {
    _currentBookId = bookId;
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final notes = await _noteService.getNotes(bookId);
      emit(state.copyWith(notes: notes, isLoading: false));
    } catch (e) {
      RemoteLoggerService.error('Failed to load book notes',
          screen: 'focus_notes', error: e);
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  /// Add a text-only note.
  Future<void> addTextNote({
    required String content,
    int? pageNumber,
  }) async {
    final bookId = _currentBookId;
    if (bookId == null || content.trim().isEmpty) return;

    emit(state.copyWith(isSaving: true));
    try {
      final note = BookNote(
        content: content.trim(),
        pageNumber: pageNumber,
      );
      await _noteService.addNote(bookId, note);

      RemoteLoggerService.book('Note added',
          bookId: bookId, screen: 'focus_notes');

      // Reload notes
      final notes = await _noteService.getNotes(bookId);
      emit(state.copyWith(notes: notes, isSaving: false));
    } catch (e) {
      RemoteLoggerService.error('Failed to add note',
          screen: 'focus_notes', error: e);
      emit(state.copyWith(isSaving: false, errorMessage: e.toString()));
    }
  }

  /// Take a photo, compress to ≤200KB base64, and save as a note.
  Future<void> addPhotoNote({
    String? content,
    int? pageNumber,
  }) async {
    final bookId = _currentBookId;
    if (bookId == null) return;

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (image == null) return; // User cancelled

      emit(state.copyWith(isSaving: true));

      final base64Image = await ImageCompressUtils.compressToBase64(image.path);
      if (base64Image == null) {
        emit(state.copyWith(isSaving: false, errorMessage: 'Compression failed'));
        return;
      }

      final note = BookNote(
        content: content?.trim(),
        pageNumber: pageNumber,
        imageBase64: base64Image,
      );
      await _noteService.addNote(bookId, note);

      RemoteLoggerService.book('Photo note added',
          bookId: bookId, screen: 'focus_notes');

      final notes = await _noteService.getNotes(bookId);
      emit(state.copyWith(notes: notes, isSaving: false));
    } catch (e) {
      RemoteLoggerService.error('Failed to add photo note',
          screen: 'focus_notes', error: e);
      emit(state.copyWith(isSaving: false, errorMessage: e.toString()));
    }
  }

  /// Pick a photo from gallery, compress, and save.
  Future<void> addPhotoFromGallery({
    String? content,
    int? pageNumber,
  }) async {
    final bookId = _currentBookId;
    if (bookId == null) return;

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (image == null) return;

      emit(state.copyWith(isSaving: true));

      final base64Image = await ImageCompressUtils.compressToBase64(image.path);
      if (base64Image == null) {
        emit(state.copyWith(isSaving: false, errorMessage: 'Compression failed'));
        return;
      }

      final note = BookNote(
        content: content?.trim(),
        pageNumber: pageNumber,
        imageBase64: base64Image,
      );
      await _noteService.addNote(bookId, note);

      RemoteLoggerService.book('Gallery photo note added',
          bookId: bookId, screen: 'focus_notes');

      final notes = await _noteService.getNotes(bookId);
      emit(state.copyWith(notes: notes, isSaving: false));
    } catch (e) {
      RemoteLoggerService.error('Failed to add gallery photo note',
          screen: 'focus_notes', error: e);
      emit(state.copyWith(isSaving: false, errorMessage: e.toString()));
    }
  }

  /// Delete a note.
  Future<void> deleteNote(String noteId) async {
    final bookId = _currentBookId;
    if (bookId == null) return;

    try {
      await _noteService.deleteNote(bookId, noteId);

      RemoteLoggerService.book('Note deleted',
          bookId: bookId, screen: 'focus_notes');

      final notes = await _noteService.getNotes(bookId);
      emit(state.copyWith(notes: notes));
    } catch (e) {
      RemoteLoggerService.error('Failed to delete note',
          screen: 'focus_notes', error: e);
    }
  }
}
