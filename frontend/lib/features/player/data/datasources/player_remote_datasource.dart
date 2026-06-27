import 'dart:convert';

import 'package:basketball_academy/core/network/api_client.dart';
import 'package:basketball_academy/core/utils/multipart/image_multipart_helper.dart';
import 'package:basketball_academy/features/player/data/models/player_model.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

abstract class PlayerRemoteDatasource {
  Future<
      ({
        List<PlayerModel> players,
        int total,
        int page,
        int totalPages,
      })> getPlayers({
    String? academyId,
    String? search,
    int? birthYear,
    String? sport,
    String? attendanceDay,
    int page = 1,
    int limit = 20,
  });

  Future<List<PlayerModel>> searchPlayers(String query);

  Future<PlayerModel> getPlayerById(String id);

  Future<PlayerModel> createPlayer({
    required String fullName,
    required DateTime birthDate,
    required String parentName,
    required String parentRelationship,
    String? parentJob,
    required String parentPhone,
    String? playerPhone,
    String? notes,
    String? sport,
    List<String> attendanceDays,
    String? academyId,
    String? imagePath,
  });

  Future<PlayerModel> updatePlayer({
    required String id,
    String? fullName,
    DateTime? birthDate,
    String? parentName,
    String? parentRelationship,
    String? parentJob,
    String? parentPhone,
    String? playerPhone,
    String? notes,
    String? sport,
    List<String>? attendanceDays,
    String? imagePath,
  });

  Future<void> deletePlayer(String id);

  Future<void> deletePlayerImage(String id);
}

class PlayerRemoteDatasourceImpl implements PlayerRemoteDatasource {
  final ApiClient _apiClient;

  PlayerRemoteDatasourceImpl(this._apiClient);

