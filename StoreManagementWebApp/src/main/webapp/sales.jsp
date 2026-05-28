<%@page contentType="text/html" pageEncoding="UTF-8" isELIgnored="true"%>
<%@include file="includes/auth.jsp"%>
<% 
  request.setAttribute("activePage", "sales");
  request.setAttribute("pageTitle", "Sales Management");
%>
<!DOCTYPE html>
<html>
<head>
  <title>Sales Management — BSiET Store</title>
  <%@include file="includes/header.jsp"%>
  <link rel="stylesheet" href="css/sales.css" />
</head>
<body>

<div class="app">
  <%@include file="includes/sidebar.jsp"%>
  <main class="main">
    <%@include file="includes/topbar.jsp"%>

    <div class="page-content">

      <!-- ── SUMMARY CARDS ── -->
      <div class="stat-grid" id="summaryCards">
        <div class="stat-card">
          <div class="stat-icon blue">💳</div>
          <div>
            <div class="stat-label">Total Sales</div>
            <div class="stat-value" id="sc-total">0</div>
          </div>
        </div>
        <div class="stat-card">
          <div class="stat-icon green">💰</div>
          <div>
            <div class="stat-label">Total Revenue</div>
            <div class="stat-value" id="sc-revenue">₹0</div>
          </div>
        </div>
        <div class="stat-card">
          <div class="stat-icon orange">📦</div>
          <div>
            <div class="stat-label">Items Sold Today</div>
            <div class="stat-value" id="sc-today">0</div>
          </div>
        </div>
        <div class="stat-card">
          <div class="stat-icon purple">🎓</div>
          <div>
            <div class="stat-label">Top Buyer Type</div>
            <div class="stat-value" id="sc-buyer" style="font-size:16px;">—</div>
          </div>
        </div>
      </div>

      <!-- ── TWO-COLUMN LAYOUT ── -->
      <div class="sales-layout">

        <!-- ── LEFT: ENTRY FORM ── -->
        <div class="form-panel">
          <div class="panel-head">
            <span class="panel-head-icon">➕</span>
            <span id="form-panel-title">Record New Sale</span>
          </div>

          <input type="hidden" id="edit-index" value="" />

          <div class="form-group">
            <label>Sale Date <span class="req">*</span></label>
            <input class="form-control" type="date" id="f-date" />
          </div>

          <div class="form-group">
            <label>Product / Item Name <span class="req">*</span></label>
            <input class="form-control" type="text" id="f-product"
                   placeholder="e.g. Notebook, Pen, USB Cable"
                   list="product-list" autocomplete="off" />
            <datalist id="product-list">
<%
    try(java.sql.Connection con = com.store.util.DBConnection.getConnection();
        java.sql.Statement st = con.createStatement();
        java.sql.ResultSet rs = st.executeQuery("SELECT name FROM products ORDER BY name")) {
        while(rs.next()) {
            out.print("<option value=\"" + rs.getString("name") + "\">\n");
        }
    } catch(Exception e){}
