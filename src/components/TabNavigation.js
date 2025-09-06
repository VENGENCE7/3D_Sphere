export class TabNavigation {
  constructor(container, tabs, onTabChange) {
    this.container = container;
    this.tabs = tabs;
    this.onTabChange = onTabChange;
    this.activeTab = tabs[0].id;
    this.init();
  }

  init() {
    this.render();
    this.attachEventListeners();
  }

  render() {
    const nav = document.createElement('nav');
    nav.className = 'tab-navigation';

    const tabList = document.createElement('ul');
    tabList.className = 'tab-list';

    this.tabs.forEach((tab) => {
      const tabItem = document.createElement('li');
      tabItem.className = 'tab-item';

      const tabButton = document.createElement('button');
      tabButton.className = `tab-button ${
        tab.id === this.activeTab ? 'active' : ''
      }`;
      tabButton.textContent = tab.label;
      tabButton.dataset.tabId = tab.id;

      tabItem.appendChild(tabButton);
      tabList.appendChild(tabItem);
    });

    nav.appendChild(tabList);
    this.container.appendChild(nav);
  }

  attachEventListeners() {
    this.container.addEventListener('click', (e) => {
      if (e.target.classList.contains('tab-button')) {
        const tabId = e.target.dataset.tabId;
        this.setActiveTab(tabId);
      }
    });
  }

  setActiveTab(tabId) {
    if (tabId === this.activeTab) return;

    // Update UI
    const buttons = this.container.querySelectorAll('.tab-button');
    buttons.forEach((button) => {
      if (button.dataset.tabId === tabId) {
        button.classList.add('active');
      } else {
        button.classList.remove('active');
      }
    });

    this.activeTab = tabId;

    // Trigger callback
    if (this.onTabChange) {
      this.onTabChange(tabId);
    }
  }

  dispose() {
    this.container.innerHTML = '';
  }
}
