import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'xfile_image_io.dart' if (dart.library.html) 'xfile_image_web.dart' as impl;

/// XFile을 웹/모바일 호환 방식으로 표시하는 위젯
class XFileImage extends StatelessWidget {
  final XFile? image;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const XFileImage({
    super.key,
    required this.image,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (image == null) {
      return placeholder ??
          Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Icon(Icons.image),
          );
    }

    // 조건부 import를 사용하여 웹/비웹 환경에서 다른 구현 사용
    return impl.XFileImageImpl.buildImage(
      image: image!,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }
}

