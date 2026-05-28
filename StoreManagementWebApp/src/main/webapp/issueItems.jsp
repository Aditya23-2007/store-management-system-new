<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@include file="includes/auth.jsp"%>
<%
    request.setAttribute("activePage", "issueItems");
    request.setAttribute("pageTitle", "Issue / Transfer Items");
%>
<!DOCTYPE html>
<html>
<head>
    <title>Issue / Transfer Items</title>
    <%@include file="includes/header.jsp"%>
</head>
<body>
<div class="app">
    <%@include file="includes/sidebar.jsp"%>
    <main class="main">
        <%@include file="includes/topbar.jsp"%>

        <% if("stock".equals(request.getParameter("error"))) { %>
            <div class="access-alert">Insufficient stock. Transfer quantity must be less than or equal to available stock.</div>
        <% } else if("issued".equals(request.getParameter("success"))) { %>
            <div class="access-alert" style="background:#dcfce7;color:#166534;border-color:#bbf7d0;">Item transfer recorded successfully and stock updated.</div>
        <% } %>

        <div class="page-title-section">
            <div>
                <h2>Department-wise Item Issue / Transfer</h2>
                <p class="role-line">Record single item or bulk quantity transfer with remarks.</p>
            </div>
        </div>

        <div class="cat-layout">
            <div class="cat-form-card">
                <div class="modal-title">Issue Items to Department</div>
                <form action="issueItems" method="post">
                    <div class="form-group">
                        <label>Product / Item</label>
                        <select class="form-control" name="product_id" required>
                            <% try(java.sql.Connection con=com.store.util.DBConnection.getConnection();
                                   java.sql.Statement st=con.createStatement();
                                   java.sql.ResultSet rs=st.executeQuery("SELECT id,name,quantity FROM products ORDER BY name")){
                                   while(rs.next()){ %>
                                <option value="<%=rs.getInt("id")%>"><%=rs.getString("name")%> - Available: <%=rs.getInt("quantity")%></option>
                            <% }} catch(Exception e){} %>
                        </select>
                    </div>

                    <div class="form-group">
                        <label>Department</label>
                        <select class="form-control" name="department_id" required>
                            <% try(java.sql.Connection con=com.store.util.DBConnection.getConnection();
                                   java.sql.Statement st=con.createStatement();
                                   java.sql.ResultSet rs=st.executeQuery("SELECT id,department_name FROM departments ORDER BY department_name")){
                                   while(rs.next()){ %>
                                <option value="<%=rs.getInt("id")%>"><%=rs.getString("department_name")%></option>
                            <% }} catch(Exception e){} %>
                        </select>
                    </div>

                    <div class="form-group">
                        <label>Linked Requirement (Optional)</label>
                        <select class="form-control" name="requirement_id">
                            <option value="0">No linked requirement</option>
                            <% try(java.sql.Connection con=com.store.util.DBConnection.getConnection();
                                   java.sql.Statement st=con.createStatement();
                                   java.sql.ResultSet rs=st.executeQuery("SELECT id,department_name,item_name,quantity,status FROM requirements ORDER BY id DESC")){
                                   while(rs.next()){ %>
                                <option value="<%=rs.getInt("id")%>">#<%=rs.getInt("id")%> - <%=rs.getString("department_name")%> - <%=rs.getString("item_name")%> (<%=rs.getString("status")%>)</option>
                            <% }} catch(Exception e){} %>
                        </select>
                    </div>

                    <div class="form-group">
                        <label>Quantity to Transfer</label>
                        <input class="form-control" type="number" min="1" name="transfer_quantity" required>
                    </div>

                    <div class="form-group">
                        <label>Transfer Type</label>
                        <select class="form-control" name="transfer_type">
                            <option value="Issue">Issue</option>
                            <option value="Replacement">Replacement</option>
                            <option value="Temporary Transfer">Temporary Transfer</option>
                            <option value="Return Adjustment">Return Adjustment</option>
                        </select>
                    </div>

                    <div class="form-group">
                        <label>Issued To / Location</label>
                        <input class="form-control" name="issued_to" placeholder="e.g. CSE Lab, Office, Seminar Hall" required>
                    </div>

                    <div class="form-group">
                        <label>Issued By</label>
                        <input class="form-control" name="issued_by" value="<%=session.getAttribute("username")%>" required>
                    </div>

                    <div class="form-group">
                        <label>Remarks for This Transfer</label>
                        <textarea class="form-control textarea" name="remarks" placeholder="Mention purpose, condition, batch/set details, user acknowledgement, etc." required></textarea>
                    </div>

                    <button class="btn-primary">Save Transfer and Update Stock</button>
                </form>
            </div>

            <div>
                <div class="table-search" style="margin-bottom:16px;"><span>🔍</span><input oninput="filterTable('transfer-table',this.value)" placeholder="Search transfers..."></div>
                <div class="data-table">
                    <table id="transfer-table">
                        <thead><tr><th>ID</th><th>Product</th><th>Department</th><th>Qty</th><th>Type</th><th>Issued To</th><th>By</th><th>Date</th><th>Remarks</th></tr></thead>
                        <tbody>
                        <% try(java.sql.Connection con=com.store.util.DBConnection.getConnection();
                               java.sql.Statement st=con.createStatement();
                               java.sql.ResultSet rs=st.executeQuery("SELECT it.*,p.name product,d.department_name dept FROM item_transfers it LEFT JOIN products p ON it.product_id=p.id LEFT JOIN departments d ON it.department_id=d.id ORDER BY it.id DESC")){
                               while(rs.next()){ %>
                            <tr>
                                <td><%=rs.getInt("id")%></td>
                                <td><%=rs.getString("product")%></td>
                                <td><%=rs.getString("dept")%></td>
                                <td><span class="stock-badge stock-yellow"><%=rs.getInt("transfer_quantity")%></span></td>
                                <td><%=rs.getString("transfer_type")%></td>
                                <td><%=rs.getString("issued_to")%></td>
                                <td><%=rs.getString("issued_by")%></td>
                                <td><%=rs.getDate("transfer_date")%></td>
                                <td><%=rs.getString("remarks")%></td>
                            </tr>
                        <% }} catch(Exception e){ %>
                            <tr><td colspan="9">Error: <%=e.getMessage()%></td></tr>
                        <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </main>
</div>
</body>
</html>
