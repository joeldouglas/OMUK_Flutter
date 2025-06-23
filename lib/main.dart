import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PG_ScriptSetting(), // Make sure this is the correct class
    );
  }
}


class PG_ScriptSetting extends StatelessWidget 
{
  const PG_ScriptSetting({super.key});
  

  void _handleImport(BuildContext context) async {
  String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
  if (selectedDirectory == null) return;

  final dir = Directory(selectedDirectory);
  final excelFiles = dir
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.xlsx'))
      .toList();

  if (excelFiles.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No Excel files found.")),
    );
    return;
  }

  final selectedFile = await showExcelFilePicker(context, excelFiles);
  if (selectedFile == null) return;

  final result = await extractHeadersWithSheetPicker(context, selectedFile);
  if (result == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No headers or sheet selected.")),
    );    
    return;
  }

  final (selectedSheetName, headers) = result;

  final selectedHeaders = await showColumnSelectorDialog(context, headers);
  if (selectedHeaders == null || selectedHeaders.isEmpty) return;

  
  final selectedFileName = p.basenameWithoutExtension(selectedFile.path);
  final sheetData = await extractSheetData(selectedFile, selectedSheetName);
  final selectedRows = extractSelectedColumnRows(sheetData, selectedHeaders);

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => SelectedColumnsScreen
      (
        rows: selectedRows,
        headers: selectedHeaders,
        fileName: selectedFileName,
        excelSheet: sheetData,
      ),
    ),
  );
}


  // --- Helper: Pick Excel File Dialog ---
  Future<File?> showExcelFilePicker(BuildContext context, List<File> excelFiles) {
    return showDialog<File>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select an Excel File'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: excelFiles.map((file) {
              final name = file.path.split(Platform.pathSeparator).last;
              return ListTile(
                title: Text(name),
                onTap: () => Navigator.pop(ctx, file),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<(String, List<String>)?> extractHeadersWithSheetPicker(
  BuildContext context,
  File file,
) async {
  final bytes = await file.readAsBytes();
  final excel = Excel.decodeBytes(bytes);

  // Get sheet names
  final sheetNames = excel.tables.keys.toList();
  if (sheetNames.isEmpty) return null;

  // Ask user to pick a worksheet
  final selectedSheetName = await showSheetPickerDialog(context, sheetNames);
  if (selectedSheetName == null) return null;

  final sheet = excel.tables[selectedSheetName];
  if (sheet == null || sheet.rows.isEmpty) return null;

  final firstRow = sheet.rows.first;
  final headers = firstRow
      .map((cell) => cell?.value?.toString().trim() ?? '')
      .where((header) => header.isNotEmpty)
      .toList();

  return (selectedSheetName, headers);
}


Future<String?> showSheetPickerDialog(BuildContext context, List<String> sheetNames) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Select Worksheet'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: sheetNames.map((name) {
            return ListTile(
              title: Text(name),
              onTap: () => Navigator.pop(ctx, name),
            );
          }).toList(),
        ),
      ),
    ),
  );
}


  // --- Helper: Column Selector Dialog ---
  Future<List<String>?> showColumnSelectorDialog(
      BuildContext context, List<String> headers) {
    final selected = <String>{};

    return showDialog<List<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Select Columns'),
          content: SingleChildScrollView(
            child: Column(
              children: headers.map((header) {
                return CheckboxListTile(
                  title: Text(header),
                  value: selected.contains(header),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        selected.add(header);
                      } else {
                        selected.remove(header);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, selected.toList()),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Script Setting")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _handleImport(context),
          child: const Text("Import Excel"),
        ),
      ),
    );
  }
  
}


//
//  THE MAIN SCRIPT DISPLAY SCREEN
//
class SelectedColumnsScreen extends StatefulWidget 
{
  final List<List<String>> rows;
  final List<String> headers; // add headers so we can identify columns by name
  final String fileName;
  final excelSheet;

  const SelectedColumnsScreen({
    super.key,
    required this.rows,
    required this.headers,
    required this.fileName,
    required this.excelSheet
  });

