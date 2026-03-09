import 'package:flutter/material.dart';
import 'package:flutter_assignment_group/data/firestore_repository.dart';
import 'package:flutter_assignment_group/screens/add_asset_page.dart';
import 'package:flutter_assignment_group/screens/asset_details_page.dart';
import 'package:flutter_assignment_group/screens/dashboard_page.dart';
import 'package:flutter_assignment_group/screens/edit_asset_page.dart';
import 'package:flutter_assignment_group/screens/login_page.dart';
import 'package:flutter_assignment_group/screens/my_repairs_page.dart';
import 'package:flutter_assignment_group/screens/profile_page.dart';
import 'package:flutter_assignment_group/screens/scan_qr_page.dart';
import 'package:flutter_assignment_group/screens/search_page.dart';

class AssetTrackApp extends StatelessWidget {
  const AssetTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFE5E7EB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D66DF),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2D66DF),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2D66DF),
            foregroundColor: Colors.white,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2D66DF),
          ),
        ),
      ),
      home: _AssetTrackShell(),
    );
  }
}

enum _AppPage {
  login,
  dashboard,
  details,
  addAsset,
  editAsset,
  scanQr,
  myRepairs,
  search,
  profile,
}

class _AssetTrackShell extends StatefulWidget {
  const _AssetTrackShell();

  @override
  State<_AssetTrackShell> createState() => _AssetTrackShellState();
}

class _AssetTrackShellState extends State<_AssetTrackShell> {
  final FirestoreRepository _repository = FirestoreRepository();
  _AppPage _currentPage = _AppPage.login;
  String? _selectedAssetCode;
  String _currentEmployeeId = 'EMP-1908';
  String _currentUserRole = 'inventory_officer';

  bool get _isRepairUser => _normalizeRole(_currentUserRole) == 'user';

  String _normalizeRole(String role) {
    return role.trim().toLowerCase().replaceAll(' ', '_');
  }

  _AppPage _homePageForCurrentRole() {
    return _isRepairUser ? _AppPage.myRepairs : _AppPage.dashboard;
  }

