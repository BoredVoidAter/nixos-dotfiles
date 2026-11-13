// Lightweight Vimium-style Keybindings & Link Hinting for Ferdium
(function() {
  let isHinting = false;
  let hints = [];
  let typedKeys = '';
  let hintContainer = null;
  let lastKey = '';
  
  // The characters used for hints (Home row focused)
  const HINT_CHARS = 'ASDFJKLGHNMUIOPQWERTYCXZVB';

  function showHints() {
    if (isHinting) return;
    
    // Find everything that looks clickable
    const selectors = 'a, button, input, select, textarea, summary, [role="button"], [role="link"], [tabindex]:not([tabindex="-1"])';
    const elements = Array.from(document.querySelectorAll(selectors)).filter(el => {
      const rect = el.getBoundingClientRect();
      // Ensure the element is currently visible on screen
      return rect.width > 0 && rect.height > 0 && 
             rect.top >= 0 && rect.left >= 0 && 
             rect.top <= window.innerHeight && rect.left <= window.innerWidth;
    });

    if (elements.length === 0) return;

    isHinting = true;
    typedKeys = '';
    
    hintContainer = document.createElement('div');
    hintContainer.id = 'vicinae-vim-hints';
    hintContainer.style.cssText = 'position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 2147483647; pointer-events: none;';
    
    // Calculate how many characters we need per hint to avoid collisions
    const labelLen = Math.max(1, Math.ceil(Math.log(elements.length) / Math.log(HINT_CHARS.length)));
    
    hints = elements.map((el, i) => {
      let label = '';
      let num = i;
      for (let j = 0; j < labelLen; j++) {
        label = HINT_CHARS[num % HINT_CHARS.length] + label;
        num = Math.floor(num / HINT_CHARS.length);
      }
      
      const rect = el.getBoundingClientRect();
      const span = document.createElement('span');
      span.textContent = label;
      
      // Styled to match your Catppuccin Mocha aesthetic
      span.style.cssText = `
        position: absolute;
        left: ${window.scrollX + rect.left}px;
        top: ${window.scrollY + rect.top}px;
        background: #d4a34b;
        color: #090a0d;
        padding: 2px 4px;
        font-size: 12px;
        font-weight: 800;
        font-family: 'JetBrainsMono Nerd Font', monospace;
        border-radius: 4px;
        box-shadow: 0 3px 6px rgba(0,0,0,0.6);
        text-transform: uppercase;
      `;
      
      hintContainer.appendChild(span);
      return { label, el, span };
    });
    
    document.body.appendChild(hintContainer);
  }

  function removeHints() {
    if (hintContainer) hintContainer.remove();
    isHinting = false;
    hints = [];
    typedKeys = '';
  }

  // Use the capturing phase to intercept keys before the web app processes them
  document.addEventListener('keydown', (e) => {
    const active = document.activeElement;
    const isInput = active && (active.tagName === 'INPUT' || active.tagName === 'TEXTAREA' || active.isContentEditable);

    // --- MODE: LINK HINTING ---
    if (isHinting) {
      e.preventDefault();
      e.stopPropagation();
      
      if (e.key === 'Escape') {
        removeHints();
        return;
      }
      
      if (e.key === 'Backspace') {
        typedKeys = typedKeys.slice(0, -1);
      } else if (e.key.length === 1 && HINT_CHARS.includes(e.key.toUpperCase())) {
        typedKeys += e.key.toUpperCase();
      }
      
      let matches = 0;
      let lastMatch = null;
      
      // Filter hints visually as you type
      hints.forEach(h => {
        if (h.label.startsWith(typedKeys)) {
          h.span.style.opacity = '1';
          // Grey out the letters that have already been typed
          h.span.innerHTML = `<span style="opacity: 0.4">${typedKeys}</span>${h.label.slice(typedKeys.length)}`;
          matches++;
          lastMatch = h;
        } else {
          h.span.style.opacity = '0';
        }
      });
      
      // If we narrowed it down to exactly one element, click it!
      if (matches === 1 && lastMatch.label === typedKeys) {
        lastMatch.el.focus();
        lastMatch.el.click();
        removeHints();
      } else if (matches === 0) {
        removeHints();
      }
      return;
    }

    // --- MODE: INSERT / INPUT ---
    if (isInput) {
      if (e.key === 'Escape') {
        active.blur(); // Exit insert mode by dropping focus
      }
      return;
    }
    
    // --- MODE: NORMAL ---
    const step = 60;
    
    switch(e.key) {
      case 'j': window.scrollBy({ top: step, behavior: 'smooth' }); break;
      case 'k': window.scrollBy({ top: -step, behavior: 'smooth' }); break;
      case 'h': window.scrollBy({ left: -step, behavior: 'smooth' }); break;
      case 'l': window.scrollBy({ left: step, behavior: 'smooth' }); break;
      case 'd': if (e.ctrlKey) window.scrollBy({ top: window.innerHeight / 2, behavior: 'smooth' }); break;
      case 'u': if (e.ctrlKey) window.scrollBy({ top: -(window.innerHeight / 2), behavior: 'smooth' }); break;
      case 'G': if (e.shiftKey) window.scrollTo({ top: document.body.scrollHeight, behavior: 'smooth' }); break;
      case 'g': 
        if (lastKey === 'g') window.scrollTo({ top: 0, behavior: 'smooth' }); 
        break;
      case 'f': 
        showHints(); 
        e.preventDefault(); 
        break;
    }
    
    lastKey = e.key;
  }, true);
})();
