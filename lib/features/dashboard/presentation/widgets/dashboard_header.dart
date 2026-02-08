import 'package:flutter/material.dart';
import '../../../../../../core/widgets/glass_card.dart';
import '../../../../../../core/network/api_client.dart';

import '../../../../features/auth/domain/entities/user.dart';
import '../../../../../../injection_container.dart';
import '../../../../features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/providers/user_provider.dart';
import '../../../../features/auth/presentation/pages/change_password/change_password_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert'; // For base64Decode

class DashboardHeader extends StatefulWidget {
  final User? user;
  final VoidCallback onLogout;

  const DashboardHeader({
    super.key,
    required this.user,
    required this.onLogout,
    this.isPlaceholder = false,
  });

  final bool isPlaceholder;

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader> {
  bool _isExpanded = false;
  User? _selectedSupervisor;
  List<User> _supervisors = [];
  bool _isLoadingSupervisors = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isPlaceholder) {
      _fetchSupervisors();
    }
  }

  Future<void> _fetchSupervisors() async {
    setState(() => _isLoadingSupervisors = true);
    try {
      final repository = sl<AuthRepository>();
      final result = await repository.getAtasanList();

      if (mounted) {
        setState(() {
          _supervisors = result;

          // Pre-select supervisor if user has one saved
          if (widget.user?.atasanId != null &&
              widget.user!.atasanId!.isNotEmpty) {
            try {
              final savedAtasan = _supervisors.firstWhere(
                (s) => s.id == widget.user!.atasanId,
              );
              _selectedSupervisor = savedAtasan;
            } catch (e) {
              // Saved atasan not found in current list (maybe inactive?)
              debugPrint("Saved supervisor not found in list: $e");
            }
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching supervisors: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingSupervisors = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    // debugPrint("SAVE BUTTON PRESSED");
    // debugPrint(
    //   "Selected Supervisor: ${_selectedSupervisor?.id} - ${_selectedSupervisor?.name}",
    // );

    if (_selectedSupervisor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih atasan terlebih dahulu')),
      );
      return;
    }

    if (_selectedSupervisor!.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data Atasan tidak valid (ID kosong)')),
      );
      return;
    }

    // Show loading indicator or simple message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Menyimpan perubahan...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      final repository = sl<AuthRepository>();
      // Update Atasan ID
      await repository.updateAtasan(_selectedSupervisor!.id);

      // Refresh Profile & Local Cache (implicitly via getProfile)
      final freshUser = await repository.getProfile();

      if (mounted) {
        // Update Riverpod Provider
        try {
          // Find the provider context properly
          // Note: Since DashboardHeader is a StatefulWidget child of DashboardView,
          // we might need to use a Consumer or ProviderScope to access the notifier.

          // Using ProviderScope.containerOf might vary depending on setup,
          // but usually context works if inside scope.
          // However, to be safe and clean, let's wrap DashboardHeader in a Consumer in the parent?
          // Or just use the global container lookup if standard.

          // Simpler: Just rely on the cache update?
          // But the UI (DashboardHeader name/etc) comes from 'widget.user'.
          // 'widget.user' is passed from DashboardView which watches userProvider.
          // So if we update userProvider, DashboardView rebuilds and passes new user to us.

          // We need 'ref' to update the provider. DashboardHeader is not a ConsumerWidget.
          // We can use context using Riverpod's standard 'ProviderScope.containerOf(context)'

          final container = ProviderScope.containerOf(context, listen: false);
          container.read(userProvider.notifier).setUser(freshUser);
        } catch (e) {
          debugPrint("Provider update error: $e");
        }

        // Show Success Dialog
        _showSuccessDialog(_selectedSupervisor!.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    }
  }

  void _showSuccessDialog(String supervisorName) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 48,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Berhasil Disimpan!",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.5,
                      fontFamily: 'Inter',
                    ),
                    children: [
                      const TextSpan(
                        text: "Atasan berhasil diperbarui menjadi\n",
                      ),
                      TextSpan(
                        text: supervisorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const TextSpan(text: "."),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Oke, Lanjut",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isUploadingPhoto = false;

  String _resolvePhotoUrl(String url) {
    if (url.startsWith('http') || url.startsWith('https')) return url;

    try {
      final apiClient = sl<ApiClient>();
      String baseUrl = apiClient.dio.options.baseUrl;

      // Ensure single slash between base and path
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }
      if (!url.startsWith('/')) {
        url = '/$url';
      }

      return '$baseUrl$url';
    } catch (e) {
      // Fallback if DI fails (unlikely)
      return url;
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Ganti Foto Profil",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPhotoOption(
                  icon: Icons.camera_alt_rounded,
                  label: "Kamera",
                  onTap: () {
                    Navigator.pop(context);
                    _processImage(ImageSource.camera);
                  },
                ),
                _buildPhotoOption(
                  icon: Icons.photo_library_rounded,
                  label: "Galeri",
                  onTap: () {
                    Navigator.pop(context);
                    _processImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.blue, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _processImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800, // Optimize size
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        final sizeInBytes = await file.length();
        final sizeInMb = sizeInBytes / (1024 * 1024);

        if (sizeInMb > 2) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Ukuran foto terlalu besar. Maksimal 2MB.',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        _uploadPhoto(file);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal mengambil gambar')));
      }
    }
  }

  // Cache buster for profile photo
  int? _profileUpdateTimestamp;

  Future<void> _uploadPhoto(File photo) async {
    setState(() => _isUploadingPhoto = true);
    try {
      final repository = sl<AuthRepository>();
      await repository.updateProfilePhoto(photo);

      // Refresh Profile
      final freshUser = await repository.getProfile();

      if (mounted) {
        // Update Riverpod
        final container = ProviderScope.containerOf(context, listen: false);
        container.read(userProvider.notifier).setUser(freshUser);

        // Update local timestamp to force image refresh
        setState(() {
          _profileUpdateTimestamp = DateTime.now().millisecondsSinceEpoch;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto Profil berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal upload: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPlaceholder) {
      // Invisible placeholder ensuring exact same height
      return IgnorePointer(
        child: Opacity(opacity: 0.0, child: _buildContent(context)),
      );
    }
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top,
        24,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Glass Profile Card with Animation
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: GlassCard(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              borderRadius: 24,
              opacity: 0.1,
              blur: 20,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 0.8,
              ),
              child: Column(
                children: [
                  // Header Row (Compact)
                  _buildHeaderRow(),

                  // Expanded Content
                  if (_isExpanded) ...[
                    const SizedBox(height: 4), // Reduced from 20 to 4
                    _buildExpandedDetails(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(String url) {
    // Check if it's a Base64 Data URI
    if (url.startsWith('data:image')) {
      try {
        final base64String = url.split(',').last;
        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint("Base64 Image Error: $error");
            return const Icon(Icons.person, size: 28, color: Colors.white);
          },
        );
      } catch (e) {
        debugPrint("Error decoding base64 image: $e");
        return const Icon(Icons.person, size: 28, color: Colors.white);
      }
    }

    // Standard Network Image
    final resolvedUrl =
        _resolvePhotoUrl(url) +
        (_profileUpdateTimestamp != null
            ? '${url.contains('?') ? '&' : '?'}v=$_profileUpdateTimestamp'
            : '');

    return Image.network(
      resolvedUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        debugPrint("IMAGE ERROR: $error");
        debugPrint("Failed URL: $resolvedUrl");
        return const Icon(Icons.person, size: 28, color: Colors.white);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                : null,
            color: Colors.white,
            strokeWidth: 2,
          ),
        );
      },
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // User Details (Left)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.user?.name ?? 'Nama Pengguna',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                widget.user?.nip ?? '-',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.user?.jabatan ?? 'Jabatan',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // Profile Avatar & Dropdown Button (Right)
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: _isUploadingPhoto
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : (widget.user?.photoUrl != null
                              ? ClipOval(
                                  child: _buildProfileImage(
                                    widget.user!.photoUrl!,
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 28,
                                  color: Colors.white,
                                )),
                  ),
                  // Camera Icon Overlay
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Icon(
                _isExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 24,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Divider
        Divider(
          color: Colors.white.withValues(alpha: 0.2),
          height: 16,
        ), // Reduced from 30 to 16
        // Organization Details (Bidang)
        _buildDetailRow(
          Icons.business_rounded,
          widget.user?.bidang ?? 'Bidang Belum Diatur',
        ),
        const SizedBox(height: 12),
        // Location (Organisasi / Unit Kerja)
        _buildDetailRow(
          Icons.location_on_rounded,
          widget.user?.organization ??
              widget.user?.unitKerja ??
              'Kantor Walikota',
        ),

        const SizedBox(height: 24),

        // Atasan Dropdown
        Text(
          "Atasan Langsung",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: _isLoadingSupervisors
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<User>(
                    value: _selectedSupervisor,
                    hint: Text(
                      "Pilih Atasan",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 15,
                      ),
                    ),
                    dropdownColor: const Color(0xFF1E1E2C),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white70,
                    ),
                    isExpanded: true,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    onChanged: (User? newValue) {
                      setState(() {
                        _selectedSupervisor = newValue;
                      });
                    },
                    items: _supervisors.map<DropdownMenuItem<User>>((
                      User value,
                    ) {
                      return DropdownMenuItem<User>(
                        value: value,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person_outline_rounded,
                              color: Colors.white70,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    value.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (value.jabatan != null)
                                    Text(
                                      value.jabatan!,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ),

        const SizedBox(height: 24),

        // Action Buttons (Password & Save)
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.lock_reset_rounded, size: 16),
                label: const Text("Ubah Sandi"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _saveProfile,
                icon: const Icon(Icons.save_rounded, size: 16),
                label: const Text("Simpan"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1565C0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Logout Button
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.redAccent.shade200, Colors.redAccent.shade700],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: widget.onLogout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text(
              "Keluar Aplikasi",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
