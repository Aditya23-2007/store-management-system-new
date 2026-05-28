package com.store.servlet;

import com.store.util.DBConnection;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet("/api/sales")
public class SalesServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        try (Connection con = DBConnection.getConnection();
             Statement st = con.createStatement();
             ResultSet rs = st.executeQuery("SELECT s.id, p.name as product, s.buyer_type, s.customer_name as buyer, s.quantity, s.unit_price, s.total_amount, s.sale_date, s.remarks FROM sales s LEFT JOIN products p ON s.product_id = p.id ORDER BY s.sale_date DESC, s.id DESC")) {
            
            StringBuilder json = new StringBuilder();
            json.append("[");
            boolean first = true;
            while (rs.next()) {
                if (!first) json.append(",");
                json.append("{");
                json.append("\"id\":").append(rs.getInt("id")).append(",");
                json.append("\"date\":\"").append(rs.getDate("sale_date")).append("\",");
                json.append("\"product\":\"").append(escapeJson(rs.getString("product"))).append("\",");
                json.append("\"qty\":").append(rs.getInt("quantity")).append(",");
                json.append("\"price\":").append(rs.getDouble("unit_price")).append(",");
                json.append("\"total\":").append(rs.getDouble("total_amount")).append(",");
                json.append("\"buyerType\":\"").append(escapeJson(rs.getString("buyer_type"))).append("\",");
                json.append("\"buyer\":\"").append(escapeJson(rs.getString("buyer"))).append("\",");
                json.append("\"remarks\":\"").append(escapeJson(rs.getString("remarks"))).append("\"");
                json.append("}");
                first = false;
            }
            json.append("]");
            out.print(json.toString());
        } catch (Exception e) {
            response.setStatus(500);
            out.print("{\"error\":\"" + e.getMessage() + "\"}");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String action = request.getParameter("action");
        if ("delete".equals(action)) {
            doDelete(request, response);
            return;
        }

        String idStr = request.getParameter("id");
        String date = request.getParameter("date");
        String productName = request.getParameter("product");
        String buyerType = request.getParameter("buyerType");
        String buyer = request.getParameter("buyer");
        String remarks = request.getParameter("remarks");
        int qty = parseInt(request.getParameter("qty"));
        double price = parseDouble(request.getParameter("price"));
        double total = qty * price;

        response.setContentType("application/json");
        PrintWriter out = response.getWriter();

        try (Connection con = DBConnection.getConnection()) {
            // Find product ID
            int productId = -1;
            try (PreparedStatement ps = con.prepareStatement("SELECT id, quantity FROM products WHERE name = ?")) {
                ps.setString(1, productName);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        productId = rs.getInt("id");
                    }
                }
            }
            
            if (productId == -1) {
                response.setStatus(400);
                out.print("{\"error\":\"Product not found\"}");
                return;
            }

            if (idStr != null && !idStr.isEmpty()) {
                // Update
                try (PreparedStatement ps = con.prepareStatement("UPDATE sales SET product_id=?, buyer_type=?, customer_name=?, quantity=?, unit_price=?, total_amount=?, sale_date=?, remarks=? WHERE id=?")) {
                    ps.setInt(1, productId);
                    ps.setString(2, buyerType);
                    ps.setString(3, buyer);
                    ps.setInt(4, qty);
                    ps.setDouble(5, price);
                    ps.setDouble(6, total);
                    ps.setString(7, date);
                    ps.setString(8, remarks);
                    ps.setInt(9, Integer.parseInt(idStr));
                    ps.executeUpdate();
                }
            } else {
                // Insert
                try (PreparedStatement ps = con.prepareStatement("INSERT INTO sales (product_id, buyer_type, customer_name, quantity, unit_price, total_amount, sale_date, remarks) VALUES (?,?,?,?,?,?,?,?)")) {
                    ps.setInt(1, productId);
                    ps.setString(2, buyerType);
                    ps.setString(3, buyer);
                    ps.setInt(4, qty);
                    ps.setDouble(5, price);
                    ps.setDouble(6, total);
                    ps.setString(7, date);
                    ps.setString(8, remarks);
                    ps.executeUpdate();
                }
            }
            out.print("{\"success\":true}");
        } catch (Exception e) {
            response.setStatus(500);
            out.print("{\"error\":\"" + e.getMessage() + "\"}");
        }
    }

    @Override
    protected void doDelete(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String idStr = request.getParameter("id");
        response.setContentType("application/json");
        PrintWriter out = response.getWriter();
        
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement("DELETE FROM sales WHERE id=?")) {
            ps.setInt(1, Integer.parseInt(idStr));
            ps.executeUpdate();
            out.print("{\"success\":true}");
        } catch (Exception e) {
            response.setStatus(500);
            out.print("{\"error\":\"" + e.getMessage() + "\"}");
        }
    }

    private String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "");
    }
    
    private int parseInt(String s) {
        try { return Integer.parseInt(s); } catch (Exception e) { return 0; }
    }
    
    private double parseDouble(String s) {
        try { return Double.parseDouble(s); } catch (Exception e) { return 0.0; }
    }
}
