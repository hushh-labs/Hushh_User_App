interface GmailApiConfig {
  accessToken: string
  refreshToken?: string
}

export class GmailApiClient {
  private config: GmailApiConfig

  constructor(config: GmailApiConfig) {
    this.config = config
  }

  async makeRequest(url: string, options: RequestInit = {}): Promise<any> {
    const response = await fetch(url, {
      ...options,
      headers: {
        'Authorization': `Bearer ${this.config.accessToken}`,
        'Content-Type': 'application/json',
        ...options.headers,
      },
    })

    if (!response.ok) {
      const errorText = await response.text()
      throw new Error(`Gmail API error: ${response.status} - ${errorText}`)
    }

    return response.json()
  }

  async getMessages(query: string, maxResults: number = 100, pageToken?: string): Promise<any> {
    const params = new URLSearchParams({
      q: query,
      maxResults: maxResults.toString(),
    })
    
    if (pageToken) {
      params.append('pageToken', pageToken)
    }

    const url = `https://gmail.googleapis.com/gmail/v1/users/me/messages?${params}`
    return this.makeRequest(url)
  }

  async getMessage(messageId: string): Promise<any> {
    const url = `https://gmail.googleapis.com/gmail/v1/users/me/messages/${messageId}`
    return this.makeRequest(url)
  }

  async getHistory(startHistoryId: string, historyTypes?: string[]): Promise<any> {
    const params = new URLSearchParams({
      startHistoryId,
    })
    
    if (historyTypes) {
      params.append('historyTypes', historyTypes.join(','))
    }

    const url = `https://gmail.googleapis.com/gmail/v1/users/me/history?${params}`
    return this.makeRequest(url)
  }
}

export function parseEmailMessage(message: any, userId: string) {
  const headers = message.payload?.headers || []
  const getHeader = (name: string) => 
    headers.find((h: any) => h.name.toLowerCase() === name.toLowerCase())?.value

  // Extract email addresses from headers
  const parseEmailList = (headerValue: string | undefined) => {
    if (!headerValue) return []
    return headerValue.split(',').map(email => email.trim()).filter(email => email.length > 0)
  }

  // Get email body
  let bodyText = ''
  let bodyHtml = ''
  
  if (message.payload?.body?.data) {
    bodyText = atob(message.payload.body.data.replace(/-/g, '+').replace(/_/g, '/'))
  } else if (message.payload?.parts) {
    for (const part of message.payload.parts) {
      if (part.mimeType === 'text/plain' && part.body?.data) {
        bodyText = atob(part.body.data.replace(/-/g, '+').replace(/_/g, '/'))
      } else if (part.mimeType === 'text/html' && part.body?.data) {
        bodyHtml = atob(part.body.data.replace(/-/g, '+').replace(/_/g, '/'))
      }
    }
  }

  // Parse labels
  const labels = message.labelIds || []

  return {
    userId,
    messageId: message.id,
    threadId: message.threadId,
    historyId: message.historyId,
    subject: getHeader('Subject') || '',
    fromEmail: getHeader('From') || '',
    fromName: getHeader('From')?.split('<')[0]?.trim() || '',
    toEmails: parseEmailList(getHeader('To')),
    ccEmails: parseEmailList(getHeader('Cc')),
    bccEmails: parseEmailList(getHeader('Bcc')),
    bodyText: bodyText.length > 0 ? bodyText : null,
    bodyHtml: bodyHtml.length > 0 ? bodyHtml : null,
    snippet: message.snippet || '',
    isRead: !labels.includes('UNREAD'),
    isImportant: labels.includes('IMPORTANT'),
    isStarred: labels.includes('STARRED'),
    labels,
    attachments: [], // TODO: Process attachments if needed
    receivedAt: new Date(parseInt(message.internalDate)).toISOString(),
    sentAt: new Date(parseInt(message.internalDate)).toISOString(),
    syncedAt: new Date().toISOString(),
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  }
}
