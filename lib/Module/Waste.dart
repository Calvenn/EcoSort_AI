import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../config/Map.dart';
import '../config/Feedback.dart';
import '../config/Correction.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;

class WastePage extends StatefulWidget {
  @override
  _WastePageState createState() => _WastePageState();
}

class _WastePageState extends State<WastePage> {
  File? _image;
  String? _prediction;
  String? _confidence;
  bool _loading = false;
  bool? _feedbackCorrect;

  Map<String, dynamic> disposalInstructions = {};
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchDisposalInstructions();
  }

  Future<void> fetchDisposalInstructions() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('recycling_guide')
        .get();
    final Map<String, dynamic> fetched = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      fetched[doc.id] = {'tip': data['tip'], 'example': data['example']};
    }

    setState(() {
      disposalInstructions = fetched;
    });
  }

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _prediction = null;
        _confidence = null;
        _feedbackCorrect = null;
      });
      await uploadImage(_image!);
    }
  }

  Future<void> uploadImage(File image) async {
    setState(() => _loading = true);
    final uri = Uri.parse('http://127.0.0.1:5000/predict');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', image.path));

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        setState(() {
          _prediction = data['prediction'];
          _confidence = data['confidence'];
          _feedbackCorrect = shouldRequestFeedback(_confidence) ? null : true;
        });
      } else {
        setState(() {
          _prediction = "Prediction failed";
          _confidence = null;
        });
      }
    } catch (e) {
      setState(() {
        _prediction = "Prediction error";
        _confidence = null;
      });
    }
    setState(() => _loading = false);
  }

  bool shouldRequestFeedback(String? confidenceStr) {
    if (confidenceStr == null) return false;
    final cleaned = confidenceStr.replaceAll('%', '');
    final confValue = double.tryParse(cleaned);
    return confValue != null && confValue < 85;
  }

  Future<String?> saveCorrectionImageLocally(File image, String label) async {
    try {
      final correctionsDir = Directory('corrections');
      if (!await correctionsDir.exists()) {
        await correctionsDir.create(recursive: true);
      }
      final fileName =
          '${label}_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
      final savedImagePath = path.join(correctionsDir.path, fileName);
      await image.copy(savedImagePath);
      return savedImagePath;
    } catch (e) {
      return null;
    }
  }

  Future<bool> saveCorrectionToFirestore(String label, String localPath) async {
    try {
      await FirebaseFirestore.instance.collection('corrections').add({
        'label': label,
        'path': localPath,
        'timestamp': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  void handleFeedback(bool isCorrect) async {
    setState(() => _feedbackCorrect = isCorrect);
    if (isCorrect) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Thanks for your feedback!")));
      return;
    }

    final correctedLabel = await showDialog<String>(
      context: context,
      builder: (context) => CorrectLabelDialog(),
    );

    if (correctedLabel != null && _image != null) {
      final localPath = await saveCorrectionImageLocally(
        _image!,
        correctedLabel,
      );
      if (localPath != null) {
        await saveCorrectionToFirestore(correctedLabel, localPath);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Correction saved locally and recorded.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4fef4),
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        title: Row(
          children: [
            Icon(Icons.search, color: Colors.green),
            Text('  Classify Waste'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Center(
          child: Column(
            children: [
              _image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(
                        _image!,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.image_outlined,
                      size: 100,
                      color: Colors.grey[400],
                    ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: pickImage,
                icon: Icon(Icons.add_photo_alternate),
                label: Text("Select Image"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                ),
              ),
              const SizedBox(height: 20),
              if (_loading)
                Column(
                  children: [
                    CircularProgressIndicator(color: Colors.green),
                    SizedBox(height: 12),
                    Text("Analyzing...", style: TextStyle(fontSize: 16)),
                  ],
                ),
              if (_prediction != null) ...[
                Card(
                  margin: EdgeInsets.only(top: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          "🧠 Prediction: $_prediction",
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 6),
                        Text(
                          _confidence != null
                              ? "🎯 Confidence: ${double.tryParse(_confidence!.replaceAll('%', ''))?.toStringAsFixed(2) ?? _confidence}%"
                              : "🎯 Confidence: $_confidence",
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 10),
                        if (_feedbackCorrect != true)
                          FeedbackWidget(
                            onFeedbackGiven: handleFeedback,
                            feedbackCorrect: _feedbackCorrect,
                          ),
                        SizedBox(height: 12),
                        Text(
                          "🗑️ Disposal Tip:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          disposalInstructions[_prediction!] != null
                              ? "${disposalInstructions[_prediction!]['tip']}"
                              : "No disposal instruction found.",
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.green[800],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (disposalInstructions[_prediction!] != null)
                          Text(
                            "Example: ${disposalInstructions[_prediction!]['example']}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: Icon(Icons.map),
                          label: Text("Find Nearby Centers"),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MapPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
