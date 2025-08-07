// Content script for LiveView DevTools
(function() {
  'use strict';
  
  let isLiveViewDetected = false;
  let currentSessionId = null;
  
  function detectLiveView() {
    return !!(
      document.querySelector('[data-phx-main]') ||
      document.querySelector('script[src*="phoenix_live_view"]') ||
      window.Phoenix
    );
  }
  
  function extractSessionId() {
    const mainElement = document.querySelector('[data-phx-main]');
    return mainElement?.getAttribute('data-phx-main') || `session_${Date.now()}`;
  }
  
  function sendEvent(eventType, details = {}) {
    chrome.runtime.sendMessage({
      type: 'LIVEVIEW_EVENT',
      eventType: eventType,
      element: details.element || 'unknown',
      sessionId: currentSessionId,
      timestamp: Date.now(),
      details: details
    }).catch(() => {}); // Ignore errors
  }
  
  function setupEventListeners() {
    document.addEventListener('click', (event) => {
      const element = event.target;
      if (element.hasAttribute('phx-click')) {
        sendEvent('phx_click', {
          event: element.getAttribute('phx-click'),
          element: element.tagName.toLowerCase(),
          text: element.textContent?.trim().substring(0, 50) || ''
        });
      }
    }, true);
    
    document.addEventListener('submit', (event) => {
      const form = event.target;
      if (form.hasAttribute('phx-submit')) {
        sendEvent('phx_submit', {
          event: form.getAttribute('phx-submit')
        });
      }
    }, true);
  }
  
  function initialize() {
    if (detectLiveView()) {
      isLiveViewDetected = true;
      currentSessionId = extractSessionId();
      
      chrome.runtime.sendMessage({
        type: 'LIVEVIEW_DETECTED',
        sessionId: currentSessionId,
        url: window.location.href
      });
      
      setupEventListeners();
      sendEvent('liveview_mount', { url: window.location.href });
    }
  }
  
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initialize);
  } else {
    initialize();
  }
})();