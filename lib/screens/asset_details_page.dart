import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_assignment_group/components/buttons/filled_btn_icon.dart';
import 'package:flutter_assignment_group/components/buttons/outlined_btn_icon.dart';
import 'package:flutter_assignment_group/components/cards/surface_card.dart';
import 'package:flutter_assignment_group/components/layout/app_top_bar.dart';
import 'package:flutter_assignment_group/components/layout/asset_detail_row.dart';
import 'package:flutter_assignment_group/data/firestore_repository.dart';
import 'package:flutter_assignment_group/models/asset_record.dart';

class AssetDetailsPage extends StatefulWidget {
  const AssetDetailsPage({
    super.key,
    required this.repository,
    required this.assetCode,
    required this.actorEmployeeId,
    required this.onBack,
    required this.onEdit,
    required this.onDeleted,
    this.canEditDetails = true,
    this.canDeleteAsset = true,
    this.restrictStatusToUnderRepair = false,
  });

  final FirestoreRepository repository;
  final String assetCode;
  final String actorEmployeeId;
  final VoidCallback onBack;
  final ValueChanged<String> onEdit;
  final VoidCallback onDeleted;
  final bool canEditDetails;
  final bool canDeleteAsset;
  final bool restrictStatusToUnderRepair;

  @override
  State<AssetDetailsPage> createState() => _AssetDetailsPageState();
}

class _AssetDetailsPageState extends State<AssetDetailsPage> {
  bool _isProcessing = false;

