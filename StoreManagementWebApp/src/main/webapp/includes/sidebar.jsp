<%@page pageEncoding="UTF-8" %>
  <% String roleMenu=(String) session.getAttribute("role"); if (roleMenu==null) roleMenu="user" ;
    roleMenu=roleMenu.toLowerCase(); boolean isAdmin="admin" .equals(roleMenu); boolean isStore="store"
    .equals(roleMenu); boolean isDirector="director" .equals(roleMenu); boolean isUser="user" .equals(roleMenu); %>

    <aside class="sidebar">
      <div class="sidebar-logo">
        <div class="logo-icon"><i class="bi bi-shop"></i></div>
        <span class="logo-text">BSiET STORE</span>
      </div>

      <nav class="sidebar-nav">

        <% if (isAdmin || isStore || isDirector) { %>
          <a class="nav-item <%= " dashboard".equals(request.getAttribute("activePage")) ? "active" : "" %>" href="
            <%=request.getContextPath()%>/dashboard.jsp">
              <span class="nav-icon"><i class="bi bi-grid-1x2-fill"></i></span><span>Dashboard</span>
          </a>
          <% } %>

            <% if (isAdmin || isStore || isDirector) { %>
              <a class="nav-item <%= " products".equals(request.getAttribute("activePage")) ? "active" : "" %>" href="
                <%=request.getContextPath()%>/products.jsp">
                  <span class="nav-icon"><i class="bi bi-box-seam-fill"></i></span><span>Products</span>
              </a>
              <% } %>

                <% if (isAdmin || isStore) { %>
                  <a class="nav-item <%= " categories".equals(request.getAttribute("activePage")) ? "active" : "" %>"
                    href="<%=request.getContextPath()%>/categories.jsp">
                      <span class="nav-icon"><i class="bi bi-tags-fill"></i></span><span>Categories</span>
                  </a>

                  <a class="nav-item <%= " orders".equals(request.getAttribute("activePage")) ? "active" : "" %>" href="
                    <%=request.getContextPath()%>/orders.jsp">
                      <span class="nav-icon"><i class="bi bi-receipt-cutoff"></i></span><span>Orders / Billing</span>
                  </a>

                  <a class="nav-item <%= " sales".equals(request.getAttribute("activePage")) ? "active" : "" %>" href="
                    <%=request.getContextPath()%>/sales.jsp">
                      <span class="nav-icon"><i class="bi bi-credit-card-fill"></i></span><span>Sales</span>
                  </a>
                  <% } %>

                    <% if (isAdmin || isStore || isDirector) { %>
                      <a class="nav-item <%= " suppliers".equals(request.getAttribute("activePage")) ? "active" : "" %>"
                        href="<%=request.getContextPath()%>/suppliers.jsp">
                          <span class="nav-icon"><i class="bi bi-truck"></i></span><span>Suppliers</span>
                      </a>
                      <% } %>

                        <% if (isAdmin) { %>
                          <a class="nav-item <%= " users".equals(request.getAttribute("activePage")) ? "active" : "" %>"
                            href="<%=request.getContextPath()%>/users.jsp">
                              <span class="nav-icon"><i class="bi bi-people-fill"></i></span><span>Users</span>
                          </a>
                          <a class="nav-item <%= "updates".equals(request.getAttribute("activePage")) ? "active" : "" %>"
                            href="<%=request.getContextPath()%>/updates.jsp">
                              <span class="nav-icon"><i class="bi bi-gear-wide-connected"></i></span><span>System Updates</span>
                          </a>
                          <% } %>

                            <% if (isAdmin || isStore || isDirector || isUser) { %>
                              <a class="nav-item <%= " requirements".equals(request.getAttribute("activePage"))
                                ? "active" : "" %>" href="<%=request.getContextPath()%>/requirements.jsp">
                                  <span class="nav-icon"><i
                                      class="bi bi-clipboard-check-fill"></i></span><span>Requirements</span>
                              </a>
                              <% } %>

                                <% if (isAdmin || isDirector) { %>
                                  <a class="nav-item <%= " approvals".equals(request.getAttribute("activePage"))
                                    ? "active" : "" %>" href="<%=request.getContextPath()%>/approvals.jsp">
                                      <span class="nav-icon"><i
                                          class="bi bi-check2-square"></i></span><span>Approvals</span>
                                  </a>
                                  <% } %>

                                    <% if (isAdmin || isStore || isDirector) { %>
                                      <a class="nav-item <%= "purchaseOrders".equals(request.getAttribute("activePage")) ? "active" : "" %>"
                                        href="<%=request.getContextPath()%>/purchaseOrders.jsp">
                                          <span class="nav-icon"><i
                                              class="bi bi-file-earmark-text-fill"></i></span><span>Purchase Orders</span>
                                      </a>

                                      <a class="nav-item <%= " receiveItems".equals(request.getAttribute("activePage"))
                                        ? "active" : "" %>" href="<%=request.getContextPath()%>/receiveItems.jsp">
                                          <span class="nav-icon"><i
                                              class="bi bi-box-arrow-in-down"></i></span><span>Receive Items</span>
                                      </a>

                                      <a class="nav-item <%= " issueItems".equals(request.getAttribute("activePage"))
                                        ? "active" : "" %>" href="<%=request.getContextPath()%>/issueItems.jsp">
                                          <span class="nav-icon"><i
                                              class="bi bi-arrow-left-right"></i></span><span>Issue / Transfer</span>
                                      </a>

                                      <a class="nav-item <%= " scrapItems".equals(request.getAttribute("activePage"))
                                        ? "active" : "" %>" href="<%=request.getContextPath()%>/scrapItems.jsp">
                                          <span class="nav-icon"><i class="bi bi-trash3-fill"></i></span><span>Scrap
                                            Items</span>
                                      </a>

                                      <a class="nav-item <%= " invoices".equals(request.getAttribute("activePage"))
                                        ? "active" : "" %>" href="<%=request.getContextPath()%>/invoices.jsp">
                                          <span class="nav-icon"><i
                                              class="bi bi-file-earmark-arrow-up-fill"></i></span><span>Invoices /
                                            Bills</span>
                                      </a>

                                      <a class="nav-item <%= " payments".equals(request.getAttribute("activePage"))
                                        ? "active" : "" %>" href="<%=request.getContextPath()%>/payments.jsp">
                                          <span class="nav-icon"><i
                                              class="bi bi-currency-rupee"></i></span><span>Payments</span>
                                      </a>

                                      <a class="nav-item <%= " reports".equals(request.getAttribute("activePage"))
                                        ? "active" : "" %>" href="<%=request.getContextPath()%>/reports.jsp">
                                          <span class="nav-icon"><i
                                              class="bi bi-bar-chart-fill"></i></span><span>Reports</span>
                                      </a>
                                      <% } %>
      </nav>

      <div class="sidebar-bottom">
        <a class="nav-item <%= " profile".equals(request.getAttribute("activePage")) ? "active" : "" %>" href="
          <%=request.getContextPath()%>/profile.jsp">
            <span class="nav-icon"><i class="bi bi-person-fill"></i></span><span>Profile</span>
        </a>

        <a class="nav-item" href="<%=request.getContextPath()%>/logout">
          <span class="nav-icon"><i class="bi bi-box-arrow-right"></i></span><span>Logout</span>
        </a>
      </div>
    </aside>