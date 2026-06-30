import 'dart:io';

import 'package:flutter/material.dart';

import '../models/kalip.dart';
import '../theme/app_theme.dart';

/// Listede tek bir kalıbı gösteren cam efektli kart.
class KalipCard extends StatelessWidget {
  const KalipCard({
    super.key,
    required this.kalip,
    required this.onTap,
  });

  final Kalip kalip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Hero(
                tag: 'kalip-foto-${kalip.id}',
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [AppColors.mor, AppColors.camgobegi],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: kalip.fotoYolu != null &&
                          File(kalip.fotoYolu!).existsSync()
                      ? Image.file(File(kalip.fotoYolu!), fit: BoxFit.cover)
                      : const Icon(Icons.qr_code_2_rounded,
                          color: Colors.white, size: 30),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kalip.numara,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if ((kalip.ad ?? '').isNotEmpty)
                      Text(
                        kalip.ad!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _etiket(context, Icons.tag_rounded, kalip.kod,
                            AppColors.morAcik),
                        _etiket(context, Icons.grid_view_rounded,
                            'Reyon ${kalip.reyon}', AppColors.camgobegi),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _etiket(
      BuildContext context, IconData icon, String metin, Color renk) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: renk),
          const SizedBox(width: 5),
          Text(
            metin,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: renk,
            ),
          ),
        ],
      ),
    );
  }
}
