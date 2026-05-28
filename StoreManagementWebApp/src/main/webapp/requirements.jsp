<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@include file="includes/auth.jsp"%>
<% 
    request.setAttribute("activePage", "requirements"); 
    request.setAttribute("pageTitle", "Requirements"); 
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <title>Requirements</title>
    <%@include file="includes/header.jsp"%>
</head>
<body>
<div class="app">
    <%@include file="includes/sidebar.jsp"%>
    <main class="main">
        <%@include file="includes/topbar.jsp"%>
        
        <div class="cat-layout">
            <!-- Generate Requirement Card -->
            <div class="cat-form-card">
                <div class="modal-title">Generate Requirement</div>
                <form action="requirements" method="post">
                    <div class="form-group">
                        <label>Department</label>
                        <input class="form-control" name="department_name" required>
                    </div>
                    
                    <div class="form-group">
                        <label>Requested By</label>
                        <input class="form-control" name="requested_by" 
                               value="<%= session.getAttribute("fullName") != null ? session.getAttribute("fullName") : session.getAttribute("username") %>" 
                               readonly>
                    </div>
                    
                    <div class="form-group">
                        <label>Item Name</label>
                        <input class="form-control" name="item_name" required>
                    </div>
                    
                    <div class="form-group">
                        <label>Quantity</label>
                        <input class="form-control" type="number" name="quantity" required>
                    </div>
                    
                    <div class="form-group">
                        <label>Purpose</label>
                        <textarea class="form-control textarea" name="purpose"></textarea>
                    </div>
                    
                    <button class="btn-primary">Submit Requirement</button>
                </form>
            </div>
            
            <!-- Requirements Table -->
            <div>
                <div class="table-search" style="margin-bottom:16px">
                    <span>🔍</span>
                    <input oninput="filterTable('req-table',this.value)" placeholder="Search requirements...">
                </div>
                
                <div class="data-table">
                    <table id="req-table">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Department</th>
                                <th>Requested By</th>
                                <th>Item</th>
                                <th>Qty</th>
                                <th>Status</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% 
                                String currentFullName = (String) session.getAttribute("fullName");
                                String currentUsername = (String) session.getAttribute("username");
                                
                                try (java.sql.Connection con = com.store.util.DBConnection.getConnection(); 
                                     java.sql.PreparedStatement st = con.prepareStatement(
                                         "SELECT * FROM requirements WHERE requested_by = ? OR requested_by = ? ORDER BY id DESC")) {
                                    
                                    st.setString(1, currentFullName != null ? currentFullName : "");
                                    st.setString(2, currentUsername != null ? currentUsername : "");
                                    
                                    try (java.sql.ResultSet rs = st.executeQuery()) {
                                        while (rs.next()) {
                                            String status = rs.getString("status");
                                            String badgeClass = "badge-yellow";
                                            if ("Approved".equalsIgnoreCase(status)) {
                                                badgeClass = "badge-green";
                                            } else if ("Rejected".equalsIgnoreCase(status)) {
                                                badgeClass = "badge-red";
                                            }
                            %>
                            <tr>
                                <td><%= rs.getInt("id") %></td>
                                <td><%= rs.getString("department_name") %></td>
                                <td><%= rs.getString("requested_by") %></td>
                                <td><%= rs.getString("item_name") %></td>
                                <td><%= rs.getInt("quantity") %></td>
                                <td><span class="status-badge <%= badgeClass %>"><%= status %></span></td>
                            </tr>
                            <% 
                                        }
                                    }
                                } catch (Exception e) { 
                            %>
                            <tr>
                                <td colspan="6">Error: <%= e.getMessage() %></td>
                            </tr>
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
