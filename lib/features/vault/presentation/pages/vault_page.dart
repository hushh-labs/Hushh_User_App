import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hushh_user_app/features/vault/presentation/bloc/vault_bloc.dart';
import 'package:hushh_user_app/features/vault/presentation/bloc/vault_state.dart';
import 'package:hushh_user_app/features/vault/presentation/bloc/vault_event.dart';
import 'package:hushh_user_app/features/vault/presentation/widgets/document_list_item.dart';
import 'package:hushh_user_app/features/vault/presentation/pages/document_upload_modal.dart';
import 'package:hushh_user_app/features/vault/presentation/widgets/document_preview_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:hushh_user_app/core/routing/route_paths.dart';

// ChatGPT-style colors matching PDA design
class VaultTheme {
  static const Color darkBackground = Color(0xFF000000);
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color sidebarBackground = Color(0xFFFFFFFF); // White sidebar
  static const Color userBubbleColor = Color(0xFF000000); // Black for user
  static const Color assistantBubbleColor = Color(
    0xFFF8F8F8,
  ); // Very light gray
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color textColor = Color(0xFF000000); // Pure black text
  static const Color hintColor = Color(0xFF666666); // Dark gray for hints
  static const Color sidebarTextColor = Color(
    0xFF000000,
  ); // Black text for sidebar
  static const Color primaryPurple = Color(0xFFA342FF);
  static const Color primaryPink = Color(0xFFE54D60);
  static const Color successGreen = Color(0xFF4CAF50);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPurple, primaryPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const double defaultBorderRadius = 16.0;
  static const double smallBorderRadius = 12.0;
}

class VaultPage extends StatefulWidget {
  const VaultPage({super.key});

