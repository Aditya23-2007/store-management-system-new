package com.store.servlet;

import com.store.util.DBConnection;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/login")
public class LoginServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        String username = request.getParameter("username");
        String password = request.getParameter("password");

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(
                "SELECT * FROM users WHERE username=? AND password=?")) {

            ps.setString(1, username);
            ps.setString(2, password);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    HttpSession session = request.getSession();

                    String role = rs.getString("role");
                    if (role == null || role.trim().isEmpty()) {
                        role = "user";
                    }
                    role = role.toLowerCase();

                    session.setAttribute("username", username);
                    session.setAttribute("role", role);
                    session.setAttribute("fullName", rs.getString("full_name"));

                    if ("user".equals(role)) {
                        response.sendRedirect("requirements.jsp");
                    } else {
                        response.sendRedirect("dashboard.jsp");
                    }
                } else {
                    request.setAttribute("error", "Invalid Username or Password");
                    request.getRequestDispatcher("login.jsp").forward(request, response);
                }
            }

        } catch(Exception e) {
            request.setAttribute("error", e.getMessage());
            request.getRequestDispatcher("login.jsp").forward(request, response);
        }
    }
}
