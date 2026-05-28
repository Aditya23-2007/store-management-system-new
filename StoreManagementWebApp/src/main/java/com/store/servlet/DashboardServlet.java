package com.store.servlet;
import com.store.dao.SalesDAO;import java.io.IOException;import javax.servlet.*;import javax.servlet.annotation.WebServlet;import javax.servlet.http.*;
@WebServlet("/dashboard") public class DashboardServlet extends HttpServlet{ protected void doGet(HttpServletRequest r,HttpServletResponse h)throws ServletException,IOException{ r.setAttribute("data",new SalesDAO().dashboard()); r.getRequestDispatcher("dashboard.jsp").forward(r,h); }}
