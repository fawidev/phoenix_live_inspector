// Background script for LiveView DevTools - Chrome Extension Manifest V3

// Store for devtools panels across tabs
const devToolsPanels = new Map();
const contentScriptData = new Map();

// Handle connections from devtools panels
chrome.runtime.onConnect.addListener((port) => {
  console.log('DevTools panel connected:', port.name);
  
  if (port.name === 'devtools-panel') {
    const tabId = port.sender?.tab?.id || extractTabIdFromPort(port);
    
    if (tabId) {
      devToolsPanels.set(tabId, port);
      
      // Send any stored data to the newly connected panel
      if (contentScriptData.has(tabId)) {
        port.postMessage({
          type: 'STORED_DATA',
          data: contentScriptData.get(tabId)
        });
      }
      
      port.onDisconnect.addListener(() => {
        console.log('DevTools panel disconnected for tab:', tabId);
        devToolsPanels.delete(tabId);
      });
      
      port.onMessage.addListener((message) => {
        handleDevToolsMessage(message, tabId, port);
      });
    }
  }
});

// Handle messages from content scripts
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  const tabId = sender.tab?.id;
  
  if (!tabId) return;
  
  // Store data for this tab
  if (!contentScriptData.has(tabId)) {
    contentScriptData.set(tabId, {
      sessions: [],
      events: [],
      isLiveView: false
    });
  }
  
  const data = contentScriptData.get(tabId);
  
  switch (message.type) {
    case 'LIVEVIEW_DETECTED':
      console.log('LiveView detected on tab:', tabId);
      data.isLiveView = true;
      data.sessions = [message.sessionId || `session_${Date.now()}`];
      break;
      
    case 'LIVEVIEW_EVENT':
      console.log('LiveView event:', message.eventType);
      data.events.unshift({
        id: Date.now(),
        type: message.eventType,
        element: message.element,
        timestamp: Date.now(),
        sessionId: data.sessions[0] || 'unknown'
      });
      
      // Keep only last 100 events
      if (data.events.length > 100) {
        data.events = data.events.slice(0, 100);
      }
      break;
      
    case 'ASSIGNS_UPDATE':
      data.currentAssigns = message.assigns;
      break;
  }
  
  // Forward to devtools panel if connected
  const panel = devToolsPanels.get(tabId);
  if (panel) {
    try {
      panel.postMessage({
        type: 'CONTENT_UPDATE',
        data: data
      });
    } catch (error) {
      console.error('Error sending to panel:', error);
    }
  }
  
  sendResponse({ success: true });
});

// Handle devtools panel messages
function handleDevToolsMessage(message, tabId, port) {
  switch (message.type) {
    case 'GET_DATA':
      // Send current data to panel
      const data = contentScriptData.get(tabId) || {
        sessions: [],
        events: [],
        isLiveView: false
      };
      
      port.postMessage({
        type: 'DATA_UPDATE',
        data: data
      });
      break;
      
    case 'CLEAR_EVENTS':
      if (contentScriptData.has(tabId)) {
        contentScriptData.get(tabId).events = [];
      }
      break;
  }
}

// Extract tab ID from port (fallback method)
function extractTabIdFromPort(port) {
  // Try to extract from port name or URL
  try {
    const url = new URL(port.sender?.url || '');
    return url.searchParams.get('tabId');
  } catch {
    return null;
  }
}

// Clean up data for closed tabs
chrome.tabs.onRemoved.addListener((tabId) => {
  devToolsPanels.delete(tabId);
  contentScriptData.delete(tabId);
});