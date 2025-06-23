import 'package:flutter/material.dart';
//import 'package:just_audio/just_audio.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'dart:async';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WAV File Player',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
                 
        scaffoldBackgroundColor: const Color.fromARGB(255, 163, 197, 255),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),

      ),
      //home: PG_DirectorySetting(),
      home: PG_ScriptSetting(),
    );
  }
}



class PG_ScriptSetting extends StatelessWidget
{
    /*@override
    _PG_ScriptSettingState createState() => _PG_ScriptSettingState();*/

    const PG_ScriptSetting({super.key});

    void _handleImport(BuildContext context) async {
    // 1. Pick Directory
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) return;

    // 2. Find Excel files
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

    // 3. Let user pick an Excel file
    final selectedFile = await showExcelFilePicker(context, excelFiles);
    if (selectedFile == null) return;

    // 4. Read headers
    final headers = await extractHeaders(selectedFile);
    if (headers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No headers found in Excel.")),
      );
      return;
    }

    // 5. Select desired columns
    final selectedHeaders = await showColumnSelectorDialog(context, headers);
    if (selectedHeaders == null || selectedHeaders.isEmpty) return;

    // 6. Navigate to display screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectedColumnsScreen(columns: selectedHeaders),
      ),
    );

}
// DIALOG: Pick Excel File
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

// READ HEADERS FROM EXCEL
Future<List<String>> extractHeaders(File file) async {
  final bytes = file.readAsBytesSync();
  final excel = Excel.decodeBytes(bytes);
  final sheet = excel.tables.values.first;
  if (sheet.maxRows == 0) return [];
  return sheet.rows.first
      .map((cell) => cell?.value.toString() ?? '')
      .toList();
}

// DIALOG: Select Columns with Checkboxes
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

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}

// DISPLAY SELECTED COLUMNS
class SelectedColumnsScreen extends StatelessWidget {
  final List<String> columns;

  const SelectedColumnsScreen({super.key, required this.columns});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selected Columns')),
      body: ListView.builder(
        itemCount: columns.length,
        itemBuilder: (context, index) {
          return ListTile(title: Text(columns[index]));
        },
      ),
    );
  }
}

