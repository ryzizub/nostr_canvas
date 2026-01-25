part of 'profile_cubit.dart';

enum ProfileStatus { initial, loading, loaded, error }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.errorMessage,
  });

  final ProfileStatus status;
  final Profile? profile;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, profile, errorMessage];

  ProfileState copyWith({
    ProfileStatus? status,
    Profile? Function()? profile,
    String? Function()? errorMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile != null ? profile() : this.profile,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}
