/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 * @flow
 */

import React, {Component} from 'react';
import {
  Platform,
  StyleSheet, 
  Text, 
  TextInput,
  View,
  FlatList,
  TouchableOpacity,
  NativeModules,
  NativeEventEmitter
} from 'react-native';

const eventEmitter = new NativeEventEmitter(NativeModules.BLEController);

export default class App extends Component {
  constructor(props) {
    super(props);

    this.BLEController = NativeModules.BLEController;

    this.state = {
      devices: [],
      name: '',
      state: 'no connection',
      instantaneousPower: 0,
      speedKPH: 0,
      ergPower: ''
    }
  }

  componentDidMount() {
    this.sensorDiscoveredListener = eventEmitter.addListener('sensorDiscovered', (sensor) => {
      this.listener(sensor.name);
    })
  }

  listener(name) {
    let devices = this.state.devices.slice(0);
    devices.push(name);
    this.setState({
      devices: devices
    })
  }

  scan() {
    this.BLEController.scan();
  }

  connect() {
    this.measureMentListener = eventEmitter.addListener('measurement', (sensorInfo) => {
      this.setState({
        instantaneousPower: sensorInfo[0],
        speedKPH: sensorInfo[1]
      })
    })
    this.BLEController.connect(0, (isConnected, msg) => {
      if (isConnected) {
        console.warn(msg, 'connected!');
        this.setState({
          state: 'connected!'
        })
      } else {
        console.warn(msg);
      }
    });
  }

  setErgMode() {
    let power = Number(this.state.ergPower);
    if (power == NaN || power < 0) return;
    this.BLEController.setErgMode(power);
  }

  componentWillUnmount() {
    this.measureMentListener.remove();
    this.sensorDiscoveredListener.remove();
  }

  render() {
    return (
      <View style={styles.container}>
        <TouchableOpacity onPress={this.scan.bind(this)}>
          <Text style={styles.welcome}>scan</Text>
        </TouchableOpacity>
        <TouchableOpacity onPress={this.connect.bind(this)}>
          <Text style={styles.welcome}>connect</Text>
        </TouchableOpacity>
        <Text style={styles.instructions}>{this.state.state}</Text>
        <View style={styles.devicesList}>
          <FlatList 
            renderItem={({item, index}) => 
            <Text key={index} style={styles.instructions}>{item}</Text>}
            data={this.state.devices} />
        </View>
        <Text style={styles.instructions}>Power: {this.state.instantaneousPower}</Text>
        <Text style={styles.instructions}>Speed: {this.state.speedKPH}</Text>
        <TextInput placeholder={'input power'} onChangeText={(value) => this.setState({ergPower: value})}/>
        <TouchableOpacity onPress={this.setErgMode.bind(this)}>
          <Text style={styles.welcome}>SET ERG</Text>
        </TouchableOpacity>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    width: '100%',
    height: '100%',
    flexDirection: 'column',
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
    paddingTop: 50
  },
  devicesList: {
    height: 200
  },
  welcome: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
  },
  instructions: {
    textAlign: 'center',
    color: '#333333',
    marginBottom: 5,
  },
});
