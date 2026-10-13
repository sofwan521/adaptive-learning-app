import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/models/concept_status.dart';

/// Galeri komponen sementara untuk melihat design system.
///
/// Rute: `/dev/gallery`. Tanpa logika bisnis — hanya tampilan.
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Galeri Komponen')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Warna', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            const _ColorSwatches(),
            const SizedBox(height: 24),
            Text('Tipografi', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Judul Poppins', style: textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Isi minimal 16 sp dengan font Inter. Contoh paragraf '
                    'ini memakai gaya isi agar keterbacaan terjaga.',
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Tombol (tinggi min. 48 dp)', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            const AppButton(label: 'Tombol Primer', icon: Icons.arrow_forward),
            const SizedBox(height: 8),
            const AppButton(
              label: 'Tombol Sekunder',
              variant: AppButtonVariant.secondary,
            ),
            const SizedBox(height: 8),
            const AppButton(label: 'Memuat…', isLoading: true),
            const SizedBox(height: 24),
            Text('Bidang Teks', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            const AppTextField(
              label: 'Nama lengkap',
              hint: 'Contoh: Budi Santoso',
            ),
            const SizedBox(height: 8),
            const AppTextField(
              label: 'Kata sandi',
              hint: 'Minimal 6 karakter',
              obscureText: true,
            ),
            const SizedBox(height: 8),
            const AppTextField(
              label: 'Surel',
              hint: 'nama@contoh.id',
              errorText: 'Format surel tidak valid',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            Text('Kartu dan Chip Status', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            AppCard(
              onTap: () {},
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Persamaan Linear',
                        style: textTheme.titleMedium,
                      ),
                      const Spacer(),
                      const XpBadge(xp: 50),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contoh kartu konsep yang dapat diketuk.',
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ConceptStatusChip(status: ConceptStatus.locked),
                ConceptStatusChip(status: ConceptStatus.open),
                ConceptStatusChip(status: ConceptStatus.learning),
                ConceptStatusChip(status: ConceptStatus.mastered),
              ],
            ),
            const SizedBox(height: 24),
            Text('Umpan Balik', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            const AppCard(
              child: SizedBox(
                height: 140,
                child: LoadingView(message: 'Memuat materi…'),
              ),
            ),
            const SizedBox(height: 8),
            const AppCard(
              child: SizedBox(
                height: 220,
                child: ErrorView(
                  message: 'Tidak dapat memuat data. Periksa koneksi.',
                  onRetry: null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const AppCard(
              child: SizedBox(
                height: 140,
                child: EmptyView(message: 'Belum ada konsep di sini.'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatches extends StatelessWidget {
  const _ColorSwatches();

  @override
  Widget build(BuildContext context) {
    const swatches = [
      (AppColors.primary, 'Primer'),
      (AppColors.secondary, 'Sekunder'),
      (AppColors.background, 'Latar'),
      (AppColors.error, 'Galat'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (color, label) in swatches)
          Container(
            width: 110,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: label == 'Sekunder' || label == 'Latar'
                        ? Colors.black87
                        : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
      ],
    );
  }
}
