import 'package:flutter/material.dart';
//import 'package:just_audio/just_audio.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'dart:async';


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
      home: PG_DirectorySetting(),
    );
  }
}

 class PG_DirectorySetting extends StatefulWidget 
 {
     @override
    _PG_DirectorySettingState createState() => _PG_DirectorySettingState(); 
  } 


class _PG_DirectorySettingState extends State<PG_DirectorySetting >
{
  final TextEditingController _directoryController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //title: const Text('WAV File Player'),
      ),
      body: Center
      (


        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PG_WavList()),
            );
          },
          child: const Text('Set Directory'),
        ),
      ),
    );
  }
}

class PG_WavList extends StatefulWidget {
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
      _directoryController.dispose();
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
              //actions: _directoryController.text.isNotEmpty
              //? [
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
              //] : null,
          ),          
          body: Padding
          (
              padding: const EdgeInsets.all(16.0),
              child: Column
              (
                  children: 
                  [
                      TextField
                      (
                          controller: _directoryController,
                          decoration: InputDecoration
                          (
                              labelText: 'Enter Directory Path',
                              border: OutlineInputBorder(),
                              suffixIcon: IconButton
                              (
                                  icon: const Icon(Icons.search),
                                  onPressed: () async 
                                  {
                                      final path = _directoryController.text;
                                      await _loadWavFiles(path);
                                  },
                              ),
                          ),

                          onSubmitted: (value) async 
                          {
                              final path = _directoryController.text;
                              await _loadWavFiles(path);
                          },

                      ),

                      SizedBox(height: 10),

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
