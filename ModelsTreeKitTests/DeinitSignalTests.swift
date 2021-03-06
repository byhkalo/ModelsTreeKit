//
//  DeinitSignalTest.swift
//  ModelsTreeKit
//
//  Created by aleksey on 22.12.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation
import UIKit
import XCTest
@testable import ModelsTreeKit

class DeinitSignalTests: XCTestCase {
  var controller: UIViewController?
  var controllerDidDeallocate = false
  
  override func setUp() {
    controller = UIViewController()
    controller?.deinitSignal.subscribeCompleted { [weak self] deallocated in
      self?.controllerDidDeallocate = true
      }.putInto(pool)
  }
  
  func testThatViewControllerExists() {
    XCTAssertNotNil(controller)
    XCTAssertFalse(controllerDidDeallocate)
  }
  
  override func tearDown() {
    controller = nil
    XCTAssertTrue(controllerDidDeallocate)
  }
}