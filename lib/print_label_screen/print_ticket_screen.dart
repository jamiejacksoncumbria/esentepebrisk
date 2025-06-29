// lib/print_label_screen/print_ticket_screen.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';

import '../models/car_model.dart';
import '../models/customer_model.dart';
import '../providers/car_notifier.dart';

enum PrinterType { windows, bluetooth }

class PrinterItem {
  final String id, name, size;
  final PrinterType type;
  final BluetoothDevice? device;
  final Printer? printer;
  PrinterItem({
    required this.id,
    required this.name,
    required this.size,
    required this.type,
    this.device,
    this.printer,
  });
  String get displayName => '$name ($size)';
}

class PrintLabelScreen extends ConsumerStatefulWidget {
  static const routeName = '/printLabel';
  final CustomerModel customer;
  const PrintLabelScreen({super.key, required this.customer});
  @override
  PrintLabelScreenState createState() => PrintLabelScreenState();
}

class PrintLabelScreenState extends ConsumerState<PrintLabelScreen> {
  Car? _selectedCar;
  DateTime? _startDateTime, _endDateTime;
  List<PrinterItem> _printers = [];
  PrinterItem? _selectedPrinter;
  bool _loadingPrinters = true;

  final DateFormat _fmt = DateFormat('d MMM yyyy h:mma');

  @override
  void initState() {
    super.initState();
    // default start to next top-of-hour, end to same time + 3 days
    final now = DateTime.now();
    final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);
    _startDateTime = nextHour;
    _endDateTime = nextHour.add(const Duration(days: 3));
    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    final items = <PrinterItem>[];