/*
class _PG_ScriptSettingState extends State<PG_ScriptSetting>
{
    final TextEditingController _productionDirectoryController = TextEditingController();
    bool _dragging = false;

    @override
    /*
    Widget build(BuildContext context)
    {
        return Scaffold
        (
            body: Center
            (    
              child: Padding
              (
                padding: const EdgeInsets.all(100.0),
                child: DropTarget
                (
                    onDragDone: (details) async 
                    {
                        if (details.files.isNotEmpty) 
                        {
                            final droppedItem = details.files.first;
                            final folder = Directory(droppedItem.path);

                            if (await folder.exists() &&
                            (await folder.stat()).type == FileSystemEntityType.directory) 
                            {
                                setState(() 
                                {
                                    _productionDirectoryController.text = folder.path;
                                });

                                // Navigate after a frame to avoid setState-related context issues
                                WidgetsBinding.instance.addPostFrameCallback((_) 
                                {
                                    Navigator.push
                                    (
                                        context,
                                        MaterialPageRoute
                                        (
                                            builder: (context) => PG_WavList(directoryPath: folder.path),
                                        ),
                                    );
                                });
                              }
                          }
                      },

                      onDragEntered: (_) => setState(() => _dragging = true),
                      onDragExited: (_) => setState(() => _dragging = false),
                      
                      child: Container
                      (
                          padding: const EdgeInsets.all(100.0),
                          
                          child: TextField
                          (
                              controller: _productionDirectoryController,
                              style: const TextStyle(fontSize: 24),

                              decoration: InputDecoration
                              (
                                  labelText: 'Enter Production Directory Path',

                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),

                                  suffixIcon: IconButton
                                  (
                                      icon: const Icon(Icons.search),
                                      onPressed: () 
                                      {
                                          final path = _productionDirectoryController.text;
                                          Navigator.push
                                          (
                                              context,
                                              MaterialPageRoute(builder: (context) => PG_WavList(directoryPath: path)),
                                          );
                                      },
                                  ),
                              ),
                              
                              onSubmitted: (value) 
                              {
                                  final path = _productionDirectoryController.text;
                                  Navigator.push
                                  (
                                      context,
                                      MaterialPageRoute(builder: (context) => PG_WavList(directoryPath: path)),
                                  );
                              },
                          ),
                      ),
                )
              ),        
                
            
          ),
        );
        
    }
    */
    

    /*
    Future<List<File>> pickDirectoryAndFindExcelFiles() async 
    {
        String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
        if (selectedDirectory == null) return [];

        final dir = Directory(selectedDirectory);
        return dir
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.xlsx'))
            .toList();
    }

    Future<File?> showExcelFilePicker(BuildContext context, List<File> excelFiles) async 
    {
        return showDialog<File>
        (
            context: context,
            builder: (ctx) => AlertDialog
            (
                title: Text('Select the correct Script'),
                content: SizedBox
                (                  
                    width: double.maxFinite,
                    child: ListView
                    (
                        shrinkWrap: true,
                        children: excelFiles.map((file) 
                        {
                            return ListTile
                                (
                                    title: Text(file.path.split('/').last),
                                    onTap: () => Navigator.pop(ctx, file),
                                );
                        }).toList(),
                    ),
                ),
            ),
        );
    }

    Future<List<String>> extractColumnHeaders(File excelFile) async 
    {
        final bytes = excelFile.readAsBytesSync();
        final excel = Excel.decodeBytes(bytes);
        final firstSheet = excel.tables.values.first;
        
        if (firstSheet.maxRows == 0) 
        {
            return [];
        }

        final headers = firstSheet.rows.first;
        return headers.map((cell) => cell?.value.toString() ?? '').toList();
    }

    Future<List<String>?> showColumnSelectorDialog(BuildContext context, List<String> headers) async 
    {
        final selected = <String>{};

        return showDialog<List<String>>
        (
            context: context,
            builder: (ctx) => StatefulBuilder
            (
                builder: (context, setState) => AlertDialog
                (
                    title: Text('Select Columns'),
                    
                    content: SingleChildScrollView
                    (
                        child: Column
                        (
                            children: headers.map((header) 
                            {
                                return CheckboxListTile
                                (
                                    title: Text(header),
                                    value: selected.contains(header),
                                    onChanged: (checked) 
                                    {
                                        setState(() 
                                        {
                                            if (checked == true) 
                                            {
                                                selected.add(header);
                                            } 
                                            else 
                                            {
                                                selected.remove(header);
                                            }
                                        });
                                    },
                                );
                            }).toList(),
                        ),
                    ),

                    actions: 
                    [                        
                        TextButton
                        (
                            onPressed: () => Navigator.pop(ctx, null),
                            child: Text('Cancel'),
                        ),
                        
                        ElevatedButton
                        (
                            onPressed: () => Navigator.pop(ctx, selected.toList()),
                            child: Text('Confirm'),
                        ),
                    ],
                ),
            ),
        );
    }

    */
    
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Excel Column Picker')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _handleImport(context),
          child: const Text('Import Excel'),
        ),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
*/


  

  
/*
  class PG_ScriptView extends StatefulWidget
  {
      @override
      _PG_ScriptViewState createState() => _PG_ScriptViewState();
  }

  class _PG_ScriptViewState extends State<PG_ScriptView>
  {
      @override
      _
  }*/


 class PG_DirectorySetting extends StatefulWidget 
 {
     @override
    _PG_DirectorySettingState createState() => _PG_DirectorySettingState(); 
  } 


class _PG_DirectorySettingState extends State<PG_DirectorySetting >
{
    final TextEditingController _directoryController = TextEditingController();
    bool _dragging = false;

