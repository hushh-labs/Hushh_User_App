import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:hushh_user_app/features/vault/domain/entities/vault_document.dart';
import 'package:hushh_user_app/features/vault/domain/usecases/delete_document_usecase.dart';
import 'package:hushh_user_app/features/vault/domain/usecases/get_documents_usecase.dart';
import 'package:hushh_user_app/features/vault/domain/usecases/upload_document_usecase.dart';
import 'package:hushh_user_app/features/vault/presentation/bloc/vault_event.dart';
import 'package:hushh_user_app/features/vault/presentation/bloc/vault_state.dart';

class VaultBloc extends Bloc<VaultEvent, VaultState> {
  final UploadDocumentUseCase uploadDocumentUseCase;
  final DeleteDocumentUseCase deleteDocumentUseCase;
  final GetDocumentsUseCase getDocumentsUseCase;

  VaultBloc({
    required this.uploadDocumentUseCase,
    required this.deleteDocumentUseCase,
    required this.getDocumentsUseCase,
  }) : super(VaultInitial()) {
    on<LoadVaultDocuments>(_onLoadVaultDocuments);
    on<UploadVaultDocument>(_onUploadVaultDocument);
    on<DeleteVaultDocument>(_onDeleteVaultDocument);
  }

  Future<void> _onLoadVaultDocuments(
      LoadVaultDocuments event, Emitter<VaultState> emit) async {
    emit(VaultLoading());
    try {
      final documents = await getDocumentsUseCase(userId: event.userId);
      emit(VaultLoaded(documents: documents));
    } catch (e) {
      emit(VaultError(e.toString()));
    }
  }

  Future<void> _onUploadVaultDocument(
      UploadVaultDocument event, Emitter<VaultState> emit) async {
    emit(const VaultDocumentUploading(0.0)); // Initial progress
    try {
      // In a real scenario, you might get progress updates from the repository
      // For now, we'll simulate a single update to 100%
      final uploadedDocument = await uploadDocumentUseCase(
        userId: event.userId,
        file: event.file,
        filename: event.filename,
      );
      emit(const VaultDocumentUploading(1.0)); // 100% progress
      emit(VaultDocumentUploaded(uploadedDocument));
      // After upload, reload documents to update the list
      add(LoadVaultDocuments(userId: event.userId));
    } catch (e) {
      emit(VaultError(e.toString()));
      // If there were documents loaded before, go back to that state
      if (state is VaultLoaded) {
        emit(VaultLoaded(documents: (state as VaultLoaded).documents));
      } else {
        emit(const VaultLoaded()); // Or some other appropriate state
      }
    }
  }

  Future<void> _onDeleteVaultDocument(
      DeleteVaultDocument event, Emitter<VaultState> emit) async {
    final currentState = state;
    if (currentState is VaultLoaded) {
      // Optimistically remove the document from the list
      final updatedDocuments = List<VaultDocument>.from(currentState.documents)
        ..removeWhere((doc) => doc.id == event.documentId);
      emit(VaultLoaded(documents: updatedDocuments));

      try {
        // Assuming userId is available from authentication bloc or similar
        const String userId = 'current_user_id'; // TODO: Replace with actual user ID
        await deleteDocumentUseCase(userId: userId, documentId: event.documentId);
        // If successful, state is already updated
      } catch (e) {
        // If deletion fails, revert to the previous state and show error
        emit(VaultError(e.toString()));
        emit(currentState); // Revert to previous state
      }
    }
  }
}