  @override
  Future<
      ({
        List<PlayerModel> players,
        int total,
        int page,
        int totalPages,
      })> getPlayers({
    String? academyId,
    String? search,
    int? birthYear,
    String? sport,
    String? attendanceDay,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (academyId != null) 'academyId': academyId,
      if (search != null && search.isNotEmpty) 'search': search,
      if (birthYear != null) 'birthYear': birthYear,
      if (sport != null && sport.isNotEmpty) 'sport': sport,
      if (attendanceDay != null && attendanceDay.isNotEmpty)
        'attendanceDay': attendanceDay,
    };

    final response = await _apiClient.get('/players', queryParameters: queryParams);
    final body = response.data as Map<String, dynamic>;
    final list = (body['data'] as List<dynamic>)
        .map((e) => PlayerModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = body['meta'] as Map<String, dynamic>;

    return (
      players: list,
      total: (meta['total'] as num).toInt(),
      page: (meta['page'] as num).toInt(),
      totalPages: (meta['totalPages'] as num).toInt(),
    );
  }

  @override
  Future<List<PlayerModel>> searchPlayers(String query) async {
    final response = await _apiClient.get(
      '/players/search',
      queryParameters: {'q': query},
    );
    final body = response.data as Map<String, dynamic>;
    final list = (body['data'] as List<dynamic>)
        .map((e) => PlayerModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  @override
  Future<PlayerModel> getPlayerById(String id) async {
    final response = await _apiClient.get('/players/$id');
    final body = response.data as Map<String, dynamic>;
    return PlayerModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<PlayerModel> createPlayer({
    required String fullName,
    required DateTime birthDate,
    required String parentName,
    required String parentRelationship,
    String? parentJob,
    required String parentPhone,
    String? playerPhone,
    String? notes,
    String? sport,
    List<String> attendanceDays = const [],
    String? academyId,
    String? imagePath,
  }) async {
    if (imagePath != null) {
      final formData = FormData.fromMap({
        'fullName': fullName,
        'birthDate': DateFormat('yyyy-MM-dd').format(birthDate),
        'parentName': parentName,
        'parentRelationship': parentRelationship,
        if (parentJob != null) 'parentJob': parentJob,
        'parentPhone': parentPhone,
        if (playerPhone != null) 'playerPhone': playerPhone,
        if (notes != null) 'notes': notes,
        if (sport != null && sport.isNotEmpty) 'sport': sport,
        'attendanceDays': jsonEncode(attendanceDays),
        if (academyId != null) 'academyId': academyId,
        'image': await buildImageMultipart(imagePath, filename: 'player_image.jpg'),
      });
      final response = await _apiClient.postMultipart<Map<String, dynamic>>(
        '/players',
        data: formData,
      );
      final body = response.data as Map<String, dynamic>;
      return PlayerModel.fromJson(body['data'] as Map<String, dynamic>);
    } else {
      final data = <String, dynamic>{
        'fullName': fullName,
        'birthDate': DateFormat('yyyy-MM-dd').format(birthDate),
        'parentName': parentName,
        'parentRelationship': parentRelationship,
        if (parentJob != null) 'parentJob': parentJob,
        'parentPhone': parentPhone,
        if (playerPhone != null) 'playerPhone': playerPhone,
        if (notes != null) 'notes': notes,
        if (sport != null && sport.isNotEmpty) 'sport': sport,
        'attendanceDays': attendanceDays,
        if (academyId != null) 'academyId': academyId,
      };
      final response = await _apiClient.post('/players', data: data);
      final body = response.data as Map<String, dynamic>;
      return PlayerModel.fromJson(body['data'] as Map<String, dynamic>);
    }
  }

  @override
  Future<PlayerModel> updatePlayer({
    required String id,
    String? fullName,
    DateTime? birthDate,
    String? parentName,
    String? parentRelationship,
    String? parentJob,
    String? parentPhone,
    String? playerPhone,
    String? notes,
    String? sport,
    List<String>? attendanceDays,
    String? imagePath,
  }) async {
    if (imagePath != null) {
      final formMap = <String, dynamic>{
        if (fullName != null) 'fullName': fullName,
        if (birthDate != null) 'birthDate': DateFormat('yyyy-MM-dd').format(birthDate),
        if (parentName != null) 'parentName': parentName,
        if (parentRelationship != null) 'parentRelationship': parentRelationship,
        if (parentJob != null) 'parentJob': parentJob,
        if (parentPhone != null) 'parentPhone': parentPhone,
        if (playerPhone != null) 'playerPhone': playerPhone,
        if (notes != null) 'notes': notes,
        if (sport != null && sport.isNotEmpty) 'sport': sport,
        if (attendanceDays != null) 'attendanceDays': jsonEncode(attendanceDays),
        'image': await buildImageMultipart(imagePath, filename: 'player_image.jpg'),
      };
      final formData = FormData.fromMap(formMap);
      final response = await _apiClient.putMultipart<Map<String, dynamic>>(
        '/players/$id',
        data: formData,
      );
      final body = response.data as Map<String, dynamic>;
      return PlayerModel.fromJson(body['data'] as Map<String, dynamic>);
    } else {
      final data = <String, dynamic>{
        if (fullName != null) 'fullName': fullName,
        if (birthDate != null) 'birthDate': DateFormat('yyyy-MM-dd').format(birthDate),
        if (parentName != null) 'parentName': parentName,
        if (parentRelationship != null) 'parentRelationship': parentRelationship,
        if (parentJob != null) 'parentJob': parentJob,
        if (parentPhone != null) 'parentPhone': parentPhone,
        if (playerPhone != null) 'playerPhone': playerPhone,
        if (notes != null) 'notes': notes,
        if (sport != null && sport.isNotEmpty) 'sport': sport,
        if (attendanceDays != null) 'attendanceDays': attendanceDays,
      };
      final response = await _apiClient.put('/players/$id', data: data);
      final body = response.data as Map<String, dynamic>;
      return PlayerModel.fromJson(body['data'] as Map<String, dynamic>);
    }
  }

  @override
  Future<void> deletePlayer(String id) async {
    await _apiClient.delete('/players/$id');
  }

  @override
  Future<void> deletePlayerImage(String id) async {
    await _apiClient.delete('/players/$id/image');
  }
}
