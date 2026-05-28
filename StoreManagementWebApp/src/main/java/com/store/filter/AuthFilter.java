package com.store.filter;

import java.io.IOException;
import javax.servlet.*;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.*;

@WebFilter(urlPatterns={"/dashboard","/products","/categories","/customers","/suppliers","/billing","/reports","/users","/requirements","/approvals","/purchaseOrders","/receiveItems","/payments","/invoiceUpload"})
public class AuthFilter implements Filter {
    @Override public void init(FilterConfig filterConfig) throws ServletException {}
    
    @Override public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain) throws IOException, ServletException {
        HttpServletRequest r=(HttpServletRequest)req; HttpServletResponse h=(HttpServletResponse)res;
        HttpSession s=r.getSession(false);
        if(s==null || (s.getAttribute("username")==null && s.getAttribute("user")==null)) h.sendRedirect(r.getContextPath()+"/login.jsp"); else chain.doFilter(req,res);
    }

    @Override public void destroy() {}
}
