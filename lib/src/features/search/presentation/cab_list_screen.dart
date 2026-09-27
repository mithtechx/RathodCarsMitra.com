import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CabListScreen extends StatefulWidget {
  final String from;
  final String to;
  final String date;

  const CabListScreen({
    super.key,
    required this.from,
    required this.to,
    required this.date,
  });

  @override
  State<CabListScreen> createState() => _CabListScreenState();
}

class _CabListScreenState extends State<CabListScreen> {
  static const primaryColor = Color(0xFFD95325);
  bool _onlyAc = false;
  bool _isFullCabMode = false;

  // Route prices fetched dynamically from 'routes_pricing' table
  double _routeSeatPrice = 500.0;
  double _routeFullCabPrice = 2000.0;
  bool _isLoadingPrice = true;

  @override
  void initState() {
    super.initState();
    _fetchRoutePricing();
  }

  Future<void> _fetchRoutePricing() async {
    try {
      final response = await Supabase.instance.client
          .from('routes_pricing')
          .select()
          .eq('pickup_city', widget.from)
          .eq('drop_city', widget.to)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _routeSeatPrice = (response['seat_price'] ?? 500).toDouble();
          _routeFullCabPrice = (response['full_cab_price'] ?? 2000).toDouble();
          _isLoadingPrice = false;
        });
      } else {
        setState(() {
          _isLoadingPrice = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPrice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentRouteName = '${widget.from} → ${widget.to}';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentRouteName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.verified, size: 12, color: primaryColor),
                const SizedBox(width: 4),
                Text(
                  'Verified Route • ${widget.date}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _isLoadingPrice
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              children: [
                // Filter Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FilterChip(
                        label: const Text('AC Only', style: TextStyle(fontSize: 12)),
                        selected: _onlyAc,
                        selectedColor: primaryColor.withOpacity(0.12),
                        checkmarkColor: primaryColor,
                        backgroundColor: const Color(0xFFF4F1EA),
                        labelStyle: TextStyle(
                          color: _onlyAc ? primaryColor : Colors.black87,
                          fontWeight: _onlyAc ? FontWeight.bold : FontWeight.w600,
                        ),
                        onSelected: (val) => setState(() => _onlyAc = val),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F1EA),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: false, label: Text('Per Seat', style: TextStyle(fontSize: 11))),
                            ButtonSegment(value: true, label: Text('Full Cab', style: TextStyle(fontSize: 11))),
                          ],
                          selected: {_isFullCabMode},
                          onSelectionChanged: (val) => setState(() => _isFullCabMode = val.first),
                          style: ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: WidgetStateProperty.resolveWith((states) =>
                              states.contains(WidgetState.selected) ? primaryColor : Colors.transparent
                            ),
                            foregroundColor: WidgetStateProperty.resolveWith((states) => 
                              states.contains(WidgetState.selected) ? Colors.white : Colors.black87
                            ),
                            side: WidgetStateProperty.all(BorderSide.none),
                            shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),

                // StreamBuilder combining baseline fleet + Admin extra cabs
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: Supabase.instance.client
                        .from('cabs')
                        .stream(primaryKey: ['id'])
                        .eq('route_name', currentRouteName)
                        .eq('date', widget.date),
                    builder: (context, snapshot) {
                      final List<Map<String, dynamic>> baselineCabs = [
                        {
                          'id': 'baseline_hatchback',
                          'cab_type': 'Hatchback / Sedan',
                          'subtitle': 'Comfortable 4-seater ride',
                          'time': '09:00 AM',
                          'seats_available': 4,
                          'is_ac': true,
                          'seat_price': _routeSeatPrice,
                          'full_cab_price': _routeFullCabPrice,
                        },
                        {
                          'id': 'baseline_suv',
                          'cab_type': 'SUV / Innova',
                          'subtitle': 'Spacious 6/7-seater premium ride',
                          'time': '10:00 AM',
                          'seats_available': 6,
                          'is_ac': true,
                          'seat_price': _routeSeatPrice,
                          'full_cab_price': _routeFullCabPrice,
                        },
                      ];

                      final List<Map<String, dynamic>> adminExtraCabs = snapshot.hasData ? snapshot.data! : [];

                      // Merge baseline + extra cabs
                      final List<Map<String, dynamic>> allCabs = [...baselineCabs, ...adminExtraCabs];

                      final filteredCabs = allCabs.where((cab) {
                        final isAc = cab['is_ac'] ?? true;
                        if (_onlyAc && !isAc) return false;
                        return true;
                      }).toList();

                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        children: [
                          ...filteredCabs.map((cab) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _cabTypeCard(context, cab: cab),
                              )),
                          
                          // Custom Rathod Cars Mitra Eco Impact Message
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE8E5DD)),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.eco_outlined, color: primaryColor, size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade800, height: 1.4),
                                      children: const [
                                        TextSpan(
                                          text: 'Ride Green with Rathod Cars Mitra: ',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                                        ),
                                        TextSpan(
                                          text: 'By sharing this ride instead of driving solo, you are actively cutting down carbon emissions and helping decongest our highways. Together, sustainable travel makes every journey count!',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _cabTypeCard(BuildContext context, {required Map<String, dynamic> cab}) {
    final double seatPrice = (cab['seat_price'] ?? _routeSeatPrice).toDouble();
    final double fullCabPrice = (cab['full_cab_price'] ?? _routeFullCabPrice).toDouble();
    final double price = _isFullCabMode ? fullCabPrice : seatPrice;
    final bool isAc = cab['is_ac'] ?? true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E5DD)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cab['cab_type'] ?? 'Standard Cab',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cab['subtitle'] ?? 'Comfortable ride option',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isAc ? primaryColor.withOpacity(0.08) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isAc ? 'AC' : 'Non-AC',
                  style: TextStyle(color: isAc ? primaryColor : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1EFEA)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.black54),
                      const SizedBox(width: 4),
                      Text(cab['time'] ?? '09:00 AM', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _isFullCabMode ? 'Exclusive vehicle booking' : '${cab['seats_available'] ?? 4} seats available',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹${price.toInt()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                      Text(_isFullCabMode ? 'Full Cab' : 'Per Seat', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      context.push('/select-seats', extra: {
                        'from': widget.from,
                        'to': widget.to,
                        'date': widget.date,
                        'cabType': cab['cab_type'],
                        'price': price.toString(),
                        'time': cab['time'],
                        'isFullCab': _isFullCabMode,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(_isFullCabMode ? 'Book Cab' : 'Select Seats', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}