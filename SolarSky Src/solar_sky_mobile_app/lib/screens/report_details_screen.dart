import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:solar_sky_mobile_app/screens/report_virtual_farm_screen.dart';

class ReportDetailsScreen extends StatefulWidget {
  final String reportId;

  const ReportDetailsScreen({Key? key, required this.reportId})
      : super(key: key);

  @override
  _ReportDetailsScreenState createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  final pdf = pw.Document();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    generateReport();
  }

  pw.Widget buildSummaryItem(String label, String value,
      {pw.TextStyle? valueStyle}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Bullet(text: label, style: const pw.TextStyle(fontSize: 12)),
        pw.Text(value, style: valueStyle ?? const pw.TextStyle(fontSize: 12)),
      ],
    );
  }

  Future<void> generateReport() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    var reportData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('reports')
        .doc(widget.reportId)
        .get();

    if (!reportData.exists) {
      return;
    }

    var reportDetails = reportData.data()!;
    var farmSize = reportDetails['rows'] * reportDetails['columns'];
    // Assume we have all necessary fields in reportDetails

    // Fetch faulty panels
    var faultyPanelsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('reports')
        .doc(widget.reportId)
        .collection('faultyPanels')
        .get();

    // Create a list of bullet points
    List<pw.Widget> faultyPanelWidgets =
        faultyPanelsSnapshot.docs.map((panelDoc) {
      var panelData = panelDoc.data() as Map<String, dynamic>;
      // Adjust the row and column to start from 1 instead of 0 for display
      int displayRow = panelData['row'] + 1;
      int displayColumn = panelData['column'] + 1;
      return pw.Bullet(
        text:
            'Solar Panel ${panelData['serialNumber']}: (Row $displayRow, Column $displayColumn)',
      );
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Center(
            child: pw.Text(
              'FARM INSPECTION REPORT',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
              textAlign:
                  pw.TextAlign.center, // Aligns text to the center horizontally
            ),
          ),
          pw.SizedBox(height: 30), // Adds space after the title

          // Details laid out in a row
          pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Paragraph(
                      text: 'Farm name: ${reportDetails['farmName']}'),
                ),
                pw.Expanded(
                  child: pw.Paragraph(
                      text: 'Drone name: ${reportDetails['droneName']}'),
                ),
                pw.Expanded(
                  child: pw.Paragraph(
                    text:
                        'Date: ${DateTime.parse(reportDetails['timestamp'].toDate().toString()).toIso8601String().substring(0, 10)}',
                  ),
                ),
              ]),
          pw.Divider(), // Divider after the row of details
          // Summary Section Title
          pw.Text(
            'Farm Inspection Summary:',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 14, // Adjust the size as per your requirement
            ),
          ),
          pw.SizedBox(height: 12), // Adds space after the title

          // Summary Details
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 16,
                    child: pw.Bullet(
                      text: 'Farm Size:',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      '$farmSize',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 16,
                    child: pw.Bullet(
                      text: 'Total Number of solar panels:',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      '${reportDetails['totalNumberOfPanels']}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 16,
                    child: pw.Bullet(
                      text: 'Number of faulty solar panels:',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      '${reportDetails['numberOfFaultyPanels']}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 16,
                    child: pw.Bullet(
                      text: 'Number of healthy solar panels:',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      '${reportDetails['numberOfHealthyPanels']}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // children: [
          //   pw.Bullet(
          //       text:
          //           'Total Number of solar panels: ${reportDetails['totalNumberOfPanels']}',
          //       style: pw.TextStyle(fontSize: 12)),
          //   pw.Bullet(
          //       text: 'Farm Size: $farmSize',
          //       style: pw.TextStyle(fontSize: 12)),
          //   pw.Bullet(
          //       text:
          //           'Number of faulty solar panels: ${reportDetails['numberOfFaultyPanels']}',
          //       style: pw.TextStyle(fontSize: 12)),
          //   pw.Bullet(
          //       text:
          //           'Number of healthy solar panels: ${reportDetails['numberOfHealthyPanels']}',
          //       style: pw.TextStyle(fontSize: 12)),
          pw.Divider(), // Divider after the row of details

          pw.Text(
            'Solar Panels with Faults:',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 14, // Adjust the size as per your requirement
            ),
          ),
          pw.SizedBox(height: 12), // Adds space after the title
          ...faultyPanelWidgets,

          pw.Divider(), // Divider after the row of details

          pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Text(
              'Recommendations:',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Paragraph(
              text:
                  'Upon inspection, certain visual faults were identified in multiple solar panels. It is essential to conduct a comprehensive cleaning and maintenance procedure to address issues such as dust accumulation, cracks, or any faults that could impede the panels\' efficiency. Regular maintenance ensures optimal performance and extends the longevity of the solar array.'),
        ],
      ),
    );

    setState(() {
      loading = false;
    });
  }

  Future<void> sharePDF() async {
    // Use the Printing package to share the PDF in memory
    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'report.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Report Details',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2F004F),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : PdfPreview(
              build: (format) => pdf.save(),
              canChangeOrientation: false,
              canChangePageFormat: false,
              allowPrinting: false, // Disable the printing option
              allowSharing: false, // Disable the sharing option
              pdfFileName: 'report.pdf',
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          mainAxisSize: MainAxisSize
              .min, // Use min to shrink wrap the content in the column
          children: [
            ElevatedButton.icon(
              icon: const Icon(
                Icons.share,
                color: Colors.white, // Icon color
              ),
              label: const Text(
                'Share PDF',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white, // Text font size
                ),
              ),
              onPressed:
                  sharePDF, // Call the sharePDF function when the button is pressed
              style: ElevatedButton.styleFrom(
                  primary: const Color(0xFF008955), // Button background color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15), // Rounded corners
                  ),
                  minimumSize:
                      const Size(double.infinity, 49), // Button minimum size
                  padding: const EdgeInsets.symmetric(
                      horizontal: 50) // Padding inside the button
                  ),
            ),
            const SizedBox(height: 8), // Spacing between buttons
            ElevatedButton.icon(
              icon: const Icon(
                Icons.chevron_right_outlined,
                color: Colors.white,
              ),
              label: const Text(
                'Display Report Virtual Farm',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              onPressed: () {
                // Navigate to ReportVirtualFarmScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ReportVirtualFarmScreen(reportId: widget.reportId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                  primary: const Color(0xFF008955),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  minimumSize: const Size(double.infinity, 49),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 50) // Padding inside the button
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
