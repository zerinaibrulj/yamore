import 'package:flutter/material.dart';
import '../../models/yacht_document.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class AdminYachtDocumentsScreen extends StatefulWidget {
  final AuthService authService;

  const AdminYachtDocumentsScreen({super.key, required this.authService});

  @override
  State<AdminYachtDocumentsScreen> createState() =>
      _AdminYachtDocumentsScreenState();
}

class _AdminYachtDocumentsScreenState extends State<AdminYachtDocumentsScreen> {
  late final ApiService _api = ApiService(
    baseUrl: widget.authService.baseUrl,
    auth: widget.authService,
  );

  List<YachtDocument> _pending = [];
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
      final list = await _api.getPendingYachtDocuments();
      if (!mounted) return;
      setState(() {
        _pending = list;
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

  Future<void> _verify(YachtDocument doc, bool approve) async {
    String? reason;
    if (!approve) {
      final controller = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Rejection reason'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Reason (required)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Please enter a reason.')),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Reject'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      reason = controller.text.trim();
      controller.dispose();
    }

    try {
      await _api.verifyYachtDocument(
        documentId: doc.yachtDocumentId,
        verificationStatus: approve ? 'Approved' : 'Rejected',
        rejectionReason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve ? 'Document approved.' : 'Document rejected.'),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending yacht documents'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _pending.isEmpty
                  ? const Center(child: Text('No documents awaiting review.'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _pending.length,
                        itemBuilder: (context, i) {
                          final d = _pending[i];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Yacht #${d.yachtId} · ${d.documentType}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (d.fileName != null)
                                    Text(d.fileName!,
                                        style: const TextStyle(fontSize: 12)),
                                  if (d.dateUploaded != null)
                                    Text(
                                      'Uploaded: ${d.dateUploaded}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FilledButton(
                                          onPressed: () => _verify(d, true),
                                          child: const Text('Approve'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _verify(d, false),
                                          child: const Text('Reject'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
