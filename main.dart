import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:percent_indicator/percent_indicator.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
       
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Roomba basic control'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

 
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
initState() {
  super.initState();
  // Add listeners to this class
  connectclient();
}
  int _counter = 0;
  final MqttClient client = MqttClient('YOUR BROKER IP ADDRESS', '');
  MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
  Future<int> connectclient() async {
   
    client.logging(on: false);
    client.keepAlivePeriod = 20;
    client.onDisconnected = onDisconnected;
    client.onConnected = onConnected;
    client.onSubscribed = onSubscribed;

    final MqttConnectMessage connMess = MqttConnectMessage()
        .withClientIdentifier('Mqtt_MyClientUniqueId')
        .keepAliveFor(20) // Must agree with the keep alive set above or not set
        .withWillTopic(
            'willtopic') // If you set this you must set a will message
        .withWillMessage('My Will message')
        .startClean() // Non persistent session for testing
        .withWillQos(MqttQos.atLeastOnce);
    print('EXAMPLE::Mosquitto client connecting....');
    client.connectionMessage = connMess;

    try {
      await client.connect();
    } on Exception catch (e) {
      print('EXAMPLE::client exception - $e');
      client.disconnect();
    }

 
    if (client.connectionStatus.state == MqttConnectionState.connected) {
      print('EXAMPLE::Mosquitto client connected');
    } else {
      print(
          'EXAMPLE::ERROR Mosquitto client connection failed - disconnecting, status is ${client.connectionStatus}');
      client.disconnect();
      exit(-1);
    }

    client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload;
      final String topic =c[0].topic;
      print(topic);
      final String pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      print(pt);
      if(topic == 'roomba/battery'){
        percent = double.parse(pt) / 100;
      }
      setState(() {
        _percentage = pt;
        _percent =percent;
      });

    });

 
    client.subscribe("roomba/status", MqttQos.exactlyOnce);
     client.subscribe("roomba/battery", MqttQos.exactlyOnce);
 
  }

  /// The subscribed callback
  void onSubscribed(String topic) {
    print('EXAMPLE::Subscription confirmed for topic $topic');
  }

  /// The unsolicited disconnect callback
  void onDisconnected() {
    print('EXAMPLE::OnDisconnected client callback - Client disconnection');
    if (client.connectionStatus.returnCode == MqttConnectReturnCode.solicited) {
      print('EXAMPLE::OnDisconnected callback is solicited, this is correct');
    }
    exit(-1);
  }

  /// The successful connect callback
  void onConnected() {
    print(
        'EXAMPLE::OnConnected client callback - Client connection was sucessful');
  }

  /// Pong callback
  void pong() {
    print('EXAMPLE::Ping response client callback invoked');
  }

  String _percentage = "70";
  double _percent = 0.7;
  double percent = 0.7;
  @override
  Widget build(BuildContext context) {
   
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new CircularPercentIndicator(
              radius: 120.0,
              lineWidth: 13.0,
              animation: true,
              percent: _percent,
              center: new Text(
                _percentage,
                style:
                    new TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
              ),
              footer: new Text(
                "Battery status",
                style:
                    new TextStyle(fontWeight: FontWeight.bold, fontSize: 17.0),
              ),
              circularStrokeCap: CircularStrokeCap.round,
              progressColor: Colors.purple,
            ),
            FlatButton(
              child: Text('Clean', style:
                      new TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0)),
              onPressed: () {
                builder = MqttClientPayloadBuilder();
                builder.addString('start');
                client.publishMessage(
                    "roomba/commands", MqttQos.exactlyOnce, builder.payload);
              },
            ),
            FlatButton(
              child: Text('Return to dock',
                  style: new TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 20.0)),
              onPressed: () {
                builder = MqttClientPayloadBuilder();

                builder.addString('stop');
                client.publishMessage(
                    "roomba/commands", MqttQos.exactlyOnce, builder.payload);
              },
            ),  FlatButton(
              child: Text('Power off',
                  style: new TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 20.0)),
              onPressed: () {
                builder = MqttClientPayloadBuilder();

                builder.addString('poweroff');
                client.publishMessage(
                    "roomba/commands", MqttQos.exactlyOnce, builder.payload);
              },
            )
          ],
        ),
      ),
      
    );
  }
}
