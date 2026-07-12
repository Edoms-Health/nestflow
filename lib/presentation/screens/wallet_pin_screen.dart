import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestflow/nestflow.dart';

class WalletPinScreen extends StatefulWidget {
  const WalletPinScreen({super.key});

  @override
  State<WalletPinScreen> createState() => _WalletPinScreenState();
}

class _WalletPinScreenState extends State<WalletPinScreen> {
  final SharedPreferencesService _prefs = SharedPreferencesService();
  final TextEditingController _controller = TextEditingController();

  bool _loading = true;
  bool _hasPin = false;
  bool _confirming = false;
  String? _firstPin;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final hasPin = await _prefs.hasWalletPin();
    if (!mounted) return;
    setState(() {
      _hasPin = hasPin;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final entered = _controller.text.trim();
    if (entered.length != 4) {
      setState(() => _error = 'Enter a 4-digit PIN');
      return;
    }

    if (!_hasPin) {
      // Create-PIN flow
      if (!_confirming) {
        setState(() {
          _firstPin = entered;
          _confirming = true;
          _error = null;
          _controller.clear();
        });
        return;
      } else {
        if (entered == _firstPin) {
          await _prefs.saveWalletPin(entered);
          if (!mounted) return;
          _goToWallets();
        } else {
          setState(() {
            _error = "PINs didn't match. Try again.";
            _confirming = false;
            _firstPin = null;
            _controller.clear();
          });
        }
      }
    } else {
      // Verify flow
      final ok = await _prefs.verifyWalletPin(entered);
      if (!mounted) return;
      if (ok) {
        _goToWallets();
      } else {
        setState(() {
          _error = 'Incorrect PIN';
          _controller.clear();
        });
      }
    }
  }

  void _goToWallets() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (_) => WalletCubit()..loadWallets(),
          child: WalletScreen(),
        ),
      ),
    );
  }

  String get _title {
    if (!_hasPin) return _confirming ? 'Confirm PIN' : 'Create Wallet PIN';
    return 'Enter Wallet PIN';
  }

  String get _description {
    if (!_hasPin) {
      return _confirming
          ? 'Re-enter the PIN to confirm it.'
          : 'Set a 4-digit PIN to protect access to your wallets.';
    }
    return 'Enter your 4-digit PIN to view your wallets.';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.padding * 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  Image.asset(
                    AppImages.logo,
                    width: MediaQuery.of(context).size.width * 0.45,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 23,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 4,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(fontSize: 24, letterSpacing: 12),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '••••',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(color: context.colors.error, fontSize: 13),
                    ),
                  ],
                ],
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(elevation: 0),
                  onPressed: _submit,
                  child: Text(
                    (!_hasPin && !_confirming) ? 'CONTINUE' : 'UNLOCK',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
