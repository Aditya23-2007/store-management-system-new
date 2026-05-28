package com.store.servlet;
import com.store.dao.SalesDAO;import java.io.IOException;import javax.servlet.*;import javax.servlet.annotation.WebServlet;import javax.servlet.http.*;
@WebServlet("/reports") public class ReportServlet extends HttpServlet{ protected void doGet(HttpServletRequest r,HttpServletResponse h)throws ServletException,IOException{ r.setAttribute("sales",new SalesDAO().salesReport()); r.getRequestDispatcher("reports.jsp").forward(r,h); }}
