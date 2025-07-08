// lib/transfers_screens/accommodation_to_airport.dart

import 'package:collection/collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/airport_model.dart';
import '../models/customer_model.dart';
import '../models/transfer_model.dart';
import '../models/transfer_query.dart';
import '../models/transfer_type.dart';
import '../providers/airport_notifier.dart';
import '../providers/child_seat_notifier.dart';
import '../providers/driver_notifier.dart';
import '../providers/staff_notifer.dart';
import '../providers/transfer_provider.dart';

class AccommodationToAirportScreen extends ConsumerStatefulWidget {
  static const routeName = '/accommodation_to_airport';
  final CustomerModel customer;
  final String? initialPickupAddress;
  const AccommodationToAirportScreen({
    Key? key,
    required this.customer,
    this.initialPickupAddress,
  }) : super(key: key);

  @override
  ConsumerState<AccommodationToAirportScreen> createState() =>
      _AccommodationToAirportScreenState();
}

class _AccommodationToAirportScreenState
    extends ConsumerState<AccommodationToAirportScreen> {
  TransferModel? _editing;

  DateTime _flightTime = DateTime.now();
  DateTime _pickupTime = DateTime.now();
  bool _manuallyEditedPickup = false;

  final _flightCtrl = TextEditingController();
  final _adultCtrl = TextEditingController(text: '1');
  final _childCtrl = TextEditingController(text: '0');
  final _agesCtrl = TextEditingController();
  final _pickupCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  Airport? _selectedAirport;
  String? _selectedDriverId;
  String? _selectedStaffId;
  final List<String> _selectedSeats = [];

  final _fmt = DateFormat('d MMM yyyy, h:mma');

  @override
  void initState() {
    super.initState();
    _flightCtrl.text = _fmt.format(_flightTime);
    if (widget.initialPickupAddress != null) {
      _pickupCtrl.text = widget.initialPickupAddress!;
      _manuallyEditedPickup = true;
    }
  }

  @override
  void dispose() {
    for (var ctl in [
      _flightCtrl,
      _adultCtrl,
      _childCtrl,
      _agesCtrl,
      _pickupCtrl,
      _costCtrl,
      _notesCtrl,
    ]) {
      ctl.dispose();
    }
    super.dispose();
  }

  void _loadForEdit(TransferModel t) {
    setState(() {
      _editing = t;
      _flightTime = t.flightDateAndTime!.toDate();
      _flightCtrl.text = _fmt.format(_flightTime);
      _pickupTime = t.collectionDateAndTime.toDate();
      _pickupCtrl.text = t.pickupLocation;
      _manuallyEditedPickup = true;

      final airports = ref.read(airportsStreamProvider).valueOrNull ?? [];
      _selectedAirport = airports.firstWhereOrNull((a) => a.name == t.dropOffLocation);

      _costCtrl.text = t.cost;
      _selectedDriverId = t.driverUUID;
      _selectedStaffId = t.staffId;
      _adultCtrl.text = t.adults.toString();
      _childCtrl.text = t.children.toString();
      _agesCtrl.text = t.childAges?.join(', ') ?? '';
      _selectedSeats
        ..clear()
        ..addAll(t.childSeatIds ?? []);
      _notesCtrl.text = t.notes ?? '';
    });
  }

  Future<void> _pickDateTime({
    required DateTime initial,
    required void Function(DateTime) onPicked,
    required TextEditingController ctrl,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    onPicked(dt);
    ctrl.text = _fmt.format(dt);
  }

  void _recomputePickup() {
    if (_selectedAirport != null && !_manuallyEditedPickup) {
      final offset = Duration(minutes: _selectedAirport!.pickupOffsetMinutes);
      setState(() {
        _pickupTime = _flightTime.subtract(offset);
        _pickupCtrl.text = _fmt.format(_pickupTime);
      });
    }
  }

  Future<void> _submit() async {
    final adults = int.tryParse(_adultCtrl.text) ?? 1;
    final children = int.tryParse(_childCtrl.text) ?? 0;
    List<String>? ages;
    if (children > 0) {
      ages = _agesCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (ages.length != children) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Enter exactly one age per child, comma-separated.'),
          ),
        );
        return;
      }
    }

    if (_selectedAirport == null ||
        _selectedDriverId == null ||
        _selectedStaffId == null ||
        _costCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    _recomputePickup();
    if (_manuallyEditedPickup) {
      final offset = Duration(minutes: _selectedAirport!.pickupOffsetMinutes);
      final computed = _flightTime.subtract(offset);
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Pickup Time Changed'),
          content: Text(
            'Computed pickup was ${_fmt.format(computed)}\n'
                'But you set ${_fmt.format(_pickupTime)}.\nProceed?',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Proceed')),
          ],
        ),
      );
      if (ok != true) return;
    }

    final t = TransferModel(
      collectionUUID: _editing?.collectionUUID ?? '',
      customerUUID: widget.customer.id,
      type: TransferType.accommodationToAirport,
      collectionDateAndTime: Timestamp.fromDate(_pickupTime),
      flightNumber: _editing?.flightNumber,
      flightDateAndTime: Timestamp.fromDate(_flightTime),
      pickupLocation: _pickupCtrl.text.trim(),
      dropOffLocation: _selectedAirport!.name,
      airportCollection: false,
      customerName:
      '${widget.customer.firstName} ${widget.customer.lastName}',
      phone1: widget.customer.phone,
      phone2: widget.customer.secondaryPhone,
      staffId: _selectedStaffId!,
      staffName: ref
          .read(staffListProvider)
          .maybeWhen(
        data: (list) => list
            .firstWhere((s) => s.id == _selectedStaffId!)
            .name +
            ' ' +
            list
                .firstWhere((s) => s.id == _selectedStaffId!)
                .lastName,
        orElse: () => '',
      ),
      driverUUID: _selectedDriverId!,
      driverName: ref
          .read(driversStreamProvider)
          .maybeWhen(
        data: (list) =>
        list.firstWhere((d) => d.id == _selectedDriverId!).name,
        orElse: () => '',
      ),
      amountOfPeople: '${adults + children}',
      cost: _costCtrl.text.trim(),
      pickupLocationGeoPoint: null,
      dropOffLocationGeoPoint: null,
      notes: _notesCtrl.text.trim().isEmpty
          ? null
          : _notesCtrl.text.trim(),
      childSeatIds:
      _selectedSeats.isEmpty ? null : _selectedSeats,
      childAges: ages,
      adults: adults,
      children: children,
      status: _editing?.status ?? TransferStatus.pending,
    );

    final repo = ref.read(transferRepoProvider);
    if (_editing == null) {
      await repo.addTransfer(t);
    } else {
      await repo.updateTransfer(t);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              _editing == null ? 'Transfer booked' : 'Transfer updated')),
    );
    setState(() {
      _editing = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final airports = ref.watch(airportsStreamProvider);
    final drivers = ref.watch(driversStreamProvider);
    final staff = ref.watch(staffListProvider);
    final seats = ref.watch(childSeatsStreamProvider);

    final transfers = ref.watch(
      transfersByQueryProvider(
        TransferQuery(
          type: TransferType.accommodationToAirport,
          start: _flightTime.subtract(const Duration(days: 1)),
          end: _flightTime.add(const Duration(days: 1)),
        ),
      ),
    );

    Widget formSection = SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Home Address:', style: Theme.of(context).textTheme.titleMedium),
        Text(widget.customer.address ?? '— none on file —'),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Use Home Address'),
            onPressed: () {
              setState(() {
                _pickupCtrl.text = widget.customer.address ?? '';
                _manuallyEditedPickup = true;
              });
            },
          ),
        ),
        const Divider(height: 24),

        ListTile(
          leading: const Icon(Icons.flight_takeoff),
          title: Text('Flight Time: ${_fmt.format(_flightTime)}'),
          onTap: () => _pickDateTime(
            initial: _flightTime,
            ctrl: _flightCtrl,
            onPicked: (dt) {
              _flightTime = dt;
              if (!_manuallyEditedPickup) _recomputePickup();
            },
          ),
        ),

        ListTile(
          leading: const Icon(Icons.access_time),
          title: Text('Pickup Time: ${_fmt.format(_pickupTime)}'),
          onTap: () => _pickDateTime(
            initial: _pickupTime,
            ctrl: TextEditingController(text: _fmt.format(_pickupTime)),
            onPicked: (dt) {
              _pickupTime = dt;
              _manuallyEditedPickup = true;
            },
          ),
        ),

        TextFormField(
          controller: _pickupCtrl,
          decoration:
          const InputDecoration(labelText: 'Collection Address'),
          onChanged: (_) => _manuallyEditedPickup = true,
        ),
        const SizedBox(height: 8),

        airports.when(
          data: (list) => DropdownButtonFormField<Airport>(
            decoration:
            const InputDecoration(labelText: 'Drop-off Airport'),
            items: list
                .map((a) =>
                DropdownMenuItem(value: a, child: Text('${a.name} (${a.code})')))
                .toList(),
            onChanged: (a) {
              _selectedAirport = a;
              _recomputePickup();
            },
            value: _selectedAirport,
          ),
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Airports error: $e'),
        ),
        const SizedBox(height: 8),

        TextFormField(
          controller: _costCtrl,
          decoration: const InputDecoration(labelText: 'Cost'),
          keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 8),

        drivers.when(
          data: (list) => DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Driver'),
            items: list
                .map((d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
                .toList(),
            onChanged: (v) => _selectedDriverId = v,
            value: _selectedDriverId,
          ),
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Drivers error: $e'),
        ),
        const SizedBox(height: 8),

        staff.when(
          data: (list) => DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Booked By'),
            items: list
                .map((s) => DropdownMenuItem(
              value: s.id,
              child: Text('${s.name} ${s.lastName}'),
            ))
                .toList(),
            onChanged: (v) => _selectedStaffId = v,
            value: _selectedStaffId,
          ),
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Staff error: $e'),
        ),
        const SizedBox(height: 8),

        TextFormField(
          controller: _adultCtrl,
          decoration: const InputDecoration(labelText: 'Adults'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _childCtrl,
          decoration: const InputDecoration(labelText: 'Children'),
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
        ),

        if ((int.tryParse(_childCtrl.text) ?? 0) > 0) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _agesCtrl,
            decoration: const InputDecoration(
                labelText: 'Children’s Ages (comma-separated)'),
          ),
          const SizedBox(height: 8),
          seats.when(
            data: (list) => Wrap(
              spacing: 8,
              children: list.map((cs) {
                final sel = _selectedSeats.contains(cs.id);
                return FilterChip(
                  label: Text(cs.type),
                  selected: sel,
                  onSelected: (_) {
                    setState(() {
                      if (sel)
                        _selectedSeats.remove(cs.id);
                      else
                        _selectedSeats.add(cs.id);
                    });
                  },
                );
              }).toList(),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Seats error: $e'),
          ),
        ],

        const SizedBox(height: 8),
        TextFormField(
          controller: _notesCtrl,
          decoration: const InputDecoration(labelText: 'Notes'),
          maxLines: 3,
        ),
        const SizedBox(height: 16),

        ElevatedButton(
          onPressed: _submit,
          child: Text(_editing == null ? 'Book Transfer' : 'Save Changes'),
        ),
      ]),
    );

    Widget listSection = transfers.when(
      data: (jobs) {
        if (jobs.isEmpty)
          return const Center(child: Text('No upcoming transfers'));
        return ListView.separated(
          padding: const EdgeInsets.all(8),
          separatorBuilder: (_, __) => const Divider(),
          itemCount: jobs.length,
          itemBuilder: (_, i) {
            final t = jobs[i];
            final isMine = t.customerUUID == widget.customer.id;
            Color bg;
            switch (t.status) {
              case TransferStatus.pending:
                bg = Colors.red.shade100;
                break;
              case TransferStatus.confirmed:
                bg = Colors.amber.shade100;
                break;
              case TransferStatus.completed:
                bg = Colors.green.shade100;
                break;
              case TransferStatus.canceled:
                bg = Colors.grey.shade300;
                break;
            }
            return Container(
              color: bg,
              child: ListTile(
                title: Text(
                  'Flight: ${_fmt.format(t.flightDateAndTime!.toDate())}\n'
                      'Pickup: ${_fmt.format(t.collectionDateAndTime.toDate())}\n'
                      'From: ${t.pickupLocation} → To: ${t.dropOffLocation}',
                ),
                subtitle: Text(
                  'Pax: ${t.adults + t.children}  Cost: ${t.cost}\n'
                      'By: ${t.staffName}  Driver: ${t.driverName}',
                ),
                isThreeLine: true,
                trailing: isMine
                    ? IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _loadForEdit(t),
                )
                    : null,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );

    return Scaffold(
      appBar: AppBar(
          title: Text(_editing == null
              ? 'Accommodation → Airport'
              : 'Edit Transfer')),
      body: LayoutBuilder(builder: (ctx, bc) {
        if (bc.maxWidth > 600) {
          return Row(
            children: [
              Expanded(child: formSection),
              const VerticalDivider(),
              Expanded(child: listSection),
            ],
          );
        }
        return Column(
          children: [
            Expanded(child: formSection),
            const Divider(),
            Expanded(child: listSection),
          ],
        );
      }),
    );
  }
}
