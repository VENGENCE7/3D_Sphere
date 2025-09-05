export class GalaxyLauncher {
    constructor(container) {
        this.container = container;
        this.init();
    }
    
    init() {
        // Create placeholder content for galaxy view
        this.container.innerHTML = `
            <div style="
                width: 100%;
                height: 100%;
                display: flex;
                align-items: center;
                justify-content: center;
                color: #ffffff;
                font-family: Arial, sans-serif;
                font-size: 24px;
                background: #000000;
            ">
                Galaxy View - Coming Soon
            </div>
        `;
    }
    
    dispose() {
        // Clean up when switching away
        if (this.container) {
            this.container.innerHTML = '';
        }
    }
}