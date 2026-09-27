import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SelectSeatsScreen extends StatefulWidget {
  final Map<String, dynamic> cabDetails;
  const SelectSeatsScreen({super.key, required this.cabDetails});

  @override
  State<SelectSeatsScreen> createState() => _SelectSeatsScreenState();
}

class _SelectSeatsScreenState extends State<SelectSeatsScreen> {
  late bool _isTwoWay;
  String _returnDate = 'Mon, 21 Sep';
  late final bool _isFullCab;
  late final Set<String> _selectedSeats;

  static const primaryColor = Color(0xFFD95325);
  static const fieldBg = Color(0xFFEBE8DF);
  static const List<String> allSeats = ['1A', '2A', '3A', '4A'];

  @override
  void initState() {
    super.initState();
    _isFullCab = widget.cabDetails['isFullCab'] == true;
    _isTwoWay = widget.cabDetails['isTwoWay'] == true;
    if (_isFullCab) {
      _selectedSeats = Set.from(allSeats);
    } else {
      _selectedSeats = {'1A'};
    }
  }

  @override
  Widget build(BuildContext context) {
    final from = widget.cabDetails['from'] ?? 'Bhopal';
    final to = widget.cabDetails['to'] ?? 'Jabalpur';
    final date = widget.cabDetails['date'] ?? 'Sat, 19 Sep';
    final time = widget.cabDetails['time'] ?? '07:00';
    final carName = widget.cabDetails['carName'] ?? 'Sedan';
    final int seatPrice = int.tryParse(widget.cabDetails['price']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '749') ?? 749;

    final int multiplier = _isTwoWay ? 2 : 1;
    final int totalAmount = _isFullCab
        ? seatPrice * multiplier
        : _selectedSeats.length * seatPrice * multiplier;
    final int advanceAmount = (totalAmount * 0.5).round();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isFullCab ? 'Full Cab Booking' : 'Select Seats',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
            Text('$from → $to • $date • $time',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vehicle Info Banner if Full Cab
                    if (_isFullCab)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.car_rental, color: primaryColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Exclusive $carName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const Text('Entire vehicle reserved for your trip.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // 1-Way / 2-Way Switcher
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isTwoWay = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: !_isTwoWay ? Colors.white : fieldBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: !_isTwoWay
                                        ? primaryColor
                                        : Colors.transparent),
                              ),
                              child: const Column(
                                children: [
                                  Text('1 Way',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text('One side only',
                                      style: TextStyle(
                                          fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isTwoWay = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _isTwoWay ? Colors.white : fieldBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: _isTwoWay
                                        ? primaryColor
                                        : Colors.transparent),
                              ),
                              child: const Column(
                                children: [
                                  Text('2 Way',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text('Same fare for return',
                                      style: TextStyle(
                                          fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_isTwoWay) ...[
                      const SizedBox(height: 16),
                      const Text('Return date',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _returnChip('Mon, 21 Sep'),
                          const SizedBox(width: 8),
                          _returnChip('Tue, 22 Sep'),
                          const SizedBox(width: 8),
                          _returnChip('Wed, 23 Sep'),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Car Seating Layout Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E2D9)),
                      ),
                      child: Column(
                        children: [
                          // Driver Indicator & Front Row (1A)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.airline_seat_recline_extra,
                                      color: Colors.grey),
                                  SizedBox(width: 4),
                                  Text('Driver',
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              _seatBox('1A'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Back/Middle Row (2A, 3A, 4A)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _seatBox('2A'),
                              _seatBox('3A'),
                              _seatBox('4A'),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Legend
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _legendItem(Colors.white, 'Available',
                                  border: true),
                              const SizedBox(width: 16),
                              _legendItem(primaryColor, 'Selected'),
                              const SizedBox(width: 16),
                              _legendItem(Colors.grey.shade300, 'Booked'),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5E2D9))),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isFullCab
                                  ? 'Full Cab (${allSeats.join(', ')})'
                                  : '${_selectedSeats.length} seat(s): ${_selectedSeats.join(', ')}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              '₹$totalAmount total • ₹$advanceAmount advance now - ${_isTwoWay ? "both sides" : "one side"}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (_selectedSeats.isEmpty && !_isFullCab)
                          ? null
                          : () {
                              context.push('/passenger-payment', extra: {
                                ...widget.cabDetails,
                                'selectedSeats': _isFullCab ? allSeats : _selectedSeats.toList(),
                                'isTwoWay': _isTwoWay,
                                'returnDate': _isTwoWay ? _returnDate : null,
                                'totalAmount': totalAmount,
                                'advanceAmount': advanceAmount,
                                'isFullCab': _isFullCab,
                              });
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Enter Passenger Details',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _returnChip(String d) {
    final selected = _returnDate == d;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _returnDate = d),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? primaryColor : fieldBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            d,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _seatBox(String seatNo) {
    final isSelected = _selectedSeats.contains(seatNo);
    return GestureDetector(
      onTap: _isFullCab
          ? null
          : () {
              setState(() {
                if (isSelected) {
                  if (_selectedSeats.length > 1) {
                    _selectedSeats.remove(seatNo);
                  }
                } else {
                  if (_selectedSeats.length < allSeats.length) {
                    _selectedSeats.add(seatNo);
                  }
                }
              });
            },
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isSelected ? primaryColor : Colors.grey.shade400),
        ),
        child: Text(
          seatNo,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _legendItem(Color col, String label, {bool border = false}) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: col,
            borderRadius: BorderRadius.circular(3),
            border: border ? Border.all(color: Colors.grey) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}