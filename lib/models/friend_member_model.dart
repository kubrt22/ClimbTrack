import 'package:climb_track/models/user_profile_model.dart';
import 'package:climb_track/models/user_stats_model.dart';

class FriendMemberModel {
  final UserProfileModel profile;
  final UserStatsModel stats;

  FriendMemberModel({required this.profile, required this.stats});
}
