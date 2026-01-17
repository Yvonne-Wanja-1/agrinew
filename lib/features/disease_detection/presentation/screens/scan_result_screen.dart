import 'package:flutter/material.dart';
import 'dart:io';
import 'package:agriclinichub_new/core/services/local_storage_service.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class ScanResultScreen extends StatefulWidget {
  final String imagePath;

  const ScanResultScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  bool _isLoading = true;
  late Map<String, dynamic> _scanResult;

  @override
  void initState() {
    super.initState();
    _performAnalysis();
  }

  Future<void> _performAnalysis() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      // Generate mock scan result data
      _scanResult = {
        'crop': 'Tomato',
        'status': 'Early Blight',
        'disease': 'Early Blight',
        'confidence': 94,
        'description':
            'Early Blight is a fungal disease that primarily affects tomato and potato plants. It causes brown spots with concentric rings on the leaves and stems.',
      };
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveToHistory() async {
    try {
      const uuid = Uuid();
      final scanId = uuid.v4();
      final now = DateTime.now();
      final dateFormatter = DateFormat('MMM d, yyyy');

      final scanData = {
        'id': scanId,
        'imagePath': widget.imagePath,
        'date': dateFormatter.format(now),
        'crop': _scanResult['crop'] ?? 'Unknown',
        'status': _scanResult['status'] ?? 'Unknown',
        'confidence': _scanResult['confidence'] ?? 0,
        'cropIcon': Icons.local_florist.codePoint,
        'timestamp': now.millisecondsSinceEpoch,
      };

      await LocalStorageService.saveScanLocally(scanId, scanData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Result saved to history!'),
            duration: Duration(seconds: 2),
          ),
        );
        // Navigate back to history after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/history', (route) => route.isFirst);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving result: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Results'),
        centerTitle: true,
        backgroundColor: Colors.green.shade600,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.green.shade600,
                        ),
                        strokeWidth: 4,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Analyzing your plant...',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(
                            File(widget.imagePath),
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 25),

                        // Disease Detection Card
                        _buildResultCard(
                          icon: Icons.warning_rounded,
                          iconColor: Colors.orange.shade600,
                          title: 'Disease Detected',
                          subtitle: 'Early Blight',
                          backgroundColor: Colors.orange.shade50,
                        ),
                        const SizedBox(height: 20),

                        // Confidence
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Confidence',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade600,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  '94%',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),

                        // Description
                        Text(
                          'Description',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Early Blight is a fungal disease that primarily affects tomato and potato plants. It causes brown spots with concentric rings on the leaves and stems. The disease thrives in warm, wet conditions and can significantly reduce crop yield if not managed properly.',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              height: 1.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),

                        // Treatment Recommendations
                        Text(
                          'Treatment Recommendations',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 15),
                        _buildRecommendation(
                          'Remove affected leaves',
                          'Prune infected leaves and dispose of them properly',
                          Icons.local_florist,
                        ),
                        const SizedBox(height: 12),
                        _buildRecommendation(
                          'Apply fungicide',
                          'Use chlorothalonil or mancozeb fungicide',
                          Icons.opacity,
                        ),
                        const SizedBox(height: 12),
                        _buildRecommendation(
                          'Improve air circulation',
                          'Ensure proper spacing and remove lower leaves',
                          Icons.air,
                        ),
                        const SizedBox(height: 12),
                        _buildRecommendation(
                          'Water properly',
                          'Water at the base and avoid wetting leaves',
                          Icons.water_drop,
                        ),
                        const SizedBox(height: 25),

                        // Read More Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Opening related articles...'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.article),
                            label: const Text('Read Related Articles'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Save Result Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: _saveToHistory,
                            icon: const Icon(Icons.bookmark_border),
                            label: const Text('Save to History'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green.shade600,
                              side: BorderSide(
                                color: Colors.green.shade600,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildResultCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: iconColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 32),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendation(String title, String description, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
