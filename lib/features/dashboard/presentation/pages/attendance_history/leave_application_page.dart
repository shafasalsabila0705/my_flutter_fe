import 'package:flutter/material.dart';
import '../../../../../../core/widgets/glass_card.dart';
import '../../../../../../core/widgets/custom_dropdown.dart';
import '../../../../../../core/constants/colors.dart'; // Added Import

import '../../../../../../injection_container.dart';
import '../../../../auth/domain/repositories/auth_repository.dart';
import '../../../../auth/domain/entities/user.dart';
import '../../../domain/repositories/leave_repository.dart';

class LeaveApplicationPage extends StatefulWidget {
  const LeaveApplicationPage({super.key});

  @override
  State<LeaveApplicationPage> createState() => _LeaveApplicationPageState();
}

class _LeaveApplicationPageState extends State<LeaveApplicationPage> {
  final TextEditingController _atasanController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  bool _isLoading = false; // Added state

  String? _selectedLeaveType;
  final List<String> _leaveTypes = ["DINAS LUAR", "BIMTEK", "TUBEL"];

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      // Use getProfile to ensure we have the latest supervisor data from server
      final user = await sl<AuthRepository>().getProfile();
      if (mounted) {
        String supervisorName = user.atasanNama ?? user.atasanId ?? "-";

        // If the name seems to be an ID (e.g. "5") or is empty, try to resolve it from the list
        bool nameIsId = supervisorName == user.atasanId;
        bool nameIsDigit = int.tryParse(supervisorName) != null;

        if (nameIsId ||
            nameIsDigit ||
            supervisorName.isEmpty ||
            supervisorName == "-") {
          try {
            final supervisors = await sl<AuthRepository>().getAtasanList();
            final supervisor = supervisors.firstWhere(
              (s) => s.id.toString() == user.atasanId.toString(),
              orElse: () => User(id: '', nip: '', name: '-'), // Dummy fallback
            );
            if (supervisor.name != '-') {
              supervisorName = supervisor.name;
            }
          } catch (e) {
            debugPrint("Error resolving supervisor name: $e");
          }
        }

        setState(() {
          _atasanController.text = supervisorName;
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Full Screen Background
          Positioned.fill(
            child: Image.asset(
              'assets/img/balai.jpeg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: const Color(0xFF1A1A2E)),
            ),
          ),
          // Gradient Overlay (Soft Blue)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(
                      alpha: 0.3,
                    ), // Consistent Black Overlay
                    Colors.black.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 2. Main Content
          SafeArea(
            bottom: false, // Fix "batas di bawah"
            child: Stack(
              children: [
                // Body Layer (Scrollable Wrapper)
                SingleChildScrollView(
                  child: Column(
                    children: [
                      // Transparent Spacer (Pushes content down)
                      SizedBox(
                        height:
                            MediaQuery.of(context).size.height *
                            0.52, // Lowered slightly
                      ),

                      // White Container (Content)
                      Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          minHeight:
                              MediaQuery.of(context).size.height *
                              0.48, // Fills remaining space
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 20,
                              offset: Offset(0, -5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            24,
                            32,
                            24,
                            40,
                          ), // Adjusted Padding
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Atasan"),
                              _buildTextField(
                                controller: _atasanController,
                                readOnly: true, // Assuming auto-filled
                                icon: Icons.person_outline_rounded,
                              ),
                              const SizedBox(height: 20),

                              _buildLabel("Jenis Izin"),
                              _buildDropdown(),
                              const SizedBox(height: 20),

                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel("Tanggal Mulai"),
                                        const SizedBox(
                                          height: 8,
                                        ), // Added spacing
                                        _buildTextField(
                                          controller: _startTimeController,
                                          readOnly: true,
                                          hintText: "- Pilih -",
                                          icon: Icons.calendar_today_rounded,
                                          onTap: () async {
                                            final pickedDate = await showDatePicker(
                                              context: context,
                                              initialDate: DateTime.now(),
                                              firstDate:
                                                  DateTime.now(), // Disable Past Dates
                                              lastDate: DateTime(2101),
                                            );
                                            if (pickedDate != null) {
                                              String day = pickedDate.day
                                                  .toString()
                                                  .padLeft(2, '0');
                                              String month = pickedDate.month
                                                  .toString()
                                                  .padLeft(2, '0');
                                              // Format: YYYY-MM-DD
                                              _startTimeController.text =
                                                  "${pickedDate.year}-$month-$day";
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel("Tanggal Selesai"),
                                        const SizedBox(
                                          height: 8,
                                        ), // Added spacing
                                        _buildTextField(
                                          controller: _endTimeController,
                                          readOnly: true,
                                          hintText: "- Pilih -",
                                          icon: Icons.calendar_today_rounded,
                                          onTap: () async {
                                            final pickedDate = await showDatePicker(
                                              context: context,
                                              initialDate: DateTime.now(),
                                              firstDate:
                                                  DateTime.now(), // Disable Past Dates
                                              lastDate: DateTime(2101),
                                            );
                                            if (pickedDate != null) {
                                              String day = pickedDate.day
                                                  .toString()
                                                  .padLeft(2, '0');
                                              String month = pickedDate.month
                                                  .toString()
                                                  .padLeft(2, '0');
                                              // Format: YYYY-MM-DD
                                              _endTimeController.text =
                                                  "${pickedDate.year}-$month-$day";
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24), // Reduced spacing
                              // Submit Button (Gradient)
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primaryBlue.withValues(
                                        alpha: 0.8,
                                      ),
                                      AppColors.primaryBlue,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryBlue.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _submitLeaveRequest,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          "Simpan",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Header Layer (Appears Fixed visually on top)
                Positioned(
                  top: 20,
                  left: 24,
                  right: 24,
                  child: _buildAppBar(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ... (Header and Labels remain unchanged)

  Widget _buildAppBar(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: GlassCard(
          borderRadius: 30,
          opacity: 0.3,
          blur: 30,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: const Row(
              children: [
                Icon(Icons.arrow_back, color: Colors.white),
                SizedBox(width: 16),
                Text(
                  "Ajukan Izin",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    bool readOnly = false,
    VoidCallback? onTap,
    String? hintText,
    IconData? icon,
    int maxLines = 1, // Added
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        maxLines: maxLines, // Passed
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: icon != null ? Icon(icon, color: Colors.grey[500]) : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return CustomDropdown<String>(
      value: _selectedLeaveType,
      hint: "Pilih Izin",
      prefixIcon: Icons.category_outlined,
      items: _leaveTypes.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Row(
            children: [
              Icon(Icons.category_outlined, color: Colors.blue[700], size: 20),
              const SizedBox(width: 12),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          _selectedLeaveType = newValue;
        });
      },
    );
  }

  Future<void> _submitLeaveRequest() async {
    // 1. Validate
    if (_selectedLeaveType == null ||
        _startTimeController.text.isEmpty ||
        _endTimeController.text.isEmpty) {
      _showNotification(context, "Harap lengkapi semua kolom!", true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Call API
      // Note: 'tipe' in DB might map to 'izin', 'sakit', 'cuti'.
      // 'jenisIzin' is the dropdown value.

      // Dates are already in yyyy-MM-dd format from picker

      await sl<LeaveRepository>().applyLeave(
        tipe: "IZIN", // Uppercase to match backend
        jenisIzin: _selectedLeaveType!,
        tanggalMulai: _startTimeController.text,
        tanggalSelesai: _endTimeController.text,
        keterangan: "-",
      );

      if (mounted) {
        _showSuccessDialog(context);
      }
    } catch (e) {
      if (mounted) {
        _showNotification(context, "Gagal mengajukan: $e", true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const CircleAvatar(
                  backgroundColor: Colors.transparent,
                  radius: 50,
                  child: Icon(
                    Icons.check_circle,
                    size: 80,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  "Berhasil!",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Pengajuan izin berhasil dikirim.\nSilakan cek status di riwayat.",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(true); // Close page & refresh
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      "OK",
                      style: TextStyle(fontSize: 16, color: Colors.white),
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

  void _showNotification(BuildContext context, String message, bool isError) {
    // ... existing implementation ...
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isError ? Colors.redAccent : Colors.green,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }
}
