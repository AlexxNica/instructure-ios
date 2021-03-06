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

// @flow

import inbox, { conversations } from '../reducer'
import { InboxActions } from '../actions'
import { apiResponse, apiError } from '../../../../test/helpers/apiMock'
import { testAsyncReducer } from '../../../../test/helpers/async'

const { refreshInboxAll, updateInboxSelectedScope, markAsRead } = InboxActions()
const templates = {
  ...require('../../../__templates__/conversations'),
}

test('it handles the data', () => {
  const data = [
    templates.conversation({ id: '1' }),
    templates.conversation({ id: '2' }),
  ]

  const action = {
    type: refreshInboxAll.toString(),
    payload: { result: { data } },
  }

  expect(inbox({}, action)).toEqual({
    conversations: {
      '1': { data: data[0] },
      '2': { data: data[1] },
    },
    selectedScope: 'all',
    all: {
      refs: [data[0].id, data[1].id],
      pending: 0,
    },
    unread: {
      refs: [],
      pending: 0,
    },
    sent: {
      refs: [],
      pending: 0,
    },
    archived: {
      refs: [],
      pending: 0,
    },
    starred: {
      refs: [],
      pending: 0,
    },
  })
})

test('handles updating scope', () => {
  const action = {
    type: updateInboxSelectedScope.toString(),
    payload: 'unread',
  }
  const result = inbox('all', action)
  expect(result).toMatchObject({
    selectedScope: 'unread',
  })
})

test('handled updating a single conversation', async () => {
  const convo = templates.conversation({ id: '2' })
  let action = InboxActions({ getConversationDetails: apiResponse(convo) }).refreshConversationDetails(convo.id)
  let state = await testAsyncReducer(inbox, action)
  expect(state).toMatchObject([
    {
      conversations: {
        [convo.id.toString()]: {
          pending: 1,
          error: null,
        },
      },
    },
    {
      conversations: {
        [convo.id.toString()]: {
          pending: 0,
          data: convo,
          error: null,
        },
      },
    },
  ])
})

test('handled updating a single conversation that errors', async () => {
  const convo = templates.conversation({ id: '2' })
  let action = InboxActions({ getConversationDetails: apiError({ message: 'error' }) }).refreshConversationDetails(convo.id)
  let state = await testAsyncReducer(inbox, action)
  expect(state).toMatchObject([
    {
      conversations: {
        [convo.id.toString()]: {
          pending: 1,
          error: null,
        },
      },
    },
    {
      conversations: {
        [convo.id.toString()]: {
          pending: 0,
          error: 'An error occured while fetching this conversation.',
        },
      },
    },
  ])
})

describe('deleteConversation', () => {
  it('handles deleting a conversation that resolves', async () => {
    const data = templates.conversation({ id: '2' })
    const api = {
      deleteConversation: apiResponse(data),
    }
    const action = InboxActions(api).deleteConversation('2')

    const defaultState = {
      '1': {
        pending: 0,
        error: null,
        data: templates.conversation({ id: '1' }),
      },
      '2': {
        pending: 0,
        error: null,
        data,
      },
    }
    const expectedPending = {
      ...defaultState,
      '2': {
        pending: 1,
        error: null,
        data,
      },
    }
    const expectedResolved = {
      '1': {
        pending: 0,
        error: null,
        data: templates.conversation({ id: '1' }),
      },
    }
    expect(await testAsyncReducer(conversations, action, defaultState)).toEqual([
      expectedPending,
      expectedResolved,
    ])
  })

  it('handles deleting a conversation that errors', async () => {
    const data = templates.conversation({ id: '2' })
    const api = {
      deleteConversation: apiError({ message: 'Something bad happened' }),
    }
    const action = InboxActions(api).deleteConversation('2')
    const defaultState = {
      '2': {
        pending: 0,
        error: null,
        data,
      },
    }
    const expectedPending = {
      '2': {
        pending: 1,
        error: null,
        data,
      },
    }
    const expectedRejected = {
      '2': {
        pending: 0,
        error: 'Something bad happened',
        data,
      },
    }
    expect(await testAsyncReducer(conversations, action, defaultState)).toEqual([
      expectedPending,
      expectedRejected,
    ])
  })
})

describe('markAsRead', () => {
  it('optimistically sets the workflow_state', () => {
    let conversationID = '1'

    let state = {
      '1': {
        data: templates.conversation({ workflow_state: 'unread' }),
        pending: 0,
        error: null,
      },
    }

    let action = {
      type: markAsRead.toString(),
      pending: true,
      payload: {
        conversationID,
      },
    }

    let nextState = conversations(state, action)
    expect(nextState['1'].data.workflow_state).toEqual('read')
  })

  it('reverts on error', () => {
    let conversationID = '1'
    let state = {
      '1': {
        data: templates.conversation({ workflow_state: 'read' }),
        pending: 0,
        error: null,
      },
    }

    let action = {
      type: markAsRead.toString(),
      error: true,
      payload: {
        conversationID,
        error: 'this is an error',
      },
    }

    let nextState = conversations(state, action)
    expect(nextState['1'].data.workflow_state).toEqual('unread')
  })
})