    @override
    Widget build(BuildContext context) 
    {
        return Scaffold
        (
            /* appBar: AppBar ( // title: const Text('WAV File Player'),), */
        body: Center(
        child: Padding(
            padding: const EdgeInsets.all(100.0),
            child: DropTarget
            (
                onDragDone: (details) async 
                {
                    if (details.files.isNotEmpty) 
                    {
                        final droppedItem = details.files.first;
                        final folder = Directory(droppedItem.path);

                        if (await folder.exists() &&
                        (await folder.stat()).type == FileSystemEntityType.directory) 
                        {
                            setState(() 
                            {
                                _directoryController.text = folder.path;
                            });

                            // Navigate after a frame to avoid setState-related context issues
                            WidgetsBinding.instance.addPostFrameCallback((_) 
                            {
                                Navigator.push
                                (
                                    context,
                                    MaterialPageRoute
                                    (
                                        builder: (context) => PG_WavList(directoryPath: folder.path),
                                    ),
                                );
                            });
                          }
                      }
                  },

                  onDragEntered: (_) => setState(() => _dragging = true),
                  onDragExited: (_) => setState(() => _dragging = false),
                  
                  child: Container(
                      padding: const EdgeInsets.all(100.0),
                      
                      child: TextField
                      (
                          controller: _directoryController,
                          style: const TextStyle(fontSize: 24),

                          decoration: InputDecoration
                          (
                              labelText: 'Enter Directory Path',

                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),

                              suffixIcon: IconButton
                              (
                                  icon: const Icon(Icons.search),
                                  onPressed: () 
                                  {
                                      final path = _directoryController.text;
                                      Navigator.push
                                      (
                                          context,
                                          MaterialPageRoute(builder: (context) => PG_WavList(directoryPath: path)),
                                      );
                                  },
                              ),
                          ),
                          
                          onSubmitted: (value) 
                          {
                              final path = _directoryController.text;
                              Navigator.push
                              (
                                  context,
                                  MaterialPageRoute(builder: (context) => PG_WavList(directoryPath: path)),
                              );
                          },
                      ),
                  ),
          )
      ),
    ),
  );
  }
}

class PG_WavList extends StatefulWidget 
{
    final String directoryPath;

    PG_WavList({Key? key, required this.directoryPath}) : super(key: key);

    // This widget is the root of your application.
  @override
    _PG_WavListState createState() => _PG_WavListState();
}

class _PG_WavListState extends State<PG_WavList> 
{
  //final TextEditingController _directoryController = TextEditingController();
  final AudioPlayer _player = AudioPlayer();  

  List<FileSystemEntity> _wavFiles = [];
  String? _error;

  bool _isPlaying = false;
  bool _playingAll = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isSeeking = false;

  File? _currentFile;
  int? _currentFileIndex;
  String _folderName = 'Select a Directory';



  @override
  void initState() 
  {
      super.initState();
      _loadWavFiles(widget.directoryPath);

      // Listen to audio duration changes
    _player.onDurationChanged.listen((d) 
    {
        setState(() 
        {
            _duration = d;
        });
    });

    // Listen to audio position changes
    _player.onPositionChanged.listen((p) 
    {
        if (!_isSeeking)
        {
            setState(() 
            {
              _position = p;
            });
        }      
    });

    // Listen to player state changes (playing, paused, stopped)
    _player.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });

  }
  
  Future<void> _loadWavFiles(String path) async 
  {
       final dir = Directory(path);
      
      if (!await dir.exists()) 
      {
          setState(()
          {
              _error = 'Directory does not exist.';
              _wavFiles = [];
              _currentFile = null;
              _isPlaying = false;
          });
      
      return;
      }
      else
      {
          setState(() 
          {
              _folderName = dir.path.split(Platform.pathSeparator).last;
          });
      }

      // Populate {list} with .wav files from the directory
      final files = dir.listSync().where((f)
      {
          return f is File && f.path.toLowerCase().endsWith('.wav') && !f.path.contains('_alt');
      })
      .toList();

      // Sort files by path in a case-insensitive manner
      files.sort((a, b) 
      {
          return a.path.toLowerCase().compareTo(b.path.toLowerCase());
      });

      setState(() 
      {
          _wavFiles = files;
          _error = null;
          _currentFile = null;
          _isPlaying = false;
      });
  }

  //final AudioPlayer _player = AudioPlayer();