  @override
  State<SelectedColumnsScreen> createState() => _SelectedColumnsScreenState();
}

class _SelectedColumnsScreenState extends State<SelectedColumnsScreen> 
{
    late List<List<String>> filteredRows;

    @override
    void initState()
    {
        super.initState();
        filteredRows = widget.rows;
    }

    void _filterByCharacter() async
    {
        // Locate the Character column using Regex
        final charIndex = widget.headers.indexWhere
        (
            (h) => 
                RegExp(r'character', caseSensitive: false).hasMatch(h)
        );        

        if (charIndex == -1)
        {
            ScaffoldMessenger.of(context).showSnackBar
            (
                const SnackBar(content: Text("No 'Character' column found.")),
            );            
            return;
        }
        
    

      final uniqueCharacters = widget.rows
          .map((row) => row.length > charIndex ? row[charIndex].trim() : '')
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList()
          ..sort();

      final selectedCharacters = 
        await showCharacterPickerDialog(context, uniqueCharacters);

      if (selectedCharacters == null || selectedCharacters.isEmpty) return;

      setState(()
        {
            filteredRows = widget.rows.where((row) 
            {
                if (row.length <= charIndex) 
                {
                    return false;
                }

                return selectedCharacters.contains(row[charIndex].trim());})
                  .toList();
            });
        }      

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        actions: [
          TextButton(
            onPressed: _filterByCharacter,
            child: const Text(
              "Filter by Character",
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          )
        ],
      ),
      body: filteredRows.isEmpty
          ? const Center(child: Text('No data found.'))
          : ListView.builder(
              itemCount: filteredRows.length,
              itemBuilder: (context, index) {
                final row = filteredRows[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
                  child: Row(
                    children: List.generate(widget.headers.length, (colIndex) {
                      final cellText =
                          (colIndex < row.length) ? row[colIndex] : '';

                      final isEnglishColumn = RegExp(r'^english$', caseSensitive: false)
                          .hasMatch(widget.headers[colIndex]);

                      final boxWidth = isEnglishColumn ? 600.0 : 150.0;

                      return Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: SizedBox(
                          width: boxWidth,
                          child: Text(cellText),
                        ),
                      );
                    }),
                  ),
                );
              },
            ),
    );
  }
}



Future<List<String>?> showCharacterPickerDialog(
    BuildContext context, List<String> characterNames) {
  final selected = <String>{};

  return showDialog<List<String>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Select Character(s)'),
        content: SingleChildScrollView(
          child: Column(
            children: characterNames.map((name) {
              return CheckboxListTile(
                title: Text(name),
                value: selected.contains(name),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      selected.add(name);
                    } else {
                      selected.remove(name);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, selected.toList()),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ),
  );
}




// Returns all rows as a List<Map<columnName, value>>
Future<List<Map<String, String>>> extractSheetData(File file, String sheetName) async {
  final bytes = await file.readAsBytes();
  final excel = Excel.decodeBytes(bytes);
  final sheet = excel.tables[sheetName];
  if (sheet == null || sheet.rows.length < 2) return [];

  final headers = sheet.rows.first
      .map((cell) => cell?.value?.toString().trim() ?? '')
      .toList();

  final rows = sheet.rows.skip(1).map((row) 
  {
    final rowMap = <String, String>{};
    for (int i = 0; i < headers.length; i++) {
      final key = headers[i];
      final value = (i < row.length) ? row[i]?.value?.toString() ?? '' : '';
      rowMap[key] = value;
    }
    return rowMap;
  }).toList();

  print(rows);
  return rows;
}

// Filters to only include selected headers
List<List<String>> extractSelectedColumnRows(
  List<Map<String, String>> allRows,
  List<String> selectedHeaders,
) {
  return allRows.map((rowMap) {
    return selectedHeaders.map((header) => rowMap[header] ?? '').toList();
  }).toList();
}

/*
Future List<List<String>> cellData()
{

}
*/

