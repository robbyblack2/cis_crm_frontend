import 'package:cis_crm/app/injection.dart';
import 'package:cis_crm/features/contacts/data/datasources/company_remote_data_source.dart';
import 'package:cis_crm/features/contacts/data/datasources/contact_remote_data_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Lightweight in-memory name resolution cache.
/// Avoids N+1 API calls by caching all entities on first access.
class NameResolver {
  NameResolver._();

  static final instance = NameResolver._();

  final Map<String, String> _contactNames = {};
  final Map<String, String> _companyNames = {};
  final Map<String, String> _userNames = {};

  bool _contactsLoaded = false;
  bool _companiesLoaded = false;
  bool _usersLoaded = false;

  Future<void> loadContacts() async {
    if (_contactsLoaded) return;
    try {
      final response = await getIt<ContactRemoteDataSource>()
          .getContacts(page: 1, perPage: 500);
      for (final c in response.items) {
        _contactNames[c.id] = '${c.firstName} ${c.lastName}'.trim();
      }
      _contactsLoaded = true;
    } catch (_) {}
  }

  Future<void> loadCompanies() async {
    if (_companiesLoaded) return;
    try {
      final companies = await getIt<CompanyRemoteDataSource>().getCompanies();
      for (final c in companies) {
        _companyNames[c.id] = c.name;
      }
      _companiesLoaded = true;
    } catch (_) {}
  }

  Future<void> loadUsers() async {
    if (_usersLoaded) return;
    try {
      final response =
          await getIt<Dio>().get<Map<String, dynamic>>('/api/users');
      final list = response.data?['data'] as List<dynamic>? ?? [];
      for (final u in list) {
        if (u is Map<String, dynamic>) {
          final id = u['id'] as String? ?? '';
          final name = u['display_name'] as String? ?? u['email'] as String? ?? '';
          if (id.isNotEmpty) _userNames[id] = name;
        }
      }
      _usersLoaded = true;
    } catch (_) {}
  }

  String? contactName(String? id) => id != null ? _contactNames[id] : null;
  String? companyName(String? id) => id != null ? _companyNames[id] : null;
  String? userName(String? id) => id != null ? _userNames[id] : null;

  void invalidate() {
    _contactsLoaded = false;
    _companiesLoaded = false;
    _usersLoaded = false;
    _contactNames.clear();
    _companyNames.clear();
    _userNames.clear();
  }
}

/// Widget that resolves an entity ID to a display name.
/// Shows a placeholder while loading, then the resolved name.
class ResolvedName extends StatefulWidget {
  const ResolvedName({
    required this.id,
    required this.type,
    this.fallback,
    this.style,
    super.key,
  });

  final String? id;
  final String type; // 'contact', 'company', 'user'
  final String? fallback;
  final TextStyle? style;

  @override
  State<ResolvedName> createState() => _ResolvedNameState();
}

class _ResolvedNameState extends State<ResolvedName> {
  String? _name;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    if (widget.id == null) {
      setState(() => _loaded = true);
      return;
    }

    final resolver = NameResolver.instance;
    switch (widget.type) {
      case 'contact':
        await resolver.loadContacts();
        _name = resolver.contactName(widget.id);
      case 'company':
        await resolver.loadCompanies();
        _name = resolver.companyName(widget.id);
      case 'user':
        await resolver.loadUsers();
        _name = resolver.userName(widget.id);
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Text(
        widget.fallback ?? widget.id ?? '',
        style: widget.style,
      );
    }
    return Text(
      _name ?? widget.fallback ?? widget.id ?? '',
      style: widget.style,
    );
  }
}
