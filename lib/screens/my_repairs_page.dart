import 'package:flutter/material.dart';
import 'package:flutter_assignment_group/components/cards/recent_activity_card.dart';
import 'package:flutter_assignment_group/components/cards/surface_card.dart';
import 'package:flutter_assignment_group/components/layout/app_top_bar.dart';
import 'package:flutter_assignment_group/data/firestore_repository.dart';
import 'package:flutter_assignment_group/models/asset_activity_record.dart';
import 'package:flutter_assignment_group/models/asset_record.dart';

class MyRepairsPage extends StatelessWidget {
  const MyRepairsPage({
    super.key,
    required this.repository,
    required this.employeeId,
    required this.onOpenDetail,
    required this.onOpenScan,
    required this.onOpenProfile,
    required this.onLogout,
  });

  final FirestoreRepository repository;
  final String employeeId;
  final ValueChanged<String> onOpenDetail;
  final VoidCallback onOpenScan;
  final VoidCallback onOpenProfile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AssetActivityRecord>>(
      stream: repository.watchActivities(limit: 600),
      builder: (context, logsSnapshot) {
        final logs = logsSnapshot.data ?? const <AssetActivityRecord>[];
        final requestedLogs = _latestRepairRequestsByEmployee(logs, employeeId);

        return StreamBuilder<List<AssetRecord>>(
          stream: repository.watchAssets(),
          builder: (context, assetsSnapshot) {
            final assets = assetsSnapshot.data ?? const <AssetRecord>[];
            final assetsByCode = <String, AssetRecord>{
              for (final asset in assets) asset.assetCode: asset,
            };

            return Scaffold(
              backgroundColor: const Color(0xFFE5E7EB),
              appBar: AppTopBar(
                title: 'My Repairs',
                showBack: false,
                action: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: onLogout,
                ),
              ),
              body: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: onOpenScan,
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Scan Asset'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SurfaceCard(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                        child: Row(
                          children: [
                            const Icon(Icons.handyman_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'My repair requests: ${requestedLogs.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Repair Status',
                        style: TextStyle(
                          fontSize: 44 / 1.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: requestedLogs.isEmpty
                            ? const Center(
                                child: Text(
                                  'No repair requests yet.\nScan an asset and send it to repair.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Color(0xFF64748B)),
                                ),
                              )
                            : ListView.builder(
                                itemCount: requestedLogs.length,
                                itemBuilder: (context, index) {
                                  final log = requestedLogs[index];
                                  final asset = assetsByCode[log.assetId];
                                  final currentStatus =
                                      asset?.status ?? 'unknown';

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: RecentActivityCard(
                                      title: asset?.name.isNotEmpty == true
                                          ? asset!.name
                                          : log.assetId,
                                      activityText:
                                          'Requested ${_formatDate(log.createdAt)}',
                                      timeText: asset?.assetCode ?? log.assetId,
                                      statusText: _statusLabel(currentStatus),
                                      statusColor: _statusColor(currentStatus),
                                      iconColor: _statusColor(currentStatus),
                                      icon: _iconForType(asset?.type),
                                      onTap: asset == null
                                          ? null
                                          : () => onOpenDetail(asset.assetCode),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: 0,
                selectedItemColor: Colors.black,
                unselectedItemColor: Colors.black,
                onTap: (index) {
                  if (index == 1) {
                    onOpenScan();
                  } else if (index == 2) {
                    onOpenProfile();
                  }
                },
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.search),
                    label: 'Search',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<AssetActivityRecord> _latestRepairRequestsByEmployee(
    List<AssetActivityRecord> logs,
    String targetEmployeeId,
  ) {
    final filtered =
        logs
            .where(
              (log) =>
                  log.actorEmployeeId == targetEmployeeId &&
                  log.toStatus == 'under_repair',
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final byAsset = <String, AssetActivityRecord>{};
    for (final log in filtered) {
      byAsset.putIfAbsent(log.assetId, () => log);
    }
    return byAsset.values.toList();
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'under_repair':
        return 'Under Repair';
      case 'normal':
        return 'Normal';
      case 'disposed':
        return 'Disposed';
      case 'unknown':
        return 'Not Found';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'under_repair':
        return const Color(0xFFDC2626);
      case 'normal':
        return const Color(0xFF16A34A);
      case 'disposed':
        return const Color(0xFF7C3AED);
      case 'unknown':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF2563EB);
    }
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'Laptop':
      case 'laptop':
        return Icons.laptop;
      case 'Printer':
      case 'printer':
        return Icons.print;
      case 'Office Chair':
      case 'chair':
        return Icons.chair;
      default:
        return Icons.widgets;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
