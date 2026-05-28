package com.store.filter;

import java.io.IOException;
import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebFilter("/*")
public class RoleAccessFilter implements Filter {

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        // No initialization required.
    }

    @Override
    public void doFilter(ServletRequest request,
                         ServletResponse response,
                         FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse res = (HttpServletResponse) response;

        String contextPath = req.getContextPath();
        String path = req.getRequestURI().substring(contextPath.length());

        if (isPublicPath(path)) {
            chain.doFilter(request, response);
            return;
        }

        HttpSession session = req.getSession(false);

        if (session == null || session.getAttribute("username") == null) {
            res.sendRedirect(contextPath + "/login.jsp");
            return;
        }

        String role = (String) session.getAttribute("role");
        if (role == null || role.trim().isEmpty()) {
            role = "user";
        }
        role = role.toLowerCase();

        if (!isAllowed(role, path)) {
            if ("user".equals(role)) {
                res.sendRedirect(contextPath + "/requirements.jsp?access=denied");
            } else {
                res.sendRedirect(contextPath + "/dashboard.jsp?access=denied");
            }
            return;
        }

        chain.doFilter(request, response);
    }

    private boolean isPublicPath(String path) {
        return path.equals("/") ||
               path.equals("/login") ||
               path.equals("/login.jsp") ||
               path.equals("/logout") ||
               path.startsWith("/css/") ||
               path.startsWith("/js/") ||
               path.startsWith("/images/") ||
               path.startsWith("/audio/") ||
               path.startsWith("/assets/") ||
               path.startsWith("/uploads/") ||
               path.startsWith("/META-INF/") ||
               path.startsWith("/WEB-INF/");
    }

    private boolean isAllowed(String role, String path) {
        if ("admin".equals(role)) {
            return true;
        }

        if ("store".equals(role)) {
            return matches(path,
                    "/dashboard", "/dashboard.jsp",
                    "/products", "/products.jsp",
                    "/categories", "/categories.jsp",
                    "/orders", "/orders.jsp",
                    "/billing", "/billing.jsp",
                    "/suppliers", "/suppliers.jsp",
                    "/requirements", "/requirements.jsp",
                    "/purchaseOrders", "/purchaseOrders.jsp",
                    "/receiveItems", "/receiveItems.jsp",
                    "/issueItems", "/issueItems.jsp",
                    "/scrapItems", "/scrapItems.jsp",
                    "/invoiceUpload", "/invoices.jsp",
                    "/payments", "/payments.jsp",
                    "/reports", "/reports.jsp", "/reportExport",
                    "/profile.jsp");
        }

        if ("director".equals(role)) {
            return matches(path,
                    "/dashboard", "/dashboard.jsp",
                    "/reports", "/reports.jsp", "/reportExport",
                    "/approvals", "/approvals.jsp",
                    "/requirements", "/requirements.jsp",
                    "/payments", "/payments.jsp",
                    "/purchaseOrders", "/purchaseOrders.jsp",
                    "/receiveItems", "/receiveItems.jsp",
                    "/issueItems", "/issueItems.jsp",
                    "/scrapItems", "/scrapItems.jsp",
                    "/invoices.jsp",
                    "/products", "/products.jsp",
                    "/suppliers", "/suppliers.jsp",
                    "/profile.jsp");
        }

        if ("accounts".equals(role) || "accountant".equals(role)) {
            return matches(path,
                    "/dashboard", "/dashboard.jsp",
                    "/reports", "/reports.jsp", "/reportExport",
                    "/payments", "/payments.jsp",
                    "/invoices.jsp", "/invoiceUpload",
                    "/profile.jsp");
        }

        return matches(path,
                "/requirements", "/requirements.jsp",
                "/profile.jsp");
    }

    private boolean matches(String path, String... allowedPaths) {
        for (String allowed : allowedPaths) {
            if (path.equals(allowed)) {
                return true;
            }
        }
        return false;
    }

    @Override
    public void destroy() {
        // No resources to release.
    }
}
