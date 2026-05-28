package com.store.servlet;

import com.store.util.DBConnection;
import java.io.IOException;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet(urlPatterns={"/requirements","/approvals","/purchaseOrders","/receiveItems","/issueItems","/scrapItems","/payments"})
public class WorkflowServlet extends HttpServlet {
    @Override protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String p = request.getServletPath();
        request.getRequestDispatcher(p.substring(1)+".jsp").forward(request, response);
    }
    @Override protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String path = request.getServletPath();
        try (Connection con = DBConnection.getConnection()) {
            if ("/requirements".equals(path)) {
                try (PreparedStatement ps = con.prepareStatement("INSERT INTO requirements(department_name,requested_by,item_name,quantity,purpose,request_date,status) VALUES (?,?,?,?,?,CURDATE(),'Pending')")) {
                    ps.setString(1, request.getParameter("department_name")); ps.setString(2, request.getParameter("requested_by")); ps.setString(3, request.getParameter("item_name")); ps.setInt(4, parseInt(request.getParameter("quantity"))); ps.setString(5, request.getParameter("purpose")); ps.executeUpdate();
                }
                response.sendRedirect("requirements.jsp"); return;
            }
            if ("/approvals".equals(path)) {
                int reqId = parseInt(request.getParameter("requirement_id")); String status = request.getParameter("approval_status");
                try (PreparedStatement ps = con.prepareStatement("INSERT INTO approvals(requirement_id,approved_by,approval_status,remarks,approval_date) VALUES (?,?,?,?,CURDATE())")) {
                    ps.setInt(1, reqId); ps.setString(2, request.getParameter("approved_by")); ps.setString(3, status); ps.setString(4, request.getParameter("remarks")); ps.executeUpdate();
                }
                try (PreparedStatement ps = con.prepareStatement("UPDATE requirements SET status=? WHERE id=?")) { ps.setString(1, status); ps.setInt(2, reqId); ps.executeUpdate(); }
                response.sendRedirect("approvals.jsp"); return;
            }
            if ("/purchaseOrders".equals(path)) {
                try (PreparedStatement ps = con.prepareStatement("INSERT INTO purchase_orders(po_number, requirement_id, supplier_name, po_date, total_amount, po_status) VALUES (?,?,?,CURDATE(),?,'Generated')")) {
                    ps.setString(1, request.getParameter("po_number")); ps.setInt(2, parseInt(request.getParameter("requirement_id"))); ps.setString(3, request.getParameter("supplier_name")); ps.setDouble(4, parseDouble(request.getParameter("total_amount"))); ps.executeUpdate();
                }
                response.sendRedirect("purchaseOrders.jsp"); return;
            }
            if ("/receiveItems".equals(path)) {
                int productId = parseInt(request.getParameter("product_id"));
                int qty = parseInt(request.getParameter("received_quantity"));
                try (PreparedStatement ps = con.prepareStatement("INSERT INTO received_items(po_id,product_id,received_quantity,received_by,receive_date,remarks) VALUES (?,?,?,?,CURDATE(),?)")) {
                    ps.setInt(1, parseInt(request.getParameter("po_id")));
                    ps.setInt(2, productId);
                    ps.setInt(3, qty);
                    ps.setString(4, request.getParameter("received_by"));
                    ps.setString(5, request.getParameter("remarks"));
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = con.prepareStatement("UPDATE products SET quantity=quantity+?, status=CASE WHEN quantity+?<=0 THEN 'Out of Stock' WHEN quantity+?<=5 THEN 'Low Stock' ELSE 'In Stock' END WHERE id=?")) {
                    ps.setInt(1, qty); ps.setInt(2, qty); ps.setInt(3, qty); ps.setInt(4, productId); ps.executeUpdate();
                }
                response.sendRedirect("receiveItems.jsp?success=received"); return;
            }

            if ("/issueItems".equals(path)) {
                int productId = parseInt(request.getParameter("product_id"));
                int qty = parseInt(request.getParameter("transfer_quantity"));
                int currentStock = 0;
                try (PreparedStatement chk = con.prepareStatement("SELECT quantity FROM products WHERE id=?")) {
                    chk.setInt(1, productId);
                    try (ResultSet rs = chk.executeQuery()) { if (rs.next()) currentStock = rs.getInt(1); }
                }
                if (qty <= 0 || currentStock < qty) {
                    response.sendRedirect("issueItems.jsp?error=stock"); return;
                }
                try (PreparedStatement ps = con.prepareStatement("INSERT INTO item_transfers(product_id,department_id,requirement_id,transfer_quantity,transfer_type,issued_to,issued_by,transfer_date,remarks) VALUES (?,?,?,?,?,?,?,?,?)")) {
                    ps.setInt(1, productId);
                    ps.setInt(2, parseInt(request.getParameter("department_id")));
                    int reqId = parseInt(request.getParameter("requirement_id"));
                    if (reqId > 0) ps.setInt(3, reqId); else ps.setNull(3, java.sql.Types.INTEGER);
                    ps.setInt(4, qty);
                    ps.setString(5, request.getParameter("transfer_type"));
                    ps.setString(6, request.getParameter("issued_to"));
                    ps.setString(7, request.getParameter("issued_by"));
                    ps.setDate(8, new java.sql.Date(System.currentTimeMillis()));
                    ps.setString(9, request.getParameter("remarks"));
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = con.prepareStatement("UPDATE products SET quantity=quantity-?, status=CASE WHEN quantity-?<=0 THEN 'Out of Stock' WHEN quantity-?<=5 THEN 'Low Stock' ELSE 'In Stock' END WHERE id=?")) {
                    ps.setInt(1, qty); ps.setInt(2, qty); ps.setInt(3, qty); ps.setInt(4, productId); ps.executeUpdate();
                }
                response.sendRedirect("issueItems.jsp?success=issued"); return;
            }

            if ("/scrapItems".equals(path)) {
                int productId = parseInt(request.getParameter("product_id"));
                int qty = parseInt(request.getParameter("scrap_quantity"));
                int currentStock = 0;
                try (PreparedStatement chk = con.prepareStatement("SELECT quantity FROM products WHERE id=?")) {
                    chk.setInt(1, productId);
                    try (ResultSet rs = chk.executeQuery()) { if (rs.next()) currentStock = rs.getInt(1); }
                }
                if (qty <= 0 || currentStock < qty) {
                    response.sendRedirect("scrapItems.jsp?error=stock"); return;
                }
                try (PreparedStatement ps = con.prepareStatement("INSERT INTO scrap_items(product_id,scrap_quantity,scrap_reason,item_condition,approved_by,scrapped_by,scrap_date,remarks) VALUES (?,?,?,?,?,?,CURDATE(),?)")) {
                    ps.setInt(1, productId);
                    ps.setInt(2, qty);
                    ps.setString(3, request.getParameter("scrap_reason"));
                    ps.setString(4, request.getParameter("item_condition"));
                    ps.setString(5, request.getParameter("approved_by"));
                    ps.setString(6, request.getParameter("scrapped_by"));
                    ps.setString(7, request.getParameter("remarks"));
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = con.prepareStatement("UPDATE products SET quantity=quantity-?, status=CASE WHEN quantity-?<=0 THEN 'Out of Stock' WHEN quantity-?<=5 THEN 'Low Stock' ELSE 'In Stock' END WHERE id=?")) {
                    ps.setInt(1, qty); ps.setInt(2, qty); ps.setInt(3, qty); ps.setInt(4, productId); ps.executeUpdate();
                }
                response.sendRedirect("scrapItems.jsp?success=scrapped"); return;
            }
            if ("/payments".equals(path)) {
                try (PreparedStatement ps = con.prepareStatement("INSERT INTO payments(invoice_document_id,supplier_name,paid_amount,payment_status,payment_date,transaction_reference,remarks) VALUES (?,?,?,?,CURDATE(),?,?)")) {
                    int invoiceId = parseInt(request.getParameter("invoice_document_id"));
                    ps.setInt(1, invoiceId); ps.setString(2, request.getParameter("supplier_name")); ps.setDouble(3, parseDouble(request.getParameter("paid_amount"))); ps.setString(4, request.getParameter("payment_status")); ps.setString(5, request.getParameter("transaction_reference")); ps.setString(6, request.getParameter("remarks")); ps.executeUpdate();
                    try (PreparedStatement up = con.prepareStatement("UPDATE invoice_documents SET payment_status=? WHERE id=?")) { up.setString(1, request.getParameter("payment_status")); up.setInt(2, invoiceId); up.executeUpdate(); }
                }
                response.sendRedirect("payments.jsp"); return;
            }
        } catch (Exception e) { throw new ServletException(e); }
    }
    private int parseInt(String s){ try{return Integer.parseInt(s);}catch(Exception e){return 0;} }
    private double parseDouble(String s){ try{return Double.parseDouble(s);}catch(Exception e){return 0;} }
}
