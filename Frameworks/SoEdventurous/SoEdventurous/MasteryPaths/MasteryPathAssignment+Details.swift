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

import Foundation
import CoreData
import SoPersistent
import TooLegit

extension MasteryPathAssignment {
    public static func observer(_ session: Session, id: String) throws -> ManagedObjectObserver<MasteryPathAssignment> {
        let predicate = NSPredicate(format: "%K == %@", "id", id)
        let context = try session.soEdventurousManagedObjectContext()
        return try ManagedObjectObserver<MasteryPathAssignment>(predicate: predicate, inContext: context)
    }
}

open class MasteryPathAssignmentDetailViewController: SoPersistent.TableViewController {
    fileprivate (set) open var observer: ManagedObjectObserver<MasteryPathAssignment>!
    
    open func prepare<DVM: TableViewCellViewModel>(_ observer: ManagedObjectObserver<MasteryPathAssignment>, detailsFactory: @escaping (MasteryPathAssignment)->[DVM]) where DVM: Equatable {
        self.observer = observer
        let details = FetchedDetailsCollection(observer: observer, detailsFactory: detailsFactory)
        dataSource = CollectionTableViewDataSource(collection: details)
    }
}