  @override
  State<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends State<VaultPage> {
  @override
  void initState() {
    super.initState();
    // Load documents when the page is first accessed
    _loadDocuments();
  }

  // Fetch full name and photo URL from Firestore 'HushUsers' like PDA page
  Future<(String?, String?)> _fetchUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return (null, null);
      final doc = await FirebaseFirestore.instance
          .collection('HushUsers')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final name =
            (data['fullname'] as String?) ??
            (data['fullName'] as String?) ??
            (data['name'] as String?) ??
            (data['displayName'] as String?);
        final photo =
            data['photoUrl'] as String? ?? data['avatarUrl'] as String?;
        return (name, photo);
      }
      return (null, null);
    } catch (_) {
      return (null, null);
    }
  }

  void _loadDocuments() {
    // Get actual user ID from Firebase Auth
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    context.read<VaultBloc>().add(LoadVaultDocuments(userId: userId));
  }

  void _showUploadModal() {
    final vaultBloc = context.read<VaultBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider.value(
        value: vaultBloc,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: const DocumentUploadModal(),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, document) {
    // Capture the VaultBloc reference before showing the dialog
    final vaultBloc = context.read<VaultBloc>();

    showCupertinoDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Delete Document'),
          content: Text(
            'Are you sure you want to delete "${document.originalName}"? This action cannot be undone.',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Use the captured VaultBloc reference instead of trying to read from dialog context
                vaultBloc.add(DeleteVaultDocument(documentId: document.id));
              },
              isDestructiveAction: true,
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VaultTheme.lightBackground,
      drawer: _buildSideDrawer(),
      body: Column(
        children: [
          _buildChatGptStyleAppBar(),
          Expanded(
            child: BlocBuilder<VaultBloc, VaultState>(
              builder: (context, state) {
                if (state is VaultLoading) {
                  return _buildLoadingState();
                } else if (state is VaultDocumentUploading) {
                  return _buildUploadingState(state.progress);
                } else if (state is VaultLoaded) {
                  if (state.documents.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildDocumentsList(state.documents);
                } else if (state is VaultError) {
                  return _buildErrorState(state.message);
                }
                return _buildWelcomeState();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideDrawer() {
    return Drawer(
      backgroundColor: VaultTheme.sidebarBackground,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: const [
                  Icon(
                    Icons.folder_open_rounded,
                    color: VaultTheme.sidebarTextColor,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Vault',
                    style: TextStyle(
                      color: VaultTheme.sidebarTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: VaultTheme.borderColor, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: const Icon(
                      Icons.upload_file,
                      color: VaultTheme.sidebarTextColor,
                    ),
                    title: const Text(
                      'Upload Document',
                      style: TextStyle(color: VaultTheme.sidebarTextColor),
                    ),
                    subtitle: const Text(
                      'Add new files',
                      style: TextStyle(
                        color: VaultTheme.hintColor,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: VaultTheme.hintColor,
                      size: 16,
                    ),
                    onTap: _showUploadModal,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 56, right: 16),
                    child: Divider(
                      color: VaultTheme.borderColor,
                      height: 8,
                      thickness: 0.6,
                    ),
                  ),
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: const Icon(
                      Icons.psychology_alt_outlined,
                      color: VaultTheme.sidebarTextColor,
                    ),
                    title: const Text(
                      'Back to PDA',
                      style: TextStyle(color: VaultTheme.sidebarTextColor),
                    ),
                    subtitle: const Text(
                      'Return to assistant',
                      style: TextStyle(
                        color: VaultTheme.hintColor,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: VaultTheme.hintColor,
                      size: 16,
                    ),
                    onTap: () => context.go(RoutePaths.discover),
                  ),
                ],
              ),
            ),
            const Divider(color: VaultTheme.borderColor, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: FutureBuilder<(String?, String?)>(
                future: _fetchUserProfile(),
                builder: (context, snapshot) {
                  final authUser = FirebaseAuth.instance.currentUser;
                  final firestoreName = snapshot.data?.$1;
                  final firestorePhoto = snapshot.data?.$2;
                  final displayName = firestoreName?.isNotEmpty == true
                      ? firestoreName
                      : (authUser?.displayName ??
                            authUser?.email?.split('@').first ??
                            'You');
                  final photoUrl = firestorePhoto ?? authUser?.photoURL;
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: VaultTheme.userBubbleColor,
                        backgroundImage: photoUrl != null
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl == null
                            ? const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          displayName ?? 'You',
                          style: const TextStyle(
                            color: VaultTheme.sidebarTextColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      BlocBuilder<VaultBloc, VaultState>(
                        builder: (context, state) {
                          if (state is VaultLoaded &&
                              state.documents.isNotEmpty) {
                            return InkWell(
                              onTap: _showClearVaultConfirmation,
                              borderRadius: BorderRadius.circular(8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    color: Colors.red[400],
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Clear',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // _buildActionButton removed (replaced by ListTile-based items in drawer)

  Widget _buildChatGptStyleAppBar() {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 60,
        decoration: const BoxDecoration(
          color: VaultTheme.lightBackground,
          border: Border(
            bottom: BorderSide(color: VaultTheme.borderColor, width: 1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Hamburger menu to open drawer
              Builder(
                builder: (context) => IconButton(
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                  icon: const Icon(
                    Icons.menu,
                    color: VaultTheme.textColor,
                    size: 24,
                  ),
                  padding: const EdgeInsets.all(8),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Vault',
                style: TextStyle(
                  color: VaultTheme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Upload button
              GestureDetector(
                onTap: _showUploadModal,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.upload_file,
                    color: VaultTheme.textColor,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(VaultTheme.textColor),
          ),
          SizedBox(height: 16),
          Text(
            'Loading your documents...',
            style: TextStyle(fontSize: 16, color: VaultTheme.hintColor),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadingState(double progress) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    VaultTheme.userBubbleColor,
                  ),
                  backgroundColor: VaultTheme.userBubbleColor.withOpacity(0.1),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: VaultTheme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Uploading document...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: VaultTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we process your file',
            style: TextStyle(fontSize: 14, color: VaultTheme.hintColor),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: VaultTheme.userBubbleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                size: 48,
                color: VaultTheme.userBubbleColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ready to build your knowledge base?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: VaultTheme.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Upload any file type to create your personal AI assistant. Your files are encrypted and only accessible to you.',
              style: TextStyle(
                fontSize: 16,
                color: VaultTheme.hintColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // File type indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFileTypeIcon(Icons.picture_as_pdf, 'PDF'),
                const SizedBox(width: 16),
                _buildFileTypeIcon(Icons.description, 'DOC'),
                const SizedBox(width: 16),
                _buildFileTypeIcon(Icons.text_snippet, 'TXT'),
                const SizedBox(width: 16),
                _buildFileTypeIcon(Icons.image, 'Images'),
                const SizedBox(width: 16),
                _buildFileTypeIcon(Icons.insert_drive_file, 'More'),
              ],
            ),
            const SizedBox(height: 8),
            // File size limit
            const Text(
              'Up to 50MB per file',
              style: TextStyle(fontSize: 12, color: VaultTheme.hintColor),
            ),
            const SizedBox(height: 32),
            // Primary CTA Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: VaultTheme.userBubbleColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _showUploadModal,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_file, color: Colors.white, size: 20),
                        SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            'Choose Your First Document',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileTypeIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: VaultTheme.assistantBubbleColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: VaultTheme.borderColor, width: 1),
          ),
          child: Icon(icon, size: 16, color: VaultTheme.hintColor),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: VaultTheme.hintColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsList(List documents) {
    return Column(
      children: [
        // Header with document count
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: VaultTheme.assistantBubbleColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: VaultTheme.borderColor, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: VaultTheme.userBubbleColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.folder, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Documents',
                      style: TextStyle(
                        color: VaultTheme.textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${documents.length} document${documents.length == 1 ? '' : 's'} stored',
                      style: const TextStyle(
                        color: VaultTheme.hintColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Upload button in header
              Container(
                decoration: BoxDecoration(
                  color: VaultTheme.userBubbleColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _showUploadModal,
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.upload_file,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Documents list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final document = documents[index];
              return DocumentListItem(
                document: document,
                onDelete: () {
                  _showDeleteConfirmation(context, document);
                },
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) =>
                        DocumentPreviewWidget(document: document),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 50,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: VaultTheme.textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: VaultTheme.hintColor),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDocuments,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: VaultTheme.userBubbleColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeState() {
    return const Center(
      child: Text(
        'Welcome to your Vault!',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: VaultTheme.textColor,
        ),
      ),
    );
  }

  void _showClearVaultConfirmation() {
    // Capture the VaultBloc reference before showing the dialog
    final vaultBloc = context.read<VaultBloc>();

    showCupertinoDialog(
      context: context,
      builder: (BuildContext dialogContext) => CupertinoAlertDialog(
        title: const Text('Clear Vault'),
        content: const Text(
          'Are you sure you want to delete all documents? This action cannot be undone.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Get actual user ID from Firebase Auth
              final userId =
                  FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
              // Use the captured VaultBloc reference instead of trying to read from dialog context
              vaultBloc.add(ClearAllVaultDocuments(userId: userId));
            },
            isDestructiveAction: true,
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
