import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../main.dart';

class ShopSetupScreen extends StatefulWidget {
  const ShopSetupScreen({super.key});
  @override
  State<ShopSetupScreen> createState() => _ShopSetupScreenState();
}

class _ShopSetupScreenState extends State<ShopSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _shop = TextEditingController();
  final _code = TextEditingController();
  bool _join = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _shop.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_join) {
        await AppData.joinShop(
          code: _code.text.trim(),
          displayName: _name.text.trim(),
        );
      } else {
        await AppData.createShop(
          name: _shop.text.trim(),
          code: _code.text.trim(),
          displayName: _name.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Set up your shop')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Image.asset('assets/images/expiry_logo.png', height: 120),
            ),
            const SizedBox(height: 16),
            Text(
              _join
                  ? 'Join the shared shop your team already uses.'
                  : 'Create a shared shop for your team.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Create shop')),
                ButtonSegment(value: true, label: Text('Join shop')),
              ],
              selected: {_join},
              onSelectionChanged: (value) =>
                  setState(() => _join = value.first),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Your name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter your name'
                        : null,
                  ),
                  if (!_join) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _shop,
                      decoration: const InputDecoration(
                        labelText: 'Shop name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().length < 2
                          ? 'Enter a shop name'
                          : null,
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _code,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: _join ? 'Shop code' : 'Create a shop code',
                      helperText: 'At least 6 characters',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.trim().length < 6
                        ? 'Use at least 6 characters'
                        : null,
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_join ? 'Join shop' : 'Create shop'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
