import 'package:flutter/material.dart';

class WebsiteLandingPage extends StatelessWidget {
  const WebsiteLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rathod Cars Mitra | Intercity Cab & Travel Blog'),
        elevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/app');
              },
              icon: const Icon(Icons.directions_car, color: Colors.white),
              label: const Text(
                'Open Booking App',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.deepOrange,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
              color: Colors.grey.shade900,
              child: Column(
                children: [
                  const Text(
                    'Your Trusted Intercity Ride Partner',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Safe, comfortable, and affordable cab bookings across cities in Maharashtra.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/app');
                    },
                    child: const Text('Book Your Ride Now'),
                  ),
                ],
              ),
            ),

            // Blog & Travel Guides Section
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Latest Travel Blogs & Guides',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Read tips, route details, and updates from Rathod Cars Mitra.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // Blog Grid / Cards
                  LayoutBuilder(
                    builder: (context, constraints) {
                      bool isWide = constraints.maxWidth > 700;
                      return Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: [
                          _buildBlogCard(
                            width: isWide ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth,
                            title: 'Top 5 Scenic Intercity Routes in Maharashtra',
                            date: 'October 14, 2026',
                            snippet: 'Discover the best road trips and smooth highway routes for your next weekend getaway.',
                          ),
                          _buildBlogCard(
                            width: isWide ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth,
                            title: 'Why Choose Cab Sharing for Outstation Travel?',
                            date: 'October 10, 2026',
                            snippet: 'Save money and travel comfortably with our verified drivers and well-maintained Ertiga fleet.',
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.grey.shade200,
              child: const Center(
                child: Text(
                  '© 2026 MithTechX - Rathod Cars Mitra. All rights reserved.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlogCard({required double width, required String title, required String date, required String snippet}) {
    return SizedBox(
      width: width,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date, style: const TextStyle(color: Colors.deepOrange, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(snippet, style: const TextStyle(color: Colors.grey, fontSize: 15)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {},
                child: const Text('Read Full Article →'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}