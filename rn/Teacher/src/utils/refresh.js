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

import React, { Component } from 'react'
import hoistStatics from 'hoist-non-react-statics'

export type RefreshFunction = (*) => *
export type ShouldRefresh = (*) => boolean
export type IsFetchingData = (*) => boolean

export default function refresh (
    refreshFunction: RefreshFunction,
    shouldRefresh: ShouldRefresh,
    isFetchingData: IsFetchingData,
    ttl: ?number = 1000 * 60 * 60 // 1 hour
  ): * {
  let lastUpdate = null

  return function (TheirComponent) {
    class Refreshed extends Component {
      state: RefreshState

      refreshFunction = refreshFunction
      shouldRefresh = shouldRefresh
      isFetchingData = isFetchingData

      constructor (props) {
        super(props)
        this.state = { refreshing: false }
      }

      componentWillReceiveProps (nextProps) {
        this.setState({
          refreshing: this.state.refreshing
            ? isFetchingData(nextProps)
            : false,
        })
      }

      componentWillMount () {
        if (shouldRefresh(this.props)) {
          lastUpdate = Date.now()
          refreshFunction(this.props)
        } else if (!lastUpdate || Date.now() > lastUpdate + ttl) {
          this.refresh()
        }
      }

      refresh = () => {
        this.setState({ refreshing: true }, () => {
          lastUpdate = Date.now()
          refreshFunction(this.props)
        })
      }

      render = () => <TheirComponent {...this.props} refresh={this.refresh} refreshing={this.state.refreshing} />
    }

    return hoistStatics(Refreshed, TheirComponent)
  }
}
