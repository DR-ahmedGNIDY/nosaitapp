import 'package:basketball_academy/core/network/api_client.dart';
import 'package:basketball_academy/features/subscription/data/models/academy_debts_model.dart';
import 'package:basketball_academy/features/subscription/data/models/subscription_model.dart';
import 'package:basketball_academy/features/subscription/domain/entities/academy_debts_entity.dart';
import 'package:basketball_academy/features/subscription/domain/entities/receipt_entity.dart';

abstract class SubscriptionRemoteDatasource {
  Future<List<SubscriptionModel>> getSubscriptionsByPlayer({
    required String playerId,
    String? status,
  });

  Future<
      ({
        List<SubscriptionModel> subscriptions,
        int total,
        int page,
        int totalPages,
      })> getSubscriptionsByAcademy({
    required String academyId,
    String? type,
    String? status,
    String? playerId,
    int page = 1,
    int limit = 20,
  });

  Future<SubscriptionModel> getSubscriptionById(String id);

  Future<SubscriptionModel> createSubscription({
    required String playerId,
    required String type,
    required double amount,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
    int? sessionsLimit,
    String? academyId,
    double? paidAmount,
    String? paymentMethod,
  });

  /// تسجيل دفعة (قسط) على اشتراك — يرجّع الاشتراك بعد التحديث.
  Future<SubscriptionModel> addPayment({
    required String subscriptionId,
    required double amount,
    String method = 'cash',
    DateTime? date,
    String? note,
  });

  /// حذف دفعة مسجّلة بالخطأ.
  Future<SubscriptionModel> deletePayment({
    required String subscriptionId,
    required String paymentId,
  });

  /// اللاعبون الذين عليهم مبالغ متبقية.
  Future<AcademyDebtsEntity> getAcademyDebts(String academyId);

  /// بيانات إيصال دفعة (paymentId = 'legacy' للاشتراك القديم بلا سجل دفعات).
  Future<ReceiptEntity> getReceipt({
    required String subscriptionId,
    required String paymentId,
  });

  Future<SubscriptionModel> updateNotes({
    required String id,
    required String notes,
  });

  Future<void> deleteSubscription(String id);

  Future<Map<String, dynamic>> getRevenueSummary(String academyId);

  /// خريطة playerId → 'active' | 'expired' — تُحسب على السيرفر بـ aggregation
  /// واحدة (أحدث endDate لكل لاعب)، فلا pagination ولا سجلات خام.
  Future<Map<String, String>> getAcademyPlayerStatusMap(String academyId);
}

class SubscriptionRemoteDatasourceImpl implements SubscriptionRemoteDatasource {
  final ApiClient _apiClient;

  SubscriptionRemoteDatasourceImpl(this._apiClient);

  @override
  Future<List<SubscriptionModel>> getSubscriptionsByPlayer({
    required String playerId,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{
      if (status != null) 'status': status,
    };
    final response = await _apiClient.get(
      '/subscriptions/player/$playerId',
      queryParameters: queryParams,
    );
    final body = response.data as Map<String, dynamic>;
    final list = (body['data'] as List<dynamic>)
        .map((e) => SubscriptionModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  @override
  Future<
      ({
        List<SubscriptionModel> subscriptions,
        int total,
        int page,
        int totalPages,
      })> getSubscriptionsByAcademy({
    required String academyId,
    String? type,
    String? status,
    String? playerId,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (playerId != null) 'playerId': playerId,
    };
    final response = await _apiClient.get(
      '/subscriptions/academy/$academyId',
      queryParameters: queryParams,
    );
    final body = response.data as Map<String, dynamic>;
    final list = (body['data'] as List<dynamic>)
        .map((e) => SubscriptionModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = body['meta'] as Map<String, dynamic>;
    return (
      subscriptions: list,
      total: (meta['total'] as num).toInt(),
      page: (meta['page'] as num).toInt(),
      totalPages: (meta['totalPages'] as num).toInt(),
    );
  }

  @override
  Future<SubscriptionModel> getSubscriptionById(String id) async {
    final response = await _apiClient.get('/subscriptions/$id');
    final body = response.data as Map<String, dynamic>;
    return SubscriptionModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<SubscriptionModel> createSubscription({
    required String playerId,
    required String type,
    required double amount,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
    int? sessionsLimit,
    String? academyId,
    double? paidAmount,
    String? paymentMethod,
  }) async {
    final data = <String, dynamic>{
      if (paidAmount != null) 'paidAmount': paidAmount,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      'playerId': playerId,
      'type': type,
      'amount': amount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      if (notes != null) 'notes': notes,
      if (sessionsLimit != null) 'sessionsLimit': sessionsLimit,
      if (academyId != null) 'academyId': academyId,
    };
    final response = await _apiClient.post('/subscriptions', data: data);
    final body = response.data as Map<String, dynamic>;
    final payload = body['data'] as Map<String, dynamic>;
    // اشتراك جديد للاعب له اشتراكات سابقة ⇒ { subscription, warning }.
    final subJson = payload['subscription'] is Map<String, dynamic>
        ? payload['subscription'] as Map<String, dynamic>
        : payload;
    return SubscriptionModel.fromJson(subJson);
  }

  @override
  Future<SubscriptionModel> addPayment({
    required String subscriptionId,
    required double amount,
    String method = 'cash',
    DateTime? date,
    String? note,
  }) async {
    final response = await _apiClient.post(
      '/subscriptions/$subscriptionId/payments',
      data: {
        'amount': amount,
        'method': method,
        if (date != null) 'date': date.toIso8601String(),
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
    final body = response.data as Map<String, dynamic>;
    return SubscriptionModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<SubscriptionModel> deletePayment({
    required String subscriptionId,
    required String paymentId,
  }) async {
    final response = await _apiClient
        .delete('/subscriptions/$subscriptionId/payments/$paymentId');
    final body = response.data as Map<String, dynamic>;
    return SubscriptionModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<AcademyDebtsEntity> getAcademyDebts(String academyId) async {
    final response =
        await _apiClient.get('/subscriptions/academy/$academyId/debts');
    final body = response.data as Map<String, dynamic>;
    return AcademyDebtsModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<ReceiptEntity> getReceipt({
    required String subscriptionId,
    required String paymentId,
  }) async {
    final response = await _apiClient
        .get('/subscriptions/$subscriptionId/payments/$paymentId/receipt');
    final body = response.data as Map<String, dynamic>;
    return ReceiptEntity.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<SubscriptionModel> updateNotes({
    required String id,
    required String notes,
  }) async {
    final response = await _apiClient.patch(
      '/subscriptions/$id/notes',
      data: {'notes': notes},
    );
    final body = response.data as Map<String, dynamic>;
    return SubscriptionModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteSubscription(String id) async {
    await _apiClient.delete('/subscriptions/$id');
  }

  @override
  Future<Map<String, String>> getAcademyPlayerStatusMap(String academyId) async {
    final response = await _apiClient
        .get('/subscriptions/academy/$academyId/player-status');
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    return data.map((k, v) => MapEntry(k, v as String));
  }

  @override
  Future<Map<String, dynamic>> getRevenueSummary(String academyId) async {
    final response =
        await _apiClient.get('/subscriptions/academy/$academyId/revenue');
    final body = response.data as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }
}
