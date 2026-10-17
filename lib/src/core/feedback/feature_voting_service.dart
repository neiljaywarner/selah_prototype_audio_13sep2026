import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../logging/app_logger.dart';

const String kFirestoreProjectId =
    String.fromEnvironment('FIRESTORE_PROJECT_ID', defaultValue: 'selahwordapp');

class RoadmapFeatureItem {
  final String id;
  final String title;
  final String description;
  final String targetVersion;
  final int votes;
  final bool hasVoted;
  final bool isApproved;
  final String status;

  const RoadmapFeatureItem({
    required this.id,
    required this.title,
    required this.description,
    required this.targetVersion,
    this.votes = 0,
    this.hasVoted = false,
    this.isApproved = true,
    this.status = 'approved',
  });

  RoadmapFeatureItem copyWith({
    String? id,
    String? title,
    String? description,
    String? targetVersion,
    int? votes,
    bool? hasVoted,
    bool? isApproved,
    String? status,
  }) {
    return RoadmapFeatureItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetVersion: targetVersion ?? this.targetVersion,
      votes: votes ?? this.votes,
      hasVoted: hasVoted ?? this.hasVoted,
      isApproved: isApproved ?? this.isApproved,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'targetVersion': targetVersion,
      'votes': votes,
      'hasVoted': hasVoted,
      'isApproved': isApproved,
      'status': status,
    };
  }

  factory RoadmapFeatureItem.fromJson(Map<String, dynamic> json) {
    return RoadmapFeatureItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      targetVersion: json['targetVersion'] as String,
      votes: (json['votes'] as num?)?.toInt() ?? 0,
      hasVoted: json['hasVoted'] as bool? ?? false,
      isApproved: json['isApproved'] as bool? ?? true,
      status: json['status'] as String? ?? 'approved',
    );
  }

  factory RoadmapFeatureItem.fromFirestoreJson(
    String id,
    Map<String, dynamic> fields, {
    bool hasVoted = false,
  }) {
    final title = fields['title']?['stringValue'] as String? ?? id;
    final description = fields['description']?['stringValue'] as String? ?? '';
    final targetVersion = fields['targetVersion']?['stringValue'] as String? ?? 'v0.3';
    final votesStr = fields['votes']?['integerValue'] as String?;
    final votes = votesStr != null ? int.tryParse(votesStr) ?? 0 : 0;
    final isApproved = fields['approved']?['booleanValue'] as bool? ?? false;
    final status = fields['status']?['stringValue'] as String? ?? (isApproved ? 'approved' : 'pending_approval');

    return RoadmapFeatureItem(
      id: id,
      title: title,
      description: description,
      targetVersion: targetVersion,
      votes: votes,
      hasVoted: hasVoted,
      isApproved: isApproved,
      status: status,
    );
  }
}

class FeatureVotingService {
  static const String _prefVotedFeaturesKey = 'selah_user_voted_features';
  static const String _prefCachedVotesKey = 'selah_cached_feature_votes';
  static const String _prefCuratorModeKey = 'selah_curator_mode_enabled';
  static const String _prefLocalProposalsKey = 'selah_local_proposals_json';

  static final List<RoadmapFeatureItem> defaultFeatures = [
    const RoadmapFeatureItem(
      id: 'karaoke_timestamps',
      title: 'Verse & Word-Level Karaoke Timestamps',
      description:
          'Synchronized millisecond word highlighting with narrator audio using Faith Comes By Hearing BibleBrain alignment.',
      targetVersion: 'v0.3',
      votes: 42,
      isApproved: true,
      status: 'approved',
    ),
    const RoadmapFeatureItem(
      id: 'gemini_voice_memorization',
      title: 'Voice Scripture Memorization Check (Gemini AI)',
      description:
          'Listen to user recite verses out loud with gentle pauses, checking recitation accuracy and progress.',
      targetVersion: 'v0.3.5',
      votes: 38,
      isApproved: true,
      status: 'approved',
    ),
    const RoadmapFeatureItem(
      id: 'ambient_soundscapes',
      title: 'Layered Ambient Soundscapes',
      description:
          'Background nature audio (gentle rain, temple pads, morning birds) layered softly beneath scripture narration.',
      targetVersion: 'v0.4',
      votes: 29,
      isApproved: true,
      status: 'approved',
    ),
    const RoadmapFeatureItem(
      id: 'audio_speed_controls',
      title: 'Paced Meditation Speeds (0.75x - 1.25x)',
      description:
          'Slow down audio for deep lectio divina contemplation or speed up for faster listening sessions.',
      targetVersion: 'v0.2.2',
      votes: 19,
      isApproved: true,
      status: 'approved',
    ),
    const RoadmapFeatureItem(
      id: 'offline_audio_downloads',
      title: 'Full Chapter Offline Audio Downloads',
      description:
          'Download narrated audio chapters locally for uninterrupted listening in airplane mode or off-grid retreats.',
      targetVersion: 'v0.2.5',
      votes: 15,
      isApproved: true,
      status: 'approved',
    ),
  ];