%>
            </datalist>
          </div>

          <div class="form-row-2">
            <div class="form-group">
              <label>Quantity <span class="req">*</span></label>
              <input class="form-control" type="number" id="f-qty" min="1" placeholder="0" oninput="calcTotal()" />
            </div>
            <div class="form-group">
              <label>Unit Price (₹) <span class="req">*</span></label>
              <input class="form-control" type="number" id="f-price" min="0" step="0.01" placeholder="0.00" oninput="calcTotal()" />
            </div>
          </div>

          <!-- Live total preview -->
          <div class="total-preview" id="total-preview">
            <span>Total Amount</span>
            <strong id="preview-amount">₹ 0.00</strong>
          </div>

          <div class="form-group">
            <label>Purchased By <span class="req">*</span></label>
            <div class="buyer-chips">
              <label class="chip">
                <input type="radio" name="buyer-type" value="Student" checked />
                <span>🎓 Student</span>
              </label>
              <label class="chip">
                <input type="radio" name="buyer-type" value="Department" />
                <span>🏢 Department</span>
              </label>
              <label class="chip">
                <input type="radio" name="buyer-type" value="Faculty" />
                <span>👩‍🏫 Faculty</span>
              </label>
              <label class="chip">
                <input type="radio" name="buyer-type" value="College" />
                <span>🏫 College</span>
              </label>
            </div>
          </div>

          <div class="form-group">
            <label>Buyer Name / ID</label>
            <input class="form-control" type="text" id="f-buyer" placeholder="e.g. Ravi Kumar / CS-2024-01" />
          </div>

          <div class="form-group">
            <label>Remarks</label>
            <textarea class="form-control form-textarea" id="f-remarks" placeholder="Optional notes…"></textarea>
          </div>

          <div id="form-error" class="form-error" style="display:none;"></div>

          <div class="form-actions">
            <button class="btn-success" onclick="submitSale()">
              <i class="bi bi-check-lg"></i> <span id="submit-label">Record Sale</span>
            </button>
            <button class="btn-secondary" onclick="resetForm()"><i class="bi bi-x-lg"></i> Clear</button>
          </div>
        </div><!-- /form-panel -->

        <!-- ── RIGHT: TABLES & CHARTS ── -->
        <div class="right-col">

          <!-- Per-product summary -->
          <div class="panel-card" style="margin-bottom:20px;">
            <div class="panel-header">
              <span class="panel-title">📊 Units Sold per Product</span>
              <span class="badge-count" id="product-count">0 products</span>
            </div>
            <div id="product-bars">
              <div class="empty-state">No sales recorded yet.</div>
            </div>
          </div>

          <!-- Filter row -->
          <div class="filter-row">
            <div class="filter-group">
              <label>From</label>
              <input class="form-control filter-input" type="date" id="filter-from" onchange="renderTable()" />
            </div>
            <div class="filter-group">
              <label>To</label>
              <input class="form-control filter-input" type="date" id="filter-to" onchange="renderTable()" />
            </div>
            <div class="filter-group">
              <label>Buyer Type</label>
              <select class="form-control filter-input" id="filter-buyer" onchange="renderTable()">
                <option value="">All</option>
                <option>Student</option>
                <option>Department</option>
                <option>Faculty</option>
                <option>College</option>
              </select>
            </div>
            <button class="btn-secondary" style="align-self:flex-end;" onclick="clearFilters()"><i class="bi bi-x-lg"></i> Clear</button>
            <button class="btn-primary" style="align-self:flex-end;" onclick="exportCSV()"><i class="bi bi-download"></i> Export CSV</button>
          </div>

          <!-- Date-wise sales table -->
          <div class="data-table">
            <table id="sales-table">
              <thead>
                <tr>
                  <th onclick="sortTable('date')" class="sortable">Date ⇅</th>
                  <th onclick="sortTable('product')" class="sortable">Product ⇅</th>
                  <th>Qty</th>
                  <th>Unit ₹</th>
                  <th>Total ₹</th>
                  <th onclick="sortTable('buyerType')" class="sortable">Buyer ⇅</th>
                  <th>Buyer Name</th>
                  <th>Remarks</th>
                  <th>Action</th>
                </tr>
              </thead>
              <tbody id="sales-tbody">
                <tr>
                  <td colspan="9" class="empty-state">No sales recorded yet. Use the form to add a sale.</td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Date-group totals footer -->
          <div id="date-totals" class="date-totals-wrap"></div>

        </div><!-- /right-col -->
      </div><!-- /sales-layout -->

    </div><!-- /page-content -->

  </main>
</div>

<!-- ══ SUCCESS TOAST ══ -->
<div class="toast" id="toast"></div>

<!-- ══════════════════════════════════════
     JAVASCRIPT
══════════════════════════════════════ -->
<script>
let sales = [];
let sortKey = 'date';
let sortAsc  = false;

window.addEventListener('DOMContentLoaded', () => {
  document.getElementById('f-date').valueAsDate = new Date();
  fetchData();
});

