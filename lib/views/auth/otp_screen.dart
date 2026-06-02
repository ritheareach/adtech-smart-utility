import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_colors.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/adtech_logo.dart';
import '../home/home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final String? devOtp;

  const OtpScreen({super.key, required this.phone, this.devOtp});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _ctrlList =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusList = List.generate(6, (_) => FocusNode());

  int _secondsLeft = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.devOtp != null && widget.devOtp!.length == 6) {
        for (int i = 0; i < 6; i++) {
          _ctrlList[i].text = widget.devOtp![i];
        }
        setState(() {});
      } else {
        _focusList[0].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    for (final c in _ctrlList) { c.dispose(); }
    for (final f in _focusList) { f.dispose(); }
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _secondsLeft = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_secondsLeft > 0) { _secondsLeft--; } else { t.cancel(); }
      });
    });
  }

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) _focusList[index + 1].requestFocus();
    setState(() {});
  }

  void _onBackspace(int index) {
    if (_ctrlList[index].text.isEmpty && index > 0) {
      _ctrlList[index - 1].clear();
      _focusList[index - 1].requestFocus();
      setState(() {});
    }
  }

  Future<void> _verify() async {
    final code = _ctrlList.map((c) => c.text).join();
    if (code.length != 6) return;
    final vm = context.read<AuthViewModel>();
    final ok = await vm.verifyOtp(widget.phone, code);
    if (!mounted) return;
    if (ok) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.error ?? 'Invalid OTP'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _resendOtp() {
    for (final c in _ctrlList) { c.clear(); }
    _focusList[0].requestFocus();
    _startTimer();
    setState(() {});
  }

  String _maskPhone(String phone) {
    final cleaned = phone.replaceAll(' ', '');
    if (cleaned.length <= 6) return phone;
    return '${cleaned.substring(0, 3)}****${cleaned.substring(cleaned.length - 3)}';
  }

  @override
  Widget build(BuildContext context) {
    final allFilled = _ctrlList.every((c) => c.text.length == 1);
    final verifying = context.watch<AuthViewModel>().loading;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const AdtechLogo(size: 72),
              const SizedBox(height: 24),
              const Text('Verify Your Phone',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit code sent to\n${_maskPhone(widget.phone)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textGray, height: 1.5),
              ),
              const SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) => _OtpBox(
                  controller: _ctrlList[i],
                  focusNode: _focusList[i],
                  onChanged: (v) => _onDigitChanged(i, v),
                  onBackspace: () => _onBackspace(i),
                )),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (allFilled && !verifying) ? _verify : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    disabledBackgroundColor: AppColors.border,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: verifying
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Verify OTP',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 24),
              if (_secondsLeft > 0)
                Text.rich(
                  TextSpan(
                    text: 'Resend code in ',
                    style: const TextStyle(fontSize: 13, color: AppColors.textGray),
                    children: [
                      TextSpan(
                        text: '${_secondsLeft}s',
                        style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              else
                GestureDetector(
                  onTap: _resendOtp,
                  child: const Text('Resend OTP',
                      style: TextStyle(fontSize: 13, color: AppColors.primaryLight,
                          fontWeight: FontWeight.bold, decoration: TextDecoration.underline,
                          decorationColor: AppColors.primaryLight)),
                ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16,
                        color: AppColors.primaryLight.withValues(alpha: 0.8)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'OTP is valid for 5 minutes. Do not share it with anyone.',
                        style: TextStyle(fontSize: 12, color: AppColors.textGray),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    final isFilled = controller.text.length == 1;
    return SizedBox(
      width: 46,
      height: 56,
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              controller.text.isEmpty) {
            onBackspace();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isFilled ? AppColors.primaryLight : AppColors.textDark,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: isFilled
                ? AppColors.primaryLight.withValues(alpha: 0.08)
                : const Color(0xFFF8FAFC),
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isFilled ? AppColors.primaryLight : AppColors.border),
            ),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
