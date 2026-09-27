import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../theme/app_theme.dart';

class CustomAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double size;
  final bool isOnline;
  final bool showOnlineBadge;
  final bool isGroup;

  const CustomAvatar({
    super.key,
    this.avatarUrl,
    required this.name,
    this.size = 44,
    this.isOnline = false,
    this.showOnlineBadge = false,
    this.isGroup = false,
  });

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final fullUrl = AppConfig.getFullMediaUrl(avatarUrl);
    final hasValidImage = fullUrl.isNotEmpty && !fullUrl.endsWith('/');

    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isGroup
                ? const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF047857)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size / 2),
            child: hasValidImage
                ? CachedNetworkImage(
                    imageUrl: fullUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: Text(
                        _getInitials(name),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: size * 0.38,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: isGroup
                          ? Icon(Icons.groups_rounded, color: Colors.white, size: size * 0.5)
                          : Text(
                              _getInitials(name),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: size * 0.38,
                              ),
                            ),
                    ),
                  )
                : Center(
                    child: isGroup
                        ? Icon(Icons.groups_rounded, color: Colors.white, size: size * 0.5)
                        : Text(
                            _getInitials(name),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: size * 0.38,
                            ),
                          ),
                  ),
          ),
        ),
        if (showOnlineBadge && !isGroup)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline ? AppColors.online : AppColors.offline,
                border: Border.all(
                  color: AppColors.surface,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
