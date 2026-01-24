import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:profile_repository/profile_repository.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({required ProfileRepository profileRepository})
    : _profileRepository = profileRepository,
      super(const ProfileState());

  final ProfileRepository _profileRepository;

  /// Fetches the profile for the given pubkey.
  Future<void> fetchProfile(String pubkey) async {
    emit(state.copyWith(status: ProfileStatus.loading));

    try {
      final profile = await _profileRepository.fetchProfile(pubkey);
      emit(
        state.copyWith(
          status: ProfileStatus.loaded,
          profile: () => profile,
          errorMessage: () => null,
        ),
      );
    } on Exception catch (e) {
      emit(
        state.copyWith(
          status: ProfileStatus.error,
          errorMessage: e.toString,
        ),
      );
    }
  }
}
