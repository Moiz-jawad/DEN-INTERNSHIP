import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class RoundedImageNetwork extends StatelessWidget {
  final String imagePath;
  final double size;

  const RoundedImageNetwork({
    super.key,
    required this.imagePath,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        image: DecorationImage(
          fit: BoxFit.cover,
          image: NetworkImage(imagePath),
        ),
        borderRadius: BorderRadius.circular(size / 2),
        color: Colors.black,
      ),
    );
  }
}

class RoundedImageFile extends StatelessWidget {
  final PlatformFile image;
  final double size;

  const RoundedImageFile({super.key, required this.image, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        image: DecorationImage(
          fit: BoxFit.cover,
          image: FileImage(File(image.path)),
        ),
        borderRadius: BorderRadius.circular(size / 2),
        color: Colors.black,
      ),
    );
  }
}

class RoundedImageNetworkWithStatusIndicator extends StatelessWidget {
  final String imagePath;
  final double size;
  final bool isActive;

  const RoundedImageNetworkWithStatusIndicator({
    super.key,
    required this.imagePath,
    required this.size,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final double indicatorSize = size * 0.20;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomRight,
      children: [
        RoundedImageNetwork(imagePath: imagePath, size: size),
        Container(
          height: indicatorSize,
          width: indicatorSize,
          decoration: BoxDecoration(
            color: isActive ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(indicatorSize / 2),
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ],
    );
  }
}
