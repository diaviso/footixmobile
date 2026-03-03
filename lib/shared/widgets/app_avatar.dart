import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_constants.dart';

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? firstName;
  final String? lastName;
  final double size;
  final bool showBorder;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.firstName,
    this.lastName,
    this.size = 40,
    this.showBorder = false,
  });

  String get _initials {
    final f = (firstName?.isNotEmpty == true) ? firstName![0].toUpperCase() : '';
    final l = (lastName?.isNotEmpty == true) ? lastName![0].toUpperCase() : '';
    return '$f$l';
  }

  String? get _fullUrl {
    if (imageUrl == null || imageUrl!.isEmpty) return null;
    if (imageUrl!.startsWith('http')) return imageUrl;
    return '${ApiConstants.baseUrl}$imageUrl';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: AppColors.primary, width: 2)
            : null,
      ),
      child: ClipOval(
        child: _fullUrl != null
            ? CachedNetworkImage(
                imageUrl: _fullUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (context, url) => _placeholder(),
                errorWidget: (context, url, error) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      color: AppColors.primarySurface,
      alignment: Alignment.center,
      child: Text(
        _initials.isNotEmpty ? _initials : '?',
        style: GoogleFonts.inter(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
