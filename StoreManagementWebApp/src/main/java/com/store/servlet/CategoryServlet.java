package com.store.servlet;

import com.store.util.DBConnection;
import java.io.IOException;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet("/categories")
public class CategoryServlet extends HttpServlet {
    @Override protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException { request.getRequestDispatcher("categories.jsp").forward(request, response); }
    @Override protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement("INSERT INTO categories(category_name, description) VALUES (?,?)")) {
            ps.setString(1, request.getParameter("category_name"));
            ps.setString(2, request.getParameter("description"));
            ps.executeUpdate();
            response.sendRedirect("categories.jsp");
        } catch (Exception e) { request.setAttribute("error", e.getMessage()); request.getRequestDispatcher("categories.jsp").forward(request,response); }
    }
}
