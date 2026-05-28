<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@include file="includes/auth.jsp"%>
<%
    request.setAttribute("activePage", "reports");
    request.setAttribute("pageTitle", "Reports");
%>
<!DOCTYPE html>
<html>
<head>
    <title>Reports</title>
    <%@include file="includes/header.jsp"%>
    <script>
        const reportSubcategories = {
            products: [
                ["all", "All Products"],
                ["in_stock", "In Stock"],
                ["low_stock", "Low Stock"],
                ["out_of_stock", "Out of Stock"],
                ["tech", "Tech Category"],
                ["fashion", "Fashion Category"],
                ["electronic", "Electronic Category"],
                ["stationery", "Stationery Category"]
            ],
            requirements: [
                ["all", "All Requirements"],
                ["pending", "Pending Requirements"],
                ["approved", "Approved Requirements"],
                ["rejected", "Rejected Requirements"]
            ],
            approvals: [
                ["all", "All Approvals"],
                ["approved", "Approved"],
                ["rejected", "Rejected"],
                ["pending", "Pending"]
            ],
            purchase_orders: [
                ["all", "All Purchase Orders"],
                ["generated", "Generated"],
                ["pending", "Pending"],
                ["completed", "Completed"]
            ],
            received_items: [
                ["all", "All Received Items"]
            ],
            item_transfers: [
                ["all", "All Department Transfers"],
                ["issue", "Issued Items"],
                ["replacement", "Replacement Transfers"],
                ["temporary_transfer", "Temporary Transfers"],
                ["return_adjustment", "Return Adjustments"]
            ],
            scrap_items: [
                ["all", "All Scrap Items"],
                ["damaged", "Damaged"],
                ["non_working", "Non-working"],
                ["broken", "Broken"],
                ["expired", "Expired"],
                ["unusable", "Unusable"],
                ["obsolete", "Obsolete"]
            ],
            invoices: [
                ["all", "All Invoices / Bills"],
                ["pending", "Pending Payment"],
                ["partial_payment", "Partial Payment"],
                ["paid", "Paid"]
            ],
            payments: [
                ["all", "All Payments"],
                ["pending", "Pending"],
                ["partial_payment", "Partial Payment"],
                ["paid", "Paid"]
            ],
            suppliers: [
                ["all", "All Suppliers"]
            ],
            users: [
                ["all", "All Users"],
                ["admin", "Administrators"],
                ["store", "Store Managers"],
                ["director", "Directors"],
                ["user", "Department Users"]
            ]
        };

        function updateSubcategories() {
            const category = document.getElementById("reportCategory").value;
            const subSelect = document.getElementById("reportSubcategory");
            subSelect.innerHTML = "";
            reportSubcategories[category].forEach(item => {
                const option = document.createElement("option");
                option.value = item[0];
                option.textContent = item[1];
                subSelect.appendChild(option);
            });
        }

        function downloadReport(format) {
            const category = document.getElementById("reportCategory").value;
            const subcategory = document.getElementById("reportSubcategory").value;
            const url = "<%=request.getContextPath()%>/reportExport?category=" +
                encodeURIComponent(category) + "&subcategory=" +
                encodeURIComponent(subcategory) + "&format=" + encodeURIComponent(format);
            window.location.href = url;
        }

        window.addEventListener("DOMContentLoaded", updateSubcategories);
    </script>
