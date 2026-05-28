<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@include file="includes/auth.jsp"%>
<%
    request.setAttribute("activePage", "scrapItems");
    request.setAttribute("pageTitle", "Scrap Items");
%>
<!DOCTYPE html>
<html>
<head>
    <title>Scrap Items</title>
    <%@include file="includes/header.jsp"%>
</head>
<body>
<div class="app">
    <%@include file="includes/sidebar.jsp"%>
    <main class="main">
        <%@include file="includes/topbar.jsp"%>

        <% if("stock".equals(request.getParameter("error"))) { %>
            <div class="access-alert">Insufficient stock. Scrap quantity must be available in current inventory.</div>
        <% } else if("scrapped".equals(request.getParameter("success"))) { %>
            <div class="access-alert" style="background:#dcfce7;color:#166534;border-color:#bbf7d0;">Scrap entry saved successfully and inventory stock reduced.</div>
        <% } %>

        <div class="page-title-section">
            <div>
                <h2>Unusable / Scrap Item Entry</h2>
                <p class="role-line">Record unusable items with reason, condition, approval and remarks.</p>
            </div>
        </div>

        <div class="cat-layout">
            <div class="cat-form-card">
                <div class="modal-title">Move Item to Scrap</div>
                <form action="scrapItems" method="post">
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
                        <label>Scrap Quantity</label>
                        <input class="form-control" type="number" min="1" name="scrap_quantity" required>
                    </div>

                    <div class="form-group">
                        <label>Item Condition</label>
                        <select class="form-control" name="item_condition">
                            <option value="Damaged">Damaged</option>
                            <option value="Non-working">Non-working</option>
                            <option value="Broken">Broken</option>
                            <option value="Expired">Expired</option>
                            <option value="Unusable">Unusable</option>
                            <option value="Obsolete">Obsolete</option>
                        </select>
                    </div>

                    <div class="form-group">
                        <label>Scrap Reason</label>
                        <input class="form-control" name="scrap_reason" placeholder="e.g. broken, repair not possible, expired" required>
                    </div>

                    <div class="form-group">
                        <label>Approved By</label>
                        <input class="form-control" name="approved_by" placeholder="Director / Principal / Authority">
                    </div>

                    <div class="form-group">
                        <label>Scrapped By</label>
                        <input class="form-control" name="scrapped_by" value="<%=session.getAttribute("username")%>" required>
                    </div>

                    <div class="form-group">
                        <label>Remarks</label>
                        <textarea class="form-control textarea" name="remarks" placeholder="Mention verification details, physical condition, approval reference, etc." required></textarea>
                    </div>

                    <button class="btn-danger">Save Scrap Entry and Reduce Stock</button>
                </form>
            </div>

            <div>
                <div class="table-search" style="margin-bottom:16px;"><span>🔍</span><input oninput="filterTable('scrap-table',this.value)" placeholder="Search scrap records..."></div>
                <div class="data-table">
                    <table id="scrap-table">
                        <thead><tr><th>ID</th><th>Product</th><th>Qty</th><th>Condition</th><th>Reason</th><th>Approved By</th><th>By</th><th>Date</th><th>Remarks</th></tr></thead>
                        <tbody>
                        <% try(java.sql.Connection con=com.store.util.DBConnection.getConnection();
                               java.sql.Statement st=con.createStatement();
                               java.sql.ResultSet rs=st.executeQuery("SELECT si.*,p.name product FROM scrap_items si LEFT JOIN products p ON si.product_id=p.id ORDER BY si.id DESC")){
                               while(rs.next()){ %>
                            <tr>
                                <td><%=rs.getInt("id")%></td>
                                <td><%=rs.getString("product")%></td>
                                <td><span class="stock-badge stock-red"><%=rs.getInt("scrap_quantity")%></span></td>
                                <td><%=rs.getString("item_condition")%></td>
                                <td><%=rs.getString("scrap_reason")%></td>
                                <td><%=rs.getString("approved_by")%></td>
                                <td><%=rs.getString("scrapped_by")%></td>
                                <td><%=rs.getDate("scrap_date")%></td>
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
