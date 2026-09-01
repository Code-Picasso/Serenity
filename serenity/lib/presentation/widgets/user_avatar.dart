import 'package:flutter/material.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/utils/url_utils.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double radius;

  const UserAvatar({super.key, required this.name, this.imageUrl, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    final resolved = resolveUrl(imageUrl);
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(RegExp(r'\s+')).map((e) => e[0]).take(2).join().toUpperCase();

    return CircleAvatar(
      radius: radius,
      backgroundColor: context.themeExt.primary,
      backgroundImage: resolved.isNotEmpty ? NetworkImage(resolved) : null,
      child: resolved.isEmpty
          ? Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: radius * 0.8,
              ),
            )
          : null,
    );
  }
}