  _AppPage _sanitizePageForCurrentRole(_AppPage page) {
    if (!_isRepairUser) {
      return page;
    }

    switch (page) {
      case _AppPage.login:
      case _AppPage.scanQr:
      case _AppPage.myRepairs:
      case _AppPage.details:
      case _AppPage.profile:
        return page;
      case _AppPage.dashboard:
      case _AppPage.addAsset:
      case _AppPage.editAsset:
      case _AppPage.search:
        return _AppPage.myRepairs;
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

  Future<void> _logout() async {
    _currentEmployeeId = 'EMP-1908';
    _currentUserRole = 'inventory_officer';
    await _navigateToPage(_AppPage.login, clearSelectedAssetCode: true);
  }

  Future<void> _navigateToPage(
    _AppPage page, {
    String? selectedAssetCode,
    bool clearSelectedAssetCode = false,
  }) async {
    final focus = FocusManager.instance.primaryFocus;
    final wasKeyboardVisible =
        (MediaQuery.maybeViewInsetsOf(context)?.bottom ?? 0) > 0;

    focus?.unfocus();

    // Give IME insets time to settle before replacing the entire page subtree.
    await Future<void>.delayed(
      wasKeyboardVisible
          ? const Duration(milliseconds: 250)
          : const Duration(milliseconds: 16),
    );

    if (!mounted) {
      return;
    }

    final targetPage = _sanitizePageForCurrentRole(page);

    setState(() {
      if (clearSelectedAssetCode) {
        _selectedAssetCode = null;
      }
      if (selectedAssetCode != null) {
        _selectedAssetCode = selectedAssetCode;
      }
      _currentPage = targetPage;
    });
  }

  Future<void> _openAssetFromScanOrInput(String assetCode) async {
    final normalizedCode = assetCode.trim();
    if (normalizedCode.isEmpty) {
      return;
    }

    final asset = await _repository.getAsset(normalizedCode);
    if (!mounted) {
      return;
    }

    if (asset != null) {
      await _navigateToPage(
        _AppPage.details,
        selectedAssetCode: normalizedCode,
      );
      return;
    }

    if (_isRepairUser) {
      _showMessage('Asset not found. You can only open existing assets.');
      return;
    }

    await _navigateToPage(_AppPage.addAsset, selectedAssetCode: normalizedCode);
  }

  Widget _buildCurrentPage() {
    switch (_currentPage) {
      case _AppPage.login:
        return LoginPage(
          key: const ValueKey('login_page'),
          onLogin: (username, password) async {
            final user = await _repository.authenticateUser(
              username: username,
              password: password,
            );
            if (!mounted) {
              return;
            }
            _currentEmployeeId = user.employeeId;
            _currentUserRole = user.role;
            await _navigateToPage(
              _homePageForCurrentRole(),
              clearSelectedAssetCode: true,
            );
          },
        );
      case _AppPage.dashboard:
        return _buildDashboardPage();
      case _AppPage.details:
        final selectedAssetCode = _selectedAssetCode;
        if (selectedAssetCode == null) {
          return _buildHomePageForCurrentRole();
        }
        return AssetDetailsPage(
          key: const ValueKey('details_page'),
          repository: _repository,
          assetCode: selectedAssetCode,
          onBack: () => _navigateToPage(_homePageForCurrentRole()),
          onEdit: (assetCode) {
            _navigateToPage(_AppPage.editAsset, selectedAssetCode: assetCode);
          },
          onDeleted: () => _navigateToPage(
            _homePageForCurrentRole(),
            clearSelectedAssetCode: true,
          ),
          actorEmployeeId: _currentEmployeeId,
          canEditDetails: !_isRepairUser,
          canDeleteAsset: !_isRepairUser,
          restrictStatusToUnderRepair: _isRepairUser,
        );
      case _AppPage.addAsset:
        final selectedAssetCode = _selectedAssetCode;
        return AddAssetPage(
          key: const ValueKey('add_asset_page'),
          repository: _repository,
          onBack: () => _navigateToPage(_AppPage.dashboard),
          actorEmployeeId: _currentEmployeeId,
          initialAssetCode: selectedAssetCode,
          onSaved: (assetCode) =>
              _navigateToPage(_AppPage.details, selectedAssetCode: assetCode),
        );
      case _AppPage.editAsset:
        final selectedAssetCode = _selectedAssetCode;
        if (selectedAssetCode == null) {
          return _buildHomePageForCurrentRole();
        }
        return EditAssetPage(
          key: const ValueKey('edit_asset_page'),
          repository: _repository,
          assetCode: selectedAssetCode,
          onBack: () => _navigateToPage(_AppPage.details),
          actorEmployeeId: _currentEmployeeId,
          onSaved: (assetCode) =>
              _navigateToPage(_AppPage.details, selectedAssetCode: assetCode),
        );
      case _AppPage.scanQr:
        return ScanQrPage(
          key: const ValueKey('scan_qr_page'),
          onBack: () {
            if (_isRepairUser) {
              _navigateToPage(_homePageForCurrentRole());
              return;
            }
            _navigateToPage(_AppPage.dashboard);
          },
          onOpenHome: _isRepairUser
              ? () => _navigateToPage(_AppPage.myRepairs)
              : null,
          onOpenProfile: _isRepairUser
              ? () => _navigateToPage(_AppPage.profile)
              : null,
          onOpenAsset: (assetCode) {
            _openAssetFromScanOrInput(assetCode);
          },
        );
      case _AppPage.myRepairs:
        return _buildMyRepairsPage();
      case _AppPage.search:
        return SearchPage(
          key: const ValueKey('search_page'),
          repository: _repository,
          onOpenDetail: (assetCode) =>
              _navigateToPage(_AppPage.details, selectedAssetCode: assetCode),
          onOpenDashboard: () => _navigateToPage(_AppPage.dashboard),
          onAddAsset: () => _navigateToPage(_AppPage.addAsset),
          onOpenProfile: () => _navigateToPage(_AppPage.profile),
        );
      case _AppPage.profile:
        return ProfilePage(
          key: const ValueKey('profile_page'),
          repository: _repository,
          employeeId: _currentEmployeeId,
          onOpenDashboard: () => _navigateToPage(
            _isRepairUser ? _AppPage.myRepairs : _AppPage.dashboard,
          ),
          onOpenSearch: () => _navigateToPage(
            _isRepairUser ? _AppPage.scanQr : _AppPage.search,
          ),
          onAddAsset: _isRepairUser
              ? () {}
              : () => _navigateToPage(_AppPage.addAsset),
          onLogout: _logout,
          showAddTab: !_isRepairUser,
        );
    }
  }

  Widget _buildHomePageForCurrentRole() {
    if (_isRepairUser) {
      return _buildMyRepairsPage();
    }
    return _buildDashboardPage();
  }

  Widget _buildMyRepairsPage() {
    return MyRepairsPage(
      key: const ValueKey('my_repairs_page'),
      repository: _repository,
      employeeId: _currentEmployeeId,
      onOpenDetail: (assetCode) =>
          _navigateToPage(_AppPage.details, selectedAssetCode: assetCode),
      onOpenScan: () => _navigateToPage(_AppPage.scanQr),
      onOpenProfile: () => _navigateToPage(_AppPage.profile),
      onLogout: _logout,
    );
  }

  Widget _buildDashboardPage() {
    return DashboardPage(
      key: const ValueKey('dashboard_page'),
      repository: _repository,
      employeeId: _currentEmployeeId,
      onOpenDetail: (assetCode) {
        _navigateToPage(_AppPage.details, selectedAssetCode: assetCode);
      },
      onAddAsset: () => _navigateToPage(_AppPage.addAsset),
      onScanQr: () => _navigateToPage(_AppPage.scanQr),
      onOpenSearch: () => _navigateToPage(_AppPage.search),
      onOpenProfile: () => _navigateToPage(_AppPage.profile),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildCurrentPage();
  }
}
