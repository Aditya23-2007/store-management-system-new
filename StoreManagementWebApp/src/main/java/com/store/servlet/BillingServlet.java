package com.store.servlet;

import com.store.util.DBConnection;
import java.io.IOException;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet("/billing")
public class BillingServlet extends HttpServlet {
    @Override protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException { request.getRequestDispatcher("billing.jsp").forward(request,response); }
    @Override protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        int productId = parseInt(request.getParameter("product_id"));
        int qty = parseInt(request.getParameter("quantity"));
        String customer = request.getParameter("customer_name");
        try (Connection con = DBConnection.getConnection()) {
            con.setAutoCommit(false);
            double price = 0; int stock = 0;
            try (PreparedStatement ps = con.prepareStatement("SELECT price,quantity FROM products WHERE id=?")) {
                ps.setInt(1, productId); ResultSet rs = ps.executeQuery();
                if (!rs.next()) { request.setAttribute("error", "Invalid product selected."); con.rollback(); doGet(request,response); return; }
                price = rs.getDouble("price"); stock = rs.getInt("quantity");
            }
            if (stock < qty) { request.setAttribute("error", "Insufficient stock."); con.rollback(); doGet(request,response); return; }
            try (PreparedStatement ps = con.prepareStatement("INSERT INTO sales(product_id,customer_name,quantity,total_amount,remarks) VALUES (?,?,?,?,?)")) {
                ps.setInt(1, productId); ps.setString(2, customer); ps.setInt(3, qty); ps.setDouble(4, price*qty); ps.setString(5, request.getParameter("remarks")); ps.executeUpdate();
            }
            try (PreparedStatement ps = con.prepareStatement("UPDATE products SET quantity=quantity-? WHERE id=?")) { ps.setInt(1, qty); ps.setInt(2, productId); ps.executeUpdate(); }
            con.commit(); request.setAttribute("success", "Bill generated successfully."); doGet(request,response);
        } catch(Exception e) { throw new ServletException(e); }
    }
    private int parseInt(String s){ try{return Integer.parseInt(s);}catch(Exception e){return 0;} }
}
