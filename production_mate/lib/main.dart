import 'package:flutter/material.dart';
import 'dart:async';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:json_rpc_2/error_code.dart' as error_code;
import 'package:libserialport/libserialport.dart';
import 'SerialPortStreamChannel.dart'
import 'package:web_socket_channel/web_socket_channel.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  _TestPageState createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  List<TestItem> _testItems = [
    TestItem("Test JSON-RPC over HTTP", (httpClient, _) async {
      final httpResult = await httpClient.sendRequest('echo', ['hello']);
      if (httpResult != 'hello') {
        throw Exception('Test failed');
      }
    }, false),
    TestItem("Test JSON-RPC over SerialPort", (_, serialPortClient) async {
      final serialPortResult = await serialPortClient.sendRequest('echo', ['world']);
      if (serialPortResult != 'world') {
        throw Exception('Test failed');
      }
    }, false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Test Page"),
      ),
      body: Column(
        children: [
          DataTable(
            columns: [
              DataColumn(label: Text("Test Item")),
              DataColumn(label: Text("Result")),
            ],
            rows: _testItems.map((item) {
              return DataRow(cells: [
                DataCell(Text(item.name)),
                DataCell(Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: item.result ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    item.result ? "Pass" : "Fail",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )),
              ]);
            }).toList(),
          ),
          ElevatedButton(
            child: Text("Start Test"),
            onPressed: () {
              _runTests();
            },
          ),
        ],
      ),
    );
  }


  void _runTests() {
    for (final item in _testItems) {
      _runTest(item);
    }
  }

  void _runTest(TestItem item) {
    bool isCancelled = false;

    final timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (isCancelled) {
        timer.cancel();
      }
    });

    // TODO: Implement the test logic here

    timer.cancel();

    item.result = true; // For testing purpose only
    setState(() {});
  }
}

class TestItem {
  final String name;
  final Function(httpClient, serialPortClient) testFunction;
  bool result;

  TestItem(this.name, this.testFunction, this.result);

  Future<void> runTest() async {
    // Create a HTTP client
    var socket = WebSocketChannel.connect(Uri.parse('ws://localhost:4321'));
    final httpClient = Client(socket);

    // Create a SerialPort client

    final client = Client(socket.cast<String>());
    // final serialPortClient = SerialPortClient('/dev/ttyUSB0');

    // Connect to both clients
    await Future.wait([
      httpClient.connect(Uri.parse('http://localhost:8080')),
      serialPortClient.connect(),
    ]);

    try {
      // Run the test function
      await testFunction(httpClient, serialPortClient);

      result = true;
    } on RpcException catch (e) {
      if (e.code == error_code.methodNotFound) {
        // Handle method not found error
        result = false;
      } else {
        // Handle other errors
        result = false;
      }
    } finally {
      // Close both connections
      await Future.wait([
        httpClient.close(),
        serialPortClient.close(),
      ]);
    }
  }
}


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // home: const MyHomePage(title: 'Flutter Demo Home Page'),
      home: const TestPage(),
    );
  }
}