  Future<void> _showUpdateStatusDialog(AssetRecord asset) async {
    final noteController = TextEditingController();
    var selectedStatus = widget.restrictStatusToUnderRepair
        ? 'under_repair'
        : asset.status;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setState) {
              final noteLength = noteController.text.length;

              return Dialog(
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Update Status',
                              style: TextStyle(
                                fontSize: 30 / 1.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFF64748B),
                            ),
                            tooltip: 'Close',
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Change the current status of this asset',
                        style: TextStyle(
                          fontSize: 22 / 1.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (widget.restrictStatusToUnderRepair)
                        _StatusOptionTile(
                          title: 'Under Repair',
                          description: 'Send this asset to repair',
                          icon: Icons.build,
                          iconColor: const Color(0xFF2563EB),
                          selected: true,
                          onTap: () =>
                              setState(() => selectedStatus = 'under_repair'),
                        )
                      else ...[
                        _StatusOptionTile(
                          title: 'Normal',
                          description: 'Asset is functioning properly',
                          icon: Icons.check_circle,
                          iconColor: const Color(0xFF16A34A),
                          selected: selectedStatus == 'normal',
                          onTap: () =>
                              setState(() => selectedStatus = 'normal'),
                        ),
                        const SizedBox(height: 10),
                        _StatusOptionTile(
                          title: 'Under Repair',
                          description: 'Asset is currently being serviced',
                          icon: Icons.build,
                          iconColor: const Color(0xFF2563EB),
                          selected: selectedStatus == 'under_repair',
                          onTap: () =>
                              setState(() => selectedStatus = 'under_repair'),
                        ),
                        const SizedBox(height: 10),
                        _StatusOptionTile(
                          title: 'Disposed',
                          description: 'Asset has been removed from inventory',
                          icon: Icons.delete,
                          iconColor: const Color(0xFFDC2626),
                          selected: selectedStatus == 'disposed',
                          onTap: () =>
                              setState(() => selectedStatus = 'disposed'),
                        ),
                      ],
                      const SizedBox(height: 14),
                      const Text(
                        'Notes (Optional)',
                        style: TextStyle(
                          fontSize: 24 / 1.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: noteController,
                        maxLength: 200,
                        minLines: 3,
                        maxLines: 3,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText:
                              'Add any additional information about this status change...',
                          counterText: '',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.all(12),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFCBD5E1),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF2563EB),
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Max $noteLength/200 characters',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF111827),
                                minimumSize: const Size.fromHeight(48),
                                side: const BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                Navigator.of(dialogContext).pop();
                                await _updateStatus(
                                  assetCode: asset.assetCode,
                                  status: widget.restrictStatusToUnderRepair
                                      ? 'under_repair'
                                      : selectedStatus,
                                  note: noteController.text.trim(),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(48),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Confirm Update',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      noteController.dispose();
    }
  }

  Future<void> _updateStatus({
    required String assetCode,
    required String status,
    required String note,
  }) async {
    if (widget.restrictStatusToUnderRepair && status != 'under_repair') {
      _showMessage('You can only send assets to repair.');
      return;
    }

    setState(() => _isProcessing = true);
    try {
      await widget.repository.updateAssetStatus(
        assetCode: assetCode,
        status: status,
        note: note,
        actorEmployeeId: widget.actorEmployeeId,
      );
      _showMessage('Status updated.');
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _confirmDelete(AssetRecord asset) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Delete Asset'),
              content: Text('Delete ${asset.name} permanently?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    setState(() => _isProcessing = true);
    try {
      await widget.repository.deleteAsset(
        asset.assetCode,
        actorEmployeeId: widget.actorEmployeeId,
      );
      if (!mounted) {
        return;
      }
      widget.onDeleted();
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AssetRecord?>(
      stream: widget.repository.watchAsset(widget.assetCode),
      builder: (context, snapshot) {
        final asset = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting &&
            asset == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (asset == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFE5E7EB),
            appBar: AppTopBar(title: 'Asset Details', onBack: widget.onBack),
            body: const Center(child: Text('Asset not found.')),
          );
        }

        final displayImageUrl = _resolveAssetImageUrl(asset.imageUrl);
        final statusButtonText = widget.restrictStatusToUnderRepair
            ? (_isProcessing ? 'Sending...' : 'Send to Repair')
            : (_isProcessing ? 'Updating...' : 'Update Status');

        return Scaffold(
          backgroundColor: const Color(0xFFE5E7EB),
          appBar: AppTopBar(
            title: 'Asset Details',
            onBack: widget.onBack,
            action: IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {},
            ),
          ),
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildAssetImage(displayImageUrl),
                  ),
                  const SizedBox(height: 16),
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    asset.name,
                                    style: const TextStyle(
                                      fontSize: 56 / 1.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF111827),
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    asset.assetCode,
                                    style: const TextStyle(
                                      fontSize: 18 / 1.5,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _statusLabel(asset.status),
                              style: TextStyle(
                                color: _statusColor(asset.status),
                                fontWeight: FontWeight.w600,
                                fontSize: 36 / 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AssetDetailRow(
                          icon: _iconForType(asset.type),
                          label: 'Asset Type',
                          value: asset.type,
                        ),
                        const SizedBox(height: 12),
                        AssetDetailRow(
                          icon: Icons.sell,
                          label: 'Brand',
                          value: asset.brand,
                        ),
                        const SizedBox(height: 12),
                        AssetDetailRow(
                          icon: Icons.format_list_bulleted,
                          label: 'Description',
                          value: asset.description.isEmpty
                              ? '-'
                              : asset.description,
                        ),
                        const SizedBox(height: 12),
                        AssetDetailRow(
                          icon: Icons.location_on,
                          label: 'Location',
                          value: asset.location,
                        ),
                        const SizedBox(height: 12),
                        AssetDetailRow(
                          icon: Icons.calendar_month,
                          label: 'Purchase Date',
                          value: asset.purchaseDate == null
                              ? '-'
                              : _formatDate(asset.purchaseDate!),
                        ),
                        const SizedBox(height: 12),
                        AssetDetailRow(
                          icon: Icons.check_circle,
                          label: 'Current Status',
                          value: _statusLabel(asset.status),
                          valueColor: _statusColor(asset.status),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (widget.canEditDetails) ...[
                    FilledBtnIcon(
                      text: 'Edit Details',
                      icon: Icons.edit_outlined,
                      onPressed: _isProcessing
                          ? null
                          : () => widget.onEdit(asset.assetCode),
                    ),
                    const SizedBox(height: 12),
                  ],
                  FilledBtnIcon(
                    text: statusButtonText,
                    icon: Icons.autorenew,
                    color: FilledBtnColor.gray,
                    onPressed: _isProcessing
                        ? null
                        : () => _showUpdateStatusDialog(asset),
                  ),
                  if (widget.canDeleteAsset) ...[
                    const SizedBox(height: 12),
                    OutlinedBtnIcon(
                      text: 'Delete Asset',
                      icon: Icons.delete,
                      fontColor: OutlinedBtnFontColor.red,
                      onPressed: _isProcessing
                          ? null
                          : () => _confirmDelete(asset),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'under_repair':
        return 'Under Repair';
      case 'disposed':
        return 'Disposed';
      case 'normal':
        return 'Normal';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'under_repair':
        return const Color(0xFFDC2626);
      case 'disposed':
        return const Color(0xFF7C3AED);
      case 'normal':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFF334155);
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'laptop':
      case 'Laptop':
        return Icons.laptop;
      case 'printer':
      case 'Printer':
        return Icons.print;
      case 'chair':
      case 'Office Chair':
        return Icons.chair;
      default:
        return Icons.widgets;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final month = months[date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }

  String _resolveAssetImageUrl(String rawUrl) {
    const fallbackUrl =
        'https://images.unsplash.com/photo-1593642634367-d91a135587b5?w=1200';

    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      return fallbackUrl;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      return fallbackUrl;
    }

    final host = uri.host.toLowerCase();
    if (!host.contains('drive.google.com')) {
      return trimmed;
    }

    final fileId = _extractGoogleDriveFileId(uri);
    if (fileId == null || fileId.isEmpty) {
      return trimmed;
    }

    return 'https://drive.google.com/uc?export=view&id=$fileId';
  }

  Widget _buildAssetImage(String imageUrl) {
    final uri = Uri.tryParse(imageUrl);
    final isNetwork =
        uri != null &&
        (uri.scheme.toLowerCase() == 'http' ||
            uri.scheme.toLowerCase() == 'https');

    if (isNetwork) {
      return Image.network(
        imageUrl,
        height: 280,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImageFallback(),
      );
    }

    final file = File(imageUrl);
    if (!file.existsSync()) {
      return _buildImageFallback();
    }

    return Image.file(
      file,
      height: 280,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildImageFallback(),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      height: 280,
      color: const Color(0xFFD1D5DB),
      alignment: Alignment.center,
      child: const Icon(Icons.laptop_mac, size: 56),
    );
  }

  String? _extractGoogleDriveFileId(Uri uri) {
    final idFromQuery = uri.queryParameters['id'];
    if (idFromQuery != null && idFromQuery.trim().isNotEmpty) {
      return idFromQuery.trim();
    }

    final segments = uri.pathSegments;
    final fileSegmentIndex = segments.indexOf('d');
    if (fileSegmentIndex != -1 && fileSegmentIndex + 1 < segments.length) {
      return segments[fileSegmentIndex + 1].trim();
    }

    return null;
  }
}

class _StatusOptionTile extends StatelessWidget {
  const _StatusOptionTile({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF94A3B8) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 19,
                height: 19,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFCBD5E1),
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Center(
                        child: CircleAvatar(
                          radius: 5,
                          backgroundColor: Color(0xFF2563EB),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 16, color: iconColor),
                      const SizedBox(width: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 23 / 1.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 20 / 1.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
