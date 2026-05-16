import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../models/yacht_document.dart';
import '../../models/yacht_overview.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

/// Owner view: upload and track mandatory yacht compliance documents.
class YachtDocumentsScreen extends StatefulWidget {
  final AuthService authService;
  final YachtOverview yacht;

  const YachtDocumentsScreen({
    super.key,
    required this.authService,
    required this.yacht,
  });

  @override
  State<YachtDocumentsScreen> createState() => _YachtDocumentsScreenState();
}

class _YachtDocumentsScreenState extends State<YachtDocumentsScreen> {
  late final ApiService _api = ApiService(
    baseUrl: widget.authService.baseUrl,
    auth: widget.authService,
  );

  static const _mandatoryTypes = [
    'Registration',
    'Insurance',
    'SafetyCertificate',
  ];

  List<YachtDocument> _docs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.getYachtDocuments(widget.yacht.yachtId);
      if (!mounted) return;
      setState(() {
        _docs = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _upload(String documentType) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.single.path == null) return;
    try {
      await _api.uploadYachtDocument(
        yachtId: widget.yacht.yachtId,
        documentType: documentType,
        filePath: result.files.single.path!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document uploaded successfully!')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Documents · ${widget.yacht.name}'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'Registration, Insurance, and Safety Certificate must be approved before your yacht can go Active.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      ..._mandatoryTypes.map((type) {
                        final doc = _docs.cast<YachtDocument?>().firstWhere(
                              (d) =>
                                  d!.documentType.toLowerCase() ==
                                  type.toLowerCase(),
                              orElse: () => null,
                            );
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(YachtDocument.displayLabelForType(type)),
                            subtitle: doc == null
                                ? const Text('Not uploaded')
                                : Text(
                                    '${doc.verificationStatus}'
                                    '${doc.rejectionReason != null ? '\nReason: ${doc.rejectionReason}' : ''}',
                                  ),
                            trailing: doc == null
                                ? IconButton(
                                    icon: const Icon(Icons.upload_file),
                                    onPressed: () => _upload(type),
                                  )
                                : Chip(
                                    label: Text(
                                      doc.verificationStatus,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                    backgroundColor:
                                        _statusColor(doc.verificationStatus),
                                  ),
                            onTap: () => _upload(type),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
    );
  }
}
