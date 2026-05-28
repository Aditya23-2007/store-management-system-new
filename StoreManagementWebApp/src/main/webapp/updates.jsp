<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@include file="includes/auth.jsp"%>
<%
    request.setAttribute("activePage", "updates");
    request.setAttribute("pageTitle", "System Updates");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <title>System Updates</title>
    <%@include file="includes/header.jsp"%>
    <style>
        .updates-container {
            display: grid;
            grid-template-columns: 1fr 340px;
            gap: 20px;
        }
        .tabs-header {
            display: flex;
            border-bottom: 2px solid var(--border);
            margin-bottom: 22px;
            gap: 15px;
        }
        .tab-btn {
            background: none;
            border: none;
            border-bottom: 3px solid transparent;
            padding: 10px 16px;
            cursor: pointer;
            font-weight: 700;
            font-size: 16px;
            color: var(--muted);
            transition: all 0.3s ease;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .tab-btn:hover {
            color: var(--blue);
        }
        .tab-btn.active {
            color: var(--blue);
            border-bottom-color: var(--blue);
        }
        .tab-content {
            display: none;
        }
        .tab-content.active {
            display: block;
            animation: fadeIn 0.4s ease;
        }
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(6px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .quick-path-list {
            display: flex;
            flex-direction: column;
            gap: 8px;
            margin-top: 10px;
        }
        .quick-path-item {
            background: #f8fafc;
            border: 1px solid var(--border);
            border-radius: 8px;
            padding: 10px 12px;
            cursor: pointer;
            font-size: 13px;
            font-family: monospace;
            transition: all 0.2s ease;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .quick-path-item:hover {
            background: #eff6ff;
            border-color: var(--blue);
            color: var(--blue);
        }
        .terminal-panel {
            background: #0f172a;
            color: #38bdf8;
            font-family: 'Courier New', Courier, monospace;
            border-radius: 12px;
            padding: 18px;
            margin-top: 24px;
            box-shadow: inset 0 2px 8px rgba(0,0,0,0.8);
            border: 1px solid #1e293b;
        }
        .terminal-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid #1e293b;
            padding-bottom: 8px;
            margin-bottom: 12px;
            font-size: 12px;
            color: #64748b;
        }
        .terminal-dots {
            display: flex;
            gap: 6px;
        }
        .dot {
            width: 10px;
            height: 10px;
            border-radius: 50%;
        }
        .dot-red { background: #ef4444; }
        .dot-yellow { background: #eab308; }
        .dot-green { background: #22c55e; }
        .terminal-body {
            max-height: 180px;
            overflow-y: auto;
            white-space: pre-wrap;
            font-size: 13px;
            line-height: 1.5;
        }
        .alert-toast {
            border-radius: 12px;
            padding: 14px 18px;
            margin-bottom: 22px;
            font-weight: 700;
            display: flex;
            align-items: flex-start;
            gap: 12px;
            animation: fadeIn 0.3s ease;
        }
        .alert-toast.success {
            background: #dcfce7;
            color: #15803d;
            border: 1px solid #bbf7d0;
        }
        .alert-toast.error {
            background: #fee2e2;
            color: #b91c1c;
            border: 1px solid #fecaca;
        }
        .alert-toast i {
            font-size: 20px;
        }
    </style>
</head>
<body>
<div class="app">
    <%@include file="includes/sidebar.jsp"%>
    <main class="main">
        <%@include file="includes/topbar.jsp"%>

        <!-- Response Messages -->
        <%
            String msgType = (String) session.getAttribute("update_msg_type");
            String msgText = (String) session.getAttribute("update_msg_text");
            if (msgType != null && msgText != null) {
                session.removeAttribute("update_msg_type");
                session.removeAttribute("update_msg_text");
        %>
            <div class="alert-toast <%= msgType %>">
                <div>
                    <% if ("success".equals(msgType)) { %>
                        <i class="bi bi-check-circle-fill"></i>
                    <% } else { %>
                        <i class="bi bi-exclamation-triangle-fill"></i>
                    <% } %>
                </div>
                <div>
                    <div><%= "success".equals(msgType) ? "Operation Succeeded" : "Operation Failed" %></div>
                    <div style="font-weight: normal; margin-top: 4px; font-size: 14px;"><%= msgText.replace("\n", "<br>") %></div>
                </div>
            </div>
        <% } %>

        <div class="updates-container">
            <!-- Forms and Console Panel -->
            <div class="panel-card">
                <div class="tabs-header">
                    <button class="tab-btn active" onclick="switchTab('db-tab')">
                        <i class="bi bi-database-fill-gear"></i> Database Update
                    </button>
                    <button class="tab-btn" onclick="switchTab('file-tab')">
                        <i class="bi bi-file-earmark-code-fill"></i> File Hotpatcher
                    </button>
                </div>

                <!-- Database Tab -->
                <div id="db-tab" class="tab-content active">
                    <form action="admin/update" method="post" enctype="multipart/form-data">
                        <input type="hidden" name="action" value="sql">
                        
                        <div class="form-group">
                            <label>Execute SQL Script File (.sql)</label>
                            <input type="file" name="sql_file" class="form-control" accept=".sql">
                            <div class="file-note">Upload schema migrations, index updates, or data seeds.</div>
                        </div>

                        <div style="text-align: center; margin: 18px 0; color: var(--muted); font-weight: 700; font-size: 13px;">OR</div>

                        <div class="form-group">
                            <label>Paste SQL Statements</label>
                            <textarea id="sql_query_area" name="sql_query" class="form-control textarea" style="font-family: monospace;" placeholder="ALTER TABLE sales ADD COLUMN buyer_email VARCHAR(100);&#10;CREATE INDEX idx_product_name ON products(name);"></textarea>
                            <div class="file-note">Multiple statements must be separated by semicolons (;).</div>
                        </div>

                        <div class="form-actions" style="margin-top: 24px;">
                            <button type="submit" class="btn-primary">
                                <i class="bi bi-play-circle-fill"></i> Execute SQL Commands
                            </button>
                        </div>
                    </form>
                </div>

                <!-- File Hotpatcher Tab -->
                <div id="file-tab" class="tab-content">
                    <form action="admin/update" method="post" enctype="multipart/form-data">
                        <input type="hidden" name="action" value="file">

                        <div class="form-group">
                            <label>Target File Path (Relative to Webapp root)</label>
                            <input type="text" id="target_path" name="target_path" class="form-control" placeholder="css/store.css" required>
                            <div class="file-note">Specify where to write the file, e.g. <code>css/store.css</code> or <code>dashboard.jsp</code>.</div>
                        </div>

                        <div class="form-group">
                            <label>Upload Replacement File</label>
                            <input type="file" name="upload_file" class="form-control" required>
                            <div class="file-note">Upload the updated file from your development environment.</div>
                        </div>

                        <div class="form-actions" style="margin-top: 24px;">
                            <button type="submit" class="btn-success">
                                <i class="bi bi-cloud-upload-fill"></i> Deploy File Patch
                            </button>
                        </div>
                    </form>
                </div>
            </div>

            <!-- Sidebar Info & Quick Paths -->
            <div class="panel-card" style="height: fit-content;">
                <!-- SQL Helper Sidebar -->
                <div id="db-sidebar">
                    <div class="modal-title" style="font-size: 18px; margin-bottom: 12px;">
                        <i class="bi bi-database-fill-check" style="color: var(--blue);"></i> SQL Helpers
                    </div>
                    <p style="font-size: 13px; color: var(--muted); line-height: 1.4; margin-bottom: 15px;">
                        Click a statement below to quickly copy it into the SQL input box:
                    </p>
                    <div class="quick-path-list">
                        <div class="quick-path-item" onclick="setSqlQuery('SHOW TABLES;')">
                            <span>SHOW TABLES;</span> <i class="bi bi-chevron-right"></i>
                        </div>
                        <div class="quick-path-item" onclick="setSqlQuery('DESCRIBE products;')">
                            <span>DESCRIBE products;</span> <i class="bi bi-chevron-right"></i>
                        </div>
                        <div class="quick-path-item" onclick="setSqlQuery('DESCRIBE sales;')">
                            <span>DESCRIBE sales;</span> <i class="bi bi-chevron-right"></i>
                        </div>
                        <div class="quick-path-item" onclick="setSqlQuery('SELECT COUNT(*) FROM users;')">
                            <span>SELECT COUNT(*) FROM users;</span> <i class="bi bi-chevron-right"></i>
                        </div>
                        <div class="quick-path-item" onclick="setSqlQuery('SHOW COLUMNS FROM requirements;')">
                            <span>SHOW COLUMNS FROM requirements;</span> <i class="bi bi-chevron-right"></i>
                        </div>
                    </div>
                </div>

                <!-- File Helper Sidebar (Initially Hidden) -->
                <div id="file-sidebar" style="display: none;">
                    <div class="modal-title" style="font-size: 18px; margin-bottom: 12px;">
                        <i class="bi bi-info-circle-fill" style="color: var(--blue);"></i> Quick Paths
                    </div>
                    <p style="font-size: 13px; color: var(--muted); line-height: 1.4; margin-bottom: 15px;">
                        Click a target file below to automatically pre-fill the Target Path field for patching:
                    </p>
                    <div class="quick-path-list">
                        <div class="quick-path-item" onclick="setPath('css/store.css')">
                            <span>css/store.css</span> <i class="bi bi-chevron-right"></i>
                        </div>
                        <div class="quick-path-item" onclick="setPath('js/store.js')">
                            <span>js/store.js</span> <i class="bi bi-chevron-right"></i>
                        </div>
                        <div class="quick-path-item" onclick="setPath('includes/sidebar.jsp')">
                            <span>includes/sidebar.jsp</span> <i class="bi bi-chevron-right"></i>
                        </div>
                        <div class="quick-path-item" onclick="setPath('includes/header.jsp')">
                            <span>includes/header.jsp</span> <i class="bi bi-chevron-right"></i>
                        </div>
                        <div class="quick-path-item" onclick="setPath('dashboard.jsp')">
                            <span>dashboard.jsp</span> <i class="bi bi-chevron-right"></i>
                        </div>
                        <div class="quick-path-item" onclick="setPath('products.jsp')">
                            <span>products.jsp</span> <i class="bi bi-chevron-right"></i>
                        </div>
                        <div class="quick-path-item" onclick="setPath('sales.jsp')">
                            <span>sales.jsp</span> <i class="bi bi-chevron-right"></i>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- SQL Logs Panel -->
        <div class="terminal-panel">
            <div class="terminal-header">
                <div class="terminal-dots">
                    <div class="dot dot-red"></div>
                    <div class="dot dot-yellow"></div>
                    <div class="dot dot-green"></div>
                </div>
                <span>Server Maintenance Console</span>
            </div>
            <div class="terminal-body" id="console-body">
                <% if (msgText != null) { %>
                    [Console Log - <%= new java.util.Date() %>]
                    <%= msgText %>
                <% } else { %>
                    Ready. Standing by for maintenance actions...
                <% } %>
            </div>
        </div>
    </main>
</div>

<script>
    function switchTab(tabId) {
        // Toggle tab buttons
        document.querySelectorAll('.tab-btn').forEach(btn => {
            btn.classList.remove('active');
        });
        event.currentTarget.classList.add('active');

        // Toggle tab content
        document.querySelectorAll('.tab-content').forEach(content => {
            content.classList.remove('active');
        });
        document.getElementById(tabId).classList.add('active');

        // Toggle sidebar content
        if (tabId === 'db-tab') {
            document.getElementById('db-sidebar').style.display = 'block';
            document.getElementById('file-sidebar').style.display = 'none';
        } else {
            document.getElementById('db-sidebar').style.display = 'none';
            document.getElementById('file-sidebar').style.display = 'block';
        }
    }

    function setPath(path) {
        // Pre-fill target path field and switch tab to hotpatcher
        document.getElementById('target_path').value = path;
        // Find the hotpatcher tab button and switch
        const fileTabBtn = document.querySelectorAll('.tab-btn')[1];
        fileTabBtn.click();
    }

    function setSqlQuery(query) {
        document.getElementById('sql_query_area').value = query;
    }
</script>
</body>
</html>
