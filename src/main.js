import { TabNavigation } from './components/TabNavigation.js';
import { BlobLauncher } from './components/blob/BlobLauncher.js';
import { GalaxyLauncher } from './components/galaxy/GalaxyLauncher.js';
import './styles.css';

class Application {
  constructor() {
    this.currentView = null;
    this.tabContainer = null;
    this.viewContainer = null;
    this.init();
  }

  init() {
    // Create main container structure
    this.createLayout();

    // Define tabs
    const tabs = [
      { id: 'galaxy', label: 'Galaxy' },
      { id: 'blob', label: 'Central Blob' },
    ];

    // Create tab navigation
    new TabNavigation(this.tabContainer, tabs, (tabId) => {
      this.switchView(tabId);
    });

    // Load initial view
    this.switchView('galaxy');
  }

  createLayout() {
    // Create tab container
    this.tabContainer = document.createElement('div');
    this.tabContainer.className = 'tab-container';
    document.body.appendChild(this.tabContainer);

    // Create view container
    this.viewContainer = document.createElement('div');
    this.viewContainer.className = 'view-container';
    document.body.appendChild(this.viewContainer);
  }

  switchView(viewId) {
    // Dispose current view
    if (this.currentView) {
      this.currentView.dispose();
      this.currentView = null;
    }

    // Clear view container
    this.viewContainer.innerHTML = '';

    // Load new view
    switch (viewId) {
      case 'blob':
        this.currentView = new BlobLauncher(this.viewContainer);
        break;
      case 'galaxy':
        this.currentView = new GalaxyLauncher(this.viewContainer);
        break;
      default:
        console.error(`Unknown view: ${viewId}`);
    }
  }

  dispose() {
    if (this.currentView) {
      this.currentView.dispose();
    }
  }
}

// Initialize the application
const app = new Application();

// Export for potential external use
export default app;
