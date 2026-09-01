import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MasareefiApp());

class MasareefiApp extends StatelessWidget {
  const MasareefiApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مصاريفي',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const HomePage(),
    );
  }
}

class Expense {
  String name;
  double amount;
  String date;
  Expense({required this.name, required this.amount, required this.date});
  Map<String, dynamic> toJson() => {'name': name, 'amount': amount, 'date': date};
  factory Expense.fromJson(Map<String, dynamic> j) =>
      Expense(name: j['name'], amount: (j['amount'] as num).toDouble(), date: j['date']);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Expense> expenses = [];
  double balance = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('expenses');
    setState(() {
      balance = p.getDouble('balance') ?? 0;
      if (raw != null) {
        expenses = (jsonDecode(raw) as List).map((e) => Expense.fromJson(e)).toList();
      }
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble('balance', balance);
    await p.setString('expenses', jsonEncode(expenses.map((e) => e.toJson()).toList()));
  }

  double get total => expenses.fold(0, (s, e) => s + e.amount);

  Future<void> _addExpense() async {
    final name = TextEditingController();
    final amount = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إضافة مصروف'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم المصروف')),
          TextField(controller: amount, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'المبلغ')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('إضافة')),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty && double.tryParse(amount.text) != null) {
      setState(() => expenses.insert(0, Expense(
        name: name.text.trim(),
        amount: double.parse(amount.text),
        date: DateTime.now().toString().substring(0, 10),
      )));
      await _save();
    }
  }

  Future<void> _setBalance() async {
    final c = TextEditingController(text: balance == 0 ? '' : balance.toStringAsFixed(0));
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تحديد الرصيد'),
        content: TextField(controller: c, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'الرصيد بالجنيه')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ')),
        ],
      ),
    );
    if (ok == true && double.tryParse(c.text) != null) {
      setState(() => balance = double.parse(c.text));
      await _save();
    }
  }

  Future<void> _delete(int i) async {
    setState(() => expenses.removeAt(i));
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = balance - total;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('💰 مصاريفي'), actions: [
          IconButton(onPressed: _setBalance, icon: const Icon(Icons.account_balance_wallet_outlined))
        ]),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Text('الرصيد المتاح', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 5),
                  Text('${remaining.toStringAsFixed(2)} جنيه',
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('إجمالي المصاريف: ${total.toStringAsFixed(2)} ج'),
                    Text('عدد العمليات: ${expenses.length}'),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(child: expenses.isEmpty
              ? const Center(child: Text('مفيش مصاريف لسه 👌'))
              : ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (_, i) {
                    final e = expenses[i];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
                        title: Text(e.name),
                        subtitle: Text(e.date),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('-${e.amount.toStringAsFixed(2)} ج',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(onPressed: () => _delete(i), icon: const Icon(Icons.delete_outline)),
                        ]),
                      ),
                    );
                  },
                )),
          ]),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addExpense,
          icon: const Icon(Icons.add),
          label: const Text('إضافة مصروف'),
        ),
      ),
    );
  }
}