  final Dio _dio;
  final SharedPreferences? prefs;

  FeatureVotingService({Dio? dio, this.prefs})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 8),
              ),
            );

  String get _firestoreBaseUrl =>
      'https://firestore.googleapis.com/v1/projects/$kFirestoreProjectId/databases/(default)/documents/feature_votes';

  Future<bool> isCuratorModeEnabled() async {
    final sp = prefs ?? await SharedPreferences.getInstance();
    return sp.getBool(_prefCuratorModeKey) ?? false;
  }

  Future<void> setCuratorMode(bool enabled) async {
    final sp = prefs ?? await SharedPreferences.getInstance();
    await sp.setBool(_prefCuratorModeKey, enabled);
  }

  Future<Set<String>> getVotedFeatureIds() async {
    final sp = prefs ?? await SharedPreferences.getInstance();
    final list = sp.getStringList(_prefVotedFeaturesKey) ?? [];
    return list.toSet();
  }

  Future<void> saveVotedFeatureIds(Set<String> ids) async {
    final sp = prefs ?? await SharedPreferences.getInstance();
    await sp.setStringList(_prefVotedFeaturesKey, ids.toList());
  }

  Future<Map<String, int>> getCachedVotes() async {
    final sp = prefs ?? await SharedPreferences.getInstance();
    final raw = sp.getString(_prefCachedVotesKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  Future<void> saveCachedVotes(Map<String, int> votes) async {
    final sp = prefs ?? await SharedPreferences.getInstance();
    await sp.setString(_prefCachedVotesKey, jsonEncode(votes));
  }

  Future<List<RoadmapFeatureItem>> getLocalProposals() async {
    final sp = prefs ?? await SharedPreferences.getInstance();
    final raw = sp.getString(_prefLocalProposalsKey);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => RoadmapFeatureItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveLocalProposals(List<RoadmapFeatureItem> items) async {
    final sp = prefs ?? await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await sp.setString(_prefLocalProposalsKey, encoded);
  }

  Future<List<RoadmapFeatureItem>> fetchFeatures({bool includePending = false}) async {
    final votedIds = await getVotedFeatureIds();
    final cachedVotes = await getCachedVotes();
    final localProposals = await getLocalProposals();

    // 1. Initialize from defaults + local cached adjustments
    final Map<String, RoadmapFeatureItem> featureMap = {};
    for (final def in defaultFeatures) {
      final voteCount = cachedVotes[def.id] ?? def.votes;
      featureMap[def.id] = def.copyWith(
        votes: voteCount,
        hasVoted: votedIds.contains(def.id),
      );
    }

    // 2. Add local proposals
    for (final prop in localProposals) {
      final voteCount = cachedVotes[prop.id] ?? prop.votes;
      featureMap[prop.id] = prop.copyWith(
        votes: voteCount,
        hasVoted: votedIds.contains(prop.id),
      );
    }

    // 3. Attempt remote sync from Cloud Firestore REST
    try {
      final response = await _dio.get(_firestoreBaseUrl);
      if (response.statusCode == 200 && response.data != null) {
        final docs = response.data['documents'] as List<dynamic>?;
        if (docs != null) {
          final updatedCache = Map<String, int>.from(cachedVotes);
          for (final doc in docs) {
            final name = doc['name'] as String? ?? '';
            final id = name.split('/').last;
            final fields = doc['fields'] as Map<String, dynamic>? ?? {};
            if (id.isNotEmpty && fields.isNotEmpty) {
              final remoteItem = RoadmapFeatureItem.fromFirestoreJson(
                id,
                fields,
                hasVoted: votedIds.contains(id),
              );
              featureMap[id] = remoteItem;
              updatedCache[id] = remoteItem.votes;
            }
          }
          await saveCachedVotes(updatedCache);
          AppLogger.info('Successfully synced ${docs.length} feature votes from Cloud Firestore');
        }
      }
    } catch (e) {
      AppLogger.info('Firestore REST sync notice (using local/cached votes): $e');
    }

    var list = featureMap.values.toList();
    if (!includePending) {
      list = list.where((f) => f.isApproved).toList();
    }
    list.sort((a, b) => b.votes.compareTo(a.votes));
    return list;
  }

  Future<RoadmapFeatureItem> proposeFeature({
    required String title,
    required String description,
    String targetVersion = 'Community',
  }) async {
    final slug = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').trim();
    final sanitizedSlug = slug.length > 24 ? slug.substring(0, 24) : slug;
    final id = 'comm_${sanitizedSlug}_${DateTime.now().millisecondsSinceEpoch % 10000}';
    final newItem = RoadmapFeatureItem(
      id: id,
      title: title,
      description: description,
      targetVersion: targetVersion,
      votes: 1,
      hasVoted: true,
      isApproved: false,
      status: 'pending_approval',
    );

    // Save voted ID locally
    final votedIds = await getVotedFeatureIds();
    final updatedVoted = Set<String>.from(votedIds)..add(id);
    await saveVotedFeatureIds(updatedVoted);

    // Save cached votes locally
    final cached = await getCachedVotes();
    final updatedCached = Map<String, int>.from(cached)..[id] = 1;
    await saveCachedVotes(updatedCached);

    // Save proposal locally in pending list
    final localProposals = await getLocalProposals();
    final updatedProposals = List<RoadmapFeatureItem>.from(localProposals)..add(newItem);
    await saveLocalProposals(updatedProposals);

    // Push to Firestore REST with approved: false (quarantine)
    await syncVoteToFirestore(newItem);

    AppLogger.info(
      'Community feature proposed: "${newItem.title}" (ID: ${newItem.id}) queued for curator review (contact: neilwarner+selah@gmail.com)',
    );

    return newItem;
  }

  Future<void> approveFeature(RoadmapFeatureItem item) async {
    final approvedItem = item.copyWith(
      isApproved: true,
      status: 'approved',
    );

    // Update local proposal cache
    final localProposals = await getLocalProposals();
    final updated = localProposals.map((p) => p.id == item.id ? approvedItem : p).toList();
    await saveLocalProposals(updated);

    // Push approved state to Cloud Firestore
    await syncVoteToFirestore(approvedItem);
    AppLogger.info('Curator approved feature: "${item.title}" (${item.id})');
  }

  Future<void> rejectFeature(RoadmapFeatureItem item) async {
    final rejectedItem = item.copyWith(
      isApproved: false,
      status: 'declined',
    );

    // Update local proposal cache
    final localProposals = await getLocalProposals();
    final updated = localProposals.map((p) => p.id == item.id ? rejectedItem : p).toList();
    await saveLocalProposals(updated);

    // Push declined state to Cloud Firestore
    await syncVoteToFirestore(rejectedItem);
    AppLogger.info('Curator declined feature: "${item.title}" (${item.id})');
  }

  Future<void> syncVoteToFirestore(RoadmapFeatureItem item) async {
    try {
      final url = '$_firestoreBaseUrl/${item.id}';
      await _dio.patch(
        url,
        data: {
          'fields': {
            'title': {'stringValue': item.title},
            'description': {'stringValue': item.description},
            'targetVersion': {'stringValue': item.targetVersion},
            'votes': {'integerValue': '${item.votes}'},
            'approved': {'booleanValue': item.isApproved},
            'status': {'stringValue': item.status},
          },
        },
      );
      AppLogger.info('Pushed vote update for ${item.id} (${item.votes}, approved: ${item.isApproved}) to Firestore');
    } catch (e) {
      AppLogger.info('Firestore vote sync deferred (cached locally): $e');
    }
  }
}
