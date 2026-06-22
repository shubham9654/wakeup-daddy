import 'package:flutter/foundation.dart';

/// Penalty Mode — if an alarm is ignored past the grace window, the user has
/// pledged to donate ₹10–₹100 to charity.
///
/// Payment capture must go through a PCI-compliant gateway (Razorpay/Stripe).
/// This service models the pledge ledger locally and exposes the hook where
/// the gateway charge is triggered. Wire [_charge] to your gateway SDK +
/// WakeDaddy backend before shipping real money movement.
class PenaltyService {
  PenaltyService._();
  static final PenaltyService instance = PenaltyService._();

  final List<PenaltyCharge> _ledger = [];
  List<PenaltyCharge> get ledger => List.unmodifiable(_ledger);

  Future<void> trigger({required int amount, required String charity}) async {
    final charge = PenaltyCharge(
      amount: amount,
      charity: charity,
      at: DateTime.now(),
    );
    _ledger.add(charge);
    await _charge(charge);
  }

  Future<void> _charge(PenaltyCharge c) async {
    // TODO: integrate Razorpay/Stripe charge + backend receipt.
    debugPrint('[penalty] would donate ₹${c.amount} to ${c.charity}');
  }
}

class PenaltyCharge {
  final int amount;
  final String charity;
  final DateTime at;
  const PenaltyCharge(
      {required this.amount, required this.charity, required this.at});
}
