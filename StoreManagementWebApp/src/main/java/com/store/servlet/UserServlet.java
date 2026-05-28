package com.store.servlet;

import com.store.util.DBConnection;
import java.io.IOException;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet("/users")
public class UserServlet extends HttpServlet {
    @Override protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String del = request.getParameter("delete");
        System.out.println("[UserServlet] doGet called, delete parameter: " + del);
        if (del != null) {
            try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement("DELETE FROM users WHERE id=?")) {
                ps.setInt(1, Integer.parseInt(del));
                int rows = ps.executeUpdate();
                System.out.println("[UserServlet] Deleted user ID " + del + ", rows affected: " + rows);
            } catch(Exception e) {
                System.err.println("[UserServlet] Delete failed: " + e.getMessage());
                e.printStackTrace();
                throw new ServletException(e);
            }
            response.sendRedirect("users.jsp"); return;
        }
        request.getRequestDispatcher("users.jsp").forward(request, response);
    }
    @Override protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String fullName = request.getParameter("full_name");
        String username = request.getParameter("username");
        String email = request.getParameter("email");
        String password = request.getParameter("password");
        String role = request.getParameter("role");
        String address = request.getParameter("address");
        try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(
                "INSERT INTO users(full_name, username, email, password, role, address) VALUES (?,?,?,?,?,?)")) {
            ps.setString(1, fullName); ps.setString(2, username); ps.setString(3, email); ps.setString(4, password); ps.setString(5, role); ps.setString(6, address);
            ps.executeUpdate();
            response.sendRedirect("users.jsp");
        } catch (Exception e) { request.setAttribute("error", e.getMessage()); request.getRequestDispatcher("users.jsp").forward(request, response); }
    }
}