function fetchData() {
  fetch('<%=request.getContextPath()%>/api/sales')
    .then(res => res.json())
    .then(data => {
      if(data.error) {
         console.error(data.error);
         return;
      }
      sales = data;
      renderAll();
    });
}

function calcTotal() {
  const qty   = parseFloat(document.getElementById('f-qty').value)   || 0;
  const price = parseFloat(document.getElementById('f-price').value) || 0;
  document.getElementById('preview-amount').textContent =
    '₹ ' + (qty * price).toFixed(2);
}

function submitSale() {
  const date      = document.getElementById('f-date').value.trim();
  const product   = document.getElementById('f-product').value.trim();
  const qty       = parseFloat(document.getElementById('f-qty').value);
  const price     = parseFloat(document.getElementById('f-price').value);
  const buyerType = document.querySelector('input[name="buyer-type"]:checked').value;
  const buyer     = document.getElementById('f-buyer').value.trim();
  const remarks   = document.getElementById('f-remarks').value.trim();
  const errEl     = document.getElementById('form-error');

  if (!date || !product || isNaN(qty) || qty < 1 || isNaN(price) || price < 0) {
    errEl.textContent = '⚠ Please fill Date, Product, Quantity (≥1), and Price correctly.';
    errEl.style.display = 'block';
    return;
  }
  errEl.style.display = 'none';

  const data = new URLSearchParams();
  const editIdx = document.getElementById('edit-index').value;
  if (editIdx !== '') {
    data.append('id', sales[parseInt(editIdx)].id);
  }
  data.append('date', date);
  data.append('product', product);
  data.append('qty', qty);
  data.append('price', price);
  data.append('buyerType', buyerType);
  data.append('buyer', buyer);
  data.append('remarks', remarks);

  fetch('<%=request.getContextPath()%>/api/sales', { method: 'POST', body: data })
    .then(res => res.json())
    .then(res => {
      if(res.success) {
        showToast(editIdx !== '' ? 'Sale updated successfully!' : 'Sale recorded successfully!');
        resetForm();
        fetchData();
      } else {
        errEl.textContent = '⚠ ' + res.error;
        errEl.style.display = 'block';
      }
    }).catch(err => {
        errEl.textContent = '⚠ Failed to communicate with server.';
        errEl.style.display = 'block';
    });
}

