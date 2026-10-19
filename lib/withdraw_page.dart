import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WithdrawPage extends StatefulWidget {
  final double balance;

  const WithdrawPage({super.key, this.balance = 0.0});

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  // ---- Colors (the dark field colors are what fix the light boxes) ----
  static const Color _bgColor = Color(0xFF0A0D14);
  static const Color _cardColor = Color(0xFF101722);
  static const Color _fieldColor = Color(0xFF0A0E16);
  static const Color _borderColor = Color(0xFF232938);
  static const Color _labelColor = Color(0xFF7D8699);
  static const Color _amberColor = Color(0xFFE5A93C);
  static const Color _redColor = Color(0xFFEF5350);

  static const double _minWithdraw = 5.0;

  // Network name -> address pattern
  static final Map<String, RegExp> _networks = {
    'USDT — BEP20 (BSC)': RegExp(r'^0x[a-fA-F0-9]{40}$'),
    'USDT — TRC20 (TRON)': RegExp(r'^T[a-zA-Z0-9]{33}$'),
    'USDT - BTC (Bitcoin)': RegExp(r'^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$'),
  };

  late String _network = _networks.keys.first;
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();

  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // ---- Network popup (the dialog with radio buttons) ----
  Future<void> _pickNetwork() async {
    final picked = await showDialog<String>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Color(0xFFF9F9F9),
          insetPadding: EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _networks.keys.map((name) {
              final selected = name == _network;
              final isLast = name == _networks.keys.last;
              return InkWell(
                onTap: () => Navigator.pop(context, name),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : const Border(
                        bottom: BorderSide(color: Color(0xFFDDDDDD))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                              color: Color(0xFF111111), fontSize: 24),
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: selected
                            ? const Color(0xFF3B5BDB)
                            : const Color(0xFF444444),
                        size: 34,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _network = picked;
        _error = null;
      });
    }
  }

  Future<void> _submit() async {
    final address = _addressController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    String? error;
    if (address.isEmpty) {
      error = 'Enter your destination wallet.py address.';
    } else if (!_networks[_network]!.hasMatch(address)) {
      error = 'That address is not valid for this network.';
    } else if (amount == null || amount <= 0) {
      error = 'Enter a valid amount.';
    } else if (amount < _minWithdraw) {
      error = 'Minimum withdrawal is \$${_minWithdraw.toStringAsFixed(0)}.';
    } else if (amount > widget.balance) {
      error = 'Amount exceeds your available balance.';
    }

    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() {
      _error = null;
      _submitting = true;
    });

    // TODO: replace with your real backend / API call
    await Future.delayed(Duration(seconds: 1));
    if (!mounted) return;

    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _cardColor,
        content: Text(
          'Withdrawal of \$${amount!.toStringAsFixed(2)} requested (simulated).',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
    Navigator.pop(context);
  }

  // ---- Small reusable pieces ----
  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        color: _labelColor,
        fontSize: 14,
        letterSpacing: 1.4,
        fontFamily: 'monospace',
      ),
    );
  }

  InputDecoration _fieldDecoration({String? hint, String? prefix}) {
    const normal = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: _borderColor),
    );
    const focused = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: _amberColor),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Color(0xFF4A5263), fontSize: 18),
      prefixText: prefix,
      prefixStyle: TextStyle(
          color: Color(0xFF4A5263), fontSize: 24, fontFamily: 'monospace'),
      filled: true,
      fillColor: _fieldColor,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      border: normal,
      enabledBorder: normal,
      focusedBorder: focused,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          child: Container(
            decoration: BoxDecoration(
              color: _cardColor,
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Header ----
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.chevron_left,
                            color: _labelColor, size: 32),
                      ),
                      SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Withdraw',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Balance: ',
                                  style: TextStyle(color: _labelColor),
                                ),
                                TextSpan(
                                  text:
                                  '\$${widget.balance.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            style: TextStyle(
                                fontSize: 17, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: _borderColor),

                // ---- Form ----
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _label('NETWORK'),
                          Text(
                            'Min \$${_minWithdraw.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: _amberColor,
                              fontSize: 15,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      // Network field: tapping opens the popup
                      GestureDetector(
                        onTap: _pickNetwork,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 22),
                          decoration: BoxDecoration(
                            color: _fieldColor,
                            border: Border.all(color: _borderColor),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _network,
                                  style: TextStyle(color: Colors.white, fontSize: 20),
                                ),
                              ),
                              Icon(Icons.keyboard_arrow_down,
                                  color: _labelColor),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),

                      _label('DESTINATION ADDRESS'),
                      SizedBox(height: 12),
                      TextField(
                        controller: _addressController,
                        style: TextStyle(color: Colors.white, fontSize: 18),
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: _fieldDecoration(
                            hint: 'Paste your wallet.py address'),
                      ),
                      SizedBox(height: 24),

                      _label('AMOUNT (USD)'),
                      SizedBox(height: 12),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        style: TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'monospace'),
                        decoration:
                        _fieldDecoration(hint: '0.00', prefix: '\$  '),
                      ),

                      if (_error != null) ...[
                        SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _redColor.withValues(alpha: 0.12),
                            border: Border.all(
                                color: _redColor.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            _error!,
                            style: TextStyle(
                                color: _redColor, fontSize: 14),
                          ),
                        ),
                      ],
                      SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _redColor,
                            disabledBackgroundColor:
                            _redColor.withValues(alpha: 0.5),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero),
                          ),
                          child: _submitting
                              ? SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          )
                              : Text(
                            'Request Withdrawal',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}