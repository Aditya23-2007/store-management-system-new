function filterTable(tableId, query){const q=(query||'').toLowerCase();document.querySelectorAll('#'+tableId+' tbody tr').forEach(r=>{r.style.display=r.textContent.toLowerCase().includes(q)?'':'none';});}
function openModal(id){document.getElementById(id).classList.add('open');}
function closeModal(id){document.getElementById(id).classList.remove('open');}
function deleteRow(btn){if(confirm('Are you sure you want to delete this entry?')) btn.closest('tr').remove();}
document.addEventListener('click',e=>{if(e.target.classList.contains('modal-overlay')) e.target.classList.remove('open');});

/* Dynamic automatic logout after inactivity: 10 to 90 minutes */
(function(){
  const STORAGE_KEY = 'store_auto_logout_minutes';
  const DEFAULT_MINUTES = 10;
  const MIN_ALLOWED = 10;
  const MAX_ALLOWED = 90;
  let logoutTimer = null;

  function getContextPath(){
    const parts = window.location.pathname.split('/').filter(Boolean);
    return parts.length ? '/' + parts[0] : '';
  }

  function normalizeMinutes(value){
    let minutes = parseInt(value, 10);
    if(isNaN(minutes)) minutes = DEFAULT_MINUTES;
    if(minutes < MIN_ALLOWED) minutes = MIN_ALLOWED;
    if(minutes > MAX_ALLOWED) minutes = MAX_ALLOWED;
    return minutes;
  }

  function getMinutes(){
    return normalizeMinutes(localStorage.getItem(STORAGE_KEY) || DEFAULT_MINUTES);
  }

  function setMinutes(value){
    const minutes = normalizeMinutes(value);
    localStorage.setItem(STORAGE_KEY, String(minutes));
    return minutes;
  }

  function redirectToLogout(){
    alert('Session expired due to inactivity. You will be logged out now.');
    window.location.href = getContextPath() + '/logout';
  }

  function resetAutoLogoutTimer(){
    clearTimeout(logoutTimer);
    const minutes = getMinutes();
    logoutTimer = setTimeout(redirectToLogout, minutes * 60 * 1000);
  }

  function setupSelector(){
    const selector = document.getElementById('autoLogoutMinutes');
    if(!selector) return;

    selector.value = String(getMinutes());
    selector.addEventListener('change', function(){
      setMinutes(this.value);
      resetAutoLogoutTimer();
    });
  }

  function setupActivityWatch(){
    ['click','mousemove','keydown','scroll','touchstart','input'].forEach(eventName => {
      document.addEventListener(eventName, resetAutoLogoutTimer, {passive:true});
    });
    resetAutoLogoutTimer();
  }

  document.addEventListener('DOMContentLoaded', function(){
    setupSelector();
    setupActivityWatch();
  });
})();