</head>
<body>
<div class="app">
    <%@include file="includes/sidebar.jsp"%>
    <main class="main">
        <%@include file="includes/topbar.jsp"%>

        <div class="page-title-section">
            <div>
                <h2>Institutional Reports</h2>
                <p class="role-line">Dr. Bapuji Salunkhe Institute of Engineering and Technology</p>
            </div>
        </div>

        <div class="form-card" style="margin-bottom:20px;">
            <h3 style="margin-bottom:16px;">Generate Category-wise and Subcategory-wise Report</h3>
            <div class="cat-layout" style="grid-template-columns: 1fr 1fr; gap:18px;">
                <div class="form-group">
                    <label>Report Category</label>
                    <select class="form-control" id="reportCategory" onchange="updateSubcategories()">
                        <option value="products">Products / Inventory</option>
                        <option value="requirements">Department Requirements</option>
                        <option value="approvals">Approvals</option>
                        <option value="purchase_orders">Purchase Orders</option>
                        <option value="received_items">Received Items</option>
                        <option value="item_transfers">Department Transfers</option>
                        <option value="scrap_items">Scrap Items</option>
                        <option value="invoices">Invoices / Bills</option>
                        <option value="payments">Payments</option>
                        <option value="suppliers">Suppliers</option>
                        <option value="users">Users</option>
                    </select>
                </div>

                <div class="form-group">
                    <label>Subcategory / Filter</label>
                    <select class="form-control" id="reportSubcategory"></select>
                </div>
            </div>

            <div class="form-actions" style="justify-content:flex-start; margin-top:8px;">
                <button class="btn-success" type="button" onclick="downloadReport('excel')">
                    <i class="bi bi-file-earmark-excel-fill"></i> Download Excel
                </button>
                <button class="btn-danger" type="button" onclick="downloadReport('pdf')">
                    <i class="bi bi-file-earmark-pdf-fill"></i> Download PDF
                </button>
            </div>
            <p class="file-note">The downloaded report will include the college name, selected category, subcategory, date/time, and matching database records.</p>
        </div>

        <div class="stat-grid">
            <%
                try (java.sql.Connection con = com.store.util.DBConnection.getConnection();
                     java.sql.Statement st = con.createStatement()) {
                    java.sql.ResultSet rs;
                    rs = st.executeQuery("SELECT COUNT(*) c FROM products"); rs.next(); int productCount = rs.getInt("c");
                    rs = st.executeQuery("SELECT COALESCE(SUM(quantity),0) c FROM products"); rs.next(); int stockCount = rs.getInt("c");
                    rs = st.executeQuery("SELECT COUNT(*) c FROM requirements WHERE status='Pending'"); rs.next(); int pendingReq = rs.getInt("c");
                    rs = st.executeQuery("SELECT COUNT(*) c FROM invoice_documents WHERE LOWER(payment_status) <> 'paid'"); rs.next(); int pendingPay = rs.getInt("c");
            %>
            <div class="stat-card"><div class="stat-icon blue"><i class="bi bi-box-seam-fill"></i></div><div><div class="stat-label">Total Products</div><div class="stat-value"><%= productCount %></div></div></div>
            <div class="stat-card"><div class="stat-icon green"><i class="bi bi-stack"></i></div><div><div class="stat-label">Total Stock</div><div class="stat-value"><%= stockCount %></div></div></div>
            <div class="stat-card"><div class="stat-icon orange"><i class="bi bi-hourglass-split"></i></div><div><div class="stat-label">Pending Requirements</div><div class="stat-value"><%= pendingReq %></div></div></div>
            <div class="stat-card"><div class="stat-icon purple"><i class="bi bi-currency-rupee"></i></div><div><div class="stat-label">Pending Payments</div><div class="stat-value"><%= pendingPay %></div></div></div>
            <% } catch (Exception e) { %>
            <div class="access-alert">Report summary loading error: <%= e.getMessage() %></div>
            <% } %>
        </div>

        <div class="data-table">
            <table>
                <thead>
                    <tr>
                        <th>Report Category</th>
                        <th>Useful For</th>
                        <th>Available Downloads</th>
                    </tr>
                </thead>
                <tbody>
                    <tr><td>Products / Inventory</td><td>Stock verification, low stock and category-wise inventory review</td><td>PDF, Excel</td></tr>
                    <tr><td>Requirements</td><td>Department-wise requirement tracking and pending request review</td><td>PDF, Excel</td></tr>
                    <tr><td>Approvals</td><td>Director approval/rejection monitoring</td><td>PDF, Excel</td></tr>
                    <tr><td>Purchase Orders</td><td>PO generation and supplier purchase tracking</td><td>PDF, Excel</td></tr>
                    <tr><td>Received Items</td><td>Goods receipt verification and inventory update support</td><td>PDF, Excel</td></tr>
                    <tr><td>Invoices / Bills</td><td>Scanned bill and invoice status review</td><td>PDF, Excel</td></tr>
                    <tr><td>Payments</td><td>Paid, pending and partial payment monitoring</td><td>PDF, Excel</td></tr>
                </tbody>
            </table>
        </div>
    </main>
</div>
</body>
</html>
