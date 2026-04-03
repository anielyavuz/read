import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/scan_constants.dart';
import '../../../core/services/page_scanner_service.dart';
import 'page_scan_state.dart';

class PageScanCubit extends Cubit<PageScanState> {
  final PageScannerService _scannerService;
  final ImagePicker _picker = ImagePicker();

  PageScanCubit({required PageScannerService scannerService})
      : _scannerService = scannerService,
        super(const PageScanState());

  int get remainingSlots => maxScanPages - state.imagePaths.length;

  /// Pick image from camera.
  Future<void> pickFromCamera() async {
    if (remainingSlots <= 0) return;
    emit(state.copyWith(status: PageScanStatus.capturing));

    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: scanImageQuality,
      );
      if (photo != null) {
        final updated = [...state.imagePaths, photo.path];
        emit(state.copyWith(
          status: PageScanStatus.initial,
          imagePaths: updated,
        ));
      } else {
        emit(state.copyWith(status: PageScanStatus.initial));
      }
    } catch (e) {
      emit(state.copyWith(
        status: PageScanStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Pick images from gallery.
  /// Uses single-image picker on iOS simulator (multi-select UI is broken),
  /// multi-image picker on real devices.
  Future<void> pickFromGallery() async {
    if (remainingSlots <= 0) return;
    emit(state.copyWith(status: PageScanStatus.capturing));

    try {
      final isSimulator = Platform.isIOS &&
          Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');

      if (isSimulator) {
        await _pickSingleFromGallery();
      } else {
        await _pickMultiFromGallery();
      }
    } catch (e) {
      emit(state.copyWith(
        status: PageScanStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _pickMultiFromGallery() async {
    final photos = await _picker.pickMultiImage(
      imageQuality: scanImageQuality,
      limit: remainingSlots,
    );
    if (photos.isNotEmpty) {
      final paths = photos.map((p) => p.path).toList();
      final allowed = paths.take(remainingSlots).toList();
      final updated = [...state.imagePaths, ...allowed];
      emit(state.copyWith(
        status: PageScanStatus.initial,
        imagePaths: updated,
      ));
    } else {
      emit(state.copyWith(status: PageScanStatus.initial));
    }
  }

  Future<void> _pickSingleFromGallery() async {
    final photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: scanImageQuality,
    );
    if (photo != null) {
      final updated = [...state.imagePaths, photo.path];
      emit(state.copyWith(
        status: PageScanStatus.initial,
        imagePaths: updated,
      ));
    } else {
      emit(state.copyWith(status: PageScanStatus.initial));
    }
  }

  /// Remove an image by index.
  void removeImage(int index) {
    if (index < 0 || index >= state.imagePaths.length) return;
    final updated = [...state.imagePaths]..removeAt(index);
    emit(state.copyWith(imagePaths: updated));
  }

  /// Process all captured images through OCR.
  Future<void> processAllImages() async {
    if (state.imagePaths.isEmpty) return;
    emit(state.copyWith(status: PageScanStatus.processing));

    try {
      final pages = await _scannerService.processImages(state.imagePaths);
      emit(state.copyWith(
        status: PageScanStatus.previewReady,
        scannedPages: pages,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PageScanStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Reset to initial state.
  void reset() {
    emit(const PageScanState());
  }
}
