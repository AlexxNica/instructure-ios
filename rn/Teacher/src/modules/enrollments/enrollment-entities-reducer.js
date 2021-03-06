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

import { Reducer } from 'redux'
import Actions from './actions'
import { handleActions } from 'redux-actions'
import handleAsync from '../../utils/handleAsync'
import fromPairs from 'lodash/fromPairs'
import { type UserProfileState } from '../users/reducer'

export const defaultEntities: EnrollmentsState = {}
const { refreshEnrollments } = Actions

export const enrollments: Reducer<EnrollmentsState, any> = handleActions({
  [refreshEnrollments.toString()]: handleAsync({
    resolved: (state, { result }) => {
      const incoming = fromPairs(result.data
        .map(enrollment => [enrollment.id, enrollment]))
      return { ...state, ...incoming }
    },
  }),
}, {})

export const enrollmentUsers: Reducer<UserProfileState, any> = handleActions({
  [refreshEnrollments.toString()]: handleAsync({
    resolved: (state, { result }) => {
      const incoming = fromPairs(result.data
        .map((enrollment) => {
          const incomingUser = enrollment.user
          let user = state[incomingUser.id]
          if (user) {
            Object.assign(user, incomingUser)
          } else {
            user = incomingUser
          }
          return [user.id, user]
        }))
      return { ...state, ...incoming }
    },
  }),
}, {})
