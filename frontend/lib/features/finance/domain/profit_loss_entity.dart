/// نقطة شهرية في الرسم البياني (آخر 12 شهر).
class MonthlyProfitPoint {
  final String month; // 'YYYY-MM'
  final double revenue;
  final double costs;
  final double profit;

  const MonthlyProfitPoint({
    required this.month,
    required this.revenue,
    required this.costs,
    required this.profit,
  });

  int get monthNumber => int.tryParse(month.split('-').last) ?? 0;
}

/// تقرير الأرباح والخسائر لفترة (رد GET /finance/profit-loss).
class ProfitLossEntity {
  final String from;
  final String to;
  final int days;

  final double revSubscriptions;
  final double revMatches;
  final double revStore;
  final double revenueTotal;

  final Map<String, double> expensesByCategory;
  final double expensesTotal;
  final double payrollPaid;
  final double payrollPendingDue;

  final double costsTotal;
  final double netProfit;
  final double? margin;

  /// تحصيلات الاشتراكات حسب طريقة الدفع.
  final Map<String, double> cashbox;

  final String prevFrom;
  final String prevTo;
  final double prevRevenue;
  final double prevCosts;
  final double prevNet;
  final double? changeRevenue;
  final double? changeCosts;
  final double? changeNet;

  final List<MonthlyProfitPoint> monthly;
  final List<String> warnings;

  const ProfitLossEntity({
    required this.from,
    required this.to,
    required this.days,
    required this.revSubscriptions,
    required this.revMatches,
    required this.revStore,
    required this.revenueTotal,
    required this.expensesByCategory,
    required this.expensesTotal,
    required this.payrollPaid,
    required this.payrollPendingDue,
    required this.costsTotal,
    required this.netProfit,
    required this.margin,
    required this.cashbox,
    required this.prevFrom,
    required this.prevTo,
    required this.prevRevenue,
    required this.prevCosts,
    required this.prevNet,
    required this.changeRevenue,
    required this.changeCosts,
    required this.changeNet,
    required this.monthly,
    required this.warnings,
  });

  bool get isProfit => netProfit >= 0;
  bool get salariesMaybeDoubleCounted => warnings.contains('salaries_double_count');

  factory ProfitLossEntity.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> m(Map<String, dynamic> src, String k) =>
        (src[k] as Map?)?.cast<String, dynamic>() ?? const {};
    double n(dynamic v) => (v as num?)?.toDouble() ?? 0;
    double? nn(dynamic v) => (v as num?)?.toDouble();
    Map<String, double> amounts(Map<String, dynamic> src) =>
        src.map((k, v) => MapEntry(k, n(v)));

    final period = m(json, 'period');
    final revenue = m(json, 'revenue');
    final expenses = m(json, 'expenses');
    final payroll = m(json, 'payroll');
    final previous = m(json, 'previous');
    final prevPeriod = m(previous, 'period');
    final change = m(json, 'change');

    return ProfitLossEntity(
      from: (period['from'] ?? '').toString(),
      to: (period['to'] ?? '').toString(),
      days: (period['days'] as num?)?.toInt() ?? 0,
      revSubscriptions: n(revenue['subscriptions']),
      revMatches: n(revenue['matches']),
      revStore: n(revenue['store']),
      revenueTotal: n(revenue['total']),
      expensesByCategory: amounts(m(expenses, 'byCategory')),
      expensesTotal: n(expenses['total']),
      payrollPaid: n(payroll['paid']),
      payrollPendingDue: n(payroll['pendingDue']),
      costsTotal: n(json['costsTotal']),
      netProfit: n(json['netProfit']),
      margin: nn(json['margin']),
      cashbox: amounts(m(json, 'cashbox')),
      prevFrom: (prevPeriod['from'] ?? '').toString(),
      prevTo: (prevPeriod['to'] ?? '').toString(),
      prevRevenue: n(previous['revenueTotal']),
      prevCosts: n(previous['costsTotal']),
      prevNet: n(previous['netProfit']),
      changeRevenue: nn(change['revenue']),
      changeCosts: nn(change['costs']),
      changeNet: nn(change['netProfit']),
      monthly: (json['monthly'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => MonthlyProfitPoint(
                month: (e['month'] ?? '').toString(),
                revenue: n(e['revenue']),
                costs: n(e['costs']),
                profit: n(e['profit']),
              ))
          .toList(),
      warnings: (json['warnings'] as List? ?? const []).map((e) => e.toString()).toList(),
    );
  }
}
