import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/profile_entity.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/upload_profile_image_usecase.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';

// Events
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class GetProfileEvent extends ProfileEvent {
  const GetProfileEvent();
}

class UpdateProfileEvent extends ProfileEvent {
  final String? name;
  final String? avatar;

  const UpdateProfileEvent({this.name, this.avatar});

  @override
  List<Object?> get props => [name, avatar];
}

class UploadProfileImageEvent extends ProfileEvent {
  final String imagePath;

  const UploadProfileImageEvent(this.imagePath);

  @override
  List<Object?> get props => [imagePath];
}

// States
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final ProfileEntity profile;

  const ProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProfileUpdating extends ProfileState {
  final ProfileEntity currentProfile;

  const ProfileUpdating(this.currentProfile);

  @override
  List<Object?> get props => [currentProfile];
}

class ProfileUpdated extends ProfileState {
  final ProfileEntity profile;

  const ProfileUpdated(this.profile);

  @override
  List<Object?> get props => [profile];
}

class ImageUploading extends ProfileState {
  final ProfileEntity currentProfile;

  const ImageUploading(this.currentProfile);

  @override
  List<Object?> get props => [currentProfile];
}

class ImageUploaded extends ProfileState {
  final String imageUrl;
  final ProfileEntity profile;

  const ImageUploaded(this.imageUrl, this.profile);

  @override
  List<Object?> get props => [imageUrl, profile];
}

// BLoC
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfileUseCase getProfileUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  final UploadProfileImageUseCase uploadProfileImageUseCase;

  ProfileBloc({
    required this.getProfileUseCase,
    required this.updateProfileUseCase,
    required this.uploadProfileImageUseCase,
  }) : super(ProfileInitial()) {
    on<GetProfileEvent>(_onGetProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<UploadProfileImageEvent>(_onUploadProfileImage);
  }

  Future<void> _onGetProfile(
    GetProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    final result = await getProfileUseCase(NoParams());

    result.fold(
      (failure) => emit(ProfileError(_mapFailureToMessage(failure))),
      (profile) => emit(ProfileLoaded(profile)),
    );
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is ProfileLoaded) {
      final currentProfile = (state as ProfileLoaded).profile;
      emit(ProfileUpdating(currentProfile));

      final params = UpdateProfileParams(
        name: event.name,
        avatar: event.avatar,
      );

      final result = await updateProfileUseCase(params);

      result.fold(
        (failure) => emit(ProfileError(_mapFailureToMessage(failure))),
        (profile) => emit(ProfileUpdated(profile)),
      );
    }
  }

  Future<void> _onUploadProfileImage(
    UploadProfileImageEvent event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is ProfileLoaded) {
      final currentProfile = (state as ProfileLoaded).profile;
      emit(ImageUploading(currentProfile));

      final result = await uploadProfileImageUseCase(event.imagePath);

      result.fold(
        (failure) => emit(ProfileError(_mapFailureToMessage(failure))),
        (imageUrl) async {
          // Update profile with new image URL
          final updateParams = UpdateProfileParams(avatar: imageUrl);
          final updateResult = await updateProfileUseCase(updateParams);

          updateResult.fold(
            (failure) => emit(ProfileError(_mapFailureToMessage(failure))),
            (profile) => emit(ImageUploaded(imageUrl, profile)),
          );
        },
      );
    }
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure _:
        return failure.message;
      case CacheFailure _:
        return 'Cache failure: ${failure.message}';
      default:
        return 'Unexpected error: ${failure.message}';
    }
  }
}
