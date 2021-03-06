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

import CoreData
import TooLegit

final public class FileUploadBatch: NSManagedObject {
    @NSManaged open internal(set) var primitiveFileTypes: String
    open internal(set) var fileTypes: [String] {
        get {
            return primitiveFileTypes.components(separatedBy: ",")
        }
        set {
            primitiveFileTypes = newValue.joined(separator: ",")
        }
    }

    @NSManaged open internal(set) var apiPath: String

    @NSManaged open internal(set) var fileUploads: Set<FileUpload>


    public convenience init(session: Session, fileTypes: [String], apiPath: String) {
        let context = try! session.filesManagedObjectContext()
        self.init(inContext: context)

        self.fileTypes = fileTypes
        self.apiPath = apiPath
    }
}
