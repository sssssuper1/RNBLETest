//
//  BLEController.swift
//  RNBLETest
//
//  Created by JuZe ZRY on 2018/9/19.
//  Copyright © 2018年 Facebook. All rights reserved.
//

import Foundation
import SwiftySensors
import SwiftySensorsTrainers

@objc(BLEController)
class BLEController: RCTEventEmitter {
  fileprivate var sensors : [Sensor] = []
  
  fileprivate var connectedSensor : Sensor? {
    didSet {
      if connectedSensor != nil {
        connectedSensor?.onServiceDiscovered.subscribe(on: self) { [weak self] sensor, service in
          let uuid = service.cbService.uuid.uuidString
          print(uuid)
          
          switch uuid {
          case "1818":
            self?.cyclingPowerService = service as? CyclingPowerService
          default:
            break
          }
        }
      } else {
        cyclingPowerService = nil
      }
    }
  }
  
  fileprivate var cyclingPowerService : CyclingPowerService? {
    didSet {
      if cyclingPowerService != nil {
        cyclingPowerService?.sensor.onCharacteristicDiscovered.subscribe(on: self) { [weak self] sensor, characteristic in
          let uuid = characteristic.cbCharacteristic.uuid.uuidString
          print(uuid)
          switch uuid {
          case "2A63" :
            self?.measurement = characteristic as? CyclingPowerService.Measurement
          case "A026E005-0A7D-4AB3-97FA-F1500F9FEB8B" :
            self?.wahooController = characteristic as? CyclingPowerService.WahooTrainer
          default :
            break
          }
        }
      } else {
        measurement = nil
        wahooController = nil
      }
    }
  }
  
  
  fileprivate var measurement : CyclingPowerService.Measurement? {
    didSet {
      if measurement != nil {
        measurement?.onValueUpdated.subscribe(on: self) {
          [weak self] characteristic in
          let instantaneousPower = self?.measurement?.instantaneousPower ?? 0
          let speedKPH = self?.measurement?.speedKPH ?? 0
          
          print(instantaneousPower, speedKPH)
          self?.sendEvent(withName: "measurement", body: [instantaneousPower, speedKPH])
        }
      } else {
        self.sendEvent(withName: "measurement", body: [-1 ,-1])
      }
    }
  }
  
  fileprivate var wahooController : CyclingPowerService.WahooTrainer?
  
  @objc override func supportedEvents() -> [String]! {
    return ["sensorDiscovered", "measurement"]
  }
  
  @objc func scan() -> Void {
    SensorManager.instance.setServicesToScanFor([CyclingPowerService.self])
    
    SensorManager.instance.addServiceTypes([DeviceInformationService.self])
    
    SensorManager.instance.state = .aggressiveScan
    
    SensorManager.logSensorMessage = { message in
      print(message)
    }
    
    SensorManager.instance.onSensorDiscovered.subscribe(on: self) { [weak self] sensor in
      guard let s = self else {return}
      if !s.sensors.contains(sensor) {
        s.sensors.append(sensor)
        
        let sensorInfo : [String : Any] = ["name": sensor.peripheral.name ?? "", "index": s.sensors.index(of: sensor) ?? -1]
        self?.sendEvent(withName: "sensorDiscovered", body: sensorInfo)
      }
    }
  }
  
  @objc func connect(_ to: Int, sensorConnectedCallback: @escaping RCTResponseSenderBlock) {
    if to < sensors.count {
      let sensor = sensors[to]
      
      SensorManager.instance.onSensorConnected.subscribe(on: self) { [weak self] sensor in
        if sensor.peripheral.state == .connected {
          print("connected")
          self?.connectedSensor = sensor
          
          sensorConnectedCallback([true, sensor.peripheral.name ?? ""])
          
          CyclingPowerService.WahooTrainer.activate()
        }
      }
      
      if sensor.peripheral.state == .disconnected {
        SensorManager.instance.connectToSensor(sensor)
      } else {
        sensorConnectedCallback([false, "status error"])
      }
    } else {
      sensorConnectedCallback([false, "no sensor"])
    }
  }
  
  @objc func disConnect() {
    if let sensor = connectedSensor, sensor.peripheral.state == .connected {
      SensorManager.instance.disconnectFromSensor(sensor)
      connectedSensor = nil
    }
  }
  
  @objc func setErgMode(_ power: Int) {
    wahooController?.setErgMode(UInt16(power))
  }
  
  @objc func setStandardMode(_ level: Int) {
    wahooController?.setStandardMode(level: UInt8(level))
  }
  
  @objc func setResistanceMode(_ percentage: Int) {
    wahooController?.setResistanceMode(resistance: Float(percentage) / 100)
  }
}
