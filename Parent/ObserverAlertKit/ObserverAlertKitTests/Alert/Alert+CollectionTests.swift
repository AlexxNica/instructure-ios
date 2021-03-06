//
// Copyright (C) 2016-present Instructure, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
    
    

import XCTest
import SoAutomated
import TooLegit
import DoNotShipThis
import Marshal
@testable import ObserverAlertKit

class AlertCollectionsTests: XCTestCase {

    func testAlertCollection_TableViewControllerPrepare() {
        attempt {
            let session = Session.parentTest
            
            let collection = try Alert.collectionOfObserveeAlerts(session, observeeID: "16")
            let viewModelFactory = ViewModelFactory<Alert>.new { _ in UITableViewCell() }
            let refresher = try Alert.refresher(session, observeeID: "16")
            let tvc = Alert.TableViewController()

            tvc.prepare(collection, refresher: refresher, viewModelFactory: viewModelFactory)

            XCTAssertEqual(collection, tvc.collection)
            XCTAssertNotNil(tvc.dataSource)
            XCTAssertNotNil(tvc.refresher)
        }
    }

}
