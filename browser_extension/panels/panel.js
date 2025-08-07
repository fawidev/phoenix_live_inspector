// Phoenix LiveView Inspector Panel - WebSocket connection to Elixir server

window.PhoenixLiveInspector = (function() {
  let port = null;
  let currentSession = null;
  let activeSessions = [];
  let events = [];
  let isConnected = false;

  const elements = {
    connectionIndicator: null,
    connectionText: null,
    sessionsList: null,
    eventsList: null,
    tabs: null,
    tabContents: null
  };

  function init() {
    console.log('🔍 Phoenix LiveView Inspector Panel initializing...');
    initElements();
    setupEventListeners();
    connectToBackground();
    switchTab('inspector'); // Start with State Inspector tab
  }

  function initElements() {
    elements.connectionIndicator = document.getElementById('connection-indicator');
    elements.connectionText = document.getElementById('connection-text');
    elements.sessionsList = document.getElementById('sessions-list');
    elements.eventsList = document.getElementById('events-list');
    elements.tabs = document.querySelectorAll('.tab');
    elements.tabContents = document.querySelectorAll('.tab-content');
  }

  function setupEventListeners() {
    elements.tabs.forEach(tab => {
      tab.addEventListener('click', () => {
        const tabName = tab.getAttribute('data-tab');
        switchTab(tabName);
      });
    });

    document.getElementById('refresh-btn').addEventListener('click', refreshData);
    document.getElementById('clear-btn').addEventListener('click', clearData);
    document.getElementById('clear-events').addEventListener('click', clearEvents);
  }

  function connectToBackground() {
    try {
      // Connect to Phoenix LiveView Inspector WebSocket server
      const socket = new WebSocket('ws://localhost:4001/devtools/websocket');
      
      socket.onopen = () => {
        console.log('✅ Connected to Phoenix LiveView Inspector server');
        isConnected = true;
        updateConnectionStatus('connected', 'Connected');
        
        // Send ping to test connection
        socket.send(JSON.stringify({ type: 'ping' }));
      };

      socket.onmessage = (event) => {
        try {
          const message = JSON.parse(event.data);
          handleServerMessage(message);
        } catch (error) {
          console.error('Failed to parse message:', error);
        }
      };

      socket.onclose = () => {
        console.log('🔌 Disconnected from Phoenix LiveView Inspector server');
        isConnected = false;
        updateConnectionStatus('disconnected', 'Disconnected');
        
        // Try to reconnect
        setTimeout(connectToBackground, 3000);
      };

      socket.onerror = (error) => {
        console.error('❌ WebSocket error:', error);
        updateConnectionStatus('disconnected', 'Connection Failed');
      };

      port = socket; // Store socket reference
      
    } catch (error) {
      console.error('❌ Failed to connect to Phoenix LiveView Inspector server:', error);
      updateConnectionStatus('disconnected', 'Server Unavailable');
      setTimeout(connectToBackground, 5000);
    }
  }

  function handleServerMessage(message) {
    console.log('📨 Message from server:', message.type);
    
    switch (message.type) {
      case 'pong':
        console.log('🏓 Received pong from server');
        break;
        
      case 'session_registered':
        if (!activeSessions.includes(message.session_id)) {
          activeSessions.push(message.session_id);
          updateSessionsList(activeSessions);
        }
        break;
        
      case 'liveview_event':
        const event = message.event;
        console.log('🎯 Received event:', event.type, '- Name:', event.event_name, '- Assigns:', Object.keys(event.assigns || {}));
        
        // Only show completed user events (stop phase) with state changes
        if (event.type === 'handle_event_stop' && event.assigns && Object.keys(event.assigns).length > 0) {
          console.log('📝 Adding event to list:', event.event_name);
          events.unshift(event);
          events = events.slice(0, 100);
          updateEventsDisplay();
          updateStateInspector(event);
        }
        // Show mount events for component initialization
        else if (event.type === 'mount_stop' && event.assigns) {
          console.log('📝 Adding mount event:', event.event_name);
          events.unshift(event);
          events = events.slice(0, 100);
          updateEventsDisplay();
          updateStateInspector(event);
        }
        
        // Always update state inspector with latest assigns
        if (event.assigns && Object.keys(event.assigns).length > 0) {
          updateStateInspector(event);
        }
        break;
        
      case 'sessions_update':
        activeSessions = message.sessions || [];
        updateSessionsList(activeSessions);
        break;
        
      case 'events_update':
        events = message.events || [];
        updateEventsDisplay();
        break;
        
      default:
        console.log('Unknown message type:', message.type);
    }
    
    updateMetrics();
  }

  function handleBackgroundMessage(message) {
    console.log('📨 Message from background:', message.type);
    
    switch (message.type) {
      case 'DATA_UPDATE':
      case 'CONTENT_UPDATE':
        updateFromBackgroundData(message.data);
        break;
        
      case 'STORED_DATA':
        updateFromBackgroundData(message.data);
        break;
    }
  }

  function updateFromBackgroundData(data) {
    if (data.sessions) {
      activeSessions = data.sessions;
      updateSessionsList(activeSessions);
    }
    
    if (data.events) {
      events = data.events;
      updateEventsDisplay();
    }
    
    updateMetrics();
  }

  function updateConnectionStatus(status, text) {
    if (elements.connectionIndicator && elements.connectionText) {
      elements.connectionIndicator.className = `status-indicator ${status}`;
      elements.connectionText.textContent = text;
    }
  }

  function updateSessionsList(sessions) {
    if (!elements.sessionsList) return;
    
    if (sessions.length === 0) {
      elements.sessionsList.innerHTML = '<div class="no-sessions">No active sessions</div>';
      return;
    }
    
    const sessionsHtml = sessions.map(sessionId => `
      <div class="session-item ${sessionId === currentSession ? 'active' : ''}" data-session="${sessionId}">
        <div class="session-id">${sessionId.substring(0, 12)}...</div>
        <div class="session-status">Active</div>
      </div>
    `).join('');
    
    elements.sessionsList.innerHTML = sessionsHtml;
    
    elements.sessionsList.querySelectorAll('.session-item').forEach(item => {
      item.addEventListener('click', () => {
        const sessionId = item.getAttribute('data-session');
        selectSession(sessionId);
      });
    });
  }

  function selectSession(sessionId) {
    currentSession = sessionId;
    updateSessionsList(activeSessions); // Refresh to show selection
  }

  function updateEventsDisplay() {
    if (!elements.eventsList) return;
    
    if (events.length === 0) {
      elements.eventsList.innerHTML = '<div class="no-events">No events recorded</div>';
      return;
    }
    
    const eventsHtml = events.slice(0, 50).map(event => `
      <div class="event-item">
        <div class="event-header">
          <span class="event-type">${event.event_name || event.type}</span>
          <span class="component-name">${event.component?.name || 'Unknown'}</span>
          <span class="event-timestamp">${formatTimestamp(event.timestamp)}</span>
          ${event.duration ? `<span class="event-duration">${event.duration.toFixed(2)}ms</span>` : ''}
        </div>
        <div class="event-details">
          ${Object.keys(event.params || {}).length > 0 ? `
            <div class="event-params">
              <strong>Params:</strong> ${JSON.stringify(event.params, null, 2)}
            </div>
          ` : ''}
          ${Object.keys(event.assigns || {}).length > 0 ? `
            <div class="event-assigns">
              <strong>Updated State:</strong>
              <pre>${JSON.stringify(event.assigns, null, 2)}</pre>
            </div>
          ` : ''}
        </div>
      </div>
    `).join('');
    
    elements.eventsList.innerHTML = eventsHtml;
  }

  function updateMetrics() {
    const activeSessionsEl = document.getElementById('active-sessions-count');
    const totalEventsEl = document.getElementById('total-events-count');
    
    if (activeSessionsEl) {
      activeSessionsEl.textContent = activeSessions.length;
    }
    
    if (totalEventsEl) {
      totalEventsEl.textContent = events.length;
    }
  }

  function switchTab(tabName) {
    elements.tabs.forEach(tab => tab.classList.remove('active'));
    elements.tabContents.forEach(content => content.classList.remove('active'));
    
    const activeTab = document.querySelector(`[data-tab="${tabName}"]`);
    const activeContent = document.getElementById(`${tabName}-tab`);
    
    if (activeTab && activeContent) {
      activeTab.classList.add('active');
      activeContent.classList.add('active');
    }
  }

  function refreshData() {
    if (port && isConnected) {
      port.send(JSON.stringify({ type: 'get_sessions' }));
      port.send(JSON.stringify({ type: 'get_events' }));
    }
  }

  function clearData() {
    events = [];
    activeSessions = [];
    updateEventsDisplay();
    updateSessionsList([]);
    updateMetrics();
  }

  function clearEvents() {
    if (port && isConnected) {
      port.send(JSON.stringify({ type: 'clear_events' }));
    }
    events = [];
    updateEventsDisplay();
    updateMetrics();
  }

  function formatTimestamp(timestamp) {
    return new Date(timestamp).toLocaleTimeString();
  }

  function updateStateInspector(event) {
    // Update the State Inspector tab with current assigns
    if (event.assigns && Object.keys(event.assigns).length > 0) {
      const stateInspectorContent = document.querySelector('#inspector-tab .state-content');
      if (stateInspectorContent) {
        const stateHtml = `
          <div class="component-state">
            <h3>${event.component?.name || 'Unknown Component'}</h3>
            <div class="assigns-display">
              ${Object.entries(event.assigns).map(([key, value]) => `
                <div class="assign-item">
                  <span class="assign-key">@${key}:</span>
                  <span class="assign-value">${JSON.stringify(value, null, 2)}</span>
                </div>
              `).join('')}
            </div>
            <div class="state-timestamp">Updated: ${formatTimestamp(event.timestamp)}</div>
          </div>
        `;
        stateInspectorContent.innerHTML = stateHtml;
      }
    }
  }

  function cleanup() {
    if (port) {
      port.disconnect();
      port = null;
    }
  }

  return { init, cleanup };
})();

// Auto-initialize
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    window.PhoenixLiveInspector.init();
  });
} else {
  window.PhoenixLiveInspector.init();
}