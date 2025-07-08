// lib/transfers_screens/airport_to_accommodation.dart

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

class AirportToAccommodationScreen extends ConsumerStatefulWidget {
  static const routeName = '/airport_to_accommodation';
  final CustomerModel customer;

  const AirportToAccommodationScreen({
    Key? key,
    required this.customer,
  }) : super(key: key);

  @override
  ConsumerState<AirportToAccommodationScreen> createState() =>
      _AirportToAccommodationScreenState();
}

class _AirportToAccommodationScreenState
    extends ConsumerState<AirportToAccommodationScreen> {
  DateTime _date = DateTime.now();
  final _flightCtrl  = TextEditingController();
  final _adultCtrl   = TextEditingController(text: '1');
  final _childCtrl   = TextEditingController(text: '0');
  final _notesCtrl   = TextEditingController();
  final _costCtrl    = TextEditingController();
  final _dropoffCtrl = TextEditingController();

  Airport? _selectedAirport;
  String?  _selectedDriverId;
  String?  _selectedStaffId;
  List<String> _selectedSeats = [];
  String? _editingId; // non-null = editing existing

  final _fmt = DateFormat('d MMM yyyy, h:mma');

  @override
  void dispose() {
    _flightCtrl.dispose();
    _adultCtrl.dispose();
    _childCtrl.dispose();
    _notesCtrl.dispose();
    _costCtrl.dispose();
    _dropoffCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate:  DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (time == null || !mounted) return;
    setState(() {
      _date = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    final adults   = int.tryParse(_adultCtrl.text) ?? 1;
    final children = int.tryParse(_childCtrl.text) ?? 0;

    if (_selectedAirport == null ||
        _dropoffCtrl.text.trim().isEmpty ||
        _selectedDriverId == null ||
        _selectedStaffId == null)
    {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    // Grab lists synchronously
    final staffList  = ref.read(staffListProvider).valueOrNull ?? [];
    final driverList = ref.read(driversStreamProvider).valueOrNull ?? [];

    // find matching staff & driver by ID
    final staffIndex  = staffList.indexWhere((s) => s.id == _selectedStaffId);
    final driverIndex = driverList.indexWhere((d) => d.id == _selectedDriverId);

    final staffName  = staffIndex  >= 0
        ? '${staffList[staffIndex].name} ${staffList[staffIndex].lastName}'
        : '';
    final driverName = driverIndex >= 0
        ? driverList[driverIndex].name
        : '';

    final model = TransferModel(
      collectionUUID:        _editingId ?? '',
      customerUUID:          widget.customer.id,
      type:                  TransferType.airportToAccommodation,
      collectionDateAndTime: Timestamp.fromDate(_date),
      flightDateAndTime:     null,
      pickupLocation:        _selectedAirport!.name,
      dropOffLocation:       _dropoffCtrl.text.trim(),
      airportCollection:     true,
      amountOfPeople:        '${adults + children}',
      cost:                  _costCtrl.text.trim(),
      driverUUID:            _selectedDriverId!,
      staffId:               _selectedStaffId!,
      staffName:             staffName,
      driverName:            driverName,
      notes:                 _notesCtrl.text,
      childSeatIds:          _selectedSeats.isEmpty ? null : _selectedSeats,
      childAges:             null,
      adults:                adults,
      children:              children,
      flightNumber:          _flightCtrl.text.trim(),
      status:                TransferStatus.pending,
      customerName:          '${widget.customer.firstName} ${widget.customer.lastName}',
      phone1:                widget.customer.phone,
      phone2:                widget.customer.secondaryPhone ?? '',
    );

    final repo = ref.read(transferRepoProvider);
    if (_editingId == null) {
      await repo.addTransfer(model);
    } else {
      await repo.updateTransfer(model);
    }

    setState(() => _editingId = null);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Transfer saved')));
  }

  void _startEdit(TransferModel t) {
    setState(() {
      _editingId        = t.collectionUUID;
      _date             = t.collectionDateAndTime.toDate();
      _flightCtrl.text  = t.flightNumber ?? '';
      _adultCtrl.text   = t.adults.toString();
      _childCtrl.text   = t.children.toString();
      _notesCtrl.text   = t.notes ?? '';
      _costCtrl.text    = t.cost;
      _dropoffCtrl.text = t.dropOffLocation;
      _selectedSeats    = t.childSeatIds ?? [];
      // Mapping back from t.pickupLocation → Airport you can fill here if you store its ID
    });
  }

  @override
  Widget build(BuildContext context) {
    final airports  = ref.watch(airportsStreamProvider);
    final drivers   = ref.watch(driversStreamProvider);
    final staff     = ref.watch(staffListProvider);
    final seats     = ref.watch(childSeatsStreamProvider);

    final q = TransferQuery(
      type: TransferType.airportToAccommodation,
      start: DateTime(_date.year, _date.month, _date.day)
          .subtract(const Duration(days: 1)),
      end:   DateTime(_date.year, _date.month, _date.day)
          .add(const Duration(days: 1)),
    );
    final transfers = ref.watch(transfersByQueryProvider(q));

    Widget form = SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ListTile(
          title: Text('Flight at: ${_fmt.format(_date)}'),
          onTap: _pickDateTime,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _flightCtrl,
          decoration: const InputDecoration(labelText: 'Flight Number'),
        ),
        const SizedBox(height: 16),
        airports.when(
          data: (list) => DropdownButtonFormField<Airport>(
            decoration: const InputDecoration(labelText: 'Arrival Airport'),
            value: _selectedAirport,
            items: list.map((a) => DropdownMenuItem(
              value: a,
              child: Text('${a.name} (${a.code})'),
            )).toList(),
            onChanged: (a) => setState(() {
              _selectedAirport = a;
              _costCtrl.text   = a?.cost.toStringAsFixed(2) ?? '';
            }),
          ),
          loading: () => const LinearProgressIndicator(),
          error: (e,_) => Text('Airports error: $e'),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _costCtrl,
          decoration: const InputDecoration(labelText: 'Price'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        if (widget.customer.address != null && widget.customer.address!.isNotEmpty) ...[
          Text('Home Address: ${widget.customer.address!}'),
          TextButton(
            onPressed: () => setState(() {
              _dropoffCtrl.text = widget.customer.address!;
            }),
            child: const Text('Copy Home Address'),
          ),
        ],
        TextFormField(
          controller: _dropoffCtrl,
          decoration: const InputDecoration(labelText: 'Drop-off Address'),
        ),
        const SizedBox(height: 16),
        drivers.when(
          data: (list) => DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Driver'),
            value: _selectedDriverId,
            items: list.map((d) => DropdownMenuItem(
              value: d.id,
              child: Text(d.name),
            )).toList(),
            onChanged: (v) => setState(() => _selectedDriverId = v),
          ),
          loading: () => const LinearProgressIndicator(),
          error: (_,__) => const Text('Driver load error'),
        ),
        const SizedBox(height: 8),
        staff.when(
          data: (list) => DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Booked By'),
            value: _selectedStaffId,
            items: list.map((s) => DropdownMenuItem(
              value: s.id,
              child: Text('${s.name} ${s.lastName}'),
            )).toList(),
            onChanged: (v) => setState(() => _selectedStaffId = v),
          ),
          loading: () => const LinearProgressIndicator(),
          error: (_,__) => const Text('Staff load error'),
        ),
        const SizedBox(height: 16),
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
          seats.when(
            data: (list) => Wrap(
              spacing: 8,
              children: list.map((cs) {
                final sel = _selectedSeats.contains(cs.id);
                return FilterChip(
                  label: Text(cs.type),
                  selected: sel,
                  onSelected: (on) {
                    setState(() {
                      if (on) _selectedSeats.add(cs.id);
                      else    _selectedSeats.remove(cs.id);
                    });
                  },
                );
              }).toList(),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_,__) => const Text('Seats load error'),
          ),
        ],
        const SizedBox(height: 16),
        TextFormField(
          controller: _notesCtrl,
          decoration: const InputDecoration(labelText: 'Notes'),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _submit,
          child: Text(_editingId == null ? 'Book Transfer' : 'Save Changes'),
        ),
      ]),
    );

    Widget list = transfers.when(
      data: (list) {
        if (list.isEmpty) {
          return const Center(child: Text('No upcoming transfers'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(8),
          separatorBuilder: (_,__) => const Divider(),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final t     = list[i];
            final isMine = t.customerUUID == widget.customer.id;
            return ListTile(
              tileColor: t.status == TransferStatus.pending
                  ? Colors.red.shade50
                  : null,
              title: Text('Flight at: ${_fmt.format(t.collectionDateAndTime.toDate())}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Airport: ${t.pickupLocation}'),
                  Text('Drop-off: ${t.dropOffLocation}'),
                  Text('Name: ${t.customerName}'),
                  Text('Phone: ${t.phone1}  ${t.phone2}'),
                  Text('Flight#: ${t.flightNumber ?? '—'}'),
                  Text('Adults: ${t.adults}  Children: ${t.children}'),
                  Text('Passengers: ${t.adults + t.children}'),
                  Text('Price: ${t.cost}'),
                  Text('Booked By: ${t.staffName}'),
                  Text('Driver: ${t.driverName}'),
                  if ((t.notes ?? '').isNotEmpty)
                    Text('Notes: ${t.notes!.length>30? t.notes!.substring(0,30)+'…' : t.notes!}'),
                ],
              ),
              trailing: isMine
                  ? IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _startEdit(t),
              )
                  : null,
            );
          },
        );
      },
      loading: () {
        debugPrint('⏳ transfers loading…');
        return const Center(child: CircularProgressIndicator());
      },
      error: (e,_) {
        debugPrint('❗️ transfers error: $e');
        return Center(child: Text('Error: $e'));
      },
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Airport → Accommodation')),
      body: LayoutBuilder(builder: (ctx, bc) {
        if (bc.maxWidth > 600) {
          return Row(children: [
            Expanded(child: form),
            const VerticalDivider(),
            Expanded(child: list),
          ]);
        }
        return Column(children: [
          Expanded(child: form),
          const Divider(),
          Expanded(child: list),
        ]);
      }),
    );
  }
}
