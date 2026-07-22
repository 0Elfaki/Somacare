import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/bloom_components.dart';

/// Payment method options mirrored from the Bloom spec (screen 9).
enum _PayMethod { mtn, airtel, card }

/// Spec screen 9 — Payment.
///
/// Expects a route `extra` map with:
/// - `doctorName` (String)
/// - `consultFee` (int, UGX)
/// - `platformFee` (int, UGX)
/// - `onConfirm` (Future<void> Function()) — performs the actual booking
///   write (Supabase insert + notification). Called when the student taps Pay.
class PaymentScreen extends StatefulWidget {
  final String doctorName;
  final int consultFee;
  final int platformFee;
  final Future<void> Function() onConfirm;

  const PaymentScreen({
    super.key,
    required this.doctorName,
    required this.consultFee,
    required this.platformFee,
    required this.onConfirm,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  _PayMethod _method = _PayMethod.mtn;
  bool _isPaying = false;

  int get _total => widget.consultFee + widget.platformFee;

  String _fmtUgx(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return 'UGX $buf';
  }

  Future<void> _pay() async {
    if (_isPaying) return;
    setState(() => _isPaying = true);
    try {
      await widget.onConfirm();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Payment successful — appointment booked!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/my-appointments');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPaying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkScreenBg,
      body: SafeArea(
        child: Column(
          children: [
            const BloomScreenHeader(title: 'Payment'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BloomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ORDER SUMMARY',
                            style: BloomTextStyles.inter(
                              size: 10,
                              weight: FontWeight.w700,
                              color: AppColors.darkTextMuted,
                              letterSpacing: 0.06,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _SummaryRow(
                            label: '${widget.doctorName} — consult',
                            value: _fmtUgx(widget.consultFee),
                          ),
                          const SizedBox(height: 6),
                          _SummaryRow(
                            label: 'Platform fee',
                            value: _fmtUgx(widget.platformFee),
                            muted: true,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: BloomDivider(),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total',
                                style: BloomTextStyles.inter(
                                  size: 14,
                                  weight: FontWeight.w700,
                                  color: AppColors.darkTextPrimary,
                                ),
                              ),
                              BloomMonoText(
                                _fmtUgx(_total),
                                size: 14,
                                weight: FontWeight.w600,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const BloomSectionTitle('Payment method'),
                    BloomCard(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Column(
                        children: [
                          BloomPaymentMethodTile(
                            iconColor: const Color(0xFFFFCB05),
                            label: 'MTN Mobile Money',
                            selected: _method == _PayMethod.mtn,
                            onTap: () =>
                                setState(() => _method = _PayMethod.mtn),
                          ),
                          BloomPaymentMethodTile(
                            iconColor: const Color(0xFFE4002B),
                            label: 'Airtel Money',
                            selected: _method == _PayMethod.airtel,
                            onTap: () =>
                                setState(() => _method = _PayMethod.airtel),
                          ),
                          BloomPaymentMethodTile(
                            iconColor: AppColors.primaryDark,
                            label: 'Visa / Mastercard',
                            selected: _method == _PayMethod.card,
                            onTap: () =>
                                setState(() => _method = _PayMethod.card),
                            showBorder: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              decoration: const BoxDecoration(
                color: AppColors.darkSurface,
                border: Border(
                  top: BorderSide(color: AppColors.darkBorder, width: 1),
                ),
              ),
              child: BloomButton(
                label: _isPaying ? 'Processing…' : 'Pay ${_fmtUgx(_total)}',
                isLoading: _isPaying,
                onPressed: _isPaying ? null : _pay,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool muted;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: BloomTextStyles.inter(
              size: 12,
              color: muted
                  ? AppColors.darkTextMuted
                  : AppColors.darkTextPrimary,
            ),
          ),
        ),
        BloomMonoText(
          value,
          size: 12,
          color: muted ? AppColors.darkTextMuted : AppColors.darkTextPrimary,
        ),
      ],
    );
  }
}