    if (!kIsWeb && Platform.isWindows) {
      for (final p in await Printing.listPrinters()) {
        items.add(PrinterItem(
          id: p.name,
          name: p.name,
          size: 'Default',
          type: PrinterType.windows,
          printer: p,
        ));
      }
    }

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final bt = BlueThermalPrinter.instance;
      for (final d in await bt.getBondedDevices()) {
        final devName = d.name ?? d.address ?? 'Unknown Device';
        for (final size in ['58mm', '80mm']) {
          items.add(PrinterItem(
            id: '${d.address}|$size',
            name: devName,
            size: size,
            type: PrinterType.bluetooth,
            device: d,
          ));
        }
      }
    }

    PrinterItem? lastSel;
    if (items.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getString('lastPrinter');
      if (last != null) {
        lastSel = items.firstWhere((it) => it.id == last, orElse: () => items[0]);
      }
    }

    setState(() {
      _printers = items;
      _selectedPrinter = lastSel;
      _loadingPrinters = false;
    });
  }

  Future<void> _pickDateTime({required bool start}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: start ? _startDateTime! : _endDateTime!,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(start ? _startDateTime! : _endDateTime!),
    );
    if (time == null) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (start) {
        _startDateTime = dt;
      } else {
        _endDateTime = dt;
      }
    });
  }

  String _format(DateTime dt) => _fmt.format(dt).toUpperCase();

  Future<void> _printLabel() async {
    if (_selectedCar == null ||
        _startDateTime == null ||
        _endDateTime == null ||
        _selectedPrinter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields and select a printer.')),
      );
      return;
    }
    if (!_endDateTime!.isAfter(_startDateTime!)) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Invalid Date Range'),
          content: const Text('End date/time must be after start date/time.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
          ],
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastPrinter', _selectedPrinter!.id);

    final c = widget.customer;
    final startStr = _format(_startDateTime!);
    final endStr   = _format(_endDateTime!);
    final carDesc  = '${_selectedCar!.registration} ${_selectedCar!.make} ${_selectedCar!.model}'.toUpperCase();
    final note     = (c.latestNoteSnippet ?? '').toUpperCase();

    // Windows / PDF printing
    if (_selectedPrinter!.type == PrinterType.windows &&
        _selectedPrinter!.printer != null) {
      final doc = pw.Document();
      doc.addPage(pw.Page(build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('${c.firstName} ${c.lastName}'.toUpperCase(), style: pw.TextStyle(fontSize: 14)),
          pw.Text(c.phone.toUpperCase(), style: pw.TextStyle(fontSize: 14)),
          // ← ID & License if present
          if (c.passportNumber != null && c.passportNumber!.isNotEmpty)
            pw.Text('I: ${c.passportNumber!}'.toUpperCase(), style: pw.TextStyle(fontSize: 14)),
          if (c.licenseNumber != null && c.licenseNumber!.isNotEmpty)
            pw.Text('L: ${c.licenseNumber!}'.toUpperCase(), style: pw.TextStyle(fontSize: 14)),
          pw.Text((c.email ?? '').toUpperCase(), style: pw.TextStyle(fontSize: 14)),
          pw.Text((c.address ?? '').toUpperCase(), style: pw.TextStyle(fontSize: 14)),
          pw.Text(startStr, style: pw.TextStyle(fontSize: 14)),
          pw.Text(endStr, style: pw.TextStyle(fontSize: 14)),
          pw.Text(carDesc, style: pw.TextStyle(fontSize: 14)),
          pw.Text('NOTE: $note', style: pw.TextStyle(fontSize: 14)),
          pw.SizedBox(height: 8),
        ],
      )));
      final bytes = await doc.save();
      await Printing.directPrintPdf(
        printer: _selectedPrinter!.printer!,
        onLayout: (_) async => bytes,
      );

      // Bluetooth printing (GS ! width x1 height x0)
    } else if (_selectedPrinter!.type == PrinterType.bluetooth &&
        _selectedPrinter!.device != null) {
      final bt = BlueThermalPrinter.instance;
      final connected = await bt.isConnected;
      if (connected != true) {
        await bt.connect(_selectedPrinter!.device!);
      }

      // GS ! 0x01 → double-width, normal height
      await bt.writeBytes(Uint8List.fromList([0x1D, 0x21, 0x01]));

      // build lines dynamically
      final lines = <String>[
        '${c.firstName} ${c.lastName}'.toUpperCase(),
        c.phone.toUpperCase(),
        if (c.passportNumber != null && c.passportNumber!.isNotEmpty)
          'I: ${c.passportNumber!}'.toUpperCase(),
        if (c.licenseNumber != null && c.licenseNumber!.isNotEmpty)
          'L: ${c.licenseNumber!}'.toUpperCase(),
        (c.email ?? '').toUpperCase(),
        (c.address ?? '').toUpperCase(),
        startStr,
        endStr,
        carDesc,
        'NOTE: $note',
        '',
      ];
      for (var line in lines) {
        await bt.writeBytes(Uint8List.fromList(line.codeUnits));
        await bt.writeBytes(Uint8List.fromList([0x0A])); // LF
      }

      // Reset size
      await bt.writeBytes(Uint8List.fromList([0x1D, 0x21, 0x00]));
      // Cut paper
      await bt.writeBytes(Uint8List.fromList([0x1D, 0x56, 0x00]));
    }
  }

  @override
  Widget build(BuildContext context) {
    final carsAsync = ref.watch(carsStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Print Car Hire Label')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(children: [
          Text(
            'Customer: ${widget.customer.firstName} ${widget.customer.lastName}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          carsAsync.when(
            data: (cars) => DropdownButton<Car?>(
              isExpanded: true,
              value: _selectedCar,
              hint: const Text('Please select a car'),
              items: [
                const DropdownMenuItem<Car?>(value: null, child: Text('Please select a car')),
                ...cars.map((c) => DropdownMenuItem<Car>(
                  value: c,
                  child: Text(
                    '${c.registration} ${c.make} ${c.model}',
                    style: const TextStyle(fontSize: 14),
                  ),
                )),
              ],
              onChanged: (c) => setState(() => _selectedCar = c),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error loading cars: $e'),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: Text(
              _startDateTime == null ? 'Select Start Date & Time' : _format(_startDateTime!),
              style: const TextStyle(fontSize: 14),
            ),
            onTap: () => _pickDateTime(start: true),
          ),
          ListTile(
            title: Text(
              _endDateTime == null ? 'Select End Date & Time' : _format(_endDateTime!),
              style: const TextStyle(fontSize: 14),
            ),
            onTap: () => _pickDateTime(start: false),
          ),
          const SizedBox(height: 16),
          _loadingPrinters
              ? const Center(child: CircularProgressIndicator())
              : DropdownButton<PrinterItem>(
            isExpanded: true,
            value: _selectedPrinter,
            hint: const Text('Select Printer & Size'),
            items: _printers
                .map((p) => DropdownMenuItem<PrinterItem>(
              value: p,
              child: Text(p.displayName, style: const TextStyle(fontSize: 14)),
            ))
                .toList(),
            onChanged: (p) => setState(() => _selectedPrinter = p),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _printLabel,
            child: const Text('Print Label', style: TextStyle(fontSize: 14)),
          ),
        ]),
      ),
    );
  }
}
