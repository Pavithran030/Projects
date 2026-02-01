/**
 * Main JavaScript for home page
 */

// Fetch and display statistics
async function loadStatistics() {
    try {
        const response = await fetch('/api/stats');
        if (response.ok) {
            const stats = await response.json();
            
            // Animate counters
            animateCounter('totalScans', stats.total_scans);
            animateCounter('maliciousDetected', stats.malicious);
            animateCounter('safeApps', stats.safe);
        }
    } catch (error) {
        console.error('Failed to load statistics:', error);
    }
}

// Animate counter from 0 to target value
function animateCounter(elementId, target) {
    const element = document.getElementById(elementId);
    if (!element) return;
    
    const duration = 2000; // 2 seconds
    const steps = 60;
    const increment = target / steps;
    let current = 0;
    
    const timer = setInterval(() => {
        current += increment;
        if (current >= target) {
            element.textContent = target;
            clearInterval(timer);
        } else {
            element.textContent = Math.floor(current);
        }
    }, duration / steps);
}

// Smooth scroll for anchor links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        const href = this.getAttribute('href');
        if (href !== '#') {
            e.preventDefault();
            const target = document.querySelector(href);
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth'
                });
            }
        }
    });
});

// Load stats when page loads
window.addEventListener('DOMContentLoaded', () => {
    loadStatistics();
});
