// Create the Phoenix LiveView Inspector panel
chrome.devtools.panels.create(
  'LiveView Inspector',
  'icons/icon16.png',
  'panels/panel.html',
  function(panel) {
    let panelWindow = null;
    
    panel.onShown.addListener(function(window) {
      panelWindow = window;
      
      // Initialize connection when panel is shown
      if (panelWindow && panelWindow.PhoenixLiveInspector) {
        panelWindow.PhoenixLiveInspector.init();
      }
    });
    
    panel.onHidden.addListener(function() {
      // Cleanup when panel is hidden
      if (panelWindow && panelWindow.PhoenixLiveInspector) {
        panelWindow.PhoenixLiveInspector.cleanup();
      }
    });
  }
);

// Listen for tab updates to detect LiveView apps
chrome.devtools.network.onNavigated.addListener(function(url) {
  // Could add logic here to detect LiveView apps
  console.log('DevTools: Navigated to', url);
});