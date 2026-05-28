<%
    if (session.getAttribute("username") == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String role = (String) session.getAttribute("role");
    if (role == null || role.trim().isEmpty()) {
        role = "user";
        session.setAttribute("role", role);
    }
    role = role.toLowerCase();

    String uri = request.getRequestURI();
    boolean allowed = true;

    if (!"admin".equals(role)) {

        if ("store".equals(role)) {
            allowed =
                uri.endsWith("/dashboard.jsp") ||
                uri.endsWith("/products.jsp") ||
                uri.endsWith("/categories.jsp") ||
                uri.endsWith("/orders.jsp") ||
                uri.endsWith("/billing.jsp") ||
                uri.endsWith("/suppliers.jsp") ||
                uri.endsWith("/requirements.jsp") ||
                uri.endsWith("/purchaseOrders.jsp") ||
                uri.endsWith("/receiveItems.jsp") ||
                uri.endsWith("/invoices.jsp") ||
                uri.endsWith("/payments.jsp") ||
                uri.endsWith("/reports.jsp") ||
                uri.endsWith("/profile.jsp");
        }
        else if ("director".equals(role)) {
            allowed =
                uri.endsWith("/dashboard.jsp") ||
                uri.endsWith("/reports.jsp") ||
                uri.endsWith("/approvals.jsp") ||
                uri.endsWith("/requirements.jsp") ||
                uri.endsWith("/payments.jsp") ||
                uri.endsWith("/purchaseOrders.jsp") ||
                uri.endsWith("/receiveItems.jsp") ||
                uri.endsWith("/invoices.jsp") ||
                uri.endsWith("/products.jsp") ||
                uri.endsWith("/suppliers.jsp") ||
                uri.endsWith("/profile.jsp");
        }
        else {
            allowed =
                uri.endsWith("/requirements.jsp") ||
                uri.endsWith("/profile.jsp");
        }
    }

    if (!allowed) {
        if ("user".equals(role)) {
            response.sendRedirect(request.getContextPath() + "/requirements.jsp?access=denied");
        } else {
            response.sendRedirect(request.getContextPath() + "/dashboard.jsp?access=denied");
        }
        return;
    }
%>
