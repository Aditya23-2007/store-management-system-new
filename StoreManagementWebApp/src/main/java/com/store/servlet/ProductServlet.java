package com.store.servlet;

import com.store.util.DBConnection;
import java.io.IOException;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet("/products")
public class ProductServlet extends HttpServlet {
    @Override protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String del = request.getParameter("delete");
        if (del != null) {
            try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement("DELETE FROM products WHERE id=?")) {
                ps.setInt(1, Integer.parseInt(del)); ps.executeUpdate();
            } catch(Exception e) { throw new ServletException(e); }
            response.sendRedirect("products.jsp"); return;
        }
        request.getRequestDispatcher("products.jsp").forward(request, response);
    }
    @Override protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String id = request.getParameter("id");
        String name = request.getParameter("name");
        String description = request.getParameter("description");
        String category = request.getParameter("category");
        String supplier = request.getParameter("supplier");
        double price = parseDouble(request.getParameter("price"));
        int quantity = parseInt(firstNonBlank(request.getParameter("quantity"), request.getParameter("stock")));
        String status = quantity <= 0 ? "Out of Stock" : (quantity <= 5 ? "Low Stock" : "In Stock");
        try (Connection con = DBConnection.getConnection()) {
            if (id != null && !id.isBlank()) {
                try (PreparedStatement ps = con.prepareStatement("UPDATE products SET name=?,description=?,category=?,supplier=?,price=?,quantity=?,status=? WHERE id=?")) {
                    ps.setString(1,name); ps.setString(2,description); ps.setString(3,category); ps.setString(4,supplier); ps.setDouble(5,price); ps.setInt(6,quantity); ps.setString(7,status); ps.setInt(8,Integer.parseInt(id)); ps.executeUpdate();
                }
            } else {
                try (PreparedStatement ps = con.prepareStatement("INSERT INTO products(name,description,category,supplier,price,quantity,status) VALUES (?,?,?,?,?,?,?)")) {
                    ps.setString(1,name); ps.setString(2,description); ps.setString(3,category); ps.setString(4,supplier); ps.setDouble(5,price); ps.setInt(6,quantity); ps.setString(7,status); ps.executeUpdate();
                }
            }
            response.sendRedirect("products.jsp");
        } catch(Exception e) { throw new ServletException(e); }
    }
    private int parseInt(String s){ try{return Integer.parseInt(s);}catch(Exception e){return 0;} }
    private double parseDouble(String s){ try{return Double.parseDouble(s);}catch(Exception e){return 0;} }
    private String firstNonBlank(String a, String b){ return a != null && !a.isBlank() ? a : b; }
}
