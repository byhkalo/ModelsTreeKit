//
//  UIControl+Signal.swift
//  ModelsTreeKit
//
//  Created by aleksey on 06.03.16.
//  Copyright © 2016 aleksey chernish. All rights reserved.
//

import Foundation

extension UIControl {
  
  public func signalForControlEvents(events: UIControlEvents) -> Signal<UIControl> {
    return signalEmitter.signalForControlEvents(events)
  }
  
}

private class ControlSignalEmitter: NSObject {
  
  init(control: UIControl) {
    self.control = control
    super.init()
    initializeSignalsMap()
  }
  
  func signalForControlEvents(events: UIControlEvents) -> Signal<UIControl> {
    var correspondingSignals = [Signal<UIControl>]()
    
    for event in eventsList {
      if events.contains(UIControlEvents(rawValue: event)) {
        correspondingSignals.append(signalsMap[event]!)
      }
    }
    
    return Signals.merge(correspondingSignals)
  }
  
  private static var EmitterHandler: Int = 0
  private weak var control: UIControl!
  private var signalsMap = [UInt: Signal<UIControl>]()
  private let controlProxy = ControlProxy.newProxy()
  
  private var eventsList: [UInt] = [
    UIControlEvents.EditingChanged.rawValue,
    UIControlEvents.ValueChanged.rawValue,
    UIControlEvents.EditingDidEnd.rawValue,
    UIControlEvents.EditingDidEndOnExit.rawValue,
    UIControlEvents.TouchUpInside.rawValue
  ]
  
  private let signaturePrefix = "selector"
  
  private func initializeSignalsMap() {
    for eventRawValue in eventsList {
      signalsMap[eventRawValue] = Signal<UIControl>()

      let signal = signalsMap[eventRawValue]
      let selectorString = signaturePrefix + String(eventRawValue)
      
      controlProxy.registerBlock({ [weak signal, unowned self] in
        signal?.sendNext(self.control)
        }, forKey: selectorString)
      control.addTarget(self.controlProxy, action: NSSelectorFromString(selectorString), forControlEvents: UIControlEvents(rawValue: eventRawValue))
    }
  }

}

private extension UIControl {
  
  var signalEmitter: ControlSignalEmitter {
    get {
      var emitter = objc_getAssociatedObject(self, &ControlSignalEmitter.EmitterHandler) as? ControlSignalEmitter
      if (emitter == nil) {
        emitter = ControlSignalEmitter(control: self)
        objc_setAssociatedObject(self, &ControlSignalEmitter.EmitterHandler, emitter, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      }
      return emitter!
    }
  }
  
}