function editSale(idx) {
  const r = filtered()[idx];
  const realIdx = sales.indexOf(r);

  document.getElementById('f-date').value    = r.date;
  document.getElementById('f-product').value = r.product;
  document.getElementById('f-qty').value     = r.qty;
  document.getElementById('f-price').value   = r.price;
  document.getElementById('f-buyer').value   = r.buyer;
  document.getElementById('f-remarks').value = r.remarks;
  
  const radio = document.querySelector(`input[name="buyer-type"][value="${r.buyerType}"]`);
  if (radio) radio.checked = true;

  document.getElementById('edit-index').value = realIdx;
  document.getElementById('form-panel-title').textContent = 'Edit Sale Record';
  document.getElementById('submit-label').textContent = 'Update Sale';
  calcTotal();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function deleteSale(idx) {
  if (!confirm('Delete this sale record?')) return;
  const r = filtered()[idx];
  
  fetch('<%=request.getContextPath()%>/api/sales?action=delete&id=' + r.id, { method: 'POST' })
    .then(res => res.json())
    .then(res => {
      if(res.success) {
        showToast('Record deleted.');
        fetchData();
      } else {
        alert("Error: " + res.error);
      }
    });
}

function resetForm() {
  ['f-date','f-product','f-qty','f-price','f-buyer','f-remarks'].forEach(id => {
    document.getElementById(id).value = '';
  });
  document.getElementById('f-date').valueAsDate = new Date();
  document.querySelector('input[name="buyer-type"][value="Student"]').checked = true;
  document.getElementById('edit-index').value = '';
  document.getElementById('form-panel-title').textContent = 'Record New Sale';
  document.getElementById('submit-label').textContent = 'Record Sale';
  document.getElementById('preview-amount').textContent = '₹ 0.00';
  document.getElementById('form-error').style.display = 'none';
}

function filtered() {
  const from  = document.getElementById('filter-from').value;
  const to    = document.getElementById('filter-to').value;
  const buyer = document.getElementById('filter-buyer').value;
  const q     = (document.getElementById('globalSearch')?.value || '').toLowerCase();

  return sales.filter(r => {
    if (from && r.date < from) return false;
    if (to   && r.date > to)   return false;
    if (buyer && r.buyerType !== buyer) return false;
    if (q && !(r.product.toLowerCase().includes(q) ||
               (r.buyer && r.buyer.toLowerCase().includes(q)) ||
               (r.buyerType && r.buyerType.toLowerCase().includes(q)))) return false;
    return true;
  });
}

function clearFilters() {
  ['filter-from','filter-to'].forEach(id => document.getElementById(id).value = '');
  document.getElementById('filter-buyer').value = '';
  const search = document.getElementById('globalSearch');
  if(search) search.value = '';
  renderAll();
}

window.globalFilter = function(v) { renderAll(); }; // Attach if globalSearch uses it

function sortTable(key) {
  if (sortKey === key) sortAsc = !sortAsc;
  else { sortKey = key; sortAsc = true; }
  renderTable();
}

function renderAll() {
  renderTable();
  renderProductBars();
  renderSummaryCards();
}

function renderTable() {
  let rows = [...filtered()];
  rows.sort((a, b) => {
    let va = a[sortKey] ?? '', vb = b[sortKey] ?? '';
    if (typeof va === 'string') va = va.toLowerCase(), vb = vb.toLowerCase();
    if (va < vb) return sortAsc ? -1 : 1;
    if (va > vb) return sortAsc ?  1 : -1;
    return 0;
  });

  const tbody = document.getElementById('sales-tbody');

  if (rows.length === 0) {
    tbody.innerHTML = '<tr><td colspan="9" class="empty-state">No matching sales records found.</td></tr>';
    document.getElementById('date-totals').innerHTML = '';
    return;
  }

  const byDate = {};
  rows.forEach(r => {
    if (!byDate[r.date]) byDate[r.date] = { qty: 0, total: 0, count: 0 };
    byDate[r.date].qty   += r.qty;
    byDate[r.date].total += r.total;
    byDate[r.date].count++;
  });

  tbody.innerHTML = rows.map((r, i) => {
    const buyerClass = {
      Student: 'chip-student', Department: 'chip-dept',
      Faculty: 'chip-faculty', College: 'chip-college'
    }[r.buyerType] || '';

    return `<tr>
      <td><span class="date-cell">${formatDate(r.date)}</span></td>
      <td><strong>${esc(r.product)}</strong></td>
      <td>${r.qty}</td>
      <td>₹${r.price.toFixed(2)}</td>
      <td class="total-cell">₹${r.total.toFixed(2)}</td>
      <td><span class="buyer-chip ${buyerClass}">${r.buyerType}</span></td>
      <td>${esc(r.buyer) || '—'}</td>
      <td class="remarks-cell">${esc(r.remarks) || '—'}</td>
      <td>
        <button class="action-link" onclick="editSale(${i})">Edit</button>
        <button class="action-link delete" onclick="deleteSale(${i})">Del</button>
      </td>
    </tr>`;
  }).join('');

  const totalsHtml = Object.entries(byDate)
    .sort((a,b) => b[0].localeCompare(a[0]))
    .map(([date, d]) => `
      <div class="date-total-row">
        <span class="dt-date">${formatDate(date)}</span>
        <span class="dt-pill">${d.count} sale${d.count>1?'s':''}</span>
        <span class="dt-pill">${d.qty} units</span>
        <span class="dt-revenue">₹${d.total.toFixed(2)}</span>
      </div>`)
    .join('');

  document.getElementById('date-totals').innerHTML =
    `<div class="date-totals-title">Date-wise Revenue Summary</div>${totalsHtml}`;
}

function renderProductBars() {
  const rows = filtered();
  const barsEl = document.getElementById('product-bars');

  if (rows.length === 0) {
    barsEl.innerHTML = '<div class="empty-state">No sales recorded yet.</div>';
    document.getElementById('product-count').textContent = '0 products';
    return;
  }

  const map = {};
  rows.forEach(r => {
    if (!map[r.product]) map[r.product] = { qty: 0, revenue: 0 };
    map[r.product].qty     += r.qty;
    map[r.product].revenue += r.total;
  });

  const items  = Object.entries(map).sort((a,b) => b[1].qty - a[1].qty);
  const maxQty = items[0][1].qty;

  document.getElementById('product-count').textContent = items.length + ' product' + (items.length > 1 ? 's' : '');

  const colors = ['#3b82f6','#22c55e','#f59e0b','#a78bfa','#ef4444',
                  '#06b6d4','#f97316','#ec4899','#84cc16','#8b5cf6'];

  barsEl.innerHTML = items.map(([name, d], i) => {
    const pct = Math.round((d.qty / maxQty) * 100);
    const col = colors[i % colors.length];
    return `
      <div class="bar-row">
        <div class="bar-label">
          <span class="bar-name">${esc(name)}</span>
          <span class="bar-stats">${d.qty} units &nbsp;·&nbsp; ₹${d.revenue.toFixed(0)}</span>
        </div>
        <div class="bar-track">
          <div class="bar-fill" style="width:${pct}%;background:${col};" title="${d.qty} units"></div>
        </div>
      </div>`;
  }).join('');
}

function renderSummaryCards() {
  const rows = filtered();
  const today = new Date().toISOString().slice(0,10);

  const total   = rows.length;
  const revenue = rows.reduce((s, r) => s + r.total, 0);
  const todayQ  = rows.filter(r => (r.date||'').startsWith(today)).reduce((s,r)=>s+r.qty, 0);

  const btCount = {};
  rows.forEach(r => btCount[r.buyerType] = (btCount[r.buyerType]||0)+1);
  const topBuyer = Object.entries(btCount).sort((a,b)=>b[1]-a[1])[0]?.[0] || '—';

  document.getElementById('sc-total').textContent   = total;
  document.getElementById('sc-revenue').textContent = '₹' + revenue.toFixed(0);
  document.getElementById('sc-today').textContent   = todayQ;
  document.getElementById('sc-buyer').textContent   = topBuyer;
}

function exportCSV() {
  const rows = filtered();
  if (!rows.length) { showToast('No data to export.'); return; }

  const header = ['Date','Product','Qty','Unit Price','Total','Buyer Type','Buyer Name','Remarks'];
  const lines  = [header.join(',')].concat(
    rows.map(r => [r.date, r.product, r.qty, r.price, r.total, r.buyerType, r.buyer, r.remarks]
      .map(v => '"' + String(v ?? '').replace(/"/g,'""') + '"').join(','))
  );

  const blob = new Blob([lines.join('\n')], {type:'text/csv'});
  const url  = URL.createObjectURL(blob);
  const a    = document.createElement('a');
  a.href = url; a.download = 'bsiet_sales.csv'; a.click();
  URL.revokeObjectURL(url);
}

function esc(str) {
  return String(str ?? '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}

function formatDate(d) {
  if (!d) return '—';
  // Attempt to parse YYYY-MM-DD
  const parts = d.split('-');
  if(parts.length < 3) return d;
  const y = parts[0], m = parts[1], day = parts[2].substring(0, 2);
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return `${day} ${months[+m-1]} ${y}`;
}

function showToast(msg) {
  const t = document.getElementById('toast');
  t.textContent = msg;
  t.classList.add('show');
  setTimeout(() => t.classList.remove('show'), 2800);
}
</script>

</body>
</html>
