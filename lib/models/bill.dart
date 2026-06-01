enum BillStatus { unpaid, paid, overdue }

class Bill {
  final String id;
  final String type;
  final String period;
  final double amount;
  final double usage;
  final String unit;
  final String dueDate;
  final BillStatus status;
  final bool selected;

  const Bill({
    required this.id,
    required this.type,
    required this.period,
    required this.amount,
    required this.usage,
    required this.unit,
    required this.dueDate,
    required this.status,
    this.selected = false,
  });

  Bill copyWith({bool? selected}) => Bill(
        id: id,
        type: type,
        period: period,
        amount: amount,
        usage: usage,
        unit: unit,
        dueDate: dueDate,
        status: status,
        selected: selected ?? this.selected,
      );
}

class MockBills {
  static final currentBills = [
    const Bill(
      id: 'WTR-2605-00015',
      type: 'Water',
      period: 'May 2025 Bill',
      amount: 37500,
      usage: 25,
      unit: 'm³',
      dueDate: 'Jun 06, 2025',
      status: BillStatus.unpaid,
    ),
    const Bill(
      id: 'ELE-2605-00015',
      type: 'Electricity',
      period: 'May 2025 Bill',
      amount: 183000,
      usage: 122,
      unit: 'kWh',
      dueDate: 'Jun 06, 2025',
      status: BillStatus.unpaid,
    ),
    const Bill(
      id: 'GAS-2605-00015',
      type: 'Gas',
      period: 'May 2025 Bill',
      amount: 27000,
      usage: 18,
      unit: 'L',
      dueDate: 'Jun 06, 2025',
      status: BillStatus.unpaid,
    ),
    const Bill(
      id: 'COL-2605-00015',
      type: 'Cooling',
      period: 'May 2025 Bill',
      amount: 30000,
      usage: 215,
      unit: 'kWh',
      dueDate: 'Jun 06, 2025',
      status: BillStatus.unpaid,
    ),
  ];

  static final recentPayments = [
    const Bill(
      id: 'ALL-2504-00012',
      type: 'All',
      period: 'Apr 2025',
      amount: 215000,
      usage: 0,
      unit: '',
      dueDate: 'May 06, 2025',
      status: BillStatus.paid,
    ),
    const Bill(
      id: 'ALL-2503-00011',
      type: 'All',
      period: 'Mar 2025',
      amount: 198500,
      usage: 0,
      unit: '',
      dueDate: 'Apr 06, 2025',
      status: BillStatus.paid,
    ),
    const Bill(
      id: 'ALL-2502-00010',
      type: 'All',
      period: 'Feb 2025',
      amount: 220000,
      usage: 0,
      unit: '',
      dueDate: 'Mar 06, 2025',
      status: BillStatus.paid,
    ),
    const Bill(
      id: 'ALL-2501-00009',
      type: 'All',
      period: 'Jan 2025',
      amount: 199500,
      usage: 0,
      unit: '',
      dueDate: 'Feb 06, 2025',
      status: BillStatus.paid,
    ),
  ];

  // Detailed per-utility history for Analytics screen
  static final billRecords = [
    // May 2025 unpaid
    const Bill(id: 'WTR-2605-00015', type: 'Water', period: 'May 2025', amount: 37500, usage: 25, unit: 'm³', dueDate: 'Jun 06, 2025', status: BillStatus.unpaid),
    const Bill(id: 'ELE-2605-00015', type: 'Electricity', period: 'May 2025', amount: 183000, usage: 122, unit: 'kWh', dueDate: 'Jun 06, 2025', status: BillStatus.unpaid),
    const Bill(id: 'GAS-2605-00015', type: 'Gas', period: 'May 2025', amount: 27000, usage: 18, unit: 'L', dueDate: 'Jun 06, 2025', status: BillStatus.unpaid),
    const Bill(id: 'COL-2605-00015', type: 'Cooling', period: 'May 2025', amount: 30000, usage: 20, unit: 'kWh', dueDate: 'Jun 06, 2025', status: BillStatus.unpaid),
    // Apr 2025 paid
    const Bill(id: 'ELE-2604-00014', type: 'Electricity', period: 'Apr 2025', amount: 187500, usage: 125, unit: 'kWh', dueDate: 'May 06, 2025', status: BillStatus.paid),
    const Bill(id: 'GAS-2604-00014', type: 'Gas', period: 'Apr 2025', amount: 25500, usage: 17, unit: 'm³', dueDate: 'May 06, 2025', status: BillStatus.paid),
    const Bill(id: 'WTR-2604-00014', type: 'Water', period: 'Apr 2025', amount: 43500, usage: 29, unit: 'm³', dueDate: 'May 06, 2025', status: BillStatus.paid),
    const Bill(id: 'COL-2604-00014', type: 'Cooling', period: 'Apr 2025', amount: 30000, usage: 20, unit: 'kWh', dueDate: 'May 06, 2025', status: BillStatus.paid),
    const Bill(id: 'ELE-2603-00013', type: 'Electricity', period: 'Mar 2025', amount: 207000, usage: 138, unit: 'm³', dueDate: 'Apr 06, 2025', status: BillStatus.paid),
  ];
}
