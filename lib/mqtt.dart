// import 'dart:io';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

// import 'dart:convert';
// import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

class MqttClient {
  Logger log = Logger('myapp.mqtt.dart');
  final hostName;
  final clientID;
  MqttServerClient client;
  bool connecting = false;
  bool connected = false;
  Map subscribers = Map();

  MqttClient(this.hostName, this.clientID);

  _connect() async {
    connecting = true;
    log.info("Setting up client for mqtt");
    client = MqttServerClient(hostName, "key");
    client.logging(on: true);
    final MqttConnectMessage connMess = MqttConnectMessage()
        .withClientIdentifier(clientID)
        .keepAliveFor(60)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);
    log.info('MQTT client connecting....');
    client.connectionMessage = connMess;

    try {
      await client.connect();
    } on Exception catch (e) {
      log.severe('EXCEPTION::client exception - $e');
      client.disconnect();
      client = null;
      connected = false;
      connecting = false;
      return false;
    }
    log.info("client.connect() returned");

    /// The subscribed callback
    void _onSubscribed(String topic) {
      log.info('Subscription confirmed for topic $topic');
    }

    /// The unsolicited disconnect callback
    void _onDisconnected() async {
      log.info('OnDisconnected client callback - Client disconnection');
      connected = false;
      log.info("reconnecing..");
      await connect();
      resubscribe();
    }

    /// The successful connect callback
    void _onConnected() {
      log.info('OnConnected client callback - Client connection was sucessful');
    }

    /// Check we are connected
    if (client != null && client.connectionStatus.state == MqttConnectionState.connected) {
      connected = true;
      connecting = false;
      log.info('MQTT client connected');

      /// Add the unsolicited disconnection callback
      client.onDisconnected = _onDisconnected;

      /// Add the successful connection callback
      client.onConnected = _onConnected;

      /// Add a subscribed callback, there is also an unsubscribed callback if you need it.
      /// You can add these before connection or change them dynamically after connection if
      /// you wish. There is also an onSubscribeFail callback for failed subscriptions, these
      /// can fail either because you have tried to subscribe to an invalid topic or the broker
      /// rejects the subscribe request.
      client.onSubscribed = _onSubscribed;

      client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage recMess = c[0].payload;
        final pt =
        MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

        if (subscribers[c[0].topic] != null) {
          subscribers[c[0].topic](pt);
        }
      });

    } else {
      /// Use status here rather than state if you also want the broker return code.
      log.info(
          'MQTT client connection failed - disconnecting, status is ${client
              .connectionStatus}');
      client.disconnect();
      client = null;
      connected = false;
      connecting = false;
    }
  }

  Future<bool> connect() async {
    if (connected) {
      log.info("already connected");
      return true;
    }

    while (connecting) {
      log.info("Connecting is already in progress, waiting for that to happen...");
      await Future.delayed(const Duration(microseconds: 200));
    }

    if (client == null || !connected) {
      log.info("Connecting not in progress, client=$client and connected=$connected, reconnecting");
      await _connect();
    }

    return connected;
  }

  resubscribe() {
    log.info("re-subscribing after reconnect");
    this.subscribers.forEach((topic, _) {
      client.subscribe(topic, MqttQos.atMostOnce);
    });
  }

  Future<bool> subscribe(String topic,
      void Function(String message) onMessage) async {
    if (!connected) {
      await connect();
    }

    client.subscribe(topic, MqttQos.atMostOnce);
    this.subscribers[topic] = onMessage;
  }

  Future<void> publish (String topic, String payload, bool retain) async {
    if (!connected) {
      await connect();
    }

    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    client.publishMessage(topic, MqttQos.atMostOnce, builder.payload, retain: retain);
  }

}
