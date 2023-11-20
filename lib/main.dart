import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  static const String _title = 'Stream Subscription Test';

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: _title),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
  });

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _textController = TextEditingController();

  StreamController<bool>? _controller;
  final List<StreamSubscription<bool>> _subscriptions = [];

  int _creationSubNum = 1;
  int _createdSubs = 0;
  int _cancelledSubs = 0;

  @override
  void initState() {
    _initController();

    super.initState();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    _closeController();
    _textController.dispose();

    super.dispose();
  }

  void _closeController() {
    _controller?.close();
    setState(() {
      _controller = null;
    });
  }

  void _initController() {
    if (_controller != null) {
      _closeController();
    }

    setState(() {
      _controller = StreamController<bool>.broadcast();
    });
  }

  void _emitEvent(bool isDelayedEvent) {
    _controller?.add(isDelayedEvent);
  }

  void _createSubscriptions({
    required int number,
    required bool isStored,
  }) {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    for (int i = 0; i < number; i++) {
      StreamSubscription<bool> subscription = controller.stream.listen(
        (isDelayed) async {
          const someLargeMemoryObject = 'someLargeMemoryObject';
          log(
            '${DateTime.now().toString()}: Start onEvent with $someLargeMemoryObject',
          );

          if (isDelayed) {
            await Future.delayed(const Duration(milliseconds: 5000));
          }

          log(
            '${DateTime.now().toString()}: Finish onEvent with $someLargeMemoryObject',
          );
        },
        onDone: () {
          log(
            '${DateTime.now().toString()}: onDone event - Stream is closed',
          );
        },
      );

      if (isStored) {
        _subscriptions.add(subscription);
      }
    }

    setState(() {
      _createdSubs += number;
    });
  }

  void _cancelSubscriptions() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }

    setState(() {
      _cancelledSubs += _subscriptions.length;
      _subscriptions.clear();
    });
  }

  void _changeCreationSubNum(String value) {
    setState(() {
      _creationSubNum = int.tryParse(value) ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isControllerInitialized = _controller != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Statistic',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 5.0),
            Text(
              'Created subs: $_createdSubs',
            ),
            Text(
              'Cancelled subs: $_cancelledSubs',
            ),
            Text(
              'Diff between created and cancelled subs: ${_createdSubs - _cancelledSubs}',
            ),
            Text(
              'Current stored subs: ${_subscriptions.length}',
            ),
            const Divider(),
            const SizedBox(height: 20.0),
            Text(
              'Stream controller actions',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 5.0),
            TextButton(
              onPressed:
                  isControllerInitialized ? _closeController : _initController,
              child: Text(
                  '${isControllerInitialized ? 'Close' : 'Init'} controller'),
            ),
            if (isControllerInitialized)
              Column(
                children: <Widget>[
                  TextButton(
                    onPressed: () => _emitEvent(true),
                    child: const Text('Emit delayed event'),
                  ),
                  TextButton(
                    onPressed: () => _emitEvent(false),
                    child: const Text('Emit non-delayed event'),
                  ),
                  const Divider(),
                  const SizedBox(height: 20.0),
                  Text(
                    'Stream Subscription actions',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  SizedBox(
                    width: 200.0,
                    child: TextFormField(
                      controller: _textController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Creation subs num'),
                      onChanged: _changeCreationSubNum,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _createSubscriptions(
                      number: _creationSubNum,
                      isStored: false,
                    ),
                    child: Text('Create $_creationSubNum subs'),
                  ),
                  const SizedBox(height: 10.0),
                  TextButton(
                    onPressed: () => _createSubscriptions(
                      number: _creationSubNum,
                      isStored: true,
                    ),
                    child: Text('Create and store $_creationSubNum subs'),
                  ),
                  const SizedBox(height: 10.0),
                  TextButton(
                    onPressed: () => _cancelSubscriptions(),
                    child: const Text('Cancel stored subs'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
