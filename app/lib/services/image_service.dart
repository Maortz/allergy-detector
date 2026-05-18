import 'package:image_picker/image_picker.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickFromCamera() => _picker.pickImage(
    source: ImageSource.camera,
    imageQuality: 85,
    maxWidth: 1024,
    maxHeight: 1024,
  );

  Future<XFile?> pickFromGallery() => _picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
    maxWidth: 1024,
    maxHeight: 1024,
  );
}
