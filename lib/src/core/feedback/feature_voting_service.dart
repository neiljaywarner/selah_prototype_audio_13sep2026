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

  const RoadmapFeatureItem({
    required this.id,
    required this.title,
    required this.description,
    required this.targetVersion,
    this.votes = 0,
    this.hasVoted = false,
  });

  RoadmapFeatureItem copyWith({
    String? id,
    String? title,
    String? description,
    String? targetVersion,
    int? votes,
    bool? hasVoted,
  }) {
    return RoadmapFeatureItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetVersion: targetVersion ?? this.targetVersion,
      votes: votes ?? this.votes,
      hasVoted: hasVoted ?? this.hasVoted,
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

    return RoadmapFeatureItem(
      id: id,
      title: title,
      description: description,
      targetVersion: targetVersion,
      votes: votes,
      hasVoted: hasVoted,
    );
  }
}

class FeatureVotingService {
  static const String _prefVotedFeaturesKey = 'selah_user_voted_features';
  static const String _prefCachedVotesKey = 'selah_cached_feature_votes';

  static final List<RoadmapFeatureItem> defaultFeatures = [
    const RoadmapFeatureItem(
      id: 'karaoke_timestamps',
      title: 'Verse & Word-Level Karaoke Timestamps',
      description:
          'Synchronized millisecond word highlighting with narrator audio using Faith Comes By Hearing BibleBrain alignment.',
      targetVersion: 'v0.3',
      votes: 42,
    ),
    const RoadmapFeatureItem(
      id: 'gemini_voice_memorization',
      title: 'Voice Scripture Memorization Check (Gemini AI)',
      description:
          'Listen to user recite verses out loud with gentle pauses, checking recitation accuracy and progress.',
      targetVersion: 'v0.3.5',
      votes: 38,
    ),
    const RoadmapFeatureItem(
      id: 'ambient_soundscapes',
      title: 'Layered Ambient Soundscapes',
      description:
          'Background nature audio (gentle rain, temple pads, morning birds) layered softly beneath scripture narration.',
      targetVersion: 'v0.4',
      votes: 29,
    ),
    const RoadmapFeatureItem(
      id: 'audio_speed_controls',
      title: 'Paced Meditation Speeds (0.75x - 1.25x)',
      description:
          'Slow down audio for deep lectio divina contemplation or speed up for faster listening sessions.',
      targetVersion: 'v0.2.2',
      votes: 19,
    ),
    const RoadmapFeatureItem(
      id: 'offline_audio_downloads',
      title: 'Full Chapter Offline Audio Downloads',
      description:
          'Download narrated audio chapters locally for uninterrupted listening in airplane mode or off-grid retreats.',
      targetVersion: 'v0.2.5',
      votes: 15,
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

  Future<List<RoadmapFeatureItem>> fetchFeatures() async {
    final votedIds = await getVotedFeatureIds();
    final cachedVotes = await getCachedVotes();

    // 1. Initialize from defaults + local cached adjustments
    final Map<String, RoadmapFeatureItem> featureMap = {};
    for (final def in defaultFeatures) {
      final voteCount = cachedVotes[def.id] ?? def.votes;
      featureMap[def.id] = def.copyWith(
        votes: voteCount,
        hasVoted: votedIds.contains(def.id),
      );
    }

    // 2. Attempt remote sync from Cloud Firestore REST
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

    final list = featureMap.values.toList();
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
    );

    // Save voted ID locally
    final votedIds = await getVotedFeatureIds();
    final updatedVoted = Set<String>.from(votedIds)..add(id);
    await saveVotedFeatureIds(updatedVoted);

    // Save cached votes locally
    final cached = await getCachedVotes();
    final updatedCached = Map<String, int>.from(cached)..[id] = 1;
    await saveCachedVotes(updatedCached);

    // Push to Firestore REST
    await syncVoteToFirestore(newItem);

    return newItem;
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
            'approved': {'booleanValue': true},
          },
        },
      );
      AppLogger.info('Pushed vote update for ${item.id} (${item.votes}) to Firestore');
    } catch (e) {
      AppLogger.info('Firestore vote sync deferred (cached locally): $e');
    }
  }
}