Future<void> _playFile(File file, [int? index]) async {
  try 
  {
      await _player.setSourceDeviceFile(file.path);
      await _player.resume();
    
      setState(() 
      {
          _currentFile = file;
          _currentFileIndex = index;
          _isPlaying = true;
          _error = null;
      });
  } 
  catch (e) 
  {
      setState(() 
      {
          _error = 'Error playing file: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar
      (
          SnackBar(content: Text('Error playing file: $e')),
      );
  }
}

Future<void> _togglePlayPause() async
{
    if (_isPlaying) 
    {
        await _player.pause();
    } 
    else if (_currentFile != null) 
    {
        await _player.resume();
    } 
    /*
    else if (_wavFiles.isNotEmpty) 
    {
        await _playFile(_wavFiles.first as File);
    }
    */
}

Future<void> _seekToSeconds(double seconds) async
{
    final newPos = Duration(milliseconds: (seconds * 1000).round());
    await _player.seek(newPos);
}


  @override
  void dispose() 
  {
      _player.dispose();
      //_directoryController.dispose();
      super.dispose();
  }

Future<void> _playAllFromIndex(int startIndex) async 
{
  _playingAll = true;

  for (int i = startIndex; i < _wavFiles.length; i++) 
  {
      final file = _wavFiles[i] as File;

      // Create a completer to await the completion event
      final completer = Completer<void>();

      // Listen for completion
      void onComplete(_) 
      {
          completer.complete();
          _player.onPlayerComplete.drain(); // Remove previous listeners to avoid duplicates
      }

    _player.onPlayerComplete.listen(onComplete);

    if (_playingAll)
    {
        await _playFile(file);
    }

      // Wait for the file to complete playing        
      await completer.future;
    
  }
}

  @override
  Widget build(BuildContext context) 
  {
      return Scaffold
      (          
          appBar: AppBar
          (
              title: Text('$_folderName'),
              //backgroundColor: Colors.blueGrey,
              actions: 
              [
                  TextButton
                  (
                      onPressed: () => _playAllFromIndex(0),
                      child: const Text('Play All (from Start)', style: TextStyle(color: Colors.blueGrey, fontSize: 16) ),
                  ),

                  if (_currentFileIndex != null) 
                    TextButton
                    (
                        onPressed: () => _playAllFromIndex(_currentFileIndex! + 1),
                        child: const Text('Play All (from Current)', style: TextStyle(color: Colors.blueGrey, fontSize: 16) ),
                    ),
              ],
          ),          
          body: Padding
          (
              padding: const EdgeInsets.all(16.0),
              child: Column
              (
                  children: 
                  [
                      

                      //SizedBox(height: 10),

                      if (_error != null) 
                      Text(_error!, style: TextStyle(color: Colors.red)),
                      Expanded
                      (
                          child: ListView.builder
                          (
                              itemCount: _wavFiles.length,
                              itemBuilder: (context, index) 
                              {                                
                                  final file = _wavFiles[index] as File;  
                                  final fileName = p.basenameWithoutExtension(file.path);                                                                  

                                  final isCurrent = _currentFile?.path == file.path;
                                  return ListTile
                                  (
                                      title: Text(fileName),
                                      selected: isCurrent,
                                      onTap: () => _playFile(file, _wavFiles.indexOf(file)),
                                  );
                              },
                          ),
                      ),

                      // Audio Player Controls
                      if (_currentFile != null)
                          Column
                          (
                              children: 
                              [
                                  Slider
                                  (
                                      min: 0.0,
                                      max: _duration.inMilliseconds > 0
                                          ? _duration.inMilliseconds.toDouble()
                                          : 1.0,
                                      
                                      // this version snaps to seconds
                                      //value: _position.inSeconds.clamp(0, _duration.inSeconds).toDouble(),
                                      
                                      // this version does not
                                      value: _position.inMilliseconds > 0
                                          ? (_position.inMilliseconds.clamp(0, _duration.inMilliseconds).toDouble())
                                          : 0.0,
                                      
                                      onChangeStart: (_)
                                      {
                                          _isSeeking = true;
                                      },

                                      onChanged: (value)
                                      {
                                          // Snap to the nearest second
                                          //_seekToSeconds(value.toInt());

                                          // Allow for sub-second precision
                                          _seekToSeconds(value);
                                      },

                                      onChangeEnd: (value)
                                      {
                                          _isSeeking = false;
                                      },
                                  ),
                                  Row
                                  (
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: 
                                      [
                                          IconButton
                                          (
                                              iconSize: 48,
                                              icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                                              onPressed: _togglePlayPause,
                                          ),
                                      
                                          SizedBox(width: 16),
                                      
                                          Text
                                          (
                                            "${_formatDuration(_position)} / ${_formatDuration(_duration)}",
                                            style: TextStyle(fontSize: 16),
                                          ),
                                          if (_isPlaying)                                            
                                            TextButton
                                            (
                                                onPressed: _stopPlayback, 
                                                child:
                                                    const Text('Stop Playback', style: TextStyle(fontSize: 16, color: Colors.blueGrey))
                                            )
                                      ],
                                  )    
                                                                             
                              ],
                          ),
                  ],
              ),
          ),
      );
  }

  String _formatDuration(Duration duration) 
  {
      final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
      final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$minutes:$seconds';
  }

  void _stopPlayback()
  {
      _player.stop();
      setState(() 
      {
          _isPlaying = false;
          _playingAll = false;
          _position = Duration.zero;
          _currentFile = null;
          _currentFileIndex = null;
      });
  }
  
}
