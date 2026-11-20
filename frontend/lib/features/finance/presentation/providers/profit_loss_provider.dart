import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/core/errors/exceptions.dart';
import 'package:basketball_academy/core/network/api_client.dart';
import 'package:basketball_academy/features/finance/domain/profit_loss_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// مفتاح الطلب: الأكاديمية + الفترة (تواريخ 'YYYY-MM-DD').
typedef ProfitLossQuery = ({String academyId, String from, String to});

/// تقرير الأرباح والخسائر — طلب واحد للسيرفر لكل فترة.
final profitLossProvider =
    FutureProvider.autoDispose.family<ProfitLossEntity, ProfitLossQuery>((ref, q) async {
  try {
    final res = await sl<ApiClient>().get<Map<String, dynamic>>(
      '/finance/profit-loss',
      queryParameters: {'from': q.from, 'to': q.to, 'academyId': q.academyId},
    );
    final body = res.data as Map<String, dynamic>;
    return ProfitLossEntity.fromJson(body['data'] as Map<String, dynamic>);
  } on AppException catch (e) {
    throw Exception(e.message);
  }
});
