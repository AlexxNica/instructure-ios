//
// Copyright (C) 2016-present Instructure, Inc.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, version 3 of the License.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

// @flow

import SubmissionActions from './actions'

export type SubmissionStatusProp =
  'none' |
  'missing' |
  'late' |
  'submitted'

export type GradeProp = 'not_submitted' | 'ungraded' | 'excused' | string

export type SubmissionDataProps = {
  userID: string,
  groupID?: string,
  avatarURL?: string,
  name: string,
  status: SubmissionStatusProp,
  grade: ?GradeProp,
  score?: ?number,
  submissionID: ?string,
  submission: ?Object,
}

export type SubmissionProps = SubmissionDataProps & {
  onPress: (userID: string) => void,
}

export type AsyncSubmissionsDataProps = {
  pending: boolean,
  submissions: Array<SubmissionDataProps>,
}

export type SubmissionListDataProps
  = AsyncSubmissionsDataProps
  & {
    groupAssignment: ?{ groupCategoryID: string, gradeIndividually: boolean },
    courseColor: string,
    courseName: string,
    pointsPossible?: string,
    anonymous: boolean,
    muted: boolean,
    assignmentName: string,
    course: ?Course,
  }

export type SubmissionListActionProps = {
  refreshSubmissions: (courseID: string, assignmentID: string, grouped: boolean) => void,
}

export type GroupSubmissionListActionProps = {
  refreshGroupsForCourse: (courseID: string) => void,
}

export type SubmissionListNavigationParameters = {
  courseID: string,
  assignmentID: string,
  filterType?: string,
}

export type SubmissionListProps
  = SubmissionListDataProps
  & SubmissionListActionProps
  & typeof SubmissionActions
  & GroupSubmissionListActionProps
  & SubmissionListNavigationParameters
