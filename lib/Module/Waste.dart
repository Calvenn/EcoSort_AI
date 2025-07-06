import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../config/Map.dart';
import '../config/Feedback.dart';
import '../config/Correction.dart';
import '../config/ImgDetector.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class WastePage extends StatefulWidget {
  @override
  _WastePageState createState() => _WastePageState();
}

class _WastePageState extends State<WastePage> {
  File? _image; // For mobile
  String? _webImageUrl; // For web
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

  Future<void> pickImageFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      uploadImage(File(pickedFile.path));
    }
  }

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (kIsWeb) {
          _webImageUrl = picked.path; // This is a blob URL
          _image = null;
        } else {
          _image = File(picked.path);
          _webImageUrl = null;
        }
        _prediction = null;
        _confidence = null;
        _feedbackCorrect = null;
      });
      await uploadImage(
        File(picked.path),
      ); // For both, you can still use picked.path
    }
  }

  Future<void> uploadImage(File image) async {
    setState(() {
      _loading = true;
      _image = image;
      _prediction = null;
      _confidence = null;
      _feedbackCorrect = null;
    });

    final imageHash = await ImageUploader.computeImageHash(image);
    final isDuplicate = await ImageUploader.isDuplicateUpload(imageHash);

    if (isDuplicate) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You've already uploaded this image before.")),
        );
      }
      return;
    }

    final uri = Uri.parse('https://ecosort-0qot.onrender.com/predict');
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
          logScan(_prediction!, imageHash);
          addPoints(10);
        });
      } else {
        setState(() {
          _prediction = "Prediction failed";
          _confidence = null;
        });
      }
    } catch (e, stacktrace) {
      print('Upload error: $e');
      if (mounted) {
        setState(() {
          _prediction = "Prediction error";
          _confidence = null;
        });
      }
    }

    setState(() => _loading = false);
  }

  String getImageForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'plastic':
      case 'metal':
        return 'assets/recycle-bin(Orange).png';
      case 'paper':
      case 'cardboard':
        return 'assets/recycle-bin(Blue).png';
      case 'glass':
        return 'assets/recycle-bin(Brown).png';
      default:
        return 'assets/default-bin.png';
    }
  }

  Color getColorForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'plastic':
      case 'metal':
        return Colors.orange;
      case 'paper':
      case 'cardboard':
        return Colors.blue[800]!;
      case 'glass':
        return Colors.brown[700]!;
      default:
        return Colors.green;
    }
  }

  bool shouldRequestFeedback(String? confidenceStr) {
    if (confidenceStr == null) return false;
    final cleaned = confidenceStr.replaceAll('%', '');
    final confValue = double.tryParse(cleaned);
    return confValue != null && confValue < 85;
  }

  Future<bool> uploadToGitHub(File imageFile, String label) async {
    final token = ''; // GitHub token
    final repoOwner = 'Calvenn';
    final repoName = 'Waste_Classifier';
    final fileName = '${label}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'corrections/$fileName';

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final url = Uri.parse(
      'https://api.github.com/repos/$repoOwner/$repoName/contents/$path',
    );

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'token $token',
        'Accept': 'application/vnd.github.v3+json',
      },
      body: json.encode({
        'message': 'Upload wrong image: $label',
        'content': base64Image,
      }),
    );

    print("GitHub response: ${response.statusCode} ${response.body}");
    return response.statusCode == 201;
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
    print("Feedback received: \$isCorrect");

    setState(() => _feedbackCorrect = isCorrect);

    if (_image == null) {
      print("No image found.");
      return;
    }

    // Compute hash early so it's available for both cases
    final imageHash = await ImageUploader.computeImageHash(_image!);

    if (isCorrect) {
      print("Logging predicted label: \$_prediction");

      await logScan(_prediction!, imageHash);
      await addPoints(10); // Add 10 points for accepted prediction

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Thanks for your feedback! +10 points")),
        );
      }
      return;
    }

    print("Prediction was incorrect. Asking for corrected label...");
    final correctedLabel = await showDialog<String>(
      context: context,
      builder: (context) => CorrectLabelDialog(),
    );

    if (correctedLabel == null) {
      print("User did not enter correction.");
      return;
    }

    print("Corrected label: \$correctedLabel");

    final uploaded = await uploadToGitHub(_image!, correctedLabel);
    if (uploaded) {
      print("Uploaded to GitHub successfully");
      await FirebaseFirestore.instance.collection('corrections').add({
        'label': correctedLabel,
        'location': 'GitHub',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      print("Failed to upload to GitHub");
      return;
    }

    await logScan(correctedLabel, imageHash);
    await addPoints(15); // Add 15 points for correction

    print("Correction logged to history");

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Correction saved and logged. +15 points")),
      );
    }
  }

  Future<void> logScan(String type, String imageHash) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final historyRef = userDoc.collection('history');

    final duplicate = await historyRef
        .where('hash', isEqualTo: imageHash)
        .limit(1)
        .get();
    if (duplicate.docs.isNotEmpty) {
      print("Duplicate scan detected, not logging again.");
      return;
    }

    await historyRef.add({
      'type': type,
      'hash': imageHash,
      'timestamp': Timestamp.now(),
    });

    print('Scan logged: $type with hash $imageHash at ${DateTime.now()}');
  }

  Future<void> addPoints(int amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDoc);
      final currentPoints = (snapshot.data()?['points'] ?? 0) as int;
      transaction.update(userDoc, {'points': currentPoints + amount});
    });

    print('Points awarded: +$amount');
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
              (_image != null || _webImageUrl != null)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: kIsWeb
                          ? Image.network(
                              _webImageUrl!,
                              height: 200,
                              fit: BoxFit.cover,
                            )
                          : Image.file(_image!, height: 200, fit: BoxFit.cover),
                    )
                  : Icon(
                      Icons.image_outlined,
                      size: 110,
                      color: Colors.grey[400],
                    ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: pickImageFromCamera,
                icon: Icon(Icons.camera_alt),
                label: Text("Take Photo"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: pickImage,
                icon: Icon(Icons.add_photo_alternate),
                label: Text("Upload from Gallery"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
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
                  elevation: 6,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.red),
                            Text(
                              " Prediction: $_prediction",
                              style: TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info, color: Colors.blue),
                            Text(
                              _confidence != null
                                  ? " Confidence: ${double.tryParse(_confidence!.replaceAll('%', ''))?.toStringAsFixed(2) ?? _confidence}%"
                                  : " Confidence: $_confidence",
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),

                        SizedBox(height: 10),
                        if (_feedbackCorrect != true)
                          FeedbackWidget(
                            onFeedbackGiven: handleFeedback,
                            feedbackCorrect: _feedbackCorrect,
                          ),
                        SizedBox(height: 12),
                        Image.asset(
                          getImageForLabel(_prediction!),
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "${_prediction!.toUpperCase()} WASTE",
                          style: TextStyle(
                            color: getColorForLabel(_prediction!),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Important Guidelines",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          disposalInstructions[_prediction!]?['tip'] ??
                              'No disposal instruction found.',
                          style: TextStyle(fontSize: 15, color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),

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